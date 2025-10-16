import 'package:flutter/material.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../l10n/app_localizations.dart';
import '../models/room_models.dart';
import '../services/realtime_room_service.dart';
import '../services/language_service.dart';
import 'create_room_screen.dart';
import 'room_lobby_screen.dart';

class RoomBrowserScreen extends StatefulWidget {
  const RoomBrowserScreen({super.key});

  @override
  State<RoomBrowserScreen> createState() => _RoomBrowserScreenState();
}

class _RoomBrowserScreenState extends State<RoomBrowserScreen>
    with TickerProviderStateMixin {
  final _roomService = RealtimeRoomService();
  final _roomCodeController = TextEditingController();
  late TabController _tabController;
  
  bool _isJoiningByCode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _tabController.dispose();
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
            title: Text(LanguageService().isArabic ? 'الانضمام للعبة' : 'Join Game'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateRoomScreen(),
                  ),
                ),
                tooltip: l10n.createRoom,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accentColor,
              labelColor: AppTheme.accentColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              tabs: [
                Tab(
                  icon: const Icon(Icons.public),
                  text: LanguageService().isArabic ? 'الغرف العامة' : 'Public Rooms',
                ),
                Tab(
                  icon: const Icon(Icons.lock),
                  text: LanguageService().isArabic ? 'غرفة خاصة' : 'Private Room',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPublicRoomsTab(),
              _buildPrivateRoomTab(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateRoomScreen(),
              ),
            ),
            backgroundColor: AppTheme.accentColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              l10n.createRoom,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublicRoomsTab() {
    return StreamBuilder<List<GameRoom>>(
      stream: _roomService.getPublicRooms(),
      builder: (context, snapshot) {
        print('Room browser - Connection state: ${snapshot.connectionState}');
        print('Room browser - Has data: ${snapshot.hasData}');
        print('Room browser - Data length: ${snapshot.data?.length ?? 0}');

        // Only show loading on first load (waiting + no data yet)
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.accentColor),
                SizedBox(height: 16),
                Text('Loading rooms...'),
              ],
            ),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading rooms: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Trigger rebuild
                    if (mounted) setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.public_off,
            title: LanguageService().isArabic ? 'لا توجد غرف عامة' : 'No Public Rooms',
            subtitle: LanguageService().isArabic ? 'كن أول من ينشئ غرفة عامة!' : 'Be the first to create a public room!',
            actionText: LanguageService().isArabic ? 'إنشاء غرفة عامة' : 'Create Public Room',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateRoomScreen(),
              ),
            ),
          );
        }

        final rooms = snapshot.data!;
        print('Displaying ${rooms.length} rooms in UI');

        return RefreshIndicator(
          color: AppTheme.accentColor,
          onRefresh: () async {
            // Refresh is handled automatically by StreamBuilder
            print('Refreshing rooms...');
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              print('Building card for room: ${room.roomName}');
              return _buildRoomCard(room);
            },
          ),
        );
      },
    );
  }

  Widget _buildPrivateRoomTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            color: AppTheme.surfaceColor,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.lock,
                    size: 64,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LanguageService().isArabic ? 'الانضمام لغرفة خاصة' : 'Join Private Room',
                    style: AppTheme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LanguageService().isArabic ? 'أدخل رمز الغرفة المكون من 4 أرقام للانضمام لغرفة خاصة' : 'Enter the 4-digit room code to join a private room',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _roomCodeController,
                    decoration: InputDecoration(
                      labelText: LanguageService().isArabic ? 'رمز الغرفة' : 'Room Code',
                      hintText: '1234',
                      prefixIcon: const Icon(Icons.pin, color: AppTheme.accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.accentColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
                      ),
                    ),
                    style: AppTheme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onChanged: (value) {
                      if (value.length == 4) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isJoiningByCode ? null : _joinRoomByCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isJoiningByCode
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  LanguageService().isArabic ? 'الانضمام للغرفة' : 'Join Room',
                                  style: AppTheme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(GameRoom room) {
    final playersText = '${room.players.length}/${room.maxPlayers}';
    final isFull = room.players.length >= room.maxPlayers;

    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isFull ? null : () => _joinRoom(room.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.roomName,
                          style: AppTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              room.hostAvatar,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${LanguageService().isArabic ? 'المضيف' : 'Host'}: ${room.hostName}',
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFull ? Colors.red.withOpacity(0.1) : AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFull ? Colors.red : AppTheme.accentColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: isFull ? Colors.red : AppTheme.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              playersText,
                              style: TextStyle(
                                color: isFull ? Colors.red : AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isFull) ...[
                        const SizedBox(height: 4),
                        Text(
                          LanguageService().isArabic ? 'ممتلئة' : 'FULL',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGameInfo(Icons.people, '${room.gameSettings.playerCount} ${LanguageService().isArabic ? 'لاعبين' : 'Players'}'),
                  _buildGameInfo(Icons.person, '${room.gameSettings.spyCount} ${LanguageService().isArabic ? 'جواسيس' : 'Spies'}'),
                  _buildGameInfo(Icons.timer, '${room.gameSettings.minutes} ${LanguageService().isArabic ? 'دقيقة' : 'min'}'),
                  _buildGameInfo(Icons.category, room.gameSettings.category),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${LanguageService().isArabic ? 'تم الإنشاء' : 'Created'} ${_getTimeAgo(room.createdAt)}',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  if (!isFull)
                    ElevatedButton(
                      onPressed: () => _joinRoom(room.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(LanguageService().isArabic ? 'انضمام' : 'Join'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return LanguageService().isArabic ? 'الآن' : 'just now';
    } else if (difference.inMinutes < 60) {
      return LanguageService().isArabic ? 'منذ ${difference.inMinutes} د' : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return LanguageService().isArabic ? 'منذ ${difference.inHours} س' : '${difference.inHours}h ago';
    } else {
      return LanguageService().isArabic ? 'منذ ${difference.inDays} ي' : '${difference.inDays}d ago';
    }
  }

  Future<void> _joinRoom(String roomId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentColor),
      ),
    );
    
    final success = await _roomService.joinRoom(
      roomCode: roomId,
      playerName: 'Player', // TODO: Get actual player name
      avatarId: '🕵️‍♂️',
    );
    
    if (mounted) Navigator.pop(context); // Close loading dialog
    
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomLobbyScreen(roomId: roomId),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService().isArabic 
              ? 'فشل الانضمام للغرفة. قد تكون ممتلئة أو لم تعد متاحة.'
              : 'Failed to join room. It may be full or no longer available.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _joinRoomByCode() async {
    final code = _roomCodeController.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService().isArabic 
              ? 'يرجى إدخال رمز غرفة من 4 أرقام'
              : 'Please enter a 4-digit room code',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isJoiningByCode = true);

    try {
      final success = await _roomService.joinRoom(
        roomCode: code,
        playerName: 'Player', // TODO: Get actual player name
        avatarId: '🕵️‍♂️',
      );
      
      if (success && mounted) {
        _roomCodeController.clear();
        
        // Navigate directly to the room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomLobbyScreen(roomId: code),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageService().isArabic 
                ? 'الغرفة غير موجودة أو لا يمكن الانضمام. تحقق من الرمز وحاول مرة أخرى.'
                : 'Room not found or unable to join. Check the code and try again.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoiningByCode = false);
    }
  }
}