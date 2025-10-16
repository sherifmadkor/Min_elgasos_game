import 'dart:async';
import 'package:flutter/material.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localizations_extension.dart';
import '../models/room_models.dart';
import '../services/realtime_room_service.dart';
import '../services/language_service.dart';
import '../services/app_lifecycle_service.dart';
import '../widgets/rank_emblem_png.dart';

class VotingScreen extends StatefulWidget {
  final GameRoom gameRoom;
  final String currentUserId;

  const VotingScreen({
    super.key,
    required this.gameRoom,
    required this.currentUserId,
  });

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final _roomService = RealtimeRoomService();
  String? _selectedPlayerId;
  bool _isSubmittingVote = false;
  StreamSubscription? _roomSubscription;
  GameRoom? _currentRoom;
  bool _hasNavigated = false; // Navigation guard

  bool get _isHost => widget.currentUserId == widget.gameRoom.hostId;
  
  List<RoomPlayer> get _votablePlayers {
    return widget.gameRoom.players.where((p) => p.id != widget.currentUserId).toList();
  }

  @override
  void initState() {
    super.initState();
    AppLifecycleService().setCurrentRoom(widget.gameRoom.id);
    _startListeningToRoom();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    AppLifecycleService().setCurrentRoom(null);
    super.dispose();
  }

