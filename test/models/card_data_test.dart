import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/models/card_data.dart';

// Assurez-vous que cette fonction main() est au niveau supérieur du fichier
void main() {
  setUp(() {
    // Réinitialiser avant chaque test si nécessaire
  });

  tearDown(() {
    // Nettoyer après chaque test si nécessaire
  });

  test('Create CardData with provided ID', () {
    final card = CardData(
      id: 123,
      rectoText: 'Question',
      versoText: 'Réponse',
    );

    expect(card.id, equals(123));
    expect(card.rectoText, equals('Question'));
    expect(card.versoText, equals('Réponse'));
  });

  test('Create CardData with generated ID', () {
    final card1 = CardData(
      rectoText: 'Question 1',
      versoText: 'Réponse 1',
    );
    final card2 = CardData(
      rectoText: 'Question 2',
      versoText: 'Réponse 2',
    );

    expect(card1.id, isNot(equals(card2.id)));
    expect(card1.id, isPositive);
    expect(card2.id, isPositive);
  });

  test('Convert CardData to JSON', () {
    final card = CardData(
      id: 123,
      rectoText: 'Question',
      versoText: 'Réponse',
      difficulty: 'EASY',
      rectoImage: 'image.jpg',
    );

    final json = card.toJson();

    expect(
        json,
        equals({
          'id': 123,
          'question': 'Question',
          'answer': 'Réponse',
          'difficulty': 'EASY',
          'imageUrl': 'image.jpg',
        }));
  });

  test('Create CardData from JSON with string ID', () {
    final json = {
      'id': '123',
      'question': 'Question',
      'answer': 'Réponse',
      'difficulty': 'MEDIUM',
      'rectoImagePath': 'image.jpg',
    };

    final card = CardData.fromJson(json);

    expect(card.id, equals(123));
    expect(card.rectoText, equals('Question'));
    expect(card.versoText, equals('Réponse'));
    expect(card.difficulty, equals('MEDIUM'));
    expect(card.rectoImage, equals('image.jpg'));
  });

  test('Create CardData from empty JSON', () {
    final json = <String, dynamic>{};
    final card = CardData.fromJson(json);

    expect(card.id, isPositive);
    expect(card.rectoText, equals(''));
    expect(card.versoText, equals(''));
    expect(card.difficulty, isNull);
    expect(card.rectoImage, isNull);
  });

  test('Create CardData from API response', () {
    final json = {
      'id': 123,
      'question': 'Question API',
      'answer': 'Réponse API',
      'difficulty': 'HARD',
      'imageUrl': 'api_image.jpg',
    };

    final card = CardData.fromApiResponse(json);

    expect(card.id, equals(123));
    expect(card.rectoText, equals('Question API'));
    expect(card.versoText, equals('Réponse API'));
    expect(card.difficulty, equals('HARD'));
    expect(card.rectoImage, equals('api_image.jpg'));
  });
}
