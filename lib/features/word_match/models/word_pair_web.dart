const dynamic WordPairSchema = null;

class _DummyCollectionWeb {
  Future<int> count() async => 0;
}

extension GetWordPairCollectionWeb on dynamic {
  dynamic get wordPairs => _DummyCollectionWeb();
  dynamic setIdEqualTo(int value) => null;
  dynamic learnedEqualTo(bool value) => null;
  dynamic findAll() => null;
  dynamic findFirst() => null;
}

class WordPair {
  int id = 0;

  late int setId;
  late String english;
  late String turkish;
  bool learned = false;
}
