import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:min_elgasos_game/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة الخصوصية'),
          centerTitle: true,
        ),
        body: Container(
          // Applying the new theme background
          decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      '''
❗ سياسة الخصوصية لتطبيق "من الجاسوس"

نحن نهتم بخصوصيتك، ونرغب في أن تفهم كيف نتعامل مع بياناتك:

1. 🔒 لا نقوم بجمع أي بيانات شخصية.
2. 📵 التطبيق يعمل بالكامل بدون إنترنت.
3. 👤 لا نطلب منك تسجيل الدخول أو إدخال أي معلومات.
4. 🚫 لا نستخدم ملفات تعريف الارتباط (Cookies).
5. 🧠 لا يتم تتبع نشاطك داخل التطبيق.

📌 استخدامك للتطبيق يعني موافقتك على هذه السياسة. 
إذا كنت لا توافق، يرجى عدم استخدام التطبيق.

شكرًا لك 🙏
''',
                      // Using the new text theme
                      style: AppTheme.textTheme.bodyMedium,
                      textAlign: TextAlign.right,
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
}
