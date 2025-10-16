import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:min_elgasos_game/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  final String _adUnitId = 'ca-app-pub-3611835750308121/1315161028';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = LanguageService.of(context);
    final isRtl = languageService.isRtl;
    
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.gameRules),
          centerTitle: true,
        ),
        body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      _buildInstructionSection(l10n.gameDescription),
                      const SizedBox(height: 24),
                      _buildHeading(l10n.spyObjective, AppTheme.accentColor),
                      const SizedBox(height: 8),
                      _buildInstructionSection(l10n.spyObjectiveDetails),
                      const SizedBox(height: 24),
                      _buildHeading(l10n.detectiveObjective, Colors.lightBlueAccent),
                      const SizedBox(height: 8),
                      _buildInstructionSection(l10n.detectiveObjectiveDetails),
                    ],
                  ),
                ),
              ),
              if (_isBannerLoaded && _bannerAd != null)
                SizedBox(
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

  Widget _buildHeading(String text, Color color) {
    final isRtl = LanguageService.of(context).isRtl;
    return Text(
      text,
      style: AppTheme.textTheme.headlineMedium?.copyWith(color: color, fontSize: 22),
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
    );
  }

  Widget _buildInstructionSection(String text) {
    final isRtl = LanguageService.of(context).isRtl;
    return Text(
      text,
      style: AppTheme.textTheme.bodyLarge,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
    );
  }
}
