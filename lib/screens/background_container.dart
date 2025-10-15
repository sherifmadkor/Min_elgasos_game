import 'package:flutter/material.dart';
import 'package:min_elgasos_game/app_theme.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback color
      body: Stack(
        children: [
          // Layer 1: The background image
          Image.asset(
            'assets/images/BG.png',
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          // Layer 2: The semi-transparent gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          // Layer 3: The actual screen content
          child,
        ],
      ),
    );
  }
}
