import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../l10n/app_localizations.dart';
import '../models/room_models.dart';
import '../services/realtime_room_service.dart';
import '../services/language_service.dart';

class RulesRevealScreen extends StatefulWidget {
  final GameRoom gameRoom;
  final String currentUserId;

  const RulesRevealScreen({
    super.key,
    required this.gameRoom,
    required this.currentUserId,
  });

  @override
  State<RulesRevealScreen> createState() => _RulesRevealScreenState();
}

class _RulesRevealScreenState extends State<RulesRevealScreen> {
  final _roomService = RealtimeRoomService();
  bool _rulesRevealed = false;

  bool get _isHost => widget.currentUserId == widget.gameRoom.hostId;

  PlayerRole? get _currentPlayerRole {
    final playerIndex = widget.gameRoom.players.indexWhere((p) => p.id == widget.currentUserId);
    if (playerIndex >= 0 && widget.gameRoom.spyAssignments != null) {
      return widget.gameRoom.spyAssignments![playerIndex] ? PlayerRole.spy : PlayerRole.detective;
    }
    return null;
  }

  String get _currentWord => widget.gameRoom.currentWord ?? '';

  int get _totalSpies {
    return widget.gameRoom.spyAssignments?.where((isSpy) => isSpy).length ?? 0;
  }

  int get _totalDetectives {
    return widget.gameRoom.players.length - _totalSpies;
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
            title: Text(widget.gameRoom.roomName),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: StreamBuilder<GameRoom?>(
            stream: _roomService.getRoomById(widget.gameRoom.id),
            builder: (context, snapshot) {
              final room = snapshot.data ?? widget.gameRoom;
              
              if (room.status == RoomStatus.inGame) {
                // Navigate to timer screen
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(
                    context,
                    '/multiplayer_game_timer',
                    arguments: {
                      'gameRoom': room,
                      'currentUserId': widget.currentUserId,
                    },
                  );
                });
                return const Center(child: CircularProgressIndicator());
              }

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Game Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rules Revealed',
                              style: AppTheme.textTheme.headlineSmall,
                            ),
                            Text(
                              '${room.players.length} Players',
                              style: AppTheme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Role Reveal Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _currentPlayerRole == PlayerRole.spy 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          border: Border.all(
                            color: _currentPlayerRole == PlayerRole.spy 
                                ? Colors.red
                                : Colors.green,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _currentPlayerRole == PlayerRole.spy 
                                  ? Icons.visibility_off
                                  : Icons.search,
                              size: 60,
                              color: _currentPlayerRole == PlayerRole.spy 
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentPlayerRole == PlayerRole.spy 
                                  ? 'You are a SPY 🥷'
                                  : 'You are a DETECTIVE 🕵️',
                              style: AppTheme.textTheme.headlineMedium?.copyWith(
                                color: _currentPlayerRole == PlayerRole.spy 
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (_currentPlayerRole == PlayerRole.detective) ...[
                              const Divider(color: AppTheme.textSecondaryColor),
                              const SizedBox(height: 16),
                              Text(
                                'The location is:',
                                style: AppTheme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentWord,
                                style: AppTheme.textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              const Divider(color: AppTheme.textSecondaryColor),
                              const SizedBox(height: 16),
                              Text(
                                'Find the location and blend in!',
                                style: AppTheme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Game Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Game Information',
                              style: AppTheme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Category:', style: AppTheme.textTheme.bodyLarge),
                                Text(
                                  room.gameSettings.category,
                                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Spies:', style: AppTheme.textTheme.bodyLarge),
                                Text(
                                  '$_totalSpies',
                                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Detectives:', style: AppTheme.textTheme.bodyLarge),
                                Text(
                                  '$_totalDetectives',
                                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Game Duration:', style: AppTheme.textTheme.bodyLarge),
                                Text(
                                  '${room.gameSettings.minutes} minutes',
                                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Players List with W/L
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Players in Game',
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
                                      child: Text(
                                        player.name,
                                        style: AppTheme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: player.isHost ? FontWeight.bold : null,
                                          color: player.isHost ? AppTheme.accentColor : null,
                                        ),
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
                                    if (player.isHost)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(Icons.star, color: AppTheme.accentColor, size: 20),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Host Controls
                      if (_isHost) ...[
                        ElevatedButton(
                          onPressed: _startGameTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Start Round Timer',
                                style: AppTheme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
                              Text(
                                'Waiting for host to start the round...',
                                style: AppTheme.textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _startGameTimer() async {
    try {
      // Update room status to start the game timer
      await _roomService.updateRoom(widget.gameRoom.id, {
        'status': RoomStatus.inGame.name,
        'startedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}