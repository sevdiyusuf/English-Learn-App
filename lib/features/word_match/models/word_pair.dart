import 'package:isar/isar.dart';

part 'word_pair.g.dart';

@collection
class WordPair {
  Id id = Isar.autoIncrement;

  late int setId;
  late String english;
  late String turkish;
  bool learned = false;
}
