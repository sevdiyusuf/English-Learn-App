const dynamic LocalSchemaMetadataSchema = null;

extension GetLocalSchemaMetadataCollectionWeb on dynamic {
  dynamic get localSchemaMetadatas => null;
  dynamic versionEqualTo(int value) => null;
  dynamic findAll() => null;
  dynamic findFirst() => null;
}

class LocalSchemaMetadata {
  int id = 0;

  late int version;
  late DateTime appliedAt;
  bool isSuccessful = true;
  String? description;
}
