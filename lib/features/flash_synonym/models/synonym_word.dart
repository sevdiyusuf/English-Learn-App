class SynonymWord {
  const SynonymWord({
    required this.word,
    required this.synonym,
    required this.translate,
  });

  final String word;
  final String synonym;
  final String translate;

  factory SynonymWord.fromJson(Map<String, dynamic> json) {
    return SynonymWord(
      word: json['word'] as String,
      synonym: json['synonym'] as String,
      translate: json['translate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'synonym': synonym,
      'translate': translate,
    };
  }
}

