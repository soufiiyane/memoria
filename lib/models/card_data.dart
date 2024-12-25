class CardData {
  final int id;
  final String rectoText;
  final String versoText;
  String? rectoImage;
  String? difficulty;

  // Compteur statique pour assurer l'unicité des IDs
  static int _counter = 0;

  // Méthode pour générer un ID unique
  static int _generateUniqueId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return timestamp * 1000 + (_counter++ % 1000);
  }

  CardData({
    int? id,
    required this.rectoText,
    required this.versoText,
    this.rectoImage,
    this.difficulty,
  }) : this.id = id ?? _generateUniqueId();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': rectoText,
      'answer': versoText,
      'difficulty': difficulty,
      'imageUrl': rectoImage,
    };
  }

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      id: json['id'] is String
          ? int.parse(json['id'])
          : json['id'] ?? _generateUniqueId(),
      rectoText: json['question'] ?? json['rectoText'] ?? '',
      versoText: json['answer'] ?? json['versoText'] ?? '',
      difficulty: json['difficulty']?.toString(),
      rectoImage: json['rectoImagePath']?.toString(),
    );
  }

  static CardData fromApiResponse(Map<String, dynamic> json) {
    return CardData(
      id: json['id'] is String
          ? int.parse(json['id'])
          : json['id'] ?? _generateUniqueId(),
      rectoText: json['question'] ?? '',
      versoText: json['answer'] ?? '',
      difficulty: json['difficulty']?.toString(),
      rectoImage: json['imageUrl'],
    );
  }
}
