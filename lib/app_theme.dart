import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Centralized class for application colors and styles
class AppTheme {
  // --- COLORS ---
  static const Color primaryColor = Color(0xFF6A1B9A);
  static const Color accentColor = Color(0xFF00E5FF);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Colors.white70;

  // --- GRADIENTS ---

  // OPTION 1: The original semi-transparent gradient overlay.
  static const LinearGradient _gradientWithOverlay = LinearGradient(
    colors: [Color(0xE6121212), Color(0xE62C1D3C)], // ~90% opacity
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // OPTION 2: A fully transparent gradient to show the BG image clearly.
  static const LinearGradient _gradientTransparent = LinearGradient(
    colors: [Colors.transparent, Colors.transparent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // =======================================================================
  // HOW TO SWITCH THE BACKGROUND STYLE
  // =======================================================================
  // - To SHOW the dark gradient overlay, use: _gradientWithOverlay
  // - To HIDE the gradient and show the full background, use: _gradientTransparent
  //
  // Just change the value on the line below.
  //
  static const LinearGradient backgroundGradient = _gradientTransparent; // <-- CHANGE THIS LINE
  // =======================================================================


  static const LinearGradient buttonGradient = LinearGradient(
    colors: [accentColor, Color(0xFF18C4DE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- TEXT STYLES ---
  static final TextTheme textTheme = GoogleFonts.cairoTextTheme(
    const TextTheme(
      displayLarge: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: textPrimaryColor),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimaryColor),
      bodyLarge: TextStyle(fontSize: 18, color: textPrimaryColor, height: 1.5),
      bodyMedium: TextStyle(fontSize: 16, color: textSecondaryColor, height: 1.5),
      labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    ),
  );

  // --- GLOBAL THEME DATA ---
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        background: Colors.transparent,
        surface: surfaceColor,
        onPrimary: textPrimaryColor,
        onSecondary: Colors.black,
        onBackground: textPrimaryColor,
        onSurface: textPrimaryColor,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: accentColor),
        titleTextStyle: textTheme.headlineMedium?.copyWith(fontSize: 22),
      ),
      iconTheme: const IconThemeData(color: accentColor, size: 28),
    );
  }
}

// --- CUSTOM WIDGETS ---
class CoolButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const CoolButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.buttonGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.black),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text, 
                style: AppTheme.textTheme.labelLarge,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
