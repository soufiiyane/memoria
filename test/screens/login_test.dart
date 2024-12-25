import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RegistrationScreen Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Vérifie les éléments UI de base', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier le titre
      expect(
        find.text('Inscrivez-vous et\ncommencez\napprentissage'),
        findsOneWidget,
      );

      // Vérifier les champs de saisie
      expect(find.byType(TextField), findsNWidgets(2));

      // Vérifier le bouton de connexion
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Vérifie la saisie des champs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Saisir du texte dans les champs
      await tester.enterText(
          find.widgetWithText(TextField, 'E-mail:'), 'test@example.com');
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, 'Mot de passe'), 'password123');
      await tester.pump();

      // Vérifier la saisie
      expect(
          find.widgetWithText(TextField, 'test@example.com'), findsOneWidget);
    });

    testWidgets('Vérifie les couleurs de base', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier la couleur de fond du Scaffold
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0D243D));
    });

    testWidgets('Vérifie le bouton Login', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier la présence du bouton
      expect(find.text('Login'), findsOneWidget);

      // Trouver le Container spécifique du bouton Login avec les bonnes propriétés
      final loginButtonContainer = find.ancestor(
        of: find.text('Login'),
        matching: find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 200 &&
            widget.constraints?.maxHeight == 50),
      );

      expect(loginButtonContainer, findsOneWidget);

      // Vérifier les propriétés du Container
      final container = tester.widget<Container>(loginButtonContainer);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, const Color(0xFF2E82DB));
      expect(decoration.borderRadius, BorderRadius.circular(10));
    });

    testWidgets('Vérifie le pré-remplissage email',
        (WidgetTester tester) async {
      const testEmail = 'test@example.com';

      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(email: testEmail),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier le TextField avec l'email pré-rempli
      final textField = find.byType(TextField).first;
      expect(
        (tester.widget(textField) as TextField).controller?.text,
        testEmail,
      );
    });
  });
}
