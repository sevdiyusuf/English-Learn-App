import 'package:isar/isar.dart';

part 'dict_entry.g.dart';

@Collection()
@Name("DictEntry2038")
class DictEntry {
  Id id = Isar.autoIncrement;

  late String word;

  late String type;
}
