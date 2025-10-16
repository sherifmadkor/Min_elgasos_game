// lib/screens/online_lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../widgets/rank_emblem_png.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import 'room_browser_screen.dart';
import 'create_room_screen.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final languageService = LanguageService();
    
    return BackgroundContainer(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.playOnline),
          centerTitle: true,
          leading: BackButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
            ),
          ],
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
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.login, style: AppTheme.textTheme.headlineMedium),
          const SizedBox(height: 20),
          // We'll add a sign-in button here for now.
          // Later, this will be a full-fledged sign-in UI.
          CoolButton(
            text: l10n.loginAsGuest,
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
    final l10n = AppLocalizations.of(context)!;
    final languageService = LanguageService();
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String displayName = user.displayName ?? (languageService.isArabic ? 'مستخدم' : 'User');
        String avatarEmoji = '🕵️‍♂️';
        
        int xp = 0;
        String rankName = 'Iron';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            displayName = data['displayName'] ?? displayName;
            avatarEmoji = data['avatarEmoji'] ?? avatarEmoji;
            xp = data['xp'] ?? 0;
            rankName = data['rank'] ?? 'Iron';
          }
        }
        
        return Directionality(
          textDirection: languageService.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Avatar and Profile Button
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accentColor,
                          width: 2,
                        ),
                        color: AppTheme.surfaceColor.withOpacity(0.5),
                      ),
                      child: Center(
                        child: Text(
                          avatarEmoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: AppTheme.textTheme.headlineMedium,
                        ),
                        const SizedBox(width: 8),
                        MiniRankEmblemPNG(
                          rankName: rankName,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit,
                          size: 18,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
          CoolButton(
            text: l10n.createRoom,
            icon: Icons.add_box_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateRoomScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          CoolButton(
            text: LanguageService().isArabic ? 'الانضمام لغرفة' : 'Join Room',
            icon: Icons.explore_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RoomBrowserScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          CoolButton(
            text: LanguageService().isArabic ? 'انضمام سريع' : 'Quick Join',
            icon: Icons.flash_on_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RoomBrowserScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          CoolButton(
            text: l10n.profile,
            icon: Icons.person_rounded,
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            child: Text(
              l10n.logout,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.redAccent,
              ),
            ),
          ),
              ],
            ),
          ),
        );
      },
    );
  }
}