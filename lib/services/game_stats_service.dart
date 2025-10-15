import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_repository.dart';
import '../widgets/rank_badge.dart';
import '../models/room_models.dart';

enum GameResult { win, loss }

class GameStatsService {
  static const int baseWinXP = 50;
  static const int baseLossXP = 15;
  static const int spyWinBonus = 15;
  static const int detectiveWinXP = 45;
  static const int streakBonus = 10;
  static const int firstWinBonus = 25;
  
  final AuthRepository _authRepository = AuthRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int calculateXP({
    required GameResult result,
    required PlayerRole role,
    int winStreak = 0,
    bool isFirstWinToday = false,
  }) {
    int xp = 0;
    
    if (result == GameResult.win) {
      if (role == PlayerRole.spy) {
        xp = baseWinXP + spyWinBonus;
      } else {
        xp = detectiveWinXP;
      }
      
      if (winStreak >= 3) {
        xp += streakBonus * (winStreak ~/ 3);
      }
      
      if (isFirstWinToday) {
        xp += firstWinBonus;
      }
    } else {
      xp = baseLossXP;
      
      if (role == PlayerRole.spy) {
        xp += 5;
      }
    }
    
    return xp;
  }
  
  Future<Map<String, dynamic>?> recordGameResult({
    required String userId,
    required GameResult result,
    required PlayerRole role,
    required List<String> allPlayerIds,
    bool isOnlineGame = false,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      
      final userData = userDoc.data()!;
      final currentStats = userData['stats'] as Map<String, dynamic>? ?? {};
      final currentXP = userData['xp'] as int? ?? 0;
      final currentRank = userData['rank'] as String? ?? 'Iron';
      
      int gamesPlayed = (currentStats['gamesPlayed'] as int? ?? 0) + 1;
      int wins = currentStats['wins'] as int? ?? 0;
      int losses = currentStats['losses'] as int? ?? 0;
      int spyWins = currentStats['spyWins'] as int? ?? 0;
      int detectiveWins = currentStats['detectiveWins'] as int? ?? 0;
      int winStreak = currentStats['winStreak'] as int? ?? 0;
      
      if (result == GameResult.win) {
        wins++;
        winStreak++;
        
        if (role == PlayerRole.spy) {
          spyWins++;
        } else {
          detectiveWins++;
        }
      } else {
        losses++;
        winStreak = 0;
      }
      
      final lastWinDate = currentStats['lastWinDate'] as Timestamp?;
      final isFirstWinToday = _isFirstWinToday(lastWinDate);
      
      final xpGained = calculateXP(
        result: result,
        role: role,
        winStreak: winStreak,
        isFirstWinToday: isFirstWinToday && result == GameResult.win,
      );
      
      final newTotalXP = currentXP + xpGained;
      
      final newRank = RankSystem.getRankByXP(newTotalXP);
      final rankChanged = newRank.name != currentRank;
      
      final updatedStats = {
        'gamesPlayed': gamesPlayed,
        'wins': wins,
        'losses': losses,
        'spyWins': spyWins,
        'detectiveWins': detectiveWins,
        'winStreak': winStreak,
        'winRate': gamesPlayed > 0 ? (wins / gamesPlayed * 100).toStringAsFixed(1) : '0.0',
        'lastGameDate': FieldValue.serverTimestamp(),
      };
      
      if (result == GameResult.win) {
        updatedStats['lastWinDate'] = FieldValue.serverTimestamp();
      }
      
      await _firestore.collection('users').doc(userId).update({
        'stats': updatedStats,
        'xp': newTotalXP,
        'rank': newRank.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _recordGameHistory(
        userId: userId,
        result: result,
        role: role,
        xpGained: xpGained,
        isOnlineGame: isOnlineGame,
        playerCount: allPlayerIds.length,
      );
      
      return {
        'xpGained': xpGained,
        'newTotalXP': newTotalXP,
        'oldRank': currentRank,
        'newRank': newRank.name,
        'rankChanged': rankChanged,
        'winStreak': winStreak,
        'stats': updatedStats,
      };
    } catch (e) {
      print('Error recording game result: $e');
      return null;
    }
  }
  
  Future<void> _recordGameHistory({
    required String userId,
    required GameResult result,
    required PlayerRole role,
    required int xpGained,
    required bool isOnlineGame,
    required int playerCount,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('gameHistory')
          .add({
        'result': result.toString(),
        'role': role.toString(),
        'xpGained': xpGained,
        'isOnlineGame': isOnlineGame,
        'playerCount': playerCount,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      final historyDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('gameHistory')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      if (historyDocs.docs.length > 50) {
        final batch = _firestore.batch();
        for (int i = 50; i < historyDocs.docs.length; i++) {
          batch.delete(historyDocs.docs[i].reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error recording game history: $e');
    }
  }
  
  bool _isFirstWinToday(Timestamp? lastWinDate) {
    if (lastWinDate == null) return true;
    
    final lastWin = lastWinDate.toDate();
    final now = DateTime.now();
    
    return lastWin.year != now.year ||
           lastWin.month != now.month ||
           lastWin.day != now.day;
  }
  
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      
      final userData = userDoc.data()!;
      return {
        'stats': userData['stats'] ?? {},
        'xp': userData['xp'] ?? 0,
        'rank': userData['rank'] ?? 'Iron',
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('xp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'avatarEmoji': data['avatarEmoji'] ?? '🕵️‍♂️',
          'xp': data['xp'] ?? 0,
          'rank': data['rank'] ?? 'Iron',
          'stats': data['stats'] ?? {},
        };
      }).toList();
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }
  
  Future<int> getUserRankPosition(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return -1;
      
      final userXP = userDoc.data()!['xp'] as int? ?? 0;
      
      final countQuery = await _firestore
          .collection('users')
          .where('xp', isGreaterThan: userXP)
          .count()
          .get();
      
      return (countQuery.count ?? 0) + 1;
    } catch (e) {
      print('Error getting user rank position: $e');
      return -1;
    }
  }
  
  Future<void> resetDailyStats() async {
    try {
      final users = await _firestore.collection('users').get();
      final batch = _firestore.batch();
      
      for (final doc in users.docs) {
        final stats = doc.data()['stats'] as Map<String, dynamic>? ?? {};
        stats['dailyGames'] = 0;
        stats['dailyWins'] = 0;
        
        batch.update(doc.reference, {'stats': stats});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error resetting daily stats: $e');
    }
  }
  
  Future<Map<String, dynamic>> calculateSeasonRewards(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {'rewards': 0, 'bonuses': []};
      
      final userData = userDoc.data()!;
      final rank = userData['rank'] as String? ?? 'Iron';
      final stats = userData['stats'] as Map<String, dynamic>? ?? {};
      
      int baseReward = 0;
      List<String> bonuses = [];
      
      switch (rank) {
        case 'Challenger':
          baseReward = 5000;
          bonuses.add('Challenger Frame');
          break;
        case 'Grandmaster':
          baseReward = 3000;
          bonuses.add('Grandmaster Badge');
          break;
        case 'Master':
          baseReward = 2000;
          bonuses.add('Master Title');
          break;
        case 'Diamond':
          baseReward = 1500;
          break;
        case 'Platinum':
          baseReward = 1000;
          break;
        case 'Gold':
          baseReward = 500;
          break;
        case 'Silver':
          baseReward = 250;
          break;
        case 'Bronze':
          baseReward = 100;
          break;
        default:
          baseReward = 50;
      }
      
      final gamesPlayed = stats['gamesPlayed'] as int? ?? 0;
      if (gamesPlayed >= 100) {
        baseReward = (baseReward * 1.5).round();
        bonuses.add('Dedicated Player Bonus');
      }
      
      final winRate = double.tryParse(stats['winRate']?.toString() ?? '0') ?? 0;
      if (winRate >= 60) {
        baseReward = (baseReward * 1.25).round();
        bonuses.add('High Win Rate Bonus');
      }
      
      return {
        'rewards': baseReward,
        'bonuses': bonuses,
        'rank': rank,
      };
    } catch (e) {
      print('Error calculating season rewards: $e');
      return {'rewards': 0, 'bonuses': []};
    }
  }
}