import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/services.dart';
import '../models/room_models.dart';

class RealtimeRoomService {
  static final RealtimeRoomService _instance = RealtimeRoomService._internal();
  factory RealtimeRoomService() => _instance;
  RealtimeRoomService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  FirebaseDatabase get database => _database;
  fs.FirebaseFirestore get firestore => _firestore;

  // Generate 4-digit room code for private rooms
  String _generateRoomCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  // Create a new game room
  Future<GameRoom?> createRoom({
    required String roomName,
    required RoomType type,
    required GameSettings gameSettings,
    int maxPlayers = 10,
  }) async {
    try {
      print('🔥 RealtimeRoom: Starting room creation...');
      print('🔥 RealtimeRoom: Room name: $roomName');
      print('🔥 RealtimeRoom: Room type: ${type.name}');
      print('🔥 RealtimeRoom: Max players: $maxPlayers');
      
      // Check database connection
      print('🔥 RealtimeRoom: Database instance: ${_database.app.name}');
      
      final currentUser = _auth.currentUser;
      print('🔥 RealtimeRoom: Checking authentication...');
      if (currentUser == null) {
        print('❌ RealtimeRoom: User not authenticated');
        return null;
      }
      
      print('✅ RealtimeRoom: User authenticated: ${currentUser.uid}');
      print('✅ RealtimeRoom: User email: ${currentUser.email}');
      print('✅ RealtimeRoom: User display name: ${currentUser.displayName}');

      // Input validation
      print('🔥 RealtimeRoom: Validating room name...');
      if (roomName.trim().isEmpty || roomName.length > 50) {
        print('❌ RealtimeRoom: Invalid room name (empty or too long)');
        return null;
      }
      print('✅ RealtimeRoom: Room name is valid');

      String? roomCode;
      if (type == RoomType.private) {
        print('🔥 RealtimeRoom: Generating room code for private room...');
        roomCode = _generateRoomCode();
        // Check if room code is unique
        while (await _isRoomCodeTaken(roomCode!)) {
          roomCode = _generateRoomCode();
        }
        print('✅ RealtimeRoom: Generated unique room code: $roomCode');
      } else {
        print('🔥 RealtimeRoom: Public room - no code needed');
      }

      // Get user data from Firestore (keep user data there)
      // For now, use default values
      print('🔥 RealtimeRoom: Creating host player object...');
      final hostPlayer = RoomPlayer(
        id: currentUser.uid,
        name: currentUser.displayName ?? 'Player',
        avatar: '🕵️‍♂️',
        rank: 'Iron',
        isHost: true,
        isReady: true,
        joinedAt: DateTime.now(),
        isOnline: true,
      );
      print('✅ RealtimeRoom: Host player created: ${hostPlayer.name}');

      // Create room document
      print('🔥 RealtimeRoom: Creating room reference in database...');
      final roomRef = _database.ref().child('gameRooms').push();
      print('✅ RealtimeRoom: Room reference created: ${roomRef.key}');
      final now = DateTime.now();
      
      print('🔥 RealtimeRoom: Preparing room data...');
      final roomData = {
        'id': roomRef.key!,
        'hostId': currentUser.uid,
        'hostName': hostPlayer.name,
        'hostAvatar': hostPlayer.avatar,
        'type': type.name,
        'roomCode': roomCode,
        'roomName': roomName.trim(),
        'status': RoomStatus.waiting.name,
        'gameSettings': gameSettings.toMap(),
        'players': {
          currentUser.uid: hostPlayer.toMap(),
        },
        'createdAt': ServerValue.timestamp,
        'maxPlayers': maxPlayers,
        'playerVotes': {},
        'sessionWins': {currentUser.uid: 0},
        'sessionLosses': {currentUser.uid: 0},
      };
      print('✅ RealtimeRoom: Room data prepared');

      print('🔥 RealtimeRoom: Writing to database...');
      await roomRef.set(roomData);
      print('✅ RealtimeRoom: Room created successfully in database: ${roomRef.key}');
      
      // Send initial system message
      await sendSystemMessage(roomRef.key!, 'Room created by ${hostPlayer.name}');
      
      // Convert back to GameRoom object
      final room = GameRoom(
        id: roomRef.key!,
        hostId: currentUser.uid,
        hostName: hostPlayer.name,
        hostAvatar: hostPlayer.avatar,
        type: type,
        roomCode: roomCode,
        roomName: roomName.trim(),
        status: RoomStatus.waiting,
        gameSettings: gameSettings,
        players: [hostPlayer],
        createdAt: now,
        maxPlayers: maxPlayers,
        playerVotes: {},
        sessionWins: {currentUser.uid: 0},
        sessionLosses: {currentUser.uid: 0},
      );
      
      return room;
      
    } catch (e, stackTrace) {
      print('RealtimeRoom: Failed to create room: $e');
      print('RealtimeRoom: Stack trace: $stackTrace');
      return null;
    }
  }

