import 'package:flutter/material.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localizations_extension.dart';
import '../models/room_models.dart';
import '../services/realtime_room_service.dart';
import '../services/language_service.dart';
import '../services/game_stats_service.dart';
import '../services/app_lifecycle_service.dart';
import '../widgets/rank_emblem_png.dart';

class VotingResultsScreen extends StatefulWidget {
  final GameRoom gameRoom;
  final String currentUserId;

  const VotingResultsScreen({
    super.key,
    required this.gameRoom,
    required this.currentUserId,
  });

  @override
  State<VotingResultsScreen> createState() => _VotingResultsScreenState();
}

class _VotingResultsScreenState extends State<VotingResultsScreen> {
  final _roomService = RealtimeRoomService();
  final _gameStatsService = GameStatsService();
  Map<String, int> _voteResults = {};
  String? _mostVotedPlayer;
  bool _spiesWon = false;
  bool _resultsProcessed = false;

  bool get _isHost => widget.currentUserId == widget.gameRoom.hostId;

  @override
  void initState() {
    super.initState();
    AppLifecycleService().setCurrentRoom(widget.gameRoom.id);
    _calculateVoteResults();
  }

  @override
  void dispose() {
    AppLifecycleService().setCurrentRoom(null);
    super.dispose();
  }

  void _calculateVoteResults() {
    final votes = widget.gameRoom.playerVotes ?? {};
    final results = <String, int>{};
    
    // Count votes for each player
    for (final votedFor in votes.values) {
      results[votedFor] = (results[votedFor] ?? 0) + 1;
    }
    
    // Find player with most votes
    String? mostVoted;
    int maxVotes = 0;
    results.forEach((playerId, voteCount) {
      if (voteCount > maxVotes) {
        maxVotes = voteCount;
        mostVoted = playerId;
      }
    });
    
    setState(() {
      _voteResults = results;
      _mostVotedPlayer = mostVoted;
      _spiesWon = _calculateSpiesWon();
    });
  }

  bool _calculateSpiesWon() {
    if (_mostVotedPlayer == null) return true; // Spies win if no one voted out
    
    // Find the most voted player's role
    final playerIndex = widget.gameRoom.players.indexWhere((p) => p.id == _mostVotedPlayer);
    if (playerIndex >= 0 && widget.gameRoom.spyAssignments != null) {
      final wasActualSpy = widget.gameRoom.spyAssignments![playerIndex];
      return !wasActualSpy; // Spies win if an innocent was voted out
    }
    
    return true; // Default to spies win
  }

  List<RoomPlayer> get _spies {
    return widget.gameRoom.players.where((player) {
      final playerIndex = widget.gameRoom.players.indexWhere((p) => p.id == player.id);
      return playerIndex >= 0 && 
             widget.gameRoom.spyAssignments != null && 
             widget.gameRoom.spyAssignments![playerIndex];
    }).toList();
  }

