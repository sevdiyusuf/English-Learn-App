import '../../../core/errors/app_failure.dart';

class RemoteDocumentData {
  const RemoteDocumentData({
    required this.documentId,
    required this.ownerUid,
    required this.entityId,
    required this.entityType,
    required this.remoteVersion,
    required this.lastOperationId,
    required this.isTombstone,
    this.deletedAt,
    this.serverUpdatedAt,
    this.payload,
  });

  final String documentId;
  final String ownerUid;
  final String entityId;
  final String entityType;
  final int remoteVersion;
  final String lastOperationId;
  final bool isTombstone;
  final DateTime? deletedAt;
  final DateTime? serverUpdatedAt;
  final Map<String, dynamic>? payload;
}

class WordSetSyncCodec {
  static Map<String, dynamic> encode({
    required String ownerUid,
    required String entityId,
    required String entityType,
    required int remoteVersion,
    required String operationId,
    required bool isTombstone,
    DateTime? deletedAt,
    Map<String, dynamic>? payload,
    dynamic serverTimestampFieldValue,
  }) {
    final map = <String, dynamic>{
      'ownerUid': ownerUid,
      'entityId': entityId,
      'entityType': entityType,
      'remoteVersion': remoteVersion,
      'lastOperationId': operationId,
      'isTombstone': isTombstone,
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
      'serverUpdatedAt':
          serverTimestampFieldValue ?? DateTime.now().toUtc().toIso8601String(),
    };

    if (!isTombstone && payload != null) {
      map['name'] = payload['name'] ?? '';
      map['createdAt'] =
          payload['createdAt'] ?? DateTime.now().toUtc().toIso8601String();
      map['updatedAt'] =
          payload['updatedAt'] ?? DateTime.now().toUtc().toIso8601String();
      map['visibility'] = payload['visibility'] ?? 'private';
      map['sourceSetId'] = payload['sourceSetId'];
      map['sourceOwnerUid'] = payload['sourceOwnerUid'];
      map['importedAt'] = payload['importedAt'];
      map['pairs'] = payload['pairs'] ?? <dynamic>[];
    }

    return map;
  }

  static RemoteDocumentData decode({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    try {
      final ownerUid = data['ownerUid'] as String?;
      final entityId = data['entityId'] as String? ?? documentId;
      final entityType = data['entityType'] as String? ?? 'word_set';
      final remoteVersion = (data['remoteVersion'] as num?)?.toInt() ?? 1;
      final lastOperationId = data['lastOperationId'] as String? ?? '';
      final isTombstone = data['isTombstone'] as bool? ?? false;

      DateTime? deletedAt;
      final deletedAtRaw = data['deletedAt'];
      if (deletedAtRaw is String && deletedAtRaw.isNotEmpty) {
        deletedAt = DateTime.tryParse(deletedAtRaw);
      }

      DateTime? serverUpdatedAt;
      final serverUpdatedAtRaw = data['serverUpdatedAt'];
      if (serverUpdatedAtRaw is String && serverUpdatedAtRaw.isNotEmpty) {
        serverUpdatedAt = DateTime.tryParse(serverUpdatedAtRaw);
      } else if (serverUpdatedAtRaw != null) {
        try {
          final dynamic ts = serverUpdatedAtRaw;
          final toDate = ts.toDate;
          if (toDate is Function) {
            serverUpdatedAt = toDate() as DateTime;
          }
        } catch (_) {}
      }

      if (ownerUid == null || ownerUid.isEmpty) {
        throw AppFailure.database(
          message: 'Remote belge ownerUid içermiyor veya malformed.',
        );
      }

      Map<String, dynamic>? payload;
      if (!isTombstone) {
        payload = {
          'name': data['name'] ?? '',
          'createdAt':
              data['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
          'updatedAt':
              data['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
          'visibility': data['visibility'] ?? 'private',
          'sourceSetId': data['sourceSetId'],
          'sourceOwnerUid': data['sourceOwnerUid'],
          'importedAt': data['importedAt'],
          'pairs': data['pairs'] ?? <dynamic>[],
        };
      }

      return RemoteDocumentData(
        documentId: documentId,
        ownerUid: ownerUid,
        entityId: entityId,
        entityType: entityType,
        remoteVersion: remoteVersion,
        lastOperationId: lastOperationId,
        isTombstone: isTombstone,
        deletedAt: deletedAt,
        serverUpdatedAt: serverUpdatedAt,
        payload: payload,
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure.database(
        message: 'Remote Firestore belgesi koda aktarılırken hata oluştu: $e',
        originalError: e,
      );
    }
  }
}