  // Check if room code is taken
  Future<bool> _isRoomCodeTaken(String code) async {
    try {
      print('🔥 RealtimeRoom: Checking if room code $code is taken...');
      final query = await _database
          .ref()
          .child('gameRooms')
          .orderByChild('roomCode')
          .equalTo(code)
          .once();

      final isTaken = query.snapshot.value != null;
      print('✅ RealtimeRoom: Room code $code taken: $isTaken');
      return isTaken;
    } catch (e) {
      print('❌ RealtimeRoom: Error checking room code: $e');
      return false;
    }
  }

  // Join a room
  Future<String?> joinRoom(String roomIdentifier, {bool isRoomCode = false}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('RealtimeRoom: User not authenticated');
        return null;
      }

      // Find room
      DatabaseReference? roomRef;
      DataSnapshot? roomSnapshot;
      
      if (isRoomCode) {
        print('RealtimeRoom: Looking for room with code: $roomIdentifier');
        final query = await _database
            .ref()
            .child('gameRooms')
            .orderByChild('roomCode')
            .equalTo(roomIdentifier)
            .once();
            
        if (query.snapshot.value == null) {
          print('RealtimeRoom: No room found with code: $roomIdentifier');
          return null;
        }
        
        final rooms = query.snapshot.value as Map<dynamic, dynamic>;
        final roomId = rooms.keys.first;
        roomRef = _database.ref().child('gameRooms').child(roomId);
        roomSnapshot = await roomRef.once().then((event) => event.snapshot);
      } else {
        print('RealtimeRoom: Looking for room with ID: $roomIdentifier');
        roomRef = _database.ref().child('gameRooms').child(roomIdentifier);
        roomSnapshot = await roomRef.once().then((event) => event.snapshot);
        
        if (!roomSnapshot!.exists) {
          print('RealtimeRoom: Room not found with ID: $roomIdentifier');
          return null;
        }
      }

      final roomData = roomSnapshot!.value as Map<dynamic, dynamic>;
      
      // Check room status
      if (roomData['status'] != RoomStatus.waiting.name) {
        print('RealtimeRoom: Room is not waiting for players');
        return null;
      }

      // Check if user already in room
      final players = roomData['players'] as Map<dynamic, dynamic>? ?? {};
      if (players.containsKey(currentUser.uid)) {
        print('RealtimeRoom: User already in room');
        return roomSnapshot!.key!;
      }

      // Check if room is full
      if (players.length >= (roomData['maxPlayers'] ?? 10)) {
        print('RealtimeRoom: Room is full');
        return null;
      }

      // Create new player
      final newPlayer = RoomPlayer(
        id: currentUser.uid,
        name: currentUser.displayName ?? 'Player',
        avatar: '🕵️‍♂️',
        rank: 'Iron',
        isHost: false,
        isReady: false,
        joinedAt: DateTime.now(),
        isOnline: true,
      );

