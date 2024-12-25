import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/screens/page_carte.dart';
import 'package:memoria/models/deck_info.dart';
import 'package:memoria/models/card_data.dart';

void main() {
  final testDeck = DeckInfo(
    id: 1,
    name: 'Test Deck',
    description: 'Test Description',
    tags: ['test'],
    totalCards: 0,
    masteredCards: 0,
    averageSuccessRate: 0.0,
  );

  group('PageCarte Widget Tests', () {
    testWidgets('Affiche tous les éléments de base',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PageCarte(deck: testDeck),
      ));

      // Vérifie le titre
      expect(find.text('Ajouter des cartes'), findsOneWidget);

      // Vérifie les sections Recto/Verso
      expect(find.text('Recto'), findsOneWidget);
      expect(find.text('Verso'), findsOneWidget);

      // Vérifie les champs de texte
      expect(find.byType(TextField), findsNWidgets(2));

      // Vérifie le bouton d'ajout de carte
      expect(find.text('Ajouter la carte'), findsOneWidget);
    });

    testWidgets('Vérifie la validation des champs vides',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PageCarte(deck: testDeck),
      ));

      // Tente d'ajouter une carte sans remplir les champs
      await tester.tap(find.text('Ajouter la carte'));
      await tester.pumpAndSettle();

      // Vérifie le message d'erreur
      expect(find.text('Veuillez remplir les champs recto et verso.'),
          findsOneWidget);
    });

    testWidgets('Vérifie la limite de caractères', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PageCarte(deck: testDeck),
      ));

      // Entre un texte court
      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.enterText(find.byType(TextField).last, 'def');

      // Tente d'ajouter la carte
      await tester.tap(find.text('Ajouter la carte'));
      await tester.pumpAndSettle();

      // Vérifie le message d'erreur de longueur minimale
      expect(
        find.text(
            'Les textes du recto et du verso doivent contenir au moins 5 caractères.'),
        findsOneWidget,
      );
    });

    testWidgets('Vérifie les styles visuels', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PageCarte(deck: testDeck),
      ));

      // Vérifie la couleur de fond
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.body,
        isA<Container>().having(
          (container) => container.decoration,
          'background color',
          isA<BoxDecoration>().having(
            (decoration) => decoration.color,
            'color',
            equals(const Color(0xFF0D243D)),
          ),
        ),
      );
    });
  });
}
