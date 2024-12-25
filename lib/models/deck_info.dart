// lib/models/deck_info.dart
import 'card_data.dart';

class DeckInfo {
  final int id;
  final String name;
  final String description;
  final List<String> tags;
  final int totalCards;
  final int masteredCards;
  final double averageSuccessRate;
  final List<CardData> cards;

  DeckInfo({
    required this.id,
    required this.name,
    required this.description,
    required List<String> tags,
    required this.totalCards,
    required this.masteredCards,
    required this.averageSuccessRate,
    List<CardData>? cards,
  })  : this.tags = List.unmodifiable(tags),
        this.cards = List.unmodifiable(cards ?? []);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tags': List<String>.from(tags),
      'totalCards': totalCards,
      'masteredCards': masteredCards,
      'averageSuccessRate': averageSuccessRate,
      'cards': cards.map((card) => card.toJson()).toList(),
    };
  }

  factory DeckInfo.fromJson(Map<String, dynamic> json) {
    var cardsList = <CardData>[];
    if (json['cards'] != null) {
      cardsList = (json['cards'] as List)
          .map(
              (cardJson) => CardData.fromJson(cardJson as Map<String, dynamic>))
          .toList();
    }

    return DeckInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: List<String>.from((json['tags'] as List<dynamic>?) ?? []),
      totalCards: json['totalCards'] as int? ?? 0,
      masteredCards: json['masteredCards'] as int? ?? 0,
      averageSuccessRate:
          (json['averageSuccessRate'] as num?)?.toDouble() ?? 0.0,
      cards: cardsList,
    );
  }
}
