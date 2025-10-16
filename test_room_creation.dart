// Test script to verify room creation and listing works
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> testRoomFunctionality() async {
  print('🧪 Starting room functionality test...');
  
  try {
    // Test 1: Check Firebase connection
    print('1. Testing Firebase connection...');
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    // Test 2: Create a test room
    print('2. Creating test room...');
    final testRoomData = {
      'hostId': 'test-user-123',
      'hostName': 'Test User',
      'hostAvatar': '🕵️‍♂️',
      'type': 'public',
      'roomName': 'Test Room - Please Join',
      'status': 'waiting',
      'gameSettings': {
        'playerCount': 6,
        'spyCount': 2,
        'minutes': 5,
        'category': 'أماكن',
      },
      'players': [{
        'id': 'test-user-123',
        'name': 'Test User',
        'avatar': '🕵️‍♂️',
        'rank': 'Iron',
        'isHost': true,
        'isReady': true,
        'joinedAt': Timestamp.now(),
        'isOnline': true,
      }],
      'createdAt': FieldValue.serverTimestamp(),
      'maxPlayers': 6,
    };
    
    final roomRef = await firestore.collection('gameRooms').add(testRoomData);
    print('✅ Test room created with ID: ${roomRef.id}');
    
    // Test 3: Query public rooms
    print('3. Querying public rooms...');
    final publicRoomsQuery = await firestore
        .collection('gameRooms')
        .where('type', isEqualTo: 'public')
        .where('status', isEqualTo: 'waiting')
        .limit(10)
        .get();
    
    print('✅ Found ${publicRoomsQuery.docs.length} public rooms:');
    for (var doc in publicRoomsQuery.docs) {
      final data = doc.data();
      print('  - ${data['roomName']} (${data['players']?.length ?? 0} players)');
    }
    
    // Test 4: Clean up test room
    print('4. Cleaning up test room...');
    await roomRef.delete();
    print('✅ Test room deleted');
    
    print('🎉 All tests passed! Room functionality is working.');
    
  } catch (e) {
    print('❌ Test failed: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}