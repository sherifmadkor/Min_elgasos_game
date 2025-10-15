import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();
    
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arabic
              GestureDetector(
                onTap: () => languageService.changeLanguage('ar'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: languageService.isArabic 
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'العربية',
                    style: TextStyle(
                      color: languageService.isArabic 
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontWeight: languageService.isArabic 
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              // Divider
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withOpacity(0.3),
              ),
              
              // English
              GestureDetector(
                onTap: () => languageService.changeLanguage('en'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: languageService.isEnglish 
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'English',
                    style: TextStyle(
                      color: languageService.isEnglish 
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontWeight: languageService.isEnglish 
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}