      // Add player using transaction to avoid race conditions
      final playersRef = roomRef!.child('players').child(currentUser.uid);
      await playersRef.set(newPlayer.toMap());
      
      // Initialize session stats for new player
      await roomRef.child('sessionWins').child(currentUser.uid).set(0);
      await roomRef.child('sessionLosses').child(currentUser.uid).set(0);

      // Send system message
      await sendSystemMessage(roomSnapshot!.key!, '${newPlayer.name} joined the room');

      print('RealtimeRoom: Successfully joined room: ${roomSnapshot!.key}');
      return roomSnapshot!.key!;
    } catch (e) {
      print('RealtimeRoom: Error joining room: $e');
      return null;
    }
  }

  // Leave room
  Future<bool> leaveRoom(String roomId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      print('RealtimeRoom: User ${currentUser.uid} leaving room $roomId');

      final roomRef = _database.ref().child('gameRooms').child(roomId);
      final roomSnapshot = await roomRef.once().then((event) => event.snapshot);
      
      if (!roomSnapshot.exists) {
        print('RealtimeRoom: Room does not exist');
        return false;
      }

      final roomData = roomSnapshot!.value as Map<dynamic, dynamic>;
      final players = roomData['players'] as Map<dynamic, dynamic>? ?? {};
      
      if (!players.containsKey(currentUser.uid)) {
        print('RealtimeRoom: Player not in room');
        return false;
      }

      final isHost = roomData['hostId'] == currentUser.uid;
      
      if (isHost) {
        print('RealtimeRoom: Host is leaving room');
        
        if (players.length <= 1) {
          // Delete room if host leaves and no other players
          await roomRef.remove();
          print('RealtimeRoom: Deleted empty room');
        } else {
          // Transfer host to next player
          final remainingPlayers = Map<dynamic, dynamic>.from(players);
          remainingPlayers.remove(currentUser.uid);
          
          final newHostId = remainingPlayers.keys.first;
          final newHostData = remainingPlayers[newHostId] as Map<dynamic, dynamic>;
          
          // Update new host
          await roomRef.child('players').child(newHostId).update({
            'isHost': true,
            'isReady': true,
          });
          
          // Update room host info
          await roomRef.update({
            'hostId': newHostId,
            'hostName': newHostData['name'],
            'hostAvatar': newHostData['avatar'],
          });
          
          // Remove leaving player
          await roomRef.child('players').child(currentUser.uid).remove();
          await roomRef.child('sessionWins').child(currentUser.uid).remove();
          await roomRef.child('sessionLosses').child(currentUser.uid).remove();
          
          print('RealtimeRoom: Transferred host to ${newHostData['name']}');
        }
      } else {
        // Just remove player
        await roomRef.child('players').child(currentUser.uid).remove();
        await roomRef.child('sessionWins').child(currentUser.uid).remove();
        await roomRef.child('sessionLosses').child(currentUser.uid).remove();
      }

      print('RealtimeRoom: Successfully left room $roomId');
      return true;
    } catch (e) {
      print('RealtimeRoom: Error leaving room: $e');
      return false;
    }
  }

  // Toggle ready status
  Future<bool> toggleReadyStatus(String roomId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final playerRef = _database.ref().child('gameRooms').child(roomId).child('players').child(currentUser.uid);
      final playerSnapshot = await playerRef.once().then((event) => event.snapshot);
      
      if (!playerSnapshot.exists) return false;

      final playerData = playerSnapshot.value as Map<dynamic, dynamic>;
      final isHost = playerData['isHost'] == true;
      
      // Host is always ready, others can toggle
      if (!isHost) {
        final currentReady = playerData['isReady'] == true;
        await playerRef.update({'isReady': !currentReady});
        
        final status = !currentReady ? 'ready' : 'not ready';
        await sendSystemMessage(roomId, '${playerData['name']} is $status');
      }

      return true;
    } catch (e) {
      print('RealtimeRoom: Error toggling ready status: $e');
      return false;
    }
  }

  // Start game
  Future<bool> startGame(String roomId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final roomRef = _database.ref().child('gameRooms').child(roomId);
      final roomSnapshot = await roomRef.once().then((event) => event.snapshot);
      
      if (!roomSnapshot.exists) return false;

      final roomData = roomSnapshot!.value as Map<dynamic, dynamic>;
      
      // Check if user is host
      if (roomData['hostId'] != currentUser.uid) return false;

      final players = roomData['players'] as Map<dynamic, dynamic>;
      final playersList = players.values.cast<Map<dynamic, dynamic>>().toList();
      
      // Check if all non-host players are ready
      final nonHostPlayers = playersList.where((p) => p['isHost'] != true).toList();
      final notReadyPlayers = nonHostPlayers.where((p) => p['isReady'] != true).toList();
      
      if (notReadyPlayers.isNotEmpty) {
        print('RealtimeRoom: Players not ready: ${notReadyPlayers.map((p) => p['name']).join(', ')}');
        return false;
      }

      // Check minimum players
      if (playersList.length < 2) {
        print('RealtimeRoom: Not enough players');
        return false;
      }

      // Get game settings
      final gameSettings = roomData['gameSettings'] as Map<dynamic, dynamic>;
      int spyCount = gameSettings['spyCount'] ?? 1;
      
      // Adjust spy count if needed
      if (spyCount >= playersList.length) {
        spyCount = playersList.length - 1;
        if (spyCount < 1) spyCount = 1;
      }

      // Select random word
      final word = await _selectRandomWord(gameSettings['category'] ?? '');
      if (word == null) return false;

      // Assign roles
      final spyAssignments = _assignRoles(playersList.length, spyCount);
      
      // Update players with roles
      final updatedPlayers = <String, Map<String, dynamic>>{};
      for (int i = 0; i < playersList.length; i++) {
        final player = playersList[i];
        final role = spyAssignments[i] ? PlayerRole.spy.name : PlayerRole.detective.name;
        updatedPlayers[player['id']] = {
          ...Map<String, dynamic>.from(player),
          'assignedRole': role,
        };
      }

      // Update room
      await roomRef.update({
        'status': RoomStatus.starting.name,
        'startedAt': ServerValue.timestamp,
        'currentWord': word,
        'spyAssignments': spyAssignments,
        'players': updatedPlayers,
        'playerVotes': {}, // Clear votes
      });

      await sendSystemMessage(roomId, 'Game started! Check your roles.');

      return true;
    } catch (e) {
      print('RealtimeRoom: Error starting game: $e');
      return false;
    }
  }

  // Assign roles randomly
  List<bool> _assignRoles(int playerCount, int spyCount) {
    final assignments = List<bool>.filled(playerCount, false);
    final spyIndices = <int>[];
    final random = Random();

    while (spyIndices.length < spyCount) {
      final index = random.nextInt(playerCount);
      if (!spyIndices.contains(index)) {
        spyIndices.add(index);
        assignments[index] = true;
      }
    }

    return assignments;
  }

  // Select random word
  Future<String?> _selectRandomWord(String category) async {
    try {
      final raw = await rootBundle.loadString('assets/data/categories.json');
      final Map<String, dynamic> categories = json.decode(raw);
      
      final words = categories[category] as List<dynamic>?;
      if (words == null || words.isEmpty) return null;

      final random = Random();
      return words[random.nextInt(words.length)] as String;
    } catch (e) {
      print('RealtimeRoom: Error selecting word: $e');
      return null;
    }
  }

  // Submit vote
  Future<bool> submitVote(String roomId, String voterId, String votedForId) async {
    try {
      print('RealtimeRoom: Submitting vote - Room: $roomId, Voter: $voterId, VotedFor: $votedForId');
      
      final voteRef = _database.ref().child('gameRooms').child(roomId).child('playerVotes').child(voterId);
      
      // Use transaction to ensure atomic voting
      final result = await voteRef.runTransaction((Object? currentValue) {
        if (currentValue != null) {
          print('RealtimeRoom: User $voterId already voted');
          return Transaction.abort();
        }
        
        print('RealtimeRoom: Setting vote for $voterId to $votedForId');
        return Transaction.success(votedForId);
      });
      
      if (result.committed) {
        print('RealtimeRoom: Vote committed successfully');
        return true;
      } else {
        print('RealtimeRoom: Vote transaction aborted - already voted');
        return false;
      }
    } catch (e) {
      print('RealtimeRoom: Error submitting vote: $e');
      return false;
    }
  }

  // Update room
  Future<bool> updateRoom(String roomId, Map<String, dynamic> updates) async {
    try {
      final roomRef = _database.ref().child('gameRooms').child(roomId);
      await roomRef.update(updates);
      return true;
    } catch (e) {
      print('RealtimeRoom: Error updating room: $e');
      return false;
    }
  }

  // Get room by ID
  Stream<GameRoom?> getRoomById(String roomId) {
    return _database
        .ref()
        .child('gameRooms')
        .child(roomId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return null;
      
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return _convertToGameRoom(roomId, data);
      } catch (e) {
        print('RealtimeRoom: Error converting room data: $e');
        return null;
      }
    }).asBroadcastStream();
  }

  // Get public rooms
  Stream<List<GameRoom>> getPublicRooms() {
    return _database
        .ref()
        .child('gameRooms')
        .orderByChild('type')
        .equalTo(RoomType.public.name)
        .onValue
        .map((event) {
      final rooms = <GameRoom>[];
      
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          try {
            final roomData = value as Map<dynamic, dynamic>;
            if (roomData['status'] == RoomStatus.waiting.name) {
              final room = _convertToGameRoom(key, roomData);
              rooms.add(room);
            }
          } catch (e) {
            print('RealtimeRoom: Error parsing room $key: $e');
          }
        });
      }
      
      // Sort by creation date (newest first)
      rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return rooms;
    }).asBroadcastStream();
  }

  // Convert Realtime Database data to GameRoom
  GameRoom _convertToGameRoom(String roomId, Map<dynamic, dynamic> data) {
    final playersData = data['players'] as Map<dynamic, dynamic>? ?? {};
    final players = playersData.values
        .map((p) => RoomPlayer.fromMap(Map<String, dynamic>.from(p as Map)))
        .toList();

    final spyAssignmentsList = data['spyAssignments'] as List<dynamic>?;
    final spyAssignments = spyAssignmentsList?.cast<bool>();

    final votesData = data['playerVotes'] as Map<dynamic, dynamic>? ?? {};
    final playerVotes = votesData.map((k, v) => MapEntry(k.toString(), v.toString()));

    final winsData = data['sessionWins'] as Map<dynamic, dynamic>? ?? {};
    final sessionWins = winsData.map((k, v) => MapEntry(k.toString(), v as int));

    final lossesData = data['sessionLosses'] as Map<dynamic, dynamic>? ?? {};
    final sessionLosses = lossesData.map((k, v) => MapEntry(k.toString(), v as int));

    final gameSettingsData = data['gameSettings'] as Map<dynamic, dynamic>? ?? {};
    final gameSettings = GameSettings.fromMap(Map<String, dynamic>.from(gameSettingsData));

    return GameRoom(
      id: roomId,
      hostId: data['hostId']?.toString() ?? '',
      hostName: data['hostName']?.toString() ?? '',
      hostAvatar: data['hostAvatar']?.toString() ?? '🕵️‍♂️',
      type: RoomType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RoomType.public,
      ),
      roomCode: data['roomCode']?.toString(),
      roomName: data['roomName']?.toString() ?? '',
      status: RoomStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RoomStatus.waiting,
      ),
      gameSettings: gameSettings,
      players: players,
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
      startedAt: data['startedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['startedAt'] as int)
          : null,
      finishedAt: data['finishedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['finishedAt'] as int)
          : null,
      maxPlayers: data['maxPlayers'] as int? ?? 10,
      currentWord: data['currentWord']?.toString(),
      spyAssignments: spyAssignments,
      playerVotes: playerVotes.isNotEmpty ? playerVotes : null,
      sessionWins: sessionWins.isNotEmpty ? sessionWins : null,
      sessionLosses: sessionLosses.isNotEmpty ? sessionLosses : null,
      currentRound: data['currentRound'] as int?,
      timerPaused: data['timerPaused'] as bool?,
    );
  }

  // Send system message
  Future<void> sendSystemMessage(String roomId, String message) async {
    try {
      final messageRef = _database.ref().child('gameRooms').child(roomId).child('messages').push();
      await messageRef.set({
        'senderId': 'system',
        'senderName': 'System',
        'message': message,
        'timestamp': ServerValue.timestamp,
        'isSystemMessage': true,
      });
    } catch (e) {
      print('RealtimeRoom: Error sending system message: $e');
    }
  }

  // End game
  Future<bool> endGame(String roomId, {required bool spiesWin}) async {
    try {
      print('RealtimeRoom: Ending game - Room: $roomId, Spies win: $spiesWin');

      final roomRef = _database.ref().child('gameRooms').child(roomId);
      final roomSnapshot = await roomRef.once().then((event) => event.snapshot);
      
      if (!roomSnapshot.exists) {
        print('RealtimeRoom: Room not found');
        return false;
      }

      // Update room status to finished
      await roomRef.update({
        'status': RoomStatus.finished.name,
        'finishedAt': ServerValue.timestamp,
        'spiesWon': spiesWin,
      });

      // Send system message about game end
      final winner = spiesWin ? 'Spies' : 'Detectives';
      await sendSystemMessage(roomId, 'Game ended! $winner won!');

      print('RealtimeRoom: Game ended successfully');
      return true;
    } catch (e) {
      print('RealtimeRoom: Error ending game: $e');
      return false;
    }
  }

  // Send chat message
  Future<bool> sendMessage(String roomId, String message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final messageRef = _database.ref().child('gameRooms').child(roomId).child('messages').push();
      await messageRef.set({
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Player',
        'message': message.trim(),
        'timestamp': ServerValue.timestamp,
        'isSystemMessage': false,
      });

      return true;
    } catch (e) {
      print('RealtimeRoom: Error sending message: $e');
      return false;
    }
  }

  // Get messages stream
  Stream<List<Map<String, dynamic>>> getMessagesStream(String roomId) {
    return _database
        .ref()
        .child('gameRooms')
        .child(roomId)
        .child('messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final messages = <Map<String, dynamic>>[];
      
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
            messages.add(Map<String, dynamic>.from(value as Map));
          }
        });
        
        // Sort by timestamp
        messages.sort((a, b) {
          final aTime = a['timestamp'] as int? ?? 0;
          final bTime = b['timestamp'] as int? ?? 0;
          return aTime.compareTo(bTime);
        });
      }
      
      return messages;
    });
  }

  // Clean up old rooms
  Future<void> cleanupOldRooms() async {
    try {
      print('RealtimeRoom: Starting room cleanup...');
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
      
      final query = await _database
          .ref()
          .child('gameRooms')
          .orderByChild('createdAt')
          .endAt(oneDayAgo)
          .once();

      if (query.snapshot.value != null) {
        final oldRooms = query.snapshot.value as Map<dynamic, dynamic>;
        
        for (final roomId in oldRooms.keys) {
          await _database.ref().child('gameRooms').child(roomId).remove();
          print('RealtimeRoom: Removed old room: $roomId');
        }
        
        print('RealtimeRoom: Cleaned up ${oldRooms.length} old rooms');
      } else {
        print('RealtimeRoom: No old rooms to cleanup');
      }
    } catch (e) {
      print('RealtimeRoom: Error cleaning up old rooms: $e');
    }
  }
}