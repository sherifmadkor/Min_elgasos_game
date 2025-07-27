import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class DataLoader {
  static Map<String, List<String>> categories = {};

  static Future<void> loadCategories() async {
    final String jsonString =
        await rootBundle.loadString('assets/data/categories.json');

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    categories = jsonMap.map((key, value) =>
        MapEntry(key, List<String>.from(value as List<dynamic>)));
  }

  static List<String> getCategoryItems(String category) {
    return categories[category] ?? [];
  }

  static List<String> getAvailableCategories() {
    return categories.keys.toList();
  }
}
