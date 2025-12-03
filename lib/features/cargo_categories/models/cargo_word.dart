class CargoWord {
  const CargoWord({
    required this.word,
    required this.translate,
    required this.category,
  });

  final String word; // English word
  final String translate; // Turkish translation
  final String category; // Category ID

  factory CargoWord.fromJson(Map<String, dynamic> json) {
    return CargoWord(
      word: json['word'] as String,
      translate: json['translate'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translate': translate,
      'category': category,
    };
  }
}

