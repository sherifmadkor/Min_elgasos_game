import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('🔥 Testing Firebase connection...');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase initialized');
    
    // Test Realtime Database connection
    final database = FirebaseDatabase.instance;
    print('🔥 Testing database connection...');
    
    // Try to read from database
    final testRef = database.ref('test');
    await testRef.set({'timestamp': DateTime.now().millisecondsSinceEpoch});
    print('✅ Database write successful');
    
    final snapshot = await testRef.get();
    print('✅ Database read successful: ${snapshot.value}');
    
    print('🎉 Firebase Realtime Database is working correctly!');
    
  } catch (e, stackTrace) {
    print('❌ Firebase connection failed: $e');
    print('❌ Stack trace: $stackTrace');
  }
}