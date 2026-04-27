import 'package:isar/isar.dart';

part 'word_pair.g.dart';

@collection
@Name("WordPair365")
class WordPair {
  Id id = Isar.autoIncrement;

  late int setId;
  late String english;
  late String turkish;
  bool learned = false;
}
