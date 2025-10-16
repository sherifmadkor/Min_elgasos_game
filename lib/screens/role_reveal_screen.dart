import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/instructions_screen.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../slide_transition.dart';
import '../l10n/app_localizations.dart';

class RoleRevealScreen extends StatefulWidget {
  final int currentPlayer;
  final bool isSpy;
  final String category;
  final String location;
  final int totalPlayers;
  final VoidCallback onNext;

  const RoleRevealScreen({
    super.key,
    required this.currentPlayer,
    required this.isSpy,
    required this.category,
    required this.location,
    required this.totalPlayers,
    required this.onNext,
  });

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  bool showRole = false;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final String _adUnitId = 'ca-app-pub-3611835750308121/1315161028';

  String get infoText {
    if (widget.isSpy) {
      return 'حاول تعرف ${widget.category} من غير ما يشكّوا فيك!';
    } else {
      switch (widget.category) {
        case 'أكلات':
          return '🍽️ الأكلة هي: ${widget.location}';
        case 'أماكن':
          return '📍 المكان هو: ${widget.location}';
        case 'لاعيبة كورة':
          return '⚽ اللاعب هو: ${widget.location}';
        default:
          return widget.location;
      }
    }
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
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    )..load();
  }

  void _confirmExit() {
    final l10n = AppLocalizations.of(context)!;
    _showConfirmationDialog(
      title: l10n.exitGame,
      content: l10n.areYouSureEndGame,
      onConfirm: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
    );
  }

  void _confirmRestart() {
    final l10n = AppLocalizations.of(context)!;
    _showConfirmationDialog(
      title: l10n.restartRound,
      content: l10n.areYouSureRestartRound,
      onConfirm: () => Navigator.pushNamedAndRemoveUntil(context, '/second', (route) => false),
    );
  }

  void _showConfirmationDialog({required String title, required String content, required VoidCallback onConfirm}) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(title, style: AppTheme.textTheme.headlineMedium?.copyWith(fontSize: 22)),
        content: Text(content, style: AppTheme.textTheme.bodyLarge),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.no, style: TextStyle(color: AppTheme.textSecondaryColor))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text(l10n.yes, style: TextStyle(color: AppTheme.accentColor))),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    _confirmExit();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BackgroundContainer(
        child: Scaffold(
          appBar: AppBar(
            // Force the AppBar to be Left-to-Right to fix button placement
            leading: Directionality(
              textDirection: TextDirection.ltr,
              child: IconButton(
                icon: const Icon(Icons.home_rounded),
                onPressed: _confirmExit,
                tooltip: AppLocalizations.of(context)!.exitToHome,
              ),
            ),
            actions: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded),
                      onPressed: () => Navigator.push(context, createSlideRoute(const InstructionsScreen())),
                      tooltip: AppLocalizations.of(context)!.gameRules,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _confirmRestart,
                      tooltip: AppLocalizations.of(context)!.restartRound,
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.surfaceColor,
                            child: const Icon(Icons.person_outline_rounded, size: 60, color: AppTheme.accentColor),
                          ),
                          const SizedBox(height: 20),
                          Text('${AppLocalizations.of(context)!.playerNumber} ${widget.currentPlayer}', style: AppTheme.textTheme.headlineMedium),
                          const SizedBox(height: 40),
                          if (!showRole)
                            CoolButton(
                              onPressed: () => setState(() => showRole = true),
                              text: AppLocalizations.of(context)!.tapToKnowRole,
                              icon: Icons.touch_app_rounded,
                            )
                          else
                            _buildRoleInfo(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isAdLoaded && _bannerAd != null)
                  Container(
                    color: Colors.black,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleInfo() {
    final l10n = AppLocalizations.of(context)!;
    final roleLabel = widget.isSpy ? l10n.youAreSpy : l10n.youAreDetective;
    final roleIcon = widget.isSpy
        ? ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.transparent],
          stops: [0.7, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Image.asset(
        'assets/images/spy_icon.png',
        height: 120,
      ),
    )
        : const Text('🕵️', style: TextStyle(fontSize: 70));

    return Column(
      children: [
        roleIcon,
        const SizedBox(height: 20),
        Text(roleLabel, style: AppTheme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          infoText,
          textAlign: TextAlign.center,
          style: AppTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 40),
        CoolButton(
          onPressed: widget.onNext,
          text: widget.currentPlayer == widget.totalPlayers ? AppLocalizations.of(context)!.startGame : AppLocalizations.of(context)!.nextPlayer,
          icon: Icons.arrow_forward_ios_rounded,
        ),
      ],
    );
  }
}
