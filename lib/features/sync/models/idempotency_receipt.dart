class IdempotencyReceipt {
  const IdempotencyReceipt({
    required this.operationId,
    required this.ownerUid,
    required this.entityType,
    required this.entityId,
    required this.appliedRemoteVersion,
    required this.appliedAt,
  });

  final String operationId;
  final String ownerUid;
  final String entityType;
  final String entityId;
  final int appliedRemoteVersion;
  final DateTime appliedAt;

  Map<String, dynamic> toMap() {
    return {
      'operationId': operationId,
      'ownerUid': ownerUid,
      'entityType': entityType,
      'entityId': entityId,
      'appliedRemoteVersion': appliedRemoteVersion,
      'appliedAt': appliedAt.toUtc().toIso8601String(),
    };
  }

  factory IdempotencyReceipt.fromMap(String docId, Map<String, dynamic> map) {
    return IdempotencyReceipt(
      operationId: map['operationId'] as String? ?? docId,
      ownerUid: map['ownerUid'] as String? ?? '',
      entityType: map['entityType'] as String? ?? 'word_set',
      entityId: map['entityId'] as String? ?? '',
      appliedRemoteVersion: (map['appliedRemoteVersion'] as num?)?.toInt() ?? 1,
      appliedAt:
          map['appliedAt'] is String
              ? DateTime.tryParse(map['appliedAt'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}
