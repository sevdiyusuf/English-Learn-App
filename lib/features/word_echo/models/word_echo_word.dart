class WordEchoWord {
  const WordEchoWord({required this.english, required this.turkish});

  final String english;
  final String turkish;

  factory WordEchoWord.fromJson(Map<String, dynamic> json) {
    return WordEchoWord(
      english: json['english'] as String,
      turkish: json['turkish'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'english': english, 'turkish': turkish};
  }
}
