import 'package:isar/isar.dart';

part 'local_schema_metadata_io.g.dart';

@collection
@Name("LocalSchemaMetadata1")
class LocalSchemaMetadata {
  Id id = Isar.autoIncrement;

  /// Applied local schema version number
  @Index(unique: true, replace: true)
  late int version;

  /// Timestamp when migration to this schema version was applied
  late DateTime appliedAt;

  /// Whether migration step completed successfully
  bool isSuccessful = true;

  /// Description of the migration step
  String? description;
}