  void _startListeningToRoom() {
    print('VotingScreen: Starting to listen to Realtime Database room');
    _roomSubscription = _roomService.getRoomById(widget.gameRoom.id).listen(
      (room) {
        print('VotingScreen: Received room update: ${room?.id}, status: ${room?.status}');
        if (mounted && room != null) {
          setState(() {
            _currentRoom = room;
            // Update selected player if we have voted
            if (room.playerVotes != null && room.playerVotes!.containsKey(widget.currentUserId)) {
              _selectedPlayerId = room.playerVotes![widget.currentUserId];
            }
          });
        } else if (mounted && room == null && !_hasNavigated) {
          // Room was deleted, navigate home (only if we haven't already navigated to results)
          print('VotingScreen: Room was deleted, navigating home');
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          });
        }
      },
      onError: (error) {
        print('VotingScreen: Error listening to room: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = LanguageService().isRtl;

    return BackgroundContainer(
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: ClipRect(
          child: Scaffold(
          appBar: AppBar(
            title: Text('${widget.gameRoom.roomName} - ${l10n.votingPhase}'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Builder(
            builder: (context) {
              final room = _currentRoom ?? widget.gameRoom;
              
              // Use Realtime Database votes as source of truth
              final votes = room.playerVotes ?? {};
              final hasVoted = votes.containsKey(widget.currentUserId);
              
              if (room.status == RoomStatus.resultsShowing && !_hasNavigated) {
                // Navigate to results screen (with guard to prevent duplicate navigation)
                _hasNavigated = true;
                print('VotingScreen: Navigating to results screen');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/voting_results',
                      arguments: {
                        'gameRoom': room,
                        'currentUserId': widget.currentUserId,
                      },
                    );
                  }
                });
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentColor,
                    ),
                  ),
                );
              }

              final totalVotes = votes.length; // Count all votes in Realtime DB
              final totalPlayers = room.players.length;
              final allVoted = totalVotes >= totalPlayers;
              
              // DEBUG: Log voting status
              print('=== VOTING SCREEN DEBUG ===');
              print('DEBUG VOTING: Current User ID: ${widget.currentUserId}');
              print('DEBUG VOTING: Room ID: ${room.id}');
              print('DEBUG VOTING: Host ID: ${room.hostId}');
              print('DEBUG VOTING: Is current user host: ${widget.currentUserId == room.hostId}');
              print('DEBUG VOTING: Total players: $totalPlayers');
              print('DEBUG VOTING: Total votes: $totalVotes');
              print('DEBUG VOTING: All voted: $allVoted');
              print('DEBUG VOTING: Votes map: $votes');
              print('DEBUG VOTING: Room players: ${room.players.map((p) => '${p.name}(${p.id})[host:${p.isHost}]').toList()}');
              print('DEBUG VOTING: Realtime Database votes:');
              print('DEBUG VOTING: Realtime votes map: $votes');
              print('DEBUG VOTING: Vote count per player:');
              for (var player in room.players) {
                final hasVoted = votes.containsKey(player.id);
                final votedFor = votes[player.id];
                print('  - ${player.name} (${player.id})[host:${player.isHost}]: voted=$hasVoted${hasVoted ? ' for $votedFor' : ''}');
              }
              print('=== END DEBUG ===');

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Voting Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.votingPhase,
                                  style: AppTheme.textTheme.headlineSmall,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: allVoted ? Colors.green : AppTheme.accentColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '$totalVotes/$totalPlayers ${l10n.voted}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: totalVotes / totalPlayers,
                              backgroundColor: AppTheme.surfaceColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                allVoted ? Colors.green : AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Instructions
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.how_to_vote,
                              color: Colors.orange,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.voteForSpy,
                              style: AppTheme.textTheme.headlineSmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.votingInstructions,
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Voting Options
                      if (!hasVoted && !_isSubmittingVote) ...[
                        Text(
                          l10n.selectPlayerToVote,
                          style: AppTheme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),
                        ..._votablePlayers.map((player) => _buildVotingCard(player, l10n)),
                        
                        const SizedBox(height: 30),
                        
                        // Submit Vote Button
                        if (_selectedPlayerId != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitVote,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.how_to_vote, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n.submitVote,
                                        style: AppTheme.textTheme.bodyLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ] else if (_isSubmittingVote) ...[
                        // Submitting Vote
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: Colors.orange),
                              const SizedBox(height: 12),
                              Text(
                                'Submitting vote...',
                                style: AppTheme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (hasVoted) ...[
                        // Already Voted
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 50,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.voteSubmitted,
                                style: AppTheme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_selectedPlayerId != null)
                                Text(
                                  '${l10n.youVotedFor} ${_getPlayerName(_selectedPlayerId!)}',
                                  style: AppTheme.textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.waitingForOthers,
                                style: AppTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 30),
                      
                      // Player Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.votingStatus,
                              style: AppTheme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            ...room.players.map((player) {
                              final hasPlayerVoted = votes.containsKey(player.id);
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
                                                  fontSize: 11,
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
                                    const SizedBox(width: 8),
                                    Icon(
                                      hasPlayerVoted ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: hasPlayerVoted ? Colors.green : AppTheme.textSecondaryColor,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Host Show Results Button
                      if (_isHost && allVoted)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showResults,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.poll, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      l10n.showResults,
                                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildVotingCard(RoomPlayer player, AppLocalizations l10n) {
    final isSelected = _selectedPlayerId == player.id;
    final wins = widget.gameRoom.sessionWins?[player.id] ?? 0;
    final losses = widget.gameRoom.sessionLosses?[player.id] ?? 0;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlayerId = player.id;
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentColor.withOpacity(0.1)
              : AppTheme.surfaceColor,
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : AppTheme.textSecondaryColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              player.avatar,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.accentColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RankEmblemPNG(rankName: player.rank, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        l10n.getLocalizedRankName(player.rank),
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
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
                ],
              ),
            ),
            Radio<String>(
              value: player.id,
              groupValue: _selectedPlayerId,
              onChanged: (value) {
                setState(() {
                  _selectedPlayerId = value;
                });
              },
              activeColor: AppTheme.accentColor,
            ),
          ],
        ),
      ),
    );
  }

  String _getPlayerName(String playerId) {
    final player = widget.gameRoom.players.firstWhere((p) => p.id == playerId);
    return player.name;
  }

  Future<void> _submitVote() async {
    if (_selectedPlayerId == null || _isSubmittingVote) return;
    
    setState(() {
      _isSubmittingVote = true;
    });
    
    try {
      print('=== REALTIME VOTE SUBMISSION START ===');
      print('VotingScreen: Current user: ${widget.currentUserId}');
      print('VotingScreen: Voting for: $_selectedPlayerId');
      print('VotingScreen: Room ID: ${widget.gameRoom.id}');
      
      // Submit vote using Realtime Database
      await _roomService.submitVote(
        roomCode: widget.gameRoom.id,
        voterName: widget.currentUserId,
        votedForName: _selectedPlayerId!,
      );

      print('=== REALTIME VOTE SUBMISSION SUCCESS ===');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('VotingScreen: Vote submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingVote = false;
        });
      }
    }
  }

  Future<void> _showResults() async {
    try {
      await _roomService.setGamePhase(widget.gameRoom.id, 'results');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error showing results: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}