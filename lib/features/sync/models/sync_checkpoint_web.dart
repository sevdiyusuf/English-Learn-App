const dynamic SyncCheckpointSchema = null;

extension GetSyncCheckpointCollectionWeb on dynamic {
  dynamic get syncCheckpoints => null;
  dynamic checkpointKeyEqualTo(String value) => null;
  dynamic ownerUidEqualTo(String value) => null;
  dynamic findAll() => null;
  dynamic findFirst() => null;
}

class SyncCheckpoint {
  int id = 0;

  late String checkpointKey;
  late String ownerUid;
  late String entityType;
  DateTime? lastServerUpdatedAt;
  String? tieBreakerDocId;
  late DateTime updatedAt;
}
