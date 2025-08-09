// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/slide_transition.dart';
import 'package:min_elgasos_game/screens/first_screen.dart'; // The existing local game screen
import 'package:min_elgasos_game/screens/online_lobby_screen.dart';
import 'package:min_elgasos_game/widgets/background_container.dart'; // A new screen we will create

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 50),
            CoolButton(
              text: 'لعبة محلية',
              icon: Icons.people_rounded,
              onPressed: () => Navigator.push(context, createSlideRoute(const FirstScreen())),
            ),
            const SizedBox(height: 20),
            CoolButton(
              text: 'لعبة عبر الإنترنت',
              icon: Icons.wifi_rounded,
              onPressed: () => Navigator.push(context, createSlideRoute(const OnlineLobbyScreen())),
            ),
          ],
        ),
      ),
    );
  }
}