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
                      text: 'لعب محلي',
                      icon: Icons.people_rounded,
                      onPressed: () => Navigator.pushNamed(context, '/second'),
                    ),
                    const SizedBox(height: 20),
                    // New button for online play
                    CoolButton(
                      text: 'لعب أونلاين',
                      icon: Icons.wifi_rounded,
                      onPressed: () => _showOnlineTermsDialog(context),
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
                        'اللعبه دي بقت اونلاين عشان نفضل مع بعض طول الوقت❤️',
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

  void _showOnlineTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text(
              'أحكام وشروط اللعب أونلاين',
              style: AppTheme.textTheme.headlineMedium?.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'أهلاً بك في مجتمع "مين الجاسوس" أونلاين! قبل الانضمام، يرجى الموافقة على الشروط التالية:',
                  style: AppTheme.textTheme.bodyLarge,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 10),
                Text(
                  '1. إنشاء الحساب: ستحتاج إلى إنشاء حساب لحفظ بياناتك الخاصة باللعبة.',
                  style: AppTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  '2. الخصوصية: بياناتك لا تُستخدم إلا في نطاق اللعبة فقط. اللاعبون الآخرون لا يمكنهم رؤية إلا اسمك الذي تختاره بنفسك.',
                  style: AppTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  '3. آداب السلوك: اللعبة تتضمن خاصية الدردشة. يجب الالتزام بالآداب والأخلاق العامة في كل الأوقات. أي إساءة قد تؤدي إلى حظر حسابك بشكل نهائي من اللعب.',
                  style: AppTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'بالموافقة، أنت توافق على هذه الشروط.',
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.accentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.textSecondaryColor),
              ),
            ),
            CoolButton(
              text: 'موافق',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/create_account');
              },
            ),
          ],
        );
      },
    );
  }
}
