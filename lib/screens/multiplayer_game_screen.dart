import 'package:flutter/material.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../l10n/app_localizations.dart';
import '../models/room_models.dart';
import '../services/realtime_room_service.dart';
import '../services/language_service.dart';
import '../services/game_stats_service.dart';
import 'dart:async';

class MultiplayerGameScreen extends StatefulWidget {
  final String roomId;

  const MultiplayerGameScreen({super.key, required this.roomId});

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  final _roomService = RealtimeRoomService();
  final _gameStatsService = GameStatsService();
  
  GameRoom? _currentRoom;
  RoomPlayer? _currentPlayer;
  Timer? _gameTimer;
  int _remainingSeconds = 0;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGameTimer(int minutes) {
    _remainingSeconds = minutes * 60;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        if (!_gameEnded) {
          _endGame(spiesWin: false); // Detectives win by default if time runs out
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
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
            title: Text(_currentRoom?.roomName ?? 'Game in Progress'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _confirmLeaveGame,
            ),
          ),
          body: StreamBuilder<GameRoom?>(
            stream: _roomService.getRoomById(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentColor),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return _buildErrorState();
              }

              _currentRoom = snapshot.data!;
              
              // Find current player
              final currentUserId = _roomService.auth.currentUser?.uid;
              _currentPlayer = _currentRoom!.players.firstWhere(
                (p) => p.id == currentUserId,
                orElse: () => _currentRoom!.players.first,
              );

              // Start timer if game just started and not already running
              if (_currentRoom!.status == RoomStatus.inGame && 
                  _gameTimer == null && 
                  !_gameEnded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _startGameTimer(_currentRoom!.gameSettings.minutes);
                });
              }

              // Check if game ended
              if (_currentRoom!.status == RoomStatus.finished && !_gameEnded) {
                _gameEnded = true;
                _gameTimer?.cancel();
              }

              return _buildGameContent();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Game not found',
            style: AppTheme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    if (_currentRoom!.status == RoomStatus.finished) {
      return _buildGameEndedState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGameHeader(),
          const SizedBox(height: 16),
          _buildRoleCard(),
          const SizedBox(height: 16),
          _buildGameInfo(),
          const Spacer(),
          if (_currentPlayer?.isHost == true)
            _buildHostControls(),
        ],
      ),
    );
  }

  Widget _buildGameHeader() {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game in Progress',
                  style: AppTheme.textTheme.titleMedium,
                ),
                Text(
                  '${_currentRoom!.players.length} Players',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Time Remaining',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  _formatTime(_remainingSeconds),
                  style: AppTheme.textTheme.headlineLarge?.copyWith(
                    color: _remainingSeconds <= 60 ? Colors.red : AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard() {
    final isSpy = _currentPlayer?.assignedRole == PlayerRole.spy;
    final roleColor = isSpy ? Colors.red : Colors.green;
    final roleIcon = isSpy ? Icons.visibility_off : Icons.visibility;
    final roleText = isSpy ? 'SPY' : 'DETECTIVE';

    return Card(
      color: roleColor.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: roleColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(
              roleIcon,
              size: 64,
              color: roleColor,
            ),
            const SizedBox(height: 12),
            Text(
              'You are a $roleText',
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                color: roleColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSpy 
                ? 'Try to figure out the location without being discovered!'
                : 'Find the spy and vote them out!',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!isSpy && _currentRoom!.currentWord != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'The location is:',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentRoom!.currentWord!,
                style: AppTheme.textTheme.headlineLarge?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else if (isSpy) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Location: ???',
                style: AppTheme.textTheme.headlineLarge?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Listen carefully and try to blend in!',
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Information',
              style: AppTheme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Category', _currentRoom!.gameSettings.category),
            _buildInfoRow('Total Spies', '${_currentRoom!.gameSettings.spyCount}'),
            _buildInfoRow('Total Detectives', 
                '${_currentRoom!.players.length - _currentRoom!.gameSettings.spyCount}'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Players in Game',
              style: AppTheme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._currentRoom!.players.map((player) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(player.avatar, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.name,
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: player.id == _currentPlayer?.id 
                            ? FontWeight.bold 
                            : null,
                      ),
                    ),
                  ),
                  if (player.id == _currentPlayer?.id)
                    Text(
                      '(You)',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostControls() {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Host Controls',
              style: AppTheme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _endGame(spiesWin: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Spies Win'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _endGame(spiesWin: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Detectives Win'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameEndedState() {
    return Center(
      child: Card(
        color: AppTheme.surfaceColor,
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag,
                size: 64,
                color: AppTheme.accentColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Game Ended',
                style: AppTheme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'The game has finished. Thanks for playing!',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _endGame({required bool spiesWin}) async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('End Game'),
        content: Text(
          'Are you sure you want to end the game?\n${spiesWin ? "Spies" : "Detectives"} will be declared the winners.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Game'),
          ),
        ],
      ),
    );

    if (shouldEnd == true) {
      _gameEnded = true;
      _gameTimer?.cancel();
      
      await _roomService.endGame(widget.roomId, spiesWin: spiesWin);
      
      if (false && mounted) { // This block is no longer needed since endGame doesn't return a boolean
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to end game.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmLeaveGame() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Leave Game'),
        content: const Text('Are you sure you want to leave the game? This will not affect the ongoing game for other players.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      await _roomService.leaveRoom(widget.roomId);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    }
  }
}