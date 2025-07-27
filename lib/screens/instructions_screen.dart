import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:min_elgasos_game/app_theme.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('قواعد اللعبة'),
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildInstructionSection(
                        '🔸 لعبة اجتماعية لـ 3 لاعبين أو أكثر 🔥\n'
                            '🔸 الكل يعرف المكان أو الأكلة لاعب الكوره الخ… ماعدا الجاسوس! 👀\n',
                      ),
                      const SizedBox(height: 24),
                      _buildHeading('🎯 هدف الجاسوس:', AppTheme.accentColor),
                      const SizedBox(height: 8),
                      _buildInstructionSection(
                        '- يتظاهر إنه عارف وميتكشفش.\n'
                            '- يسمع الأسئلة والإجابات.\n'
                            '- يحاول يعرف المكان أو الأكلة.\n'
                            '- لكن ❗ ممنوع يقول المكان أو الأكلة إلا بعد انتهاء اللفة.\n'
                            '- لو قالها صح → الجواسيس يكسبوا.\n'
                            '- لو غلط:\n'
                            '  ❌ بيتخصم منه نقطة.\n'
                            '  ✅ وكل لاعب تاني بياخد نقطة.',
                      ),
                      const SizedBox(height: 24),
                      _buildHeading('🧠 هدف باقي اللاعبين:', Colors.lightBlueAccent),
                      const SizedBox(height: 8),
                      _buildInstructionSection(
                        '- يسألوا بعض أسئلة بنعم أو لا فقط.\n'
                            '- يحاولوا يكتشفوا مين الجاسوس من إجاباته.\n'
                            '- بعد انتهاء الجولة، يتناقشوا ويتفقوا ويختاروا مين الجاسوس لو متفقوش اللي قال صح ليه نقطه مع الجاسوس.',
                      ),
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
    );
  }

  Widget _buildHeading(String text, Color color) {
    return Text(
      text,
      style: AppTheme.textTheme.headlineMedium?.copyWith(color: color, fontSize: 22),
      textAlign: TextAlign.right,
    );
  }

  Widget _buildInstructionSection(String text) {
    return Text(
      text,
      style: AppTheme.textTheme.bodyLarge,
      textAlign: TextAlign.right,
    );
  }
}
