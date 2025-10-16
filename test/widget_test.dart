// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:min_elgasos_game/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Mock Firebase initialization for testing
    await tester.pumpWidget(const MyGameApp());
    await tester.pumpAndSettle();

    // Just verify the app doesn't crash and shows some content
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
