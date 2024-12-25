import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/screens/registre.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Tests de la page d\'inscription', () {
    testWidgets('Vérifie les titres', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: registre()));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue,'), findsOneWidget);
      expect(find.text('inscrivez-vous pour'), findsOneWidget);
      expect(find.text('utiliser l\'application'), findsOneWidget);
    });

    testWidgets('Vérifie les champs de saisie', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: registre()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));

      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      expect(textFields.length, 3);
      expect(textFields.last.obscureText, true);
    });

    testWidgets('Test saisie des champs', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: registre()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Test du bouton Registre', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: registre()));
      await tester.pumpAndSettle();

      expect(find.text('Registre'), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);

      final containerFinder = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is ShapeDecoration &&
          (widget.decoration as ShapeDecoration).color == Color(0xFF2E82DB));
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('Test de validation du formulaire vide',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: registre()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registre'));
      await tester.pumpAndSettle();

      expect(find.text('Veuillez remplir tous les champs.'), findsOneWidget);
    });

    testWidgets('Test des styles et containers', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: registre()));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Color(0xFF0D243D)));

      final textFieldContainers = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color?.withOpacity(0.1) != null);
      expect(textFieldContainers, findsWidgets);
    });

    testWidgets('Test de la structure des widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: registre()));
      await tester.pumpAndSettle();

      // Test de la structure de base
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(TextField), findsNWidgets(3));

      // Test des containers de texte
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).borderRadius != null),
          findsWidgets);

      // Test du bouton d'inscription
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.decoration is ShapeDecoration &&
              (widget.decoration as ShapeDecoration).color ==
                  Color(0xFF2E82DB)),
          findsOneWidget);
    });
  });
}
