import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:min_elgasos_game/app_theme.dart'; // Import the new theme file
import 'slide_transition.dart';
import 'screens/first_screen.dart';
import 'screens/second_screen.dart';
import 'screens/instructions_screen.dart';
import 'screens/privacy_policy_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mobile Ads on Android/iOS only
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(const MyGameApp());
}

class MyGameApp extends StatelessWidget {
  const MyGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Apply the new global theme
      theme: AppTheme.themeData,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return createSlideRoute(const FirstScreen());
          case '/second':
            return createSlideRoute(const SecondScreen());
          case '/instructions':
            return createSlideRoute(const InstructionsScreen());
          case '/privacy':
            return createSlideRoute(const PrivacyPolicyScreen());
          default:
          // It's good practice to have a fallback route
            return createSlideRoute(const FirstScreen());
        }
      },
    );
  }
}
