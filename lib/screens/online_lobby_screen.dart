// lib/screens/online_lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/widgets/background_container.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  // We'll use a stream to listen for the user's authentication state
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اللعب عبر الإنترنت'),
          centerTitle: true,
        ),
        body: StreamBuilder<User?>(
          stream: _auth.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              );
            }
            // If the user is logged in
            if (snapshot.hasData) {
              return _buildLoggedInContent(snapshot.data!);
            }
            // If the user is not logged in, show the sign-in screen
            return _buildSignInScreen();
          },
        ),
      ),
    );
  }

  Widget _buildSignInScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('تسجيل الدخول', style: AppTheme.textTheme.headlineMedium),
          const SizedBox(height: 20),
          // We'll add a sign-in button here for now.
          // Later, this will be a full-fledged sign-in UI.
          CoolButton(
            text: 'تسجيل الدخول كضيف',
            onPressed: () async {
              try {
                await _auth.signInAnonymously();
              } catch (e) {
                // Handle sign-in errors
                debugPrint('Error signing in anonymously: $e');
              }
            },
            icon: Icons.person_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInContent(User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('أهلاً بك، ${user.isAnonymous ? 'ضيف' : user.displayName ?? 'مستخدم'}!',
              style: AppTheme.textTheme.headlineMedium),
          const SizedBox(height: 40),
          CoolButton(
            text: 'إنشاء غرفة',
            icon: Icons.create_new_folder_rounded,
            onPressed: () {
              // TODO: Navigate to a new screen for creating a room
            },
          ),
          const SizedBox(height: 20),
          CoolButton(
            text: 'الانضمام لغرفة',
            icon: Icons.join_full_rounded,
            onPressed: () {
              // TODO: Show a dialog or navigate to a screen to enter a room ID
            },
          ),
          const SizedBox(height: 20),
          CoolButton(
            text: 'قائمة الأصدقاء',
            icon: Icons.group_rounded,
            onPressed: () {
              // TODO: Navigate to the friends list screen
            },
          ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () async {
              await _auth.signOut();
            },
            child: Text(
              'تسجيل الخروج',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}