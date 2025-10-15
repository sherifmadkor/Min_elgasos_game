import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../l10n/app_localizations.dart';
import '../models/room_models.dart';
import '../services/realtime_room_service.dart';
import '../services/language_service.dart';
import 'room_lobby_screen.dart';
import '../services/validation_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _roomNameController = TextEditingController();
  final _roomService = RealtimeRoomService();
  
  RoomType _roomType = RoomType.public;
  bool _isLoading = false;
  
  // Game settings
  int _playerCount = 6;
  int _spyCount = 2;
  int _minutes = 5;
  String? _selectedCategory;
  
  Map<String, List<String>> _categories = {};
  List<String> _categoryNames = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _roomNameController.text = _generateDefaultRoomName();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final raw = await rootBundle.loadString('assets/data/categories.json');
      final Map<String, dynamic> jsonMap = json.decode(raw);
      _categories = jsonMap.map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );
      _categoryNames = _categories.keys.toList();
      _selectedCategory = _categoryNames.first;
      setState(() {});
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  String _generateDefaultRoomName() {
    final adjectives = ['Epic', 'Secret', 'Mystery', 'Hidden', 'Shadow', 'Elite', 'Cool', 'Fun'];
    final nouns = ['Spies', 'Agents', 'Detectives', 'Game', 'Hunt', 'Mission', 'Quest'];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    final adjective = adjectives[random % adjectives.length];
    final noun = nouns[(random ~/ adjectives.length) % nouns.length];
    
    return '$adjective $noun';
  }

  Future<void> _createRoom() async {
    final roomName = _roomNameController.text.trim();
    
    // Input validation
    if (!ValidationService.isValidRoomName(roomName)) {
      _showSnackBar(
        LanguageService().isArabic 
          ? 'اسم الغرفة غير صالح. يرجى استخدام الأحرف والأرقام فقط (2-50 حرف)'
          : 'Invalid room name. Please use only letters and numbers (2-50 characters)',
        isError: true,
      );
      return;
    }
    
    if (_selectedCategory == null) {
      _showSnackBar(
        LanguageService().isArabic ? 'يرجى اختيار فئة' : 'Please select a category',
        isError: true,
      );
      return;
    }

    // Validate game settings
    final errors = ValidationService.validateGameSettings(
      playerCount: _playerCount,
      spyCount: _spyCount,
      minutes: _minutes,
      category: _selectedCategory!,
    );
    
    if (errors != null) {
      _showSnackBar(errors.values.first, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check rate limiting
      final validationService = ValidationService();
      final currentUser = _roomService.auth.currentUser;
      
      if (currentUser != null) {
        final canCreate = await validationService.canCreateRoom(currentUser.uid);
        if (!canCreate) {
          _showSnackBar(
            LanguageService().isArabic 
              ? 'يرجى الانتظار 30 ثانية قبل إنشاء غرفة جديدة'
              : 'Please wait 30 seconds before creating another room',
            isError: true,
          );
          return;
        }
      }
      
      final gameSettings = GameSettings(
        playerCount: _playerCount,
        spyCount: _spyCount,
        minutes: _minutes,
        category: _selectedCategory!,
      );

      final room = await _roomService.createRoom(
        roomName: ValidationService.sanitizeInput(roomName),
        type: _roomType,
        gameSettings: gameSettings,
        maxPlayers: _playerCount,
      );

      if (room != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoomLobbyScreen(roomId: room.id),
          ),
        );
      } else {
        _showSnackBar(
          LanguageService().isArabic 
            ? 'فشل إنشاء الغرفة. تأكد من اتصالك بالإنترنت'
            : 'Failed to create room. Check your internet connection',
          isError: true,
        );
      }
    } catch (e) {
      print('Error creating room: $e');
      _showSnackBar(
        LanguageService().isArabic 
          ? 'حدث خطأ. يرجى المحاولة مرة أخرى'
          : 'An error occurred. Please try again',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
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
            title: Text(AppLocalizations.of(context)!.createRoom),
            centerTitle: true,
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentColor),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRoomNameSection(l10n),
                      const SizedBox(height: 24),
                      _buildRoomTypeSection(l10n),
                      const SizedBox(height: 24),
                      _buildGameSettingsSection(l10n),
                      const SizedBox(height: 32),
                      _buildCreateButton(l10n),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRoomNameSection(AppLocalizations l10n) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageService().isArabic ? 'اسم الغرفة' : 'Room Name',
              style: AppTheme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomNameController,
              decoration: InputDecoration(
                hintText: 'Enter room name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accentColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
                ),
              ),
              style: AppTheme.textTheme.bodyLarge,
              maxLength: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _roomNameController.text = _generateDefaultRoomName(),
                  child: Text(LanguageService().isArabic ? 'توليد عشوائي' : 'Generate Random'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTypeSection(AppLocalizations l10n) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageService().isArabic ? 'نوع الغرفة' : 'Room Type',
              style: AppTheme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRoomTypeOption(
                    type: RoomType.public,
                    icon: Icons.public,
                    title: LanguageService().isArabic ? 'غرفة عامة' : 'Public Room',
                    subtitle: LanguageService().isArabic ? 'يمكن لأي شخص الانضمام' : 'Anyone can join',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoomTypeOption(
                    type: RoomType.private,
                    icon: Icons.lock,
                    title: LanguageService().isArabic ? 'غرفة خاصة' : 'Private Room',
                    subtitle: LanguageService().isArabic ? 'يتطلب رمز من 4 أرقام' : '4-digit code required',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTypeOption({
    required RoomType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _roomType == type;
    
    return InkWell(
      onTap: () => setState(() => _roomType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? AppTheme.accentColor.withOpacity(0.1) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.accentColor : AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.textTheme.titleMedium?.copyWith(
                color: isSelected ? AppTheme.accentColor : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSettingsSection(AppLocalizations l10n) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageService().isArabic ? 'إعدادات اللعبة' : 'Game Settings',
              style: AppTheme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              emoji: '👥',
              label: l10n.howManyPlayers,
              value: _playerCount,
              onAdd: () => setState(() {
                if (_playerCount < 10) _playerCount++;
              }),
              onRemove: () => setState(() {
                if (_playerCount > 3) {
                  _playerCount--;
                  if (_spyCount >= _playerCount) _spyCount = _playerCount - 1;
                }
              }),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              emoji: '🥷',
              label: l10n.howManySpies,
              value: _spyCount,
              onAdd: () => setState(() {
                if (_spyCount < _playerCount - 1) _spyCount++;
              }),
              onRemove: () => setState(() {
                if (_spyCount > 1) _spyCount--;
              }),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              emoji: '⏱️',
              label: l10n.howManyMinutes,
              value: _minutes,
              onAdd: () => setState(() {
                if (_minutes < 15) _minutes++;
              }),
              onRemove: () => setState(() {
                if (_minutes > 1) _minutes--;
              }),
            ),
            const SizedBox(height: 16),
            _buildCategorySelector(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String emoji,
    required String label,
    required int value,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTheme.textTheme.bodyLarge),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.accentColor,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toString(),
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.accentColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector(AppLocalizations l10n) {
    return Row(
      children: [
        Text('🎲', style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(l10n.chooseGameType, style: AppTheme.textTheme.bodyLarge),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentColor, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: AppTheme.surfaceColor,
              value: _selectedCategory,
              items: _categoryNames.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton(AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: _createRoom,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _roomType == RoomType.public ? Icons.public : Icons.lock,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            _roomType == RoomType.public 
              ? '${l10n.createRoom} - ${LanguageService().isArabic ? 'عامة' : 'Public'}'
              : '${l10n.createRoom} - ${LanguageService().isArabic ? 'خاصة' : 'Private'}',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}