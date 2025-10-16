import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/room_models.dart';
import '../services/realtime_room_service.dart';
import 'background_container.dart';

class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({super.key});

  @override
  State<FirebaseDebugScreen> createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  final List<String> _logs = [];
  final _roomService = RealtimeRoomService();
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  void _addLog(String message, {bool isError = false}) {
    setState(() {
      final timestamp = DateTime.now().toString().split('.')[0].split(' ')[1];
      _logs.add('[$timestamp] ${isError ? '❌' : '✅'} $message');
    });
  }

  Future<void> _runDiagnostics() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    try {
      // 1. Check Firebase Auth
      _addLog('Checking Firebase Auth...');
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser != null) {
        _addLog('User authenticated: ${currentUser.uid}');
        _addLog('Is anonymous: ${currentUser.isAnonymous}');
      } else {
        _addLog('No user authenticated', isError: true);
        _addLog('Attempting anonymous sign-in...');
        await auth.signInAnonymously();
        _addLog('Anonymous sign-in successful');
      }

      // 2. Check Firestore connection
      _addLog('Testing Firestore connection...');
      final firestore = FirebaseFirestore.instance;
      
      // Try to read test document
      try {
        final testDoc = await firestore
            .collection('test')
            .doc('connection')
            .get(const GetOptions(source: Source.server));
        _addLog('Firestore connection successful');
      } catch (e) {
        _addLog('Firestore read test failed: $e', isError: true);
      }

      // 3. Test write permissions
      _addLog('Testing write permissions...');
      try {
        await firestore.collection('test').doc('write-test').set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': true,
        });
        _addLog('Write test PASSED');
        
        // Clean up
        await firestore.collection('test').doc('write-test').delete();
      } catch (e) {
        _addLog('Write test FAILED: $e', isError: true);
      }

      // 4. Check user document
      final userId = auth.currentUser?.uid;
      if (userId != null) {
        _addLog('Checking user document...');
        final userDoc = await firestore.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          _addLog('User document exists');
          final data = userDoc.data()!;
          _addLog('Display name: ${data['displayName'] ?? 'Not set'}');
          _addLog('Rank: ${data['rank'] ?? 'Iron'}');
        } else {
          _addLog('User document does not exist', isError: true);
          _addLog('Creating user document...');
          
          try {
            await firestore.collection('users').doc(userId).set({
              'displayName': 'Test User',
              'avatarEmoji': '🕵️‍♂️',
              'rank': 'Iron',
              'xp': 0,
              'stats': {
                'gamesPlayed': 0,
                'wins': 0,
                'losses': 0,
                'winRate': '0.0',
              },
              'createdAt': FieldValue.serverTimestamp(),
            });
            _addLog('User document created');
          } catch (e) {
            _addLog('Failed to create user document: $e', isError: true);
          }
        }
      }

      // 5. Test gameRooms collection
      _addLog('Testing gameRooms collection...');
      try {
        final roomsQuery = await firestore
            .collection('gameRooms')
            .where('type', isEqualTo: 'public')
            .where('status', isEqualTo: 'waiting')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();
        
        _addLog('Found ${roomsQuery.docs.length} public rooms');
        
        for (final doc in roomsQuery.docs) {
          final data = doc.data();
          _addLog('  Room: ${data['roomName']} (${data['players']?.length ?? 0} players)');
        }
      } catch (e) {
        _addLog('GameRooms query failed: $e', isError: true);
        if (e.toString().contains('index')) {
          _addLog('⚠️ FIRESTORE INDEX REQUIRED!', isError: true);
          _addLog('Click the link in the error to create the index', isError: true);
        }
      }

      // 6. Test room creation
      _addLog('Testing room creation...');
      try {
        final gameSettings = GameSettings(
          playerCount: 6,
          spyCount: 2,
          minutes: 5,
          category: 'أماكن',
        );
        
        final roomCode = await _roomService.createRoom(
          hostName: 'Debug Host',
          hostAvatarId: '🧪',
          maxPlayers: 8,
          gameMinutes: 5,
        );
        
        if (roomCode.isNotEmpty) {
          _addLog('Room created successfully!');
          _addLog('Room Code: $roomCode');
          
          // Clean up - delete the test room
          await Future.delayed(const Duration(seconds: 2));
          _addLog('Cleaning up test room...');
          await _roomService.deleteRoom(roomCode);
          _addLog('Test room deleted');
        } else {
          _addLog('Room creation returned null', isError: true);
        }
      } catch (e) {
        _addLog('Room creation failed: $e', isError: true);
      }

      // 7. Summary
      _addLog('===================');
      _addLog('DIAGNOSTICS COMPLETE');
      
      final errors = _logs.where((log) => log.contains('❌')).length;
      if (errors == 0) {
        _addLog('All tests passed! ✅');
      } else {
        _addLog('$errors issues found. Please check the logs above.', isError: true);
      }
      
    } catch (e) {
      _addLog('Unexpected error: $e', isError: true);
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Diagnostics'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isRunning ? null : _runDiagnostics,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isRunning)
              const LinearProgressIndicator(color: AppTheme.accentColor),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final isError = log.contains('❌');
                  final isWarning = log.contains('⚠️');
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isError ? Colors.red 
                             : isWarning ? Colors.orange 
                             : Colors.green,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'This screen helps diagnose Firebase connection issues',
                    style: AppTheme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runDiagnostics,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Diagnostics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}