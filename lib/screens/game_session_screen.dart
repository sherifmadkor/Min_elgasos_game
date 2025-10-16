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

class GameSessionScreen extends StatefulWidget {
  final GameRoom gameRoom;
  final String currentUserId;

  const GameSessionScreen({
    super.key,
    required this.gameRoom,
    required this.currentUserId,
  });

  @override
  State<GameSessionScreen> createState() => _GameSessionScreenState();
}

class _GameSessionScreenState extends State<GameSessionScreen> {
  final _roomService = RealtimeRoomService();
  bool _hasNavigated = false;

  bool get _isHost => widget.currentUserId == widget.gameRoom.hostId;

  @override
  void initState() {
    super.initState();
    AppLifecycleService().setCurrentRoom(widget.gameRoom.id);
  }

  @override
  void dispose() {
    AppLifecycleService().setCurrentRoom(null);
    super.dispose();
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
            title: Text('${widget.gameRoom.roomName} - ${l10n.gameSession}'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: StreamBuilder<GameRoom?>(
            stream: _roomService.getRoomById(widget.gameRoom.id),
            builder: (context, snapshot) {
              final room = snapshot.data ?? widget.gameRoom;
              
              // Handle status transitions
              if (room.status == RoomStatus.rulesRevealed && !_hasNavigated) {
                _hasNavigated = true;
                // Navigate to rules reveal screen
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/rules_reveal',
                      arguments: {
                        'gameRoom': room,
                        'currentUserId': widget.currentUserId,
                      },
                    );
                  }
                });
                return const Center(child: CircularProgressIndicator());
              }
              
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Game Status Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.accentColor, width: 2),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.sports_esports,
                              size: 50,
                              color: AppTheme.accentColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.gameSession,
                              style: AppTheme.textTheme.headlineLarge?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${l10n.round} ${room.currentRound ?? 1}',
                              style: AppTheme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Game Information
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.gameInformation,
                              style: AppTheme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(l10n.timerDuration, '${room.gameSettings.minutes} ${l10n.minutes}'),
                            _buildInfoRow(l10n.totalPlayers, '${room.players.length}'),
                            _buildInfoRow(l10n.detectives, '${room.players.length - (room.gameSettings.spyCount)}'),
                            _buildInfoRow(l10n.spies, '${room.gameSettings.spyCount}'),
                            if (room.status == RoomStatus.rulesRevealed && room.currentWord != null)
                              _buildInfoRow(l10n.location, room.currentWord!),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Players List with Session Stats
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.playersInSession,
                              style: AppTheme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            ...room.players.map((player) {
                              final wins = room.sessionWins?[player.id] ?? 0;
                              final losses = room.sessionLosses?[player.id] ?? 0;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: player.isHost 
                                      ? AppTheme.accentColor.withOpacity(0.1)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: player.isHost 
                                        ? AppTheme.accentColor
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
                                    if (player.isHost)
                                      const Icon(Icons.star, color: AppTheme.accentColor, size: 20),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'W: $wins',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'L: $losses',
                                        style: const TextStyle(
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
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Pre-Reveal Section (waiting for host to reveal roles)
                      if (room.status == RoomStatus.starting) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            border: Border.all(color: AppTheme.accentColor, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 60,
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Game Ready!',
                                style: AppTheme.textTheme.headlineLarge?.copyWith(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isHost 
                                    ? 'Click below to reveal roles to all players'
                                    : 'Waiting for host to reveal player roles...',
                                style: AppTheme.textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_isHost) ...[
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _revealRoles,
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
                                      const Icon(Icons.visibility, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Reveal Roles',
                                        style: AppTheme.textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 20),
                                const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.accentColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      
                      // Rules Reveal Section
                      if (room.status == RoomStatus.rulesRevealed) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _getCurrentPlayerRole(room) == PlayerRole.spy 
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            border: Border.all(
                              color: _getCurrentPlayerRole(room) == PlayerRole.spy 
                                  ? Colors.red 
                                  : Colors.green,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getCurrentPlayerRole(room) == PlayerRole.spy 
                                    ? Icons.visibility_off
                                    : Icons.search,
                                size: 60,
                                color: _getCurrentPlayerRole(room) == PlayerRole.spy 
                                    ? Colors.red 
                                    : Colors.green,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getCurrentPlayerRole(room) == PlayerRole.spy
                                    ? '${l10n.youAreSpy} 🥷'
                                    : '${l10n.youAreDetective} 🕵️',
                                style: AppTheme.textTheme.headlineLarge?.copyWith(
                                  color: _getCurrentPlayerRole(room) == PlayerRole.spy 
                                      ? Colors.red 
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ...[
                                const Divider(color: AppTheme.textSecondaryColor),
                                const SizedBox(height: 12),
                                Text(
                                  '${l10n.location}:',
                                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  room.currentWord ?? '',
                                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Host Controls
                      if (_isHost) ...[
                        if (room.status == RoomStatus.rulesRevealed) ...[
                          // Start Round Button
                          ElevatedButton(
                            onPressed: _startRound,
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
                                  l10n.startRound,
                                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  PlayerRole? _getCurrentPlayerRole(GameRoom room) {
    final playerIndex = room.players.indexWhere((p) => p.id == widget.currentUserId);
    if (playerIndex >= 0 && room.spyAssignments != null) {
      return room.spyAssignments![playerIndex] ? PlayerRole.spy : PlayerRole.detective;
    }
    return PlayerRole.detective; // Default to detective if not found
  }

  Future<void> _revealRoles() async {
    try {
      await _roomService.revealRoles(widget.gameRoom.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error revealing rules: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startRound() async {
    try {
      await _roomService.updateRoom(widget.gameRoom.id, {
        'status': RoomStatus.inGame.name,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting round: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}