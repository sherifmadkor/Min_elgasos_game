import 'package:cloud_firestore/cloud_firestore.dart';

class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Room name validation
  static bool isValidRoomName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.length > 50) return false;
    
    // Check for profanity or inappropriate content
    final inappropriate = [
      // Add inappropriate words to filter
      // This is a basic list - you should expand it
      'spam', 'hack', 'cheat',
    ];
    
    final lowerName = name.toLowerCase();
    for (final word in inappropriate) {
      if (lowerName.contains(word)) return false;
    }
    
    // Check for special characters that might cause issues
    final validPattern = RegExp(r'^[a-zA-Z0-9\s\u0600-\u06FF]+$'); // Allows alphanumeric, spaces, and Arabic
    return validPattern.hasMatch(name);
  }

  // User display name validation
  static bool isValidDisplayName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.length < 2 || name.length > 30) return false;
    
    // Similar checks as room name
    return isValidRoomName(name);
  }

  // Room code validation
  static bool isValidRoomCode(String code) {
    if (code.length != 4) return false;
    return RegExp(r'^\d{4}$').hasMatch(code);
  }

  // Message validation for chat
  static bool isValidMessage(String message) {
    if (message.trim().isEmpty) return false;
    if (message.length > 500) return false;
    
    // Check for spam patterns
    if (_isSpam(message)) return false;
    
    return true;
  }

  // Check for spam patterns
  static bool _isSpam(String message) {
    // Check for excessive caps
    final capsCount = message.split('').where((char) => char == char.toUpperCase() && char != char.toLowerCase()).length;
    if (capsCount > message.length * 0.7 && message.length > 5) return true;
    
    // Check for repeated characters
    if (RegExp(r'(.)\1{9,}').hasMatch(message)) return true;
    
    // Check for repeated words
    final words = message.split(' ');
    if (words.length > 3) {
      final uniqueWords = words.toSet();
      if (uniqueWords.length < words.length / 3) return true;
    }
    
    return false;
  }

  // Sanitize input to prevent XSS or injection
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .trim();
  }

  // Rate limiting check for room creation
  Future<bool> canCreateRoom(String userId) async {
    try {
      // Check if user has created a room in the last 30 seconds
      final recentRooms = await _firestore
          .collection('gameRooms')
          .where('hostId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(seconds: 30))))
          .limit(1)
          .get();
      
      if (recentRooms.docs.isNotEmpty) {
        print('Rate limit: User created a room too recently');
        return false;
      }
      
      // Check if user has more than 3 active rooms
      final activeRooms = await _firestore
          .collection('gameRooms')
          .where('hostId', isEqualTo: userId)
          .where('status', whereIn: ['waiting', 'inGame'])
          .get();
      
      if (activeRooms.docs.length >= 3) {
        print('Rate limit: User has too many active rooms');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking rate limit: $e');
      return true; // Allow on error to not block legitimate users
    }
  }

  // Validate game settings
  static Map<String, String>? validateGameSettings({
    required int playerCount,
    required int spyCount,
    required int minutes,
    required String category,
  }) {
    final errors = <String, String>{};
    
    if (playerCount < 3 || playerCount > 10) {
      errors['playerCount'] = 'Player count must be between 3 and 10';
    }
    
    if (spyCount < 1 || spyCount >= playerCount) {
      errors['spyCount'] = 'Spy count must be at least 1 and less than player count';
    }
    
    if (minutes < 1 || minutes > 15) {
      errors['minutes'] = 'Game duration must be between 1 and 15 minutes';
    }
    
    if (category.isEmpty) {
      errors['category'] = 'Please select a category';
    }
    
    return errors.isEmpty ? null : errors;
  }

  // Clean up old/abandoned rooms (call periodically)
  static Future<void> cleanupAbandonedRooms() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      
      // Find rooms that are waiting for more than 2 hours
      final abandonedRooms = await firestore
          .collection('gameRooms')
          .where('status', isEqualTo: 'waiting')
          .where('createdAt', isLessThan: Timestamp.fromDate(twoHoursAgo))
          .get();
      
      final batch = firestore.batch();
      for (final doc in abandonedRooms.docs) {
        batch.delete(doc.reference);
      }
      
      if (abandonedRooms.docs.isNotEmpty) {
        await batch.commit();
        print('Cleaned up ${abandonedRooms.docs.length} abandoned rooms');
      }
    } catch (e) {
      print('Error cleaning up abandoned rooms: $e');
    }
  }
}