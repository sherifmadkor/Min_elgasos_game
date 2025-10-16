import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/foundation.dart';
import '../models/room_models.dart';

/// Simplified Firebase Realtime Database service based on working casino app pattern
class RealtimeRoomService {
  RealtimeRoomService._();
  static final RealtimeRoomService _inst = RealtimeRoomService._();
  factory RealtimeRoomService() => _inst;

  // Use region-specific database instance with explicit URL
  late final DatabaseReference _db;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  // Expose auth for external access
  FirebaseAuth get auth => _auth;
  
  // Expose firestore for compatibility (some screens still need it)
  // We'll keep a minimal firestore instance for user data
  late final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;
  fs.FirebaseFirestore get firestore => _firestore;

  /// Initialize with proper region configuration
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('🔥 RealtimeRoom: Initializing with region-specific database...');
      
      // Use explicit database URL for Europe West region
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://min-el-gasos-default-rtdb.europe-west1.firebasedatabase.app',
      );
      
      _db = database.ref();
      _initialized = true;
      print('✅ RealtimeRoom: Database initialized successfully');
    } catch (e) {
      print('❌ RealtimeRoom: Failed to initialize database: $e');
      rethrow;
    }
  }

  /// Ensure initialization before any operation
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // ─────────────────────────── ROOM MANAGEMENT ──────────────────────────
  
  /// Create a new game room using casino app pattern
  Future<String> createRoom({
    required String hostName,
    required String hostAvatarId,
    required int maxPlayers,
    required int gameMinutes,
    String? roomName, // Optional room name parameter
  }) async {
    await _ensureInitialized();

    print('🔥 RealtimeRoom: Starting room creation...');
    print('🔥 RealtimeRoom: Host: $hostName, Avatar: $hostAvatarId');
    print('🔥 RealtimeRoom: Max players: $maxPlayers, Minutes: $gameMinutes');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get user data from Firestore for accurate display name and rank
    final userData = await _getUserData(currentUser.uid);
    final displayName = userData['displayName'] ?? currentUser.displayName ?? hostName;
    final userAvatar = userData['avatarEmoji'] ?? hostAvatarId;
    final userRank = userData['rank'] ?? 'Iron';

    // Generate simple room code like casino app (numbers for backend only)
    final code = (1000 + Random().nextInt(9000)).toString();
    print('🔥 RealtimeRoom: Generated room code: $code');

    // Use provided room name or generate a default one
    final finalRoomName = roomName ?? _generateDefaultRoomName();
    print('🔥 RealtimeRoom: Room name: $finalRoomName');

    final ref = _db.child('rooms/$code');

    // Simple room structure like casino app
    final roomData = {
      'host': displayName,
      'hostId': currentUser.uid,
      'roomName': finalRoomName, // Store the actual room name
      'roomCode': code, // Store the numeric code separately
      'maxPlayers': maxPlayers,
      'gameMinutes': gameMinutes,
      'gameStarted': false,
      'gameEnded': false,
      'currentPhase': 'lobby',
      'createdAt': ServerValue.timestamp,
      'players': {
        displayName: {
          'id': currentUser.uid,
          'score': 0,
          'avatarId': userAvatar,
          'rank': userRank,
          'isHost': true,
          'isReady': true,
          'isOnline': true,
          'joinedAt': ServerValue.timestamp,
        },
      },
    };

    await ref.set(roomData);
    print('✅ RealtimeRoom: Room created successfully with code: $code and name: $finalRoomName');
    return code;
  }

  /// Generate a default room name if none provided
  String _generateDefaultRoomName() {
    final adjectives = ['Epic', 'Secret', 'Mystery', 'Hidden', 'Shadow', 'Elite', 'Cool', 'Fun', 'Wild', 'Crazy'];
    final nouns = ['Spies', 'Agents', 'Detectives', 'Game', 'Hunt', 'Mission', 'Quest', 'Battle', 'War', 'Chase'];
    final random = Random();

    final adjective = adjectives[random.nextInt(adjectives.length)];
    final noun = nouns[random.nextInt(nouns.length)];

    return '$adjective $noun';
  }

  /// Join a room using simple pattern from casino app
  Future<bool> joinRoom({
    required String roomCode,
    required String playerName,
    required String avatarId,
  }) async {
    await _ensureInitialized();
    
    print('🔥 RealtimeRoom: Joining room $roomCode as $playerName');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get user data from Firestore for accurate display name and rank
    final userData = await _getUserData(currentUser.uid);
    final displayName = userData['displayName'] ?? currentUser.displayName ?? playerName;
    final userAvatar = userData['avatarEmoji'] ?? avatarId;
    final userRank = userData['rank'] ?? 'Iron';

    final playerRef = _db.child('rooms/$roomCode/players/$displayName');
    final roomSnap = await _db.child('rooms/$roomCode').get();
    
    if (!roomSnap.exists) {
      print('❌ RealtimeRoom: Room not found');
      return false;
    }

    // Check room capacity like casino app
    if (roomSnap.value is Map) {
      final room = Map<String, dynamic>.from(roomSnap.value as Map);
      final players = room['players'] is Map ? Map.from(room['players']) : {};
      final capacity = room['maxPlayers'] as int? ?? 10;
      
      if (players.length >= capacity) {
        print('❌ RealtimeRoom: Room is full');
        return false;
      }
      
      if (room['gameStarted'] == true) {
        print('❌ RealtimeRoom: Game already started');
        return false;
      }
      
      // Check if player is already in room to prevent duplicates
      if (players.containsKey(displayName)) {
        print('❌ RealtimeRoom: Player already in room');
        return false;
      }
    }

    // Add player with complete user data
    await playerRef.set({
      'id': currentUser.uid,
      'score': 0,
      'avatarId': userAvatar,
      'rank': userRank,
      'isHost': false,
      'isReady': false,
      'isOnline': true,
      'joinedAt': ServerValue.timestamp,
    });

    print('✅ RealtimeRoom: Successfully joined room');
    return true;
  }

  /// Remove player from room by name
  Future<void> removePlayer(String roomCode, String playerName) async {
    await _ensureInitialized();
    await _db.child('rooms/$roomCode/players/$playerName').remove();
    print('🔥 RealtimeRoom: Removed player $playerName from room $roomCode');
  }

  /// Remove player from room by user ID (more reliable)
  Future<void> removePlayerById(String roomCode, String userId) async {
    await _ensureInitialized();
    
    // Get user data to find correct player name
    final userData = await _getUserData(userId);
    final displayName = userData['displayName'] ?? '';
    
    if (displayName.isNotEmpty) {
      await _db.child('rooms/$roomCode/players/$displayName').remove();
      print('🔥 RealtimeRoom: Removed player $displayName (ID: $userId) from room $roomCode');
    } else {
      // Fallback: search through all players to find the one with this user ID
      final playersSnap = await _db.child('rooms/$roomCode/players').get();
      if (playersSnap.exists && playersSnap.value is Map) {
        final players = Map<String, dynamic>.from(playersSnap.value as Map);
        for (final entry in players.entries) {
          final playerName = entry.key;
          final playerData = entry.value;
          if (playerData is Map && playerData['id'] == userId) {
            await _db.child('rooms/$roomCode/players/$playerName').remove();
            print('🔥 RealtimeRoom: Removed player $playerName (ID: $userId) from room $roomCode');
            break;
          }
        }
      }
    }
  }

  /// Delete entire room
  Future<void> deleteRoom(String roomCode) async {
    await _ensureInitialized();
    await _db.child('rooms/$roomCode').remove();
  }

  /// Start the game (goes to waiting for host to reveal roles)
  Future<void> startGame(String roomCode) async {
    await _ensureInitialized();
    await _db.child('rooms/$roomCode').update({
      'gameStarted': true,
      'currentPhase': 'waitingForReveal',
      'gameStartedAt': ServerValue.timestamp,
    });
  }

  /// Reveal roles to players (generates spy assignments)
  Future<void> revealRoles(String roomCode) async {
    await _ensureInitialized();
    
    // Get room data to generate spy assignments
    final roomSnap = await _db.child('rooms/$roomCode').get();
    if (!roomSnap.exists || roomSnap.value is! Map) {
      throw Exception('Room not found');
    }
    
    final roomData = Map<String, dynamic>.from(roomSnap.value as Map);
    final players = roomData['players'] is Map ? Map.from(roomData['players']) : {};
    final playerCount = players.length;
    
    // Generate spy assignments (2 spies for rooms with 6+ players, 1 spy for smaller rooms)
    final spyCount = playerCount >= 6 ? 2 : 1;
    final spyAssignments = _generateSpyAssignments(playerCount, spyCount);
    
    // Generate random word from a simple list for now
    final words = ['Restaurant', 'Library', 'Hospital', 'School', 'Airport', 'Beach', 'Park', 'Museum', 'Mall', 'Hotel'];
    final randomWord = words[DateTime.now().millisecondsSinceEpoch % words.length];
    
    await _db.child('rooms/$roomCode').update({
      'currentPhase': 'rulesRevealed',
      'spyAssignments': spyAssignments,
      'currentWord': randomWord,
    });
  }
  
  /// Generate spy assignments for players
  List<bool> _generateSpyAssignments(int playerCount, int spyCount) {
    final assignments = List<bool>.filled(playerCount, false);
    final spyIndices = <int>[];
    final random = Random();
    
    // Randomly select spy positions
    while (spyIndices.length < spyCount) {
      final index = random.nextInt(playerCount);
      if (!spyIndices.contains(index)) {
        spyIndices.add(index);
        assignments[index] = true;
      }
    }
    
    return assignments;
  }

  /// End the game (with compatibility for spiesWin parameter)
  Future<void> endGame(String roomCode, {bool? spiesWin}) async {
    await _ensureInitialized();
    await _db.child('rooms/$roomCode').update({
      'gameEnded': true,
      'currentPhase': 'ended',
      'gameEndedAt': ServerValue.timestamp,
      if (spiesWin != null) 'spiesWin': spiesWin,
    });
  }

  // ─────────────────────────── VOTING SYSTEM ──────────────────────────
  
  /// Submit vote using simple push pattern like casino app's buzz system
  Future<void> submitVote({
    required String roomCode,
    required String voterName,
    required String votedForName,
  }) async {
    await _ensureInitialized();
    
    print('🔥 RealtimeRoom: $voterName voting for $votedForName in room $roomCode');
    
    // Use push() for auto-generated IDs like casino app
    final ref = _db.child('rooms/$roomCode/votes').push();
    await ref.set({
      'voter': voterName,
      'votedFor': votedForName,
      'timestamp': ServerValue.timestamp,
    });
    
    print('✅ RealtimeRoom: Vote submitted successfully');
  }

  /// Reset votes for new round
  Future<void> resetVotes(String roomCode) async {
    await _ensureInitialized();
    await _db.child('rooms/$roomCode/votes').remove();
  }

  /// Update player score
  Future<void> updateScore(String roomCode, String playerName, int score) async {
    await _ensureInitialized();
    await _db.child('rooms/$roomCode/players/$playerName/score').set(score);
  }

  /// Set game phase
  Future<void> setGamePhase(String roomCode, String phase) async {
    await _ensureInitialized();
    print('🔥 RealtimeRoom: Setting game phase to: $phase for room: $roomCode');
    await _db.child('rooms/$roomCode/currentPhase').set(phase);
    print('✅ RealtimeRoom: Game phase updated successfully');
  }

  // ─────────────────────────── STREAMS ──────────────────────────
  
  /// Get room data stream with proper broadcast
  Stream<Map<String, dynamic>?> getRoomStream(String roomCode) {
    return _db.child('rooms/$roomCode').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) {
        return null;
      }
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    }).asBroadcastStream();
  }

  /// Get players stream
  Stream<Map<String, Map<String, dynamic>>> getPlayersStream(String roomCode) {
    return _db.child('rooms/$roomCode/players').onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value is! Map) {
        return <String, Map<String, dynamic>>{};
      }
      final raw = Map<dynamic, dynamic>.from(e.snapshot.value as Map);
      final out = <String, Map<String, dynamic>>{};
      raw.forEach((k, v) {
        if (v is Map) out[k.toString()] = Map<String, dynamic>.from(v);
      });
      return out;
    }).asBroadcastStream();
  }

  /// Get votes stream - fires when new vote is added (like casino app's buzz system)
  Stream<Map<String, dynamic>?> getVotesStream(String roomCode) {
    return _db
        .child('rooms/$roomCode/votes')
        .onChildAdded
        .map((event) {
      if (event.snapshot.value is! Map) return null;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return {
        'voter': data['voter'] as String,
        'votedFor': data['votedFor'] as String,
        'timestamp': data['timestamp'],
      };
    }).asBroadcastStream();
  }

  /// Get current phase stream
  Stream<String> getPhaseStream(String roomCode) {
    return _db.child('rooms/$roomCode/currentPhase').onValue.map(
      (e) => e.snapshot.value as String? ?? 'lobby',
    ).asBroadcastStream();
  }

  // ─────────────────────────── HELPER METHODS ──────────────────────────
  
  /// Get user data from Firestore
  Future<Map<String, dynamic>> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
    } catch (e) {
      print('❌ RealtimeRoom: Error fetching user data: $e');
    }
    return {};
  }

  // ─────────────────────────── CONVERSION HELPERS ──────────────────────────
  
  /// Convert Firebase Realtime Database map to GameRoom object
  GameRoom? _mapToGameRoom(String roomId, Map<String, dynamic>? data) {
    if (data == null) return null;
    
    try {
      final players = <RoomPlayer>[];
      if (data['players'] is Map) {
        final playersMap = Map<String, dynamic>.from(data['players']);
        playersMap.forEach((name, playerData) {
          if (playerData is Map) {
            final pd = Map<String, dynamic>.from(playerData);
            players.add(RoomPlayer(
              id: pd['id'] ?? '',
              name: name,
              avatar: pd['avatarId'] ?? '🕵️‍♂️',
              rank: pd['rank'] ?? 'Iron', // Use stored rank from realtime data
              isHost: pd['isHost'] ?? false,
              isReady: pd['isReady'] ?? false,
              joinedAt: pd['joinedAt'] is int 
                  ? DateTime.fromMillisecondsSinceEpoch(pd['joinedAt'])
                  : DateTime.now(),
              isOnline: pd['isOnline'] ?? true,
            ));
          }
        });
      }
      
      // Convert votes from realtime format to GameRoom format
      Map<String, String>? playerVotes;
      if (data['votes'] is Map) {
        playerVotes = <String, String>{};
        final votesMap = Map<String, dynamic>.from(data['votes']);
        votesMap.forEach((voteId, voteData) {
          if (voteData is Map) {
            final vd = Map<String, dynamic>.from(voteData);
            final voter = vd['voter'] as String?;
            final votedFor = vd['votedFor'] as String?;
            if (voter != null && votedFor != null) {
              playerVotes![voter] = votedFor;
            }
          }
        });
      }
      
      return GameRoom(
        id: roomId,
        hostId: data['hostId'] ?? '',
        hostName: data['host'] ?? '',
        hostAvatar: '🕵️‍♂️', // Default since not stored
        type: RoomType.public, // Default since simplified
        roomCode: data['roomCode'] ?? roomId, // Use stored room code
        roomName: data['roomName'] ?? 'Room $roomId', // Use stored room name or fallback
        status: _mapToRoomStatus(data['currentPhase'] as String?),
        gameSettings: GameSettings(
          playerCount: data['maxPlayers'] ?? 6,
          spyCount: 1, // Default
          minutes: data['gameMinutes'] ?? 5,
          category: 'أماكن', // Default
        ),
        players: players,
        createdAt: data['createdAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
            : DateTime.now(),
        startedAt: data['gameStartedAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(data['gameStartedAt'])
            : null,
        finishedAt: data['gameEndedAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(data['gameEndedAt'])
            : null,
        maxPlayers: data['maxPlayers'] ?? 6,
        currentWord: data['currentWord'],
        spyAssignments: data['spyAssignments'] is List
            ? List<bool>.from(data['spyAssignments'])
            : null,
        playerVotes: playerVotes,
      );
    } catch (e) {
      print('❌ RealtimeRoom: Error converting map to GameRoom: $e');
      return null;
    }
  }
  
  /// Convert realtime phase to RoomStatus
  RoomStatus _mapToRoomStatus(String? phase) {
    switch (phase) {
      case 'lobby':
        return RoomStatus.waiting;
      case 'waitingForReveal':
        return RoomStatus.starting;
      case 'rulesRevealed':
        return RoomStatus.rulesRevealed;
      case 'game':
        return RoomStatus.inGame;
      case 'voting':
        return RoomStatus.voting;
      case 'results':
        return RoomStatus.resultsShowing;
      case 'ended':
        return RoomStatus.finished;
      default:
        return RoomStatus.waiting;
    }
  }

  // ─────────────────────────── MISSING METHODS FOR COMPATIBILITY ──────────────────────────
  
  /// Get room by ID stream (for compatibility with existing screens)
  Stream<GameRoom?> getRoomById(String roomId) {
    return getRoomStream(roomId).map((data) => _mapToGameRoom(roomId, data));
  }

  /// Update room (for compatibility with existing screens)
  Future<void> updateRoom(String roomId, Map<String, dynamic> updates) async {
    await _ensureInitialized();
    await _db.child('rooms/$roomId').update(updates);
  }

  /// Leave room (for compatibility with existing screens)
  Future<void> leaveRoom(String roomId) async {
    await _ensureInitialized();
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    // Get user data to find correct player name
    final userData = await _getUserData(currentUser.uid);
    final displayName = userData['displayName'] ?? currentUser.displayName ?? currentUser.uid;
    
    // Check if this player is the host
    final roomSnap = await _db.child('rooms/$roomId').get();
    if (roomSnap.exists && roomSnap.value is Map) {
      final roomData = Map<String, dynamic>.from(roomSnap.value as Map);
      final hostId = roomData['hostId'] as String?;
      
      if (hostId == currentUser.uid) {
        // Host is leaving - delete the entire room
        print('🔥 RealtimeRoom: Host leaving, deleting room $roomId');
        await deleteRoom(roomId);
        return;
      }
    }
    
    // Remove player from room
    await _db.child('rooms/$roomId/players/$displayName').remove();
    print('🔥 RealtimeRoom: Player $displayName left room $roomId');
  }

  /// Toggle ready status (for compatibility with existing screens)
  Future<void> toggleReadyStatus(String roomId) async {
    await _ensureInitialized();
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    // Get user data to find correct player name
    final userData = await _getUserData(currentUser.uid);
    final displayName = userData['displayName'] ?? currentUser.displayName ?? currentUser.uid;
    final playerRef = _db.child('rooms/$roomId/players/$displayName');
    
    // Get current ready status
    final snapshot = await playerRef.child('isReady').get();
    final currentStatus = snapshot.value as bool? ?? false;
    
    // Toggle it
    await playerRef.update({'isReady': !currentStatus});
  }

  /// Get public rooms stream (for compatibility with existing screens)
  Stream<List<GameRoom>> getPublicRooms() {
    return _db.child('rooms').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) {
        return <GameRoom>[];
      }
      
      final rooms = Map<String, dynamic>.from(event.snapshot.value as Map);
      final publicRooms = <GameRoom>[];
      
      rooms.forEach((key, value) {
        if (value is Map) {
          final roomData = Map<String, dynamic>.from(value);
          // Only return public rooms that haven't started
          if (roomData['gameStarted'] != true) {
            final gameRoom = _mapToGameRoom(key, roomData);
            if (gameRoom != null) {
              publicRooms.add(gameRoom);
            }
          }
        }
      });
      
      return publicRooms;
    }).asBroadcastStream();
  }

  // ─────────────────────────── CLEANUP ──────────────────────────
  
  /// Clean up old rooms (like casino app)
  Future<void> cleanupOldRooms() async {
    try {
      await _ensureInitialized();
      print('🔥 RealtimeRoom: Starting room cleanup...');
      
      final snapshot = await _db.child('rooms').get();
      if (!snapshot.exists) {
        print('✅ RealtimeRoom: No rooms to cleanup');
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final cutoff = now - (24 * 60 * 60 * 1000); // 24 hours ago
      
      if (snapshot.value is Map) {
        final rooms = Map<String, dynamic>.from(snapshot.value as Map);
        
        for (final entry in rooms.entries) {
          final roomCode = entry.key;
          final roomData = entry.value;
          
          if (roomData is Map) {
            final createdAt = roomData['createdAt'] as int?;
            if (createdAt != null && createdAt < cutoff) {
              print('🗑️ RealtimeRoom: Deleting old room: $roomCode');
              await _db.child('rooms/$roomCode').remove();
            }
          }
        }
      }
      
      print('✅ RealtimeRoom: Room cleanup completed');
    } catch (e) {
      print('❌ RealtimeRoom: Error during cleanup: $e');
    }
  }
}