import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/screens/recto.dart';
import 'package:memoria/models/card_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<CardData> testCards;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    testCards = [
      CardData(
        id: 1,
        rectoText: 'Question 1',
        versoText: 'Réponse 1',
        difficulty: 'easy',
      ),
      CardData(
        id: 2,
        rectoText: 'Question 2',
        versoText: 'Réponse 2',
        rectoImage: null,
        difficulty: 'medium',
      ),
    ];
  });

  group('Recto Widget Tests', () {
    testWidgets('affiche correctement la carte initiale',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Recto(cards: testCards),
      ));

      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('Afficher la réponse'), findsOneWidget);
    });

    testWidgets('passe à la carte suivante', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Recto(cards: testCards),
      ));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('Question 2'), findsOneWidget);
    });

    testWidgets('affiche le dialogue de difficulté à la dernière carte',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Recto(cards: testCards, initialIndex: 1),
      ));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Difficile'), findsOneWidget);
    });
  });
}
