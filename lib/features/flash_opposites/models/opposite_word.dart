class OppositeWord {
  const OppositeWord({
    required this.word,
    required this.opposite,
    required this.translate,
  });

  final String word;
  final String opposite;
  final String translate;

  factory OppositeWord.fromJson(Map<String, dynamic> json) {
    return OppositeWord(
      word: json['word'] as String,
      opposite: json['opposite'] as String,
      translate: json['translate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'word': word, 'opposite': opposite, 'translate': translate};
  }
}
