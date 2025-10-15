import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../l10n/app_localizations.dart';
import '../models/room_models.dart';
import '../services/realtime_room_service.dart';
import '../services/language_service.dart';
import '../services/app_lifecycle_service.dart';
import '../widgets/rank_emblem_png.dart';
import 'multiplayer_game_screen.dart';

class RoomLobbyScreen extends StatefulWidget {
  final String roomId;

  const RoomLobbyScreen({super.key, required this.roomId});

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  final _roomService = RealtimeRoomService();
  GameRoom? _currentRoom;
  bool _hasNavigated = false;
  
  @override
  void initState() {
    super.initState();
    AppLifecycleService().setCurrentRoom(widget.roomId);
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
            title: Text(_currentRoom?.roomName ?? (LanguageService().isArabic ? 'صالة الغرفة' : 'Room Lobby')),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _leaveRoom,
            ),
            actions: [
              if (_currentRoom?.type == RoomType.private)
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareRoomCode,
                ),
            ],
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Room not found',
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

              _currentRoom = snapshot.data!;
              
              // DEBUG: Log room data
              final currentUserId = _roomService.auth.currentUser?.uid;
              print('\n=== ROOM LOBBY DEBUG ===');
              print('Current User ID: $currentUserId');
              print('Room Host ID: ${_currentRoom!.hostId}');
              print('Room Status: ${_currentRoom!.status}');
              print('Players count: ${_currentRoom!.players.length}');
              print('Players list:');
              for (var player in _currentRoom!.players) {
                print('  - ${player.name} (${player.id}) isHost: ${player.isHost} isReady: ${player.isReady}');
              }
              print('Is current user host? ${_currentRoom!.hostId == currentUserId}');
              print('========================\n');

              // Check if game started and navigate to game session screen
              if ((_currentRoom!.status == RoomStatus.starting || 
                  _currentRoom!.status == RoomStatus.rulesRevealed || 
                  _currentRoom!.status == RoomStatus.inGame) && !_hasNavigated) {
                _hasNavigated = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/game_session',
                      arguments: {
                        'gameRoom': _currentRoom,
                        'currentUserId': _roomService.auth.currentUser!.uid,
                      },
                    );
                  }
                });
                return const Center(child: CircularProgressIndicator());
              }
              
              // Check if room was deleted
              if (snapshot.data == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          LanguageService().isArabic 
                            ? 'تم حذف الغرفة بواسطة المضيف'
                            : 'Room was deleted by the host',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                });
                return const SizedBox.shrink();
              }

              return _buildLobbyContent();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLobbyContent() {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRoomInfo(),
          const SizedBox(height: 16),
          _buildGameSettings(),
          const SizedBox(height: 16),
          _buildPlayersList(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildGlassyCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomInfo() {
    return _buildGlassyCard(
      child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentRoom!.roomName,
                      style: AppTheme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _currentRoom!.type == RoomType.public ? Icons.public : Icons.lock,
                          size: 16,
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentRoom!.type == RoomType.public 
                              ? (LanguageService().isArabic ? 'غرفة عامة' : 'Public Room')
                              : (LanguageService().isArabic ? 'غرفة خاصة' : 'Private Room'),
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_currentRoom!.type == RoomType.private)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          LanguageService().isArabic ? 'كود الغرفة' : 'Room Code',
                          style: AppTheme.textTheme.bodySmall,
                        ),
                        Text(
                          _currentRoom!.roomCode ?? '',
                          style: AppTheme.textTheme.headlineMedium?.copyWith(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildPlayersList() {
    return _buildGlassyCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LanguageService().isArabic 
                      ? 'اللاعبين (${_currentRoom!.players.length}/${_currentRoom!.maxPlayers})'
                      : 'Players (${_currentRoom!.players.length}/${_currentRoom!.maxPlayers})',
                  style: AppTheme.textTheme.titleMedium,
                ),
                Icon(
                  Icons.people,
                  color: AppTheme.accentColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show players list
            ...(_currentRoom!.players.map((player) => _buildPlayerTile(player)).toList()),
            // Show waiting for players placeholder if needed
            if (_currentRoom!.players.length < _currentRoom!.maxPlayers)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.textSecondaryColor.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 32,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LanguageService().isArabic ? 'في انتظار اللاعبين...' : 'Waiting for players...',
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
    );
  }

  Widget _buildPlayerTile(RoomPlayer player) {
    final isCurrentUser = player.id == _roomService.auth.currentUser?.uid;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? AppTheme.accentColor.withOpacity(0.15) 
                  : AppTheme.surfaceColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentUser 
                    ? AppTheme.accentColor.withOpacity(0.5)
                    : AppTheme.textSecondaryColor.withOpacity(0.3),
                width: 1,
              ),
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
                Row(
                  children: [
                    Text(
                      player.name,
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: player.isHost ? FontWeight.bold : null,
                      ),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'HOST',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(You)',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  player.rank,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          MiniRankEmblemPNG(
            rankName: player.rank,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Icon(
                player.isOnline ? Icons.circle : Icons.circle_outlined,
                size: 12,
                color: player.isOnline ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: player.isReady ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    player.isReady ? 'READY' : 'WAIT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
            ),
          ),
        ),
    );
  }

  Widget _buildGameSettings() {
    final isHost = _currentRoom!.hostId == _roomService.auth.currentUser?.uid;
    
    return _buildGlassyCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  LanguageService().isArabic ? 'إعدادات اللعبة' : 'Game Settings',
                  style: AppTheme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (isHost)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: AppTheme.accentColor,
                    onPressed: _showGameSettingsDialog,
                    tooltip: LanguageService().isArabic ? 'تعديل الإعدادات' : 'Edit Settings',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingRow(
              icon: '👥',
              label: LanguageService().isArabic ? 'اللاعبين' : 'Players',
              value: '${_currentRoom!.gameSettings.playerCount}',
            ),
            _buildSettingRow(
              icon: '🥷',
              label: LanguageService().isArabic ? 'الجواسيس' : 'Spies',
              value: '${_currentRoom!.gameSettings.spyCount}',
            ),
            _buildSettingRow(
              icon: '⏱️',
              label: LanguageService().isArabic ? 'الوقت' : 'Time',
              value: LanguageService().isArabic 
                  ? '${_currentRoom!.gameSettings.minutes} دقيقة'
                  : '${_currentRoom!.gameSettings.minutes} min',
            ),
            _buildSettingRow(
              icon: '🎲',
              label: LanguageService().isArabic ? 'الفئة' : 'Category',
              value: _currentRoom!.gameSettings.category,
            ),
            if (isHost && _currentRoom!.currentWord != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LanguageService().isArabic ? 'المكان:' : 'Location:',
                      style: AppTheme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentRoom!.currentWord!,
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              LanguageService().isArabic ? 'حالة الغرفة' : 'Room Status',
              style: AppTheme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  size: 16,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusText(),
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildSettingRow({
    required String icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTheme.textTheme.bodyMedium,
            ),
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

  Widget _buildActionButtons() {
    final currentUserId = _roomService.auth.currentUser?.uid;
    final isHost = _currentRoom!.hostId == currentUserId;
    final currentPlayer = _currentRoom!.players.firstWhere(
      (p) => p.id == currentUserId,
      orElse: () => _currentRoom!.players.first,
    );

    return Row(
      children: [
        if (!isHost) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: _toggleReady,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentPlayer.isReady ? Colors.orange : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentPlayer.isReady ? Icons.pause : Icons.check,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentPlayer.isReady 
                        ? (LanguageService().isArabic ? 'غير جاهز' : 'Not Ready')
                        : (LanguageService().isArabic ? 'جاهز' : 'Ready Up'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (isHost) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: _canStartGame() ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    LanguageService().isArabic ? 'ابدأ اللعبة' : 'Start Game',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: _leaveRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          child: const Icon(Icons.exit_to_app, color: Colors.white),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (_currentRoom!.status) {
      case RoomStatus.waiting:
        return Icons.hourglass_empty;
      case RoomStatus.starting:
        return Icons.play_circle_outline;
      case RoomStatus.rulesRevealed:
        return Icons.visibility;
      case RoomStatus.inGame:
        return Icons.sports_esports;
      case RoomStatus.voting:
        return Icons.how_to_vote;
      case RoomStatus.resultsShowing:
        return Icons.poll;
      case RoomStatus.finished:
        return Icons.flag;
    }
  }

  Color _getStatusColor() {
    switch (_currentRoom!.status) {
      case RoomStatus.waiting:
        return Colors.orange;
      case RoomStatus.starting:
        return Colors.blue;
      case RoomStatus.rulesRevealed:
        return Colors.purple;
      case RoomStatus.inGame:
        return Colors.green;
      case RoomStatus.voting:
        return Colors.yellow;
      case RoomStatus.resultsShowing:
        return Colors.cyan;
      case RoomStatus.finished:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    if (LanguageService().isArabic) {
      switch (_currentRoom!.status) {
        case RoomStatus.waiting:
          return 'في انتظار اللاعبين';
        case RoomStatus.starting:
          return 'بدء اللعبة...';
        case RoomStatus.rulesRevealed:
          return 'عرض الأدوار';
        case RoomStatus.inGame:
          return 'اللعبة جارية';
        case RoomStatus.voting:
          return 'التصويت جاري';
        case RoomStatus.resultsShowing:
          return 'عرض النتائج';
        case RoomStatus.finished:
          return 'انتهت اللعبة';
      }
    } else {
      switch (_currentRoom!.status) {
        case RoomStatus.waiting:
          return 'Waiting for players';
        case RoomStatus.starting:
          return 'Starting game...';
        case RoomStatus.rulesRevealed:
          return 'Rules revealed';
        case RoomStatus.inGame:
          return 'Game in progress';
        case RoomStatus.voting:
          return 'Voting in progress';
        case RoomStatus.resultsShowing:
          return 'Showing results';
        case RoomStatus.finished:
          return 'Game finished';
      }
    }
  }

  bool _canStartGame() {
    // Allow starting with 2 players for testing
    if (_currentRoom!.players.length < 2) return false;
    
    final nonHostPlayers = _currentRoom!.players.where((p) => !p.isHost);
    return nonHostPlayers.every((p) => p.isReady);
  }

  Future<void> _toggleReady() async {
    await _roomService.toggleReadyStatus(widget.roomId);
  }

  Future<void> _startGame() async {
    try {
      // Debug current room state before starting game
      print('DEBUG: Starting game with current room data:');
      if (_currentRoom != null) {
        final nonHostPlayers = _currentRoom!.players.where((p) => !p.isHost).toList();
        print('DEBUG: Non-host players in UI:');
        for (final player in nonHostPlayers) {
          print('DEBUG: UI - Player ${player.name} - isReady: ${player.isReady}');
        }
      }
      
      // Start game automatically with predefined word selection (no dialogs)
      final success = await _roomService.startGame(widget.roomId);
      
      if (success) {
        // Get the updated room data first
        final roomDoc = await _roomService.firestore.collection('gameRooms').doc(widget.roomId).get();
        if (roomDoc.exists) {
          final updatedRoom = GameRoom.fromFirestore(roomDoc);
          // Navigate to game session screen
          Navigator.pushReplacementNamed(
            context,
            '/game_session',
            arguments: {
              'gameRoom': updatedRoom,
              'currentUserId': _roomService.auth.currentUser!.uid,
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start game. Make sure all players are ready.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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


  Future<void> _leaveRoom() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Leave Room'),
        content: const Text('Are you sure you want to leave this room?'),
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
      if (mounted) {
        // Navigate back to main menu safely
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  Future<void> _shareRoomCode() async {
    if (_currentRoom?.roomCode != null) {
      await Clipboard.setData(ClipboardData(text: _currentRoom!.roomCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room code ${_currentRoom!.roomCode} copied to clipboard'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    }
  }
  
  Future<void> _showGameSettingsDialog() async {
    if (_currentRoom!.hostId != _roomService.auth.currentUser?.uid) return;
    
    // Create local copies for editing
    int playerCount = _currentRoom!.gameSettings.playerCount;
    int spyCount = _currentRoom!.gameSettings.spyCount;
    int minutes = _currentRoom!.gameSettings.minutes;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: Text(
            LanguageService().isArabic ? 'تعديل إعدادات اللعبة' : 'Edit Game Settings',
            style: AppTheme.textTheme.headlineMedium,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Player count
                _buildEditableSettingRow(
                  icon: '👥',
                  label: LanguageService().isArabic ? 'عدد اللاعبين' : 'Players',
                  value: playerCount.toString(),
                  onDecrease: () {
                    if (playerCount > 3) {
                      setDialogState(() {
                        playerCount--;
                        if (spyCount >= playerCount) {
                          spyCount = playerCount - 1;
                        }
                      });
                    }
                  },
                  onIncrease: () {
                    if (playerCount < 10) {
                      setDialogState(() => playerCount++);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Spy count
                _buildEditableSettingRow(
                  icon: '🥷',
                  label: LanguageService().isArabic ? 'عدد الجواسيس' : 'Spies',
                  value: spyCount.toString(),
                  onDecrease: () {
                    if (spyCount > 1) {
                      setDialogState(() => spyCount--);
                    }
                  },
                  onIncrease: () {
                    if (spyCount < playerCount - 1) {
                      setDialogState(() => spyCount++);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Minutes
                _buildEditableSettingRow(
                  icon: '⏱️',
                  label: LanguageService().isArabic ? 'الوقت (دقائق)' : 'Time (minutes)',
                  value: minutes.toString(),
                  onDecrease: () {
                    if (minutes > 1) {
                      setDialogState(() => minutes--);
                    }
                  },
                  onIncrease: () {
                    if (minutes < 15) {
                      setDialogState(() => minutes++);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  LanguageService().isArabic 
                    ? 'ملاحظة: لا يمكن تغيير الفئة بعد إنشاء الغرفة'
                    : 'Note: Category cannot be changed after room creation',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                LanguageService().isArabic ? 'إلغاء' : 'Cancel',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Update room settings
                final updatedSettings = _currentRoom!.gameSettings.copyWith(
                  playerCount: playerCount,
                  spyCount: spyCount,
                  minutes: minutes,
                );
                
                try {
                  await FirebaseFirestore.instance
                      .collection('gameRooms')
                      .doc(widget.roomId)
                      .update({
                    'gameSettings': updatedSettings.toMap(),
                    'maxPlayers': playerCount,
                  });
                  
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  print('Error updating settings: $e');
                }
              },
              child: Text(
                LanguageService().isArabic ? 'حفظ' : 'Save',
                style: TextStyle(color: AppTheme.accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEditableSettingRow({
    required String icon,
    required String label,
    required String value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTheme.textTheme.bodyMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: AppTheme.accentColor,
          onPressed: onDecrease,
        ),
        Container(
          width: 40,
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accentColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              value,
              style: AppTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppTheme.accentColor,
          onPressed: onIncrease,
        ),
      ],
    );
  }
}