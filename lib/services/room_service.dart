import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../models/room_models.dart';
import 'realtime_voting_service.dart';

class RoomService {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RealtimeVotingService _votingService = RealtimeVotingService();
  
  // Expose firestore for external access when needed
  FirebaseFirestore get firestore => _firestore;
  
  FirebaseAuth get auth => _auth;
  
  // Expose voting service
  RealtimeVotingService get votingService => _votingService;

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
      print('Creating room: $roomName (${type.name})');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Error: User not authenticated');
        return null;
      }

      // Input validation
      if (roomName.trim().isEmpty || roomName.length > 50) {
        print('Error: Invalid room name');
        return null;
      }
      
      if (gameSettings.playerCount < 3 || gameSettings.playerCount > 10) {
        print('Error: Invalid player count');
        return null;
      }
      
      if (gameSettings.spyCount < 1 || gameSettings.spyCount >= gameSettings.playerCount) {
        print('Error: Invalid spy count');
        return null;
      }

      // Get user data for proper player info
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.exists ? userDoc.data()! : {};

      String? roomCode;
      if (type == RoomType.private) {
        roomCode = _generateRoomCode();
        // Ensure room code is unique
        while (await _isRoomCodeTaken(roomCode!)) {
          roomCode = _generateRoomCode();
        }
        print('Generated room code: $roomCode');
      }

      // Create host player with actual user data
      final hostPlayer = RoomPlayer(
        id: currentUser.uid,
        name: userData['displayName'] ?? currentUser.displayName ?? 'Player',
        avatar: userData['avatarEmoji'] ?? '🕵️‍♂️',
        rank: userData['rank'] ?? 'Iron',
        isHost: true,
        isReady: true,
        joinedAt: DateTime.now(),
        isOnline: true,
      );

      // Create room document with proper timestamp
      final roomDoc = _firestore.collection('gameRooms').doc();
      final now = DateTime.now();
      final room = GameRoom(
        id: roomDoc.id,
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
      );

      // Use FieldValue.serverTimestamp() for consistency
      final firestoreData = room.toFirestore();
      firestoreData['createdAt'] = FieldValue.serverTimestamp();
      
      await roomDoc.set(firestoreData).timeout(const Duration(seconds: 10));
      print('Room created successfully: ${room.id}');
      
      // Send initial system message
      await sendSystemMessage(room.id, 'Room created by ${hostPlayer.name}');
      
      // Validate room integrity after creation
      await _validateRoomIntegrity(room.id);
      
      return room;
      
    } catch (e, stackTrace) {
      print('Failed to create room: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Join a room by code or room ID
  // Validate room data integrity
  Future<bool> _validateRoomIntegrity(String roomId) async {
    try {
      final roomDoc = await _firestore.collection('gameRooms').doc(roomId).get();
      if (!roomDoc.exists) return false;
      
      final room = GameRoom.fromFirestore(roomDoc);
      final hostCount = room.players.where((p) => p.isHost).length;
      
      if (hostCount != 1) {
        print('🚨 CRITICAL ERROR: Room $roomId has $hostCount hosts instead of 1!');
        
        // Fix the room by ensuring only the hostId user is marked as host
        final fixedPlayers = room.players.map((player) {
          return player.copyWith(isHost: player.id == room.hostId);
        }).toList();
        
        await roomDoc.reference.update({
          'players': fixedPlayers.map((p) => p.toMap()).toList(),
        });
        
        print('✅ Fixed room $roomId host assignment');
      }
      
      return true;
    } catch (e) {
      print('Error validating room integrity: $e');
      return false;
    }
  }
  
  Future<String?> joinRoom(String roomIdentifier, {bool isRoomCode = false}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Error: User not authenticated');
        return null;
      }

      // Input validation
      if (roomIdentifier.trim().isEmpty) {
        print('Error: Invalid room identifier');
        return null;
      }

      // Get or create user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      Map<String, dynamic> userData;
      
      if (!userDoc.exists) {
        print('User document not found, creating default...');
        userData = {
          'displayName': currentUser.displayName ?? 'Player',
          'avatarEmoji': '🕵️‍♂️',
          'rank': 'Iron',
          'xp': 0,
        };
        // Create the user document
        await _firestore.collection('users').doc(currentUser.uid).set({
          ...userData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        userData = userDoc.data()!;
      }

      // Find room with better error handling
      DocumentSnapshot? roomDoc;
      
      if (isRoomCode) {
        print('Looking for room with code: $roomIdentifier');
        final querySnapshot = await _firestore
            .collection('gameRooms')
            .where('roomCode', isEqualTo: roomIdentifier)
            .where('status', whereIn: [RoomStatus.waiting.name])
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isEmpty) {
          print('No room found with code: $roomIdentifier');
          return null;
        }
        roomDoc = querySnapshot.docs.first;
      } else {
        print('Looking for room with ID: $roomIdentifier');
        roomDoc = await _firestore.collection('gameRooms').doc(roomIdentifier).get();
        
        if (!roomDoc.exists) {
          print('Room not found with ID: $roomIdentifier');
          return null;
        }
      }

      final room = GameRoom.fromFirestore(roomDoc);
      print('Found room: ${room.roomName}, Status: ${room.status}, Players: ${room.players.length}/${room.maxPlayers}');

      // Check various conditions
      if (room.status != RoomStatus.waiting) {
        print('Room is not waiting for players. Status: ${room.status}');
        return null;
      }

      if (room.players.any((p) => p.id == currentUser.uid)) {
        print('User already in room, returning room ID');
        return room.id; // User is already in room, just return the ID
      }

      if (room.players.length >= room.maxPlayers) {
        print('Room is full: ${room.players.length}/${room.maxPlayers}');
        return null;
      }

      // Create player
      final newPlayer = RoomPlayer(
        id: currentUser.uid,
        name: userData['displayName'] ?? 'Unknown',
        avatar: userData['avatarEmoji'] ?? '🕵️‍♂️',
        rank: userData['rank'] ?? 'Iron',
        isHost: false, // ✅ CRITICAL: Always false for joining players
        isReady: false,
        joinedAt: DateTime.now(),
        isOnline: true,
      );
      
      print('DEBUG: Creating new player - ${newPlayer.name} (${newPlayer.id}) - isHost: ${newPlayer.isHost}');

      // Use transaction to avoid race conditions
      await _firestore.runTransaction((transaction) async {
        final roomDocRef = roomDoc!.reference;
        final freshRoomDoc = await transaction.get(roomDocRef);
        if (!freshRoomDoc.exists) {
          throw Exception('Room no longer exists');
        }
        
        final freshRoom = GameRoom.fromFirestore(freshRoomDoc);
        
        // Re-check conditions with fresh data
        if (freshRoom.players.length >= freshRoom.maxPlayers) {
          throw Exception('Room became full');
        }
        
        if (freshRoom.players.any((p) => p.id == currentUser.uid)) {
          return; // Already joined
        }
        
        final updatedPlayers = List<RoomPlayer>.from(freshRoom.players)..add(newPlayer);
        
        print('DEBUG: Before update - ${freshRoom.players.length} players:');
        for (var p in freshRoom.players) {
          print('  - ${p.name} (${p.id}) isHost: ${p.isHost}');
        }
        print('DEBUG: After adding new player - ${updatedPlayers.length} players:');
        for (var p in updatedPlayers) {
          print('  - ${p.name} (${p.id}) isHost: ${p.isHost}');
        }
        
        final playersData = updatedPlayers.map((p) => p.toMap()).toList();
        print('DEBUG: Players data being saved to Firestore:');
        for (var pData in playersData) {
          print('  - ${pData['name']} (${pData['id']}) isHost: ${pData['isHost']}');
        }
        
        transaction.update(roomDocRef, {
          'players': playersData,
        });
      });

      // Send system message
      await sendSystemMessage(room.id, '${newPlayer.name} joined the room');
      
      // Validate room integrity after joining
      await _validateRoomIntegrity(room.id);

      print('Successfully joined room: ${room.id}');
      return room.id;
    } catch (e) {
      print('Error joining room: $e');
      return null;
    }
  }

  // Leave a room
  Future<bool> leaveRoom(String roomId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      print('User ${currentUser.uid} leaving room $roomId');

      // Use transaction for atomic updates
      await _firestore.runTransaction((transaction) async {
        final roomDoc = await transaction.get(
          _firestore.collection('gameRooms').doc(roomId)
        );
        
        if (!roomDoc.exists) {
          print('Room $roomId does not exist');
          return false;
        }

        final room = GameRoom.fromFirestore(roomDoc);
        final playerIndex = room.players.indexWhere((p) => p.id == currentUser.uid);
        
        if (playerIndex == -1) {
          print('Player not in room');
          return false;
        }

        final leavingPlayer = room.players[playerIndex];
        final updatedPlayers = List<RoomPlayer>.from(room.players)..removeAt(playerIndex);

        if (leavingPlayer.isHost) {
          print('Host is leaving room');
          
          if (updatedPlayers.isEmpty) {
            // Delete room if host leaves and no other players
            print('Deleting empty room');
            transaction.delete(roomDoc.reference);
            
            // Delete messages subcollection (do this outside transaction)
            final messagesQuery = await _firestore
                .collection('gameRooms')
                .doc(roomId)
                .collection('messages')
                .get();
            
            final batch = _firestore.batch();
            for (final doc in messagesQuery.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
          } else {
            // Transfer host to next player
            updatedPlayers[0] = updatedPlayers[0].copyWith(isHost: true, isReady: true);
            
            transaction.update(roomDoc.reference, {
              'players': updatedPlayers.map((p) => p.toMap()).toList(),
              'hostId': updatedPlayers[0].id,
              'hostName': updatedPlayers[0].name,
              'hostAvatar': updatedPlayers[0].avatar,
            });
            
            print('Transferred host to ${updatedPlayers[0].name}');
          }
        } else if (updatedPlayers.isEmpty) {
          // Delete room if last player leaves
          print('Last player leaving, deleting room');
          transaction.delete(roomDoc.reference);
        } else {
          // Just remove player
          transaction.update(roomDoc.reference, {
            'players': updatedPlayers.map((p) => p.toMap()).toList(),
          });
        }
      });

      print('Successfully left room $roomId');
      return true;
    } catch (e) {
      print('Error leaving room: $e');
      return false;
    }
  }

  // Toggle player ready status
  Future<bool> toggleReadyStatus(String roomId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final roomDoc = await _firestore.collection('gameRooms').doc(roomId).get();
      if (!roomDoc.exists) return false;

      final room = GameRoom.fromFirestore(roomDoc);
      final playerIndex = room.players.indexWhere((p) => p.id == currentUser.uid);
      
      if (playerIndex == -1) return false;

      final updatedPlayers = List<RoomPlayer>.from(room.players);
      final currentPlayer = updatedPlayers[playerIndex];
      
      // Host is always ready, others can toggle
      if (!currentPlayer.isHost) {
        updatedPlayers[playerIndex] = currentPlayer.copyWith(isReady: !currentPlayer.isReady);

        await roomDoc.reference.update({
          'players': updatedPlayers.map((p) => p.toMap()).toList(),
        });

        final status = updatedPlayers[playerIndex].isReady ? 'ready' : 'not ready';
        await sendSystemMessage(roomId, '${currentPlayer.name} is $status');
      }

      return true;
    } catch (e) {
      print('Error toggling ready status: $e');
      return false;
    }
  }

  // Start game (host only)
  Future<bool> startGame(String roomId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final roomDoc = await _firestore.collection('gameRooms').doc(roomId).get();
      if (!roomDoc.exists) return false;

      final room = GameRoom.fromFirestore(roomDoc);
      
      // Check if user is host
      if (room.hostId != currentUser.uid) return false;

      // Check if all players are ready
      final nonHostPlayers = room.players.where((p) => !p.isHost).toList();
      
      // Debug logging
      print('DEBUG: Checking ready status for ${nonHostPlayers.length} non-host players');
      for (final player in nonHostPlayers) {
        print('DEBUG: Player ${player.name} (${player.id}) - isHost: ${player.isHost}, isReady: ${player.isReady}');
      }
      
      final notReadyPlayers = nonHostPlayers.where((p) => !p.isReady).toList();
      if (notReadyPlayers.isNotEmpty) {
        print('DEBUG: Players not ready: ${notReadyPlayers.map((p) => p.name).join(', ')}');
        return false;
      }

      // Check minimum players (allow 2 for testing)
      if (room.players.length < 2) {
        print('DEBUG: Not enough players - need at least 2, have ${room.players.length}');
        return false;
      }
      
      // Adjust spy count if it's too high for total players
      int adjustedSpyCount = room.gameSettings.spyCount;
      if (adjustedSpyCount >= room.players.length) {
        // Ensure at least one detective among all players
        adjustedSpyCount = room.players.length - 1;
        // But ensure at least 1 spy
        if (adjustedSpyCount < 1) adjustedSpyCount = 1;
        print('DEBUG: Adjusted spy count from ${room.gameSettings.spyCount} to $adjustedSpyCount for ${room.players.length} total players');
      }
      
      print('DEBUG: Final spy count: $adjustedSpyCount, Total players: ${room.players.length}');

      // Load game categories and select word
      final word = await _selectRandomWord(room.gameSettings.category);
      if (word == null) return false;

      // Assign roles to ALL players including host
      final spyAssignments = _assignRoles(room.players.length, adjustedSpyCount);
      
      // Update player roles
      final updatedPlayers = <RoomPlayer>[];
      for (int i = 0; i < room.players.length; i++) {
        final player = room.players[i];
        final role = spyAssignments[i] ? PlayerRole.spy : PlayerRole.detective;
        updatedPlayers.add(player.copyWith(assignedRole: role));
      }

      // Update room status to starting (game session begins)
      await roomDoc.reference.update({
        'status': RoomStatus.starting.name,
        'startedAt': FieldValue.serverTimestamp(),
        'currentWord': word,
        'spyAssignments': spyAssignments,
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'playerVotes': {}, // Initialize empty votes map
      });

      await sendSystemMessage(roomId, 'Game started! Check your roles.');

      return true;
    } catch (e) {
      print('Error starting game: $e');
      return false;
    }
  }

  // Assign roles randomly (legacy method - still used elsewhere)
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

  // This method is no longer needed as we use _assignRoles for all players

  // Select random word from category
  Future<String?> _selectRandomWord(String category) async {
    try {
      final raw = await rootBundle.loadString('assets/data/categories.json');
      final Map<String, dynamic> categories = json.decode(raw);
      
      final words = categories[category] as List<dynamic>?;
      if (words == null || words.isEmpty) return null;

      final random = Random();
      return words[random.nextInt(words.length)] as String;
    } catch (e) {
      print('Error selecting word: $e');
      return null;
    }
  }

  // Check if room code is already taken
  Future<bool> _isRoomCodeTaken(String code) async {
    try {
      final query = await _firestore
          .collection('gameRooms')
          .where('roomCode', isEqualTo: code)
          .where('status', whereIn: [RoomStatus.waiting.name, RoomStatus.inGame.name])
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get public rooms
  Stream<List<GameRoom>> getPublicRooms() {
    print('🔍 Fetching public rooms...');
    
    // Try with index first, fallback to simple query
    return _firestore
        .collection('gameRooms')
        .where('type', isEqualTo: RoomType.public.name)
        .where('status', isEqualTo: RoomStatus.waiting.name)
        .orderBy('createdAt', descending: true)
        .limit(20)
.snapshots()
        .handleError((error) {
          print('❌ Error fetching public rooms with index: $error');
          if (error.toString().contains('requires an index')) {
            print('🚨 FIRESTORE INDEX REQUIRED!');
            print('Go to Firebase Console > Firestore > Indexes');
            print('Create composite index: type (asc) + status (asc) + createdAt (desc)');
            print('Or click the link in the error message above.');
            
            // Return fallback stream without orderBy
            return _getPublicRoomsWithoutIndex();
          }
          throw error;
        })
        .map((snapshot) {
          print('📦 Received ${snapshot.docs.length} room documents from Firestore');
          
          final rooms = <GameRoom>[];
          for (var doc in snapshot.docs) {
            try {
              final room = GameRoom.fromFirestore(doc);
              print('✅ Parsed room: ${room.roomName} (${room.players.length}/${room.maxPlayers})');
              rooms.add(room);
            } catch (e) {
              print('❌ Error parsing room ${doc.id}: $e');
              print('   Data: ${doc.data()}');
            }
          }
          
          print('🎯 Returning ${rooms.length} valid rooms to UI');
          return rooms;
        });
  }
  
  // Fallback method without index requirement
  Stream<List<GameRoom>> _getPublicRoomsWithoutIndex() {
    print('🔄 Using fallback query without index...');
    
    return _firestore
        .collection('gameRooms')
        .where('type', isEqualTo: RoomType.public.name)
        .where('status', isEqualTo: RoomStatus.waiting.name)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          print('📦 Fallback: Received ${snapshot.docs.length} room documents');
          
          final rooms = <GameRoom>[];
          for (var doc in snapshot.docs) {
            try {
              final room = GameRoom.fromFirestore(doc);
              rooms.add(room);
            } catch (e) {
              print('❌ Error parsing room ${doc.id}: $e');
            }
          }
          
          // Sort manually since we can't use orderBy without index
          rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('🎯 Fallback: Returning ${rooms.length} rooms');
          return rooms;
        });
  }

  // Get room by ID
  Stream<GameRoom?> getRoomById(String roomId) {
    return _firestore
        .collection('gameRooms')
        .doc(roomId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final room = GameRoom.fromFirestore(doc);
        
        // Validate room integrity in background (non-blocking)
        Future.microtask(() async {
          try {
            await _validateRoomIntegrity(roomId);
          } catch (e) {
            print('Background validation error for room $roomId: $e');
          }
        });
        
        return room;
      }
      return null;
    });
  }

  // Send system message
  Future<void> sendSystemMessage(String roomId, String message) async {
    try {
      await _firestore
          .collection('gameRooms')
          .doc(roomId)
          .collection('messages')
          .add(RoomMessage(
            id: '',
            senderId: 'system',
            senderName: 'System',
            message: message,
            timestamp: DateTime.now(),
            isSystemMessage: true,
          ).toFirestore());
    } catch (e) {
      print('Error sending system message: $e');
    }
  }

  // Get room messages
  Stream<List<RoomMessage>> getRoomMessages(String roomId) {
    return _firestore
        .collection('gameRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomMessage.fromFirestore(doc))
            .toList());
  }

  // End game
  Future<bool> endGame(String roomId, {bool spiesWin = false}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final roomDoc = await _firestore.collection('gameRooms').doc(roomId).get();
      if (!roomDoc.exists) return false;

      final room = GameRoom.fromFirestore(roomDoc);
      
      // Only host can end game
      if (room.hostId != currentUser.uid) return false;

      await roomDoc.reference.update({
        'status': RoomStatus.finished.name,
        'finishedAt': FieldValue.serverTimestamp(),
      });

      final winMessage = spiesWin ? 'Spies won the game!' : 'Detectives won the game!';
      await sendSystemMessage(roomId, winMessage);

      return true;
    } catch (e) {
      print('Error ending game: $e');
      return false;
    }
  }

  // Start game with role assignments
  Future<bool> startGameWithRoles(String roomId, String chosenWord, List<String> categories) async {
    try {
      final roomDoc = await _firestore.collection('gameRooms').doc(roomId).get();
      if (!roomDoc.exists) return false;

      final room = GameRoom.fromFirestore(roomDoc);
      final players = room.players;
      
      // Generate spy assignments
      final spyCount = room.gameSettings.spyCount;
      final assignments = List.generate(players.length, (index) => false);
      final spyIndices = <int>[];
      
      // Randomly select spies
      while (spyIndices.length < spyCount) {
        final randomIndex = (DateTime.now().millisecondsSinceEpoch % players.length);
        if (!spyIndices.contains(randomIndex)) {
          spyIndices.add(randomIndex);
          assignments[randomIndex] = true;
        }
      }

      // Initialize session stats if first round
      final sessionWins = room.sessionWins ?? 
          Map.fromIterable(players, key: (p) => p.id, value: (_) => 0);
      final sessionLosses = room.sessionLosses ?? 
          Map.fromIterable(players, key: (p) => p.id, value: (_) => 0);

      await _firestore.collection('gameRooms').doc(roomId).update({
        'status': RoomStatus.rulesRevealed.name,
        'spyAssignments': assignments,
        'currentWord': chosenWord,
        'startedAt': FieldValue.serverTimestamp(),
        'playerVotes': null, // Clear previous votes
        'sessionWins': sessionWins,
        'sessionLosses': sessionLosses,
        'currentRound': (room.currentRound ?? 0) + 1,
      });

      return true;
    } catch (e) {
      print('Error starting game with roles: $e');
      return false;
    }
  }

  // Update room data
  Future<bool> updateRoom(String roomId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('gameRooms').doc(roomId).update(updates);
      return true;
    } catch (e) {
      print('Error updating room: $e');
      return false;
    }
  }

  // Delete room
  Future<bool> deleteRoom(String roomId) async {
    try {
      print('Deleting room $roomId and all subcollections...');
      
      // Delete messages subcollection first
      final messagesQuery = await _firestore
          .collection('gameRooms')
          .doc(roomId)
          .collection('messages')
          .get();

      // Use batched writes for efficiency
      final batch = _firestore.batch();
      
      // Delete all messages
      for (final doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the room document itself
      batch.delete(_firestore.collection('gameRooms').doc(roomId));
      
      await batch.commit();
      
      print('Room $roomId deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting room $roomId: $e');
      return false;
    }
  }

  // Submit a vote using Realtime Database (much more reliable for concurrent writes)
  Future<bool> submitVote(String roomId, String voterId, String votedForId) async {
    print('RoomService: Delegating vote to Realtime Database service');
    return await _votingService.submitVote(roomId, voterId, votedForId);
  }

  // Initialize voting in Realtime Database when voting phase starts
  Future<void> initializeRealtimeVoting(String roomId) async {
    await _votingService.initializeVoting(roomId);
    await _votingService.setVotingStatus(roomId, 'active');
  }

  // Get votes from Realtime Database
  Stream<Map<String, String>> getRealtimeVotes(String roomId) {
    return _votingService.getVotesStream(roomId);
  }

  // End voting phase
  Future<void> endVotingPhase(String roomId) async {
    await _votingService.setVotingStatus(roomId, 'ended');
  }

  // Clean up old rooms (finished rooms older than 1 hour and old rooms in general)
  Future<void> cleanupOldRooms() async {
    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      
      print('RoomService: Starting room cleanup...');
      
      // Clean up finished rooms older than 1 hour
      final finishedQuery = await _firestore
          .collection('gameRooms')
          .where('status', isEqualTo: RoomStatus.finished.name)
          .where('finishedAt', isLessThan: Timestamp.fromDate(oneHourAgo))
          .get();

      print('RoomService: Found ${finishedQuery.docs.length} finished rooms to cleanup');

      // Clean up any rooms created more than 1 day ago (regardless of status)
      final oldQuery = await _firestore
          .collection('gameRooms')
          .where('createdAt', isLessThan: Timestamp.fromDate(oneDayAgo))
          .get();

      print('RoomService: Found ${oldQuery.docs.length} old rooms to cleanup');

      final batch = _firestore.batch();
      int deleteCount = 0;
      
      // Delete finished rooms
      for (final doc in finishedQuery.docs) {
        await _deleteRoomWithSubcollections(doc.id, batch);
        deleteCount++;
      }
      
      // Delete old rooms
      for (final doc in oldQuery.docs) {
        await _deleteRoomWithSubcollections(doc.id, batch);
        deleteCount++;
      }

      if (deleteCount > 0) {
        await batch.commit();
        print('RoomService: Successfully cleaned up $deleteCount rooms');
      } else {
        print('RoomService: No rooms to cleanup');
      }
    } catch (e) {
      print('Error cleaning up old rooms: $e');
    }
  }

  // Helper method to delete room with all subcollections
  Future<void> _deleteRoomWithSubcollections(String roomId, WriteBatch batch) async {
    try {
      // Delete messages subcollection
      final messagesQuery = await _firestore
          .collection('gameRooms')
          .doc(roomId)
          .collection('messages')
          .get();

      for (final messageDoc in messagesQuery.docs) {
        batch.delete(messageDoc.reference);
      }

      // Delete the room document itself
      batch.delete(_firestore.collection('gameRooms').doc(roomId));
      
      print('RoomService: Marked room $roomId and ${messagesQuery.docs.length} messages for deletion');
    } catch (e) {
      print('Error preparing room $roomId for deletion: $e');
    }
  }
}