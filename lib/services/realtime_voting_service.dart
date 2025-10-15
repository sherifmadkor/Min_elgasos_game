import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealtimeVotingService {
  static final RealtimeVotingService _instance = RealtimeVotingService._internal();
  factory RealtimeVotingService() => _instance;
  RealtimeVotingService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit vote using Realtime Database transaction
  Future<bool> submitVote(String roomId, String voterId, String votedForId) async {
    try {
      print('RealtimeVoting: Submitting vote - Room: $roomId, Voter: $voterId, VotedFor: $votedForId');
      
      final voteRef = _database.ref().child('gameRooms').child(roomId).child('playerVotes').child(voterId);
      
      // Use transaction to ensure atomic voting
      final result = await voteRef.runTransaction((Object? currentValue) {
        // If user already voted, prevent overwrite
        if (currentValue != null) {
          print('RealtimeVoting: User $voterId already voted');
          return Transaction.abort();
        }
        
        print('RealtimeVoting: Setting vote for $voterId to $votedForId');
        return Transaction.success(votedForId);
      });
      
      if (result.committed) {
        print('RealtimeVoting: Vote committed successfully');
        return true;
      } else {
        print('RealtimeVoting: Vote transaction aborted');
        return false;
      }
    } catch (e) {
      print('RealtimeVoting: Error submitting vote: $e');
      return false;
    }
  }

  // Listen to votes for a room
  Stream<Map<String, String>> getVotesStream(String roomId) {
    return _database
        .ref()
        .child('gameRooms')
        .child(roomId)
        .child('playerVotes')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return <String, String>{};
      }
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.map((key, value) => MapEntry(key.toString(), value.toString()));
    });
  }

  // Initialize voting for a room
  Future<void> initializeVoting(String roomId) async {
    try {
      final votesRef = _database.ref().child('gameRooms').child(roomId).child('playerVotes');
      await votesRef.set({});
      print('RealtimeVoting: Initialized voting for room $roomId');
    } catch (e) {
      print('RealtimeVoting: Error initializing voting: $e');
    }
  }

  // Clear votes for a room (start new voting round)
  Future<void> clearVotes(String roomId) async {
    try {
      final votesRef = _database.ref().child('gameRooms').child(roomId).child('playerVotes');
      await votesRef.remove();
      print('RealtimeVoting: Cleared votes for room $roomId');
    } catch (e) {
      print('RealtimeVoting: Error clearing votes: $e');
    }
  }

  // Get current vote count
  Future<int> getVoteCount(String roomId) async {
    try {
      final snapshot = await _database
          .ref()
          .child('gameRooms')
          .child(roomId)
          .child('playerVotes')
          .get();
      
      if (snapshot.value == null) return 0;
      
      final votes = snapshot.value as Map<dynamic, dynamic>;
      return votes.length;
    } catch (e) {
      print('RealtimeVoting: Error getting vote count: $e');
      return 0;
    }
  }

  // Check if user has voted
  Future<bool> hasUserVoted(String roomId, String userId) async {
    try {
      final snapshot = await _database
          .ref()
          .child('gameRooms')
          .child(roomId)
          .child('playerVotes')
          .child(userId)
          .get();
      
      return snapshot.exists;
    } catch (e) {
      print('RealtimeVoting: Error checking vote status: $e');
      return false;
    }
  }

  // Get user's vote
  Future<String?> getUserVote(String roomId, String userId) async {
    try {
      final snapshot = await _database
          .ref()
          .child('gameRooms')
          .child(roomId)
          .child('playerVotes')
          .child(userId)
          .get();
      
      if (snapshot.exists) {
        return snapshot.value.toString();
      }
      return null;
    } catch (e) {
      print('RealtimeVoting: Error getting user vote: $e');
      return null;
    }
  }

  // Set voting status for room
  Future<void> setVotingStatus(String roomId, String status) async {
    try {
      final statusRef = _database.ref().child('gameRooms').child(roomId).child('votingStatus');
      await statusRef.set(status);
      print('RealtimeVoting: Set voting status to $status for room $roomId');
    } catch (e) {
      print('RealtimeVoting: Error setting voting status: $e');
    }
  }

  // Listen to voting status
  Stream<String> getVotingStatusStream(String roomId) {
    return _database
        .ref()
        .child('gameRooms')
        .child(roomId)
        .child('votingStatus')
        .onValue
        .map((event) {
      return event.snapshot.value?.toString() ?? 'waiting';
    });
  }

  // Cleanup old voting data
  Future<void> cleanupVotingData(String roomId) async {
    try {
      final roomRef = _database.ref().child('gameRooms').child(roomId);
      await roomRef.remove();
      print('RealtimeVoting: Cleaned up voting data for room $roomId');
    } catch (e) {
      print('RealtimeVoting: Error cleaning up voting data: $e');
    }
  }
}