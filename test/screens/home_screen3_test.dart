import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/screens/home_screen3.dart';
import 'package:memoria/screens/login.dart';

void main() {
  group('HomeScreen3 Widget Tests', () {
    testWidgets('Renders HomeScreen3 with correct structure',
        (WidgetTester tester) async {
      // Pump the HomeScreen3 widget
      await tester.pumpWidget(MaterialApp(home: HomeScreen3()));

      // Verify Scaffold exists
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Verifies main title', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: HomeScreen3()));

      // Check for title text
      expect(find.text('Pourquoi Memoria\nest différent ?'), findsOneWidget);
    });

    testWidgets('Checks feature description texts',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: HomeScreen3()));

      // Check for feature description texts
      expect(find.text('Apprentissage intelligent qui s\'adapte\nà ton rythme'),
          findsOneWidget);
      expect(
          find.text(
              'Crée tes propres cartes personnalisées\nen quelques secondes'),
          findsOneWidget);
      expect(find.text('Apprends n\'importe où, même\nsans connexion'),
          findsOneWidget);
    });

    testWidgets('Verifies "Lance-toi" button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: HomeScreen3()));

      // Find the "Lance-toi" button
      final buttonFinder = find.text('Lance-toi');
      expect(buttonFinder, findsOneWidget);
    });

    testWidgets('Navigation button triggers screen transition',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HomeScreen3(),
      ));

      // Find and tap the "Lance-toi" button
      await tester.tap(find.text('Lance-toi'));
      await tester.pumpAndSettle();

      // Verify navigation to RegistrationScreen
      expect(find.byType(RegistrationScreen), findsOneWidget);
    });
  });
}
