import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'app_theme.dart';
import 'slide_transition.dart';
import 'services/language_service.dart';
import 'services/realtime_room_service.dart';
import 'screens/login_screen.dart';
import 'screens/online_entry_screen.dart';

// Screens
import 'screens/first_screen.dart';
import 'screens/second_screen.dart';
import 'screens/instructions_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/online_lobby_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/firebase_debug_screen.dart';
import 'screens/rules_reveal_screen.dart';
import 'screens/game_session_screen.dart';
import 'screens/voting_screen.dart';
import 'screens/voting_results_screen.dart';
import 'screens/multiplayer_game_timer_screen.dart';
import 'services/app_lifecycle_service.dart';

void main() async {
  try {
    print('🚀 App starting...');
    WidgetsFlutterBinding.ensureInitialized();
    
    print('🔥 Initializing Firebase...');
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 10));
      print('✅ Firebase initialized successfully');
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        print('✅ Firebase already initialized, continuing...');
      } else {
        print('⚠️ Firebase initialization error: $e');
        throw e;
      }
    }
    
    if (!kIsWeb) {
      print('📱 Initializing Mobile Ads...');
      await MobileAds.instance.initialize();
      print('✅ Mobile Ads initialized');
    }
    
    print('🌐 Loading language settings...');
    await LanguageService().loadSavedLanguage();
    print('✅ Language service loaded');
    
    print('🔄 Initializing app lifecycle service...');
    AppLifecycleService().initialize();
    print('✅ App lifecycle service initialized');
    
    print('🔥 Initializing Realtime Room Service...');
    await RealtimeRoomService().initialize();
    print('✅ Realtime Room Service initialized');
    
    print('✅ App initialization complete, starting UI...');
    runApp(const MyGameApp());
    
    // Clean up old Firebase rooms AFTER app starts (completely non-blocking)
    Future.delayed(const Duration(seconds: 2), () {
      RealtimeRoomService().cleanupOldRooms().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Room cleanup timed out');
        },
      ).catchError((e) {
        print('⚠️ Failed to cleanup old rooms: $e');
      });
    });
    
  } catch (e, stackTrace) {
    print('❌ Fatal error during app initialization: $e');
    print('❌ Stack trace: $stackTrace');
    runApp(const MyGameApp()); // Start app anyway with minimal functionality
  }
}

class MyGameApp extends StatelessWidget {
  const MyGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          locale: LanguageService().currentLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
              return createSlideRoute(const CreateAccountScreen());
            case '/online':
            // Your actual online screen (creation/lobby) goes here
              return createSlideRoute(const OnlineLobbyScreen());
            case '/go_online':
            // <-- NEW: the gate that decides whether to show login/create or jump to /online
              return createSlideRoute(const OnlineEntryScreen());
            case '/login':
            // <-- Allow passing a "next route" via arguments
              return createSlideRoute(LoginScreen.fromRouteSettings(settings));
            case '/profile':
              return createSlideRoute(const ProfileScreen());
            case '/debug':
              return createSlideRoute(const FirebaseDebugScreen());
            case '/rules_reveal':
              final args = settings.arguments as Map<String, dynamic>;
              return createSlideRoute(RulesRevealScreen(
                gameRoom: args['gameRoom'],
                currentUserId: args['currentUserId'],
              ));
            case '/game_session':
              final args = settings.arguments as Map<String, dynamic>;
              return createSlideRoute(GameSessionScreen(
                gameRoom: args['gameRoom'],
                currentUserId: args['currentUserId'],
              ));
            case '/voting':
              final args = settings.arguments as Map<String, dynamic>;
              return createSlideRoute(VotingScreen(
                gameRoom: args['gameRoom'],
                currentUserId: args['currentUserId'],
              ));
            case '/voting_results':
              final args = settings.arguments as Map<String, dynamic>;
              return createSlideRoute(VotingResultsScreen(
                gameRoom: args['gameRoom'],
                currentUserId: args['currentUserId'],
              ));
            case '/multiplayer_game_timer':
              final args = settings.arguments as Map<String, dynamic>;
              return createSlideRoute(MultiplayerGameTimerScreen(
                minutes: args['gameRoom'].gameSettings.minutes,
                spyList: List<bool>.from(args['gameRoom'].spyAssignments ?? []),
                chosenItem: args['gameRoom'].currentWord ?? '',
                gameRoom: args['gameRoom'],
              ));
            default:
              return createSlideRoute(const FirstScreen());
            }
          },
        );
      },
    );
  }
}
