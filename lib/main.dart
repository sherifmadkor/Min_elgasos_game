import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:min_elgasos_game/app_theme.dart'; // Import the new theme file
import 'package:min_elgasos_game/screens/online_lobby_screen.dart';
import 'slide_transition.dart';
import 'screens/first_screen.dart';
import 'screens/second_screen.dart';
import 'screens/instructions_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/create_account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (make sure firebase_options.dart is generated)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          case '/create_account':
          // New route for account creation
            return createSlideRoute(const CreateAccountScreen());
          case '/online':
          // Placeholder for the online lobby
            return createSlideRoute(const OnlineLobbyScreen());
          default:
            return createSlideRoute(const FirstScreen());
        }
      },
    );
  }
}
