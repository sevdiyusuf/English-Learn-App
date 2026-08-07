import 'dart:convert';

const dynamic OutboxItemSchema = null;

extension GetOutboxItemCollectionWeb on dynamic {
  dynamic get outboxItems => null;
  dynamic operationIdEqualTo(String value) => null;
  dynamic coalescingKeyEqualTo(String value) => null;
  dynamic ownerUidEqualTo(String? value) => null;
  dynamic syncStatusEqualTo(OutboxSyncStatus value) => null;
  dynamic findAll() => null;
  dynamic findFirst() => null;
}

enum OutboxOperationType { create, update, delete }

enum OutboxSyncStatus {
  pending,
  synced,
  failedRetryable,
  failedPermanent,
  conflict,
}

class OutboxItem {
  int id = 0;

  late String operationId;
  late String entityType;
  late String entityId;
  late String coalescingKey;
  String? ownerUid;
  late OutboxOperationType operation;
  OutboxSyncStatus syncStatus = OutboxSyncStatus.pending;
  int localVersion = 1;
  int? remoteVersion;
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? lastAttemptAt;
  int attemptCount = 0;
  DateTime? deletedAt;
  bool isTombstone = false;
  String? lastErrorMessage;
  String? lastErrorCode;
  String? conflictDetails;
  String? payloadJson;

  Map<String, dynamic>? get payload {
    if (payloadJson == null || payloadJson!.isEmpty) return null;
    try {
      return jsonDecode(payloadJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  set payload(Map<String, dynamic>? value) {
    if (value == null) {
      payloadJson = null;
    } else {
      payloadJson = jsonEncode(value);
    }
  }
}
