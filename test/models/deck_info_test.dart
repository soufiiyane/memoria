import 'package:flutter_test/flutter_test.dart';
import 'package:memoria/models/deck_info.dart';
import 'package:memoria/models/card_data.dart';

void main() {
  late DeckInfo testDeck;
  late Map<String, dynamic> testJson;

  setUp(() {
    testDeck = DeckInfo(
      id: 1,
      name: 'Test Deck',
      description: 'Test Description',
      tags: ['tag1', 'tag2'],
      totalCards: 10,
      masteredCards: 5,
      averageSuccessRate: 0.75,
      cards: [
        CardData(
          id: 1,
          rectoText: 'Question 1',
          versoText: 'Answer 1',
        ),
      ],
    );

    testJson = {
      'id': 1,
      'name': 'Test Deck',
      'description': 'Test Description',
      'tags': ['tag1', 'tag2'],
      'totalCards': 10,
      'masteredCards': 5,
      'averageSuccessRate': 0.75,
      'cards': [
        {
          'id': 1,
          'question': 'Question 1',
          'answer': 'Answer 1',
        }
      ],
    };
  });

  test('Create DeckInfo with valid data', () {
    expect(testDeck.id, equals(1));
    expect(testDeck.name, equals('Test Deck'));
    expect(testDeck.description, equals('Test Description'));
    expect(testDeck.tags, equals(['tag1', 'tag2']));
    expect(testDeck.totalCards, equals(10));
    expect(testDeck.masteredCards, equals(5));
    expect(testDeck.averageSuccessRate, equals(0.75));
    expect(testDeck.cards.length, equals(1));
  });

  test('Tags and cards lists should be immutable', () {
    expect(() => testDeck.tags.add('tag3'), throwsUnsupportedError);
    expect(
        () => testDeck.cards
            .add(CardData(rectoText: 'New Question', versoText: 'New Answer')),
        throwsUnsupportedError);
  });

  test('Create DeckInfo with null cards', () {
    final deck = DeckInfo(
      id: 1,
      name: 'Test Deck',
      description: 'Test Description',
      tags: ['tag1'],
      totalCards: 1,
      masteredCards: 0,
      averageSuccessRate: 0.0,
      cards: null,
    );

    expect(deck.cards, isEmpty);
  });

  test('Convert DeckInfo to JSON', () {
    final json = testDeck.toJson();

    expect(json['id'], equals(1));
    expect(json['name'], equals('Test Deck'));
    expect(json['description'], equals('Test Description'));
    expect(json['tags'], equals(['tag1', 'tag2']));
    expect(json['totalCards'], equals(10));
    expect(json['masteredCards'], equals(5));
    expect(json['averageSuccessRate'], equals(0.75));
    expect(json['cards'], isNotEmpty);
  });

  test('Create DeckInfo from JSON', () {
    final deck = DeckInfo.fromJson(testJson);

    expect(deck.id, equals(1));
    expect(deck.name, equals('Test Deck'));
    expect(deck.description, equals('Test Description'));
    expect(deck.tags, equals(['tag1', 'tag2']));
    expect(deck.totalCards, equals(10));
    expect(deck.masteredCards, equals(5));
    expect(deck.averageSuccessRate, equals(0.75));
    expect(deck.cards.length, equals(1));
  });

  test('Create DeckInfo from empty JSON', () {
    final deck = DeckInfo.fromJson({});

    expect(deck.id, equals(0));
    expect(deck.name, equals(''));
    expect(deck.description, equals(''));
    expect(deck.tags, isEmpty);
    expect(deck.totalCards, equals(0));
    expect(deck.masteredCards, equals(0));
    expect(deck.averageSuccessRate, equals(0.0));
    expect(deck.cards, isEmpty);
  });

  test('Handle null values in JSON', () {
    final json = {
      'id': null,
      'name': null,
      'description': null,
      'tags': null,
      'totalCards': null,
      'masteredCards': null,
      'averageSuccessRate': null,
      'cards': null,
    };

    final deck = DeckInfo.fromJson(json);

    expect(deck.id, equals(0));
    expect(deck.name, equals(''));
    expect(deck.description, equals(''));
    expect(deck.tags, isEmpty);
    expect(deck.totalCards, equals(0));
    expect(deck.masteredCards, equals(0));
    expect(deck.averageSuccessRate, equals(0.0));
    expect(deck.cards, isEmpty);
  });
}
