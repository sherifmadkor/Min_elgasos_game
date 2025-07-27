import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/privacy_policy_screen.dart';
import 'package:min_elgasos_game/widgets/background_container.dart';
import '../slide_transition.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  final String _adUnitId = 'ca-app-pub-3611835750308121/1315161028';

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

  @override
  Widget build(BuildContext context) {
    // Wrapped with BackgroundContainer
    return BackgroundContainer(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60.0, bottom: 40.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                    CoolButton(
                      text: 'ابدأ اللعب',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Navigator.pushNamed(context, '/second'),
                    ),
                    const SizedBox(height: 20),
                    CoolButton(
                      text: 'تعليمات اللعبة',
                      icon: Icons.rule_rounded,
                      onPressed: () => Navigator.pushNamed(context, '/instructions'),
                    ),
                    const SizedBox(height: 40),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          createSlideRoute(const PrivacyPolicyScreen()),
                        );
                      },
                      child: Text(
                        'سياسة الخصوصية',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'اللعبه دي مفيهاش اونلاين عشان الغرض منها التجمع الجميل دا❤️',
                        textAlign: TextAlign.center,
                        style: AppTheme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (_isBannerLoaded && _bannerAd != null)
              Container(
                color: Colors.black,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}
