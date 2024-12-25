import 'package:test/test.dart';
import 'package:memoria/models/card_data.dart';

void main() {
  group('CardData Tests', () {
    test('Création avec ID spécifié', () {
      final card = CardData(
        id: 1,
        rectoText: 'Question',
        versoText: 'Réponse',
      );
      expect(card.id, equals(1));
    });

    test('Création avec ID auto-généré', () {
      final card = CardData(
        rectoText: 'Question',
        versoText: 'Réponse',
      );
      expect(card.id, isNotNull);
      expect(card.id, isPositive);
    });

    test('fromJson avec ID string', () {
      final json = {
        'id': '123',
        'question': 'Test Question',
        'answer': 'Test Answer',
        'difficulty': 'easy',
        'rectoImagePath': 'path/to/image',
      };

      final card = CardData.fromJson(json);
      expect(card.id, equals(123));
      expect(card.rectoText, equals('Test Question'));
      expect(card.versoText, equals('Test Answer'));
      expect(card.difficulty, equals('easy'));
      expect(card.rectoImage, equals('path/to/image'));
    });

    test('fromJson avec ID numérique', () {
      final json = {
        'id': 456,
        'question': 'Test Question',
        'answer': 'Test Answer',
      };

      final card = CardData.fromJson(json);
      expect(card.id, equals(456));
    });

    test('fromJson avec valeurs manquantes', () {
      final json = <String, dynamic>{};
      final card = CardData.fromJson(json);

      expect(card.id, isNotNull);
      expect(card.rectoText, equals(''));
      expect(card.versoText, equals(''));
      expect(card.difficulty, isNull);
      expect(card.rectoImage, isNull);
    });

    test('fromApiResponse avec données complètes', () {
      final json = {
        'id': 789,
        'question': 'API Question',
        'answer': 'API Answer',
        'difficulty': 'medium',
        'imageUrl': 'http://example.com/image.jpg',
      };

      final card = CardData.fromApiResponse(json);
      expect(card.id, equals(789));
      expect(card.rectoText, equals('API Question'));
      expect(card.versoText, equals('API Answer'));
      expect(card.difficulty, equals('medium'));
      expect(card.rectoImage, equals('http://example.com/image.jpg'));
    });

    test('toJson conversion', () {
      final card = CardData(
        id: 999,
        rectoText: 'Question Test',
        versoText: 'Réponse Test',
        difficulty: 'hard',
        rectoImage: 'image.jpg',
      );

      final json = card.toJson();
      expect(json['id'], equals(999));
      expect(json['question'], equals('Question Test'));
      expect(json['answer'], equals('Réponse Test'));
      expect(json['difficulty'], equals('hard'));
      expect(json['imageUrl'], equals('image.jpg'));
    });

    test('IDs uniques pour plusieurs cartes', () {
      final card1 = CardData(rectoText: 'Q1', versoText: 'R1');
      final card2 = CardData(rectoText: 'Q2', versoText: 'R2');
      final card3 = CardData(rectoText: 'Q3', versoText: 'R3');

      expect(card1.id, isNot(equals(card2.id)));
      expect(card2.id, isNot(equals(card3.id)));
      expect(card3.id, isNot(equals(card1.id)));
    });
  });
}