  List<RoomPlayer> get _detectives {
    return widget.gameRoom.players.where((player) {
      final playerIndex = widget.gameRoom.players.indexWhere((p) => p.id == player.id);
      return playerIndex >= 0 && 
             widget.gameRoom.spyAssignments != null && 
             !widget.gameRoom.spyAssignments![playerIndex];
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = LanguageService().isRtl;

    return BackgroundContainer(
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text('${widget.gameRoom.roomName} - ${l10n.result}'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Game Result Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _spiesWon 
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      border: Border.all(
                        color: _spiesWon ? Colors.red : Colors.green,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _spiesWon ? Icons.visibility_off : Icons.search,
                          size: 60,
                          color: _spiesWon ? Colors.red : Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _spiesWon ? '${l10n.spies.toUpperCase()} WIN! 🥷' : '${l10n.detectives.toUpperCase()} WIN! 🕵️',
                          style: AppTheme.textTheme.headlineLarge?.copyWith(
                            color: _spiesWon ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _spiesWon 
                              ? (isRtl ? 'نجح الجواسيس في خداع المحققين!' : 'The spies successfully deceived the detectives!')
                              : (isRtl ? 'المحققون أمسكوا بالجاسوس!' : 'The detectives caught the spy!'),
                          style: AppTheme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Voting Results
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.votingResults,
                          style: AppTheme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (_mostVotedPlayer != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  l10n.mostVotedPlayer,
                                  style: AppTheme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getPlayerName(_mostVotedPlayer!),
                                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_voteResults[_mostVotedPlayer!]} ${l10n.votes}',
                                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // All voting results
                        ...widget.gameRoom.players.map((player) {
                          final votes = _voteResults[player.id] ?? 0;
                          final isMostVoted = player.id == _mostVotedPlayer;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMostVoted 
                                  ? Colors.orange.withOpacity(0.1)
                                  : AppTheme.surfaceColor,
                              border: Border.all(
                                color: isMostVoted 
                                    ? Colors.orange
                                    : AppTheme.textSecondaryColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  player.avatar,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.name,
                                        style: AppTheme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: isMostVoted ? FontWeight.bold : null,
                                          color: isMostVoted ? Colors.orange : null,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          RankEmblemPNG(rankName: player.rank, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.getLocalizedRankName(player.rank),
                                            style: AppTheme.textTheme.bodySmall?.copyWith(
                                              color: AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$votes ${l10n.votes}',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Role Reveals
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.playerRoles,
                          style: AppTheme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        
                        // Spies
                        if (_spies.isNotEmpty) ...[
                          Text(
                            '${l10n.spies} 🥷',
                            style: AppTheme.textTheme.bodyLarge?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._spies.map((spy) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text(spy.avatar, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      spy.name,
                                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        RankEmblemPNG(rankName: spy.rank, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.getLocalizedRankName(spy.rank),
                                          style: AppTheme.textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                        
                        // Detectives
                        if (_detectives.isNotEmpty) ...[
                          Text(
                            '${l10n.detectives} 🕵️',
                            style: AppTheme.textTheme.bodyLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._detectives.map((detective) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text(detective.avatar, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detective.name,
                                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        RankEmblemPNG(rankName: detective.rank, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.getLocalizedRankName(detective.rank),
                                          style: AppTheme.textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                        
                        // Location reveal
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.accentColor),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.location}: ${widget.gameRoom.currentWord}',
                                style: AppTheme.textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Updated Session Stats
                  StreamBuilder<GameRoom?>(
                    stream: _roomService.getRoomById(widget.gameRoom.id),
                    builder: (context, snapshot) {
                      final room = snapshot.data ?? widget.gameRoom;
                      
                      // Navigate to game session when next round starts
                      if (room.status == RoomStatus.starting) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pushReplacementNamed(
                            context,
                            '/game_session',
                            arguments: {
                              'gameRoom': room,
                              'currentUserId': widget.currentUserId,
                            },
                          );
                        });
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      // Navigate to main menu when session ends or room is deleted
                      if (room.status == RoomStatus.finished || snapshot.data == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            );
                          }
                        });
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.sessionStats,
                              style: AppTheme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            ...room.players.map((player) {
                              final wins = room.sessionWins?[player.id] ?? 0;
                              final losses = room.sessionLosses?[player.id] ?? 0;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      player.avatar,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player.name,
                                            style: AppTheme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: player.isHost ? FontWeight.bold : null,
                                              color: player.isHost ? AppTheme.accentColor : null,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              RankEmblemPNG(rankName: player.rank, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                l10n.getLocalizedRankName(player.rank),
                                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textSecondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'W: $wins',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'L: $losses',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Host Controls
                  if (_isHost) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _startNextRound,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.skip_next, color: Colors.white),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    l10n.nextRound,
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _endGameSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stop, color: Colors.white),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    l10n.endSession,
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.textSecondaryColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              isRtl ? 'في انتظار المضيف...' : 'Waiting for host...',
                              style: AppTheme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPlayerName(String playerId) {
    final player = widget.gameRoom.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => RoomPlayer(
        id: playerId,
        name: 'Unknown Player',
        avatar: '❓',
        isHost: false,
        rank: 'Iron',
        isReady: false,
        joinedAt: DateTime.now(),
        isOnline: false,
      ),
    );
    return player.name;
  }

  Future<void> _startNextRound() async {
    try {
      // Update session stats first if not already done
      if (!_resultsProcessed) {
        await _updateSessionStats();
      }
      
      // Reset the room to starting phase for next round
      await _roomService.updateRoom(widget.gameRoom.id, {
        'currentPhase': 'waitingForReveal',
        'status': 'starting',
      });
      await _roomService.resetVotes(widget.gameRoom.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting next round: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _endGameSession() async {
    try {
      print('🛑 Host ending game session for room: ${widget.gameRoom.id}');

      // Update session stats if not already done
      if (!_resultsProcessed) {
        await _updateSessionStats();
      }

      // Properly end the game using the endGame method and update all necessary fields
      print('📝 Updating room status to finished...');
      await _roomService.endGame(widget.gameRoom.id);
      await _roomService.updateRoom(widget.gameRoom.id, {
        'currentPhase': 'ended',
        'gameEnded': true,
        'status': 'finished',
        'finishedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Small delay to ensure status update propagates to all clients
      await Future.delayed(const Duration(milliseconds: 500));

      // Delete the room to clean up backend
      print('🗑️ Deleting room from backend...');
      await _roomService.deleteRoom(widget.gameRoom.id);
      print('✅ Room deleted successfully');

      // Navigate to main menu even if deletion fails
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error ending session: $e');

      // Ensure we still navigate even if there was an error
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session ended (cleanup error: $e)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _updateSessionStats() async {
    if (_resultsProcessed) return;
    
    try {
      final currentWins = widget.gameRoom.sessionWins ?? <String, int>{};
      final currentLosses = widget.gameRoom.sessionLosses ?? <String, int>{};
      
      // Update wins/losses for each player (including host)
      for (final player in widget.gameRoom.players) {
        final playerIndex = widget.gameRoom.players.indexWhere((p) => p.id == player.id);
        if (playerIndex >= 0 && widget.gameRoom.spyAssignments != null) {
          final isSpy = widget.gameRoom.spyAssignments![playerIndex];
          final playerWon = (isSpy && _spiesWon) || (!isSpy && !_spiesWon);
          
          if (playerWon) {
            currentWins[player.id] = (currentWins[player.id] ?? 0) + 1;
          } else {
            currentLosses[player.id] = (currentLosses[player.id] ?? 0) + 1;
          }
          
          // Award XP to user account
          await _gameStatsService.recordGameResult(
            userId: player.id,
            result: playerWon ? GameResult.win : GameResult.loss,
            role: isSpy ? PlayerRole.spy : PlayerRole.detective,
            allPlayerIds: widget.gameRoom.players.map((p) => p.id).toList(),
            isOnlineGame: true,
          );
        }
      }
      
      // Update room with new stats using realtime database
      await _roomService.updateRoom(widget.gameRoom.id, {
        'sessionWins': currentWins,
        'sessionLosses': currentLosses,
      });
      
      setState(() {
        _resultsProcessed = true;
      });
    } catch (e) {
      print('Error updating session stats: $e');
    }
  }
}