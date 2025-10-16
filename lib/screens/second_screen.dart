import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/role_reveal_screen.dart';
import 'package:min_elgasos_game/screens/game_timer_screen.dart';
import 'package:min_elgasos_game/slide_transition.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  Map<String, List<String>> categories = {};
  List<String> categoryNames = [];
  String? _selectedCategory;

  int players = 3;
  int spies = 1;
  int minutes = 5;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  final String _adUnitId = 'ca-app-pub-3611835750308121/1315161028';

  List<bool> _spyList = [];
  String _chosenItem = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    final AnchoredAdaptiveBannerAdSize? size =
    await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.of(context).size.width.truncate());

    if (size == null) {
      debugPrint('Unable to get ad size.');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    )..load();
  }

  Future<void> _loadCategories() async {
    final raw = await rootBundle.loadString('assets/data/categories.json');
    final Map<String, dynamic> jsonMap = json.decode(raw);
    categories = jsonMap.map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
    );
    categoryNames = categories.keys.toList();
    _selectedCategory = categoryNames.first;
    setState(() {});
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      players = prefs.getInt('players') ?? 3;
      spies = prefs.getInt('spies') ?? 1;
      minutes = prefs.getInt('minutes') ?? 5;
      final savedCategory = prefs.getString('selectedCategory');
      if (savedCategory != null && categories.containsKey(savedCategory)) {
        _selectedCategory = savedCategory;
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('players', players);
    await prefs.setInt('spies', spies);
    await prefs.setInt('minutes', minutes);
    if (_selectedCategory != null) {
      await prefs.setString('selectedCategory', _selectedCategory!);
    }
  }

  void _updatePlayerCount(int change) {
    setState(() {
      players = max(3, players + change);
      if (spies >= players) {
        spies = players - 1;
      }
    });
    _savePreferences();
  }

  void _updateSpyCount(int change) {
    setState(() {
      spies = max(1, min(players - 1, spies + change));
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = LanguageService.of(context);
    final isRtl = languageService.isRtl;
    
    if (_selectedCategory == null) {
      return const BackgroundContainer(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );
    }

    return BackgroundContainer(
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          bottom: false,
          child: Column(
              children: [
              if (_isBannerLoaded && _bannerAd != null)
                Container(
                  color: Colors.black,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      label: Text(l10n.back),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondaryColor,
                      ),
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Image.asset('assets/images/vector.png', height: 120),
                      const SizedBox(height: 20),
                      _buildSection(
                        emoji: '👥',
                        label: l10n.howManyPlayers,
                        value: players,
                        onAdd: () => _updatePlayerCount(1),
                        onRemove: () => _updatePlayerCount(-1),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        emoji: '🥷',
                        label: l10n.howManySpies,
                        value: spies,
                        onAdd: () => _updateSpyCount(1),
                        onRemove: () => _updateSpyCount(-1),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        emoji: '⏱️',
                        label: l10n.howManyMinutes,
                        value: minutes,
                        onAdd: () {
                          setState(() => minutes++);
                          _savePreferences();
                        },
                        onRemove: () {
                          if (minutes > 1) {
                            setState(() => minutes--);
                            _savePreferences();
                          }
                        },
                      ),
                      const SizedBox(height: 30),
                      _buildCategorySelector(l10n),
                      const SizedBox(height: 30),
                      CoolButton(
                        icon: Icons.play_circle_fill_rounded,
                        text: l10n.startPlaying,
                        onPressed: _startGame,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame() {
    _spyList = List<bool>.generate(players, (i) => i < spies)..shuffle();
    final items = categories[_selectedCategory]!..shuffle();
    _chosenItem = items.first;

    int currentIndex = 0;
    void showNextPlayer() {
      final isSpy = _spyList[currentIndex];
      Navigator.push(
        context,
        createSlideRoute(
          RoleRevealScreen(
            currentPlayer: currentIndex + 1,
            isSpy: isSpy,
            category: _selectedCategory!,
            location: isSpy ? '؟؟؟' : _chosenItem,
            totalPlayers: players,
            onNext: () {
              Navigator.pop(context);
              currentIndex++;
              if (currentIndex < players) {
                showNextPlayer();
              } else {
                Navigator.pushReplacement(
                  context,
                  createSlideRoute(
                    GameTimerScreen(
                      minutes: minutes,
                      spyList: _spyList,
                      chosenItem: _chosenItem,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
    }
    showNextPlayer();
  }

  Widget _buildCategorySelector(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(l10n.chooseGameType, style: AppTheme.textTheme.bodyLarge),
        const SizedBox(width: 12),
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
              style: AppTheme.textTheme.bodyLarge,
              iconEnabledColor: AppTheme.accentColor,
              items: categoryNames.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) {
                  setState(() => _selectedCategory = newVal);
                  _savePreferences();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String emoji,
    required String label,
    required int value,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.textTheme.headlineMedium?.copyWith(fontSize: 22)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: onRemove, icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 30)),
              const SizedBox(width: 8),
              Text(value.toString(), style: AppTheme.textTheme.displayLarge?.copyWith(fontSize: 28)),
              const SizedBox(width: 8),
              IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 30)),
            ],
          ),
        ),
      ],
    );
  }
}
