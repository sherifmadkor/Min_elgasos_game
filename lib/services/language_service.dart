import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('ar'); // Default to Arabic
  
  Locale get currentLocale => _currentLocale;
  
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isRtl => _currentLocale.languageCode == 'ar';
  
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();
  
  static LanguageService of(BuildContext context) {
    return _instance;
  }
  
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);
    
    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
    }
  }
  
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      notifyListeners();
    }
  }
  
  Future<void> toggleLanguage() async {
    final newLanguage = isArabic ? 'en' : 'ar';
    await changeLanguage(newLanguage);
  }
}