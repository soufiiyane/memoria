import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/screens/parametre.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ParametresPage Tests', () {
    testWidgets('Vérifie les éléments de base', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ParametresPage(),
      ));
      await tester.pumpAndSettle();

      // Vérifie le titre et les sections principales
      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('COMPTE'), findsOneWidget);
      expect(find.text('SYNCHRONISATION'), findsOneWidget);

      // Vérifie les éléments du compte
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Changer le mot de passe'), findsOneWidget);
    });

    testWidgets('Vérifie le mode hors ligne', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ParametresPage(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mode hors ligne'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('Test des composants de base', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ParametresPage(),
      ));
      await tester.pumpAndSettle();

      // Vérifie la présence de ListView
      expect(find.byType(ListView), findsOneWidget);

      // Vérifie la présence des Dividers
      expect(find.byType(Divider), findsWidgets);

      // Vérifie la présence des ListTiles
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('Test du changement de mot de passe',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ParametresPage(),
      ));
      await tester.pumpAndSettle();

      final changePwdButton =
          find.widgetWithText(ListTile, 'Changer le mot de passe');
      expect(changePwdButton, findsOneWidget);
    });

    testWidgets('Vérifie l\'AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ParametresPage(),
      ));
      await tester.pumpAndSettle();

      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      final title = find.text('Paramètres');
      expect(title, findsOneWidget);
    });

    testWidgets('Test des couleurs de background', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ParametresPage(),
      ));
      await tester.pumpAndSettle();

      final scaffold = find.byType(Scaffold);
      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(scaffoldWidget.backgroundColor, const Color(0xFF0D243D));
    });

    testWidgets('Test de la section évaluation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ParametresPage(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ÉVALUATION'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsWidgets);
    });
  });
}
