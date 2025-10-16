import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Live test script to diagnose room browser issues
// Run this to verify what's actually happening with room queries

Future<void> testRoomBrowserLive() async {
  print('🔥 LIVE ROOM BROWSER TEST - STARTING');
  print('═' * 50);
  
  try {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      print('❌ User not authenticated');
      return;
    }
    
    print('✅ User authenticated: ${currentUser.uid}');
    print('');
    
    // Test 1: Check if any rooms exist at all
    print('📋 TEST 1: Checking all rooms in collection...');
    final allRoomsQuery = await firestore
        .collection('gameRooms')
        .limit(5)
        .get();
    
    print('Found ${allRoomsQuery.docs.length} total rooms:');
    for (var doc in allRoomsQuery.docs) {
      final data = doc.data();
      print('  Room: ${data['roomName']} | Status: ${data['status']} | Type: ${data['type']}');
    }
    print('');
    
    // Test 2: Try the exact query the room browser uses
    print('🎯 TEST 2: Testing room browser query...');
    print('Query: type==public AND status==waiting');
    
    try {
      final publicRoomsQuery = await firestore
          .collection('gameRooms')
          .where('type', isEqualTo: 'public')
          .where('status', isEqualTo: 'waiting')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      print('✅ Room browser query succeeded!');
      print('Found ${publicRoomsQuery.docs.length} public waiting rooms:');
      
      for (var doc in publicRoomsQuery.docs) {
        final data = doc.data();
        final playerCount = data['players']?.length ?? 0;
        final maxPlayers = data['maxPlayers'] ?? 6;
        print('  - ${data['roomName']} ($playerCount/$maxPlayers players)');
      }
      
    } catch (e) {
      print('❌ Room browser query FAILED: $e');
      
      // Try fallback query without orderBy
      print('🔄 Trying fallback query without orderBy...');
      try {
        final fallbackQuery = await firestore
            .collection('gameRooms')
            .where('type', isEqualTo: 'public')
            .where('status', isEqualTo: 'waiting')
            .limit(10)
            .get();
        
        print('✅ Fallback query succeeded!');
        print('Found ${fallbackQuery.docs.length} rooms');
        
      } catch (fallbackError) {
        print('❌ Even fallback query failed: $fallbackError');
      }
    }
    print('');
    
    // Test 3: Create a test room to verify creation works
    print('🏗️ TEST 3: Creating test room...');
    try {
      final testRoomRef = await firestore.collection('gameRooms').add({
        'roomName': 'TEST ROOM - Live Browser Test',
        'hostId': currentUser.uid,
        'hostName': 'Test Host',
        'hostAvatar': '🧪',
        'type': 'public',
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
        'maxPlayers': 6,
        'players': [{
          'id': currentUser.uid,
          'name': 'Test Host',
          'avatar': '🧪',
          'rank': 'Iron',
          'isHost': true,
          'isReady': true,
          'joinedAt': Timestamp.now(),
          'isOnline': true,
        }],
        'gameSettings': {
          'playerCount': 6,
          'spyCount': 2,
          'minutes': 5,
          'category': 'أماكن',
        }
      });
      
      print('✅ Test room created: ${testRoomRef.id}');
      
      // Wait a moment then query again
      print('⏳ Waiting 3 seconds then querying again...');
      await Future.delayed(Duration(seconds: 3));
      
      final afterCreateQuery = await firestore
          .collection('gameRooms')
          .where('type', isEqualTo: 'public')
          .where('status', isEqualTo: 'waiting')
          .limit(10)
          .get();
      
      print('After creating test room, found ${afterCreateQuery.docs.length} rooms');
      
      // Clean up test room
      await testRoomRef.delete();
      print('🗑️ Test room deleted');
      
    } catch (createError) {
      print('❌ Test room creation failed: $createError');
    }
    
    print('');
    print('🎉 LIVE TEST COMPLETE');
    print('═' * 50);
    
  } catch (e, stackTrace) {
    print('❌ LIVE TEST FAILED: $e');
    print('Stack trace: $stackTrace');
  }
}

// Widget to run this test in the actual app
class LiveRoomBrowserTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Room Browser Test'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await testRoomBrowserLive();
          },
          child: Text('Run Live Test'),
        ),
      ),
    );
  }
}