import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/sync/data/firestore_sync_gateway.dart';
import 'package:yunoo/features/sync/domain/sync_conflict_resolver.dart';
import 'package:yunoo/features/sync/domain/word_set_sync_codec.dart';
import 'package:yunoo/features/sync/models/idempotency_receipt.dart';
import 'package:yunoo/features/sync/models/outbox_item.dart';
import 'package:yunoo/features/sync/services/sync_listener_manager.dart';

// ────────────────────────────────────────────────────────────────────────────
// Controllable Fake Gateway
// ────────────────────────────────────────────────────────────────────────────

class FakeListenerGateway implements FirestoreSyncGateway {
  /// Emits to all active subscriptions.
  final StreamController<List<RemoteDocumentData>> streamController =
      StreamController<List<RemoteDocumentData>>.broadcast();

  /// If set, the stream will emit this error on the next [emitError] call.
  AppFailure? errorToEmit;

  void emitDocs(List<RemoteDocumentData> docs) {
    streamController.add(docs);
  }

  void emitError(dynamic error) {
    streamController.addError(error);
  }

  @override
  Stream<List<RemoteDocumentData>> listenToChanges({
    required String ownerUid,
  }) => streamController.stream;

  @override
  Future<ConflictDecision> executeIdempotentTransaction({
    required String ownerUid,
    required OutboxItem localOp,
  }) async => throw UnimplementedError();

  @override
  Future<RemoteDocumentData?> fetchDocument({
    required String ownerUid,
    required String entityId,
  }) async => null;

  @override
  Future<List<RemoteDocumentData>> fetchIncrementalChanges({
    required String ownerUid,
    DateTime? sinceServerUpdatedAt,
    String? tieBreakerDocId,
    int limit = 20,
  }) async => [];

  @override
  Future<IdempotencyReceipt?> fetchReceipt({
    required String ownerUid,
    required String operationId,
  }) async => null;
}

RemoteDocumentData _makeDoc(String id, String ownerUid) => RemoteDocumentData(
  documentId: id,
  ownerUid: ownerUid,
  entityId: id,
  entityType: 'word_set',
  remoteVersion: 1,
  lastOperationId: 'op_$id',
  isTombstone: false,
);

// ────────────────────────────────────────────────────────────────────────────
// Tests
// ────────────────────────────────────────────────────────────────────────────

void main() {
  group('Sprint 4D — SyncListenerManager Unit Tests', () {
    late FakeListenerGateway fakeGateway;

    setUp(() {
      fakeGateway = FakeListenerGateway();
    });

    tearDown(() {
      fakeGateway.streamController.close();
    });

    test('Dispose closes subscription once and is safe to call twice', () {
      final manager = SyncListenerManager(
        gateway: fakeGateway,
        activeAuthenticatedUidFetcher: () => 'user_A',
      );

      manager.startListening(ownerUid: 'user_A', onChanges: (_) {});
      expect(manager.isListening, isTrue);

      manager.dispose();
      expect(manager.isListening, isFalse);

      // Safe to call twice
      expect(() => manager.dispose(), returnsNormally);
    });

    test(
      'Stale session event from User A is discarded when User B session is active',
      () async {
        String activeUser = 'user_A';
        final manager = SyncListenerManager(
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => activeUser,
        );

        List<RemoteDocumentData>? receivedChanges;
        manager.startListening(
          ownerUid: 'user_A',
          onChanges: (c) => receivedChanges = c,
        );

        // Switch session
        activeUser = 'user_B';

        fakeGateway.emitDocs([_makeDoc('101', 'user_A')]);
        await Future.delayed(Duration.zero);

        expect(receivedChanges, isNull);
        manager.dispose();
      },
    );

    test(
      'Dispose after startListening: subsequent stream event is NOT delivered',
      () async {
        final manager = SyncListenerManager(
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        List<RemoteDocumentData>? receivedChanges;
        manager.startListening(
          ownerUid: 'user_A',
          onChanges: (c) => receivedChanges = c,
        );

        manager.dispose(); // Dispose immediately
        expect(manager.isListening, isFalse);

        fakeGateway.emitDocs([_makeDoc('202', 'user_A')]);
        await Future.delayed(Duration.zero);

        expect(receivedChanges, isNull);
      },
    );

    test(
      'Old session generation event is discarded after stopListening + restartListening',
      () async {
        String activeUser = 'user_A';
        final manager = SyncListenerManager(
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => activeUser,
        );

        final receivedBatches = <List<RemoteDocumentData>>[];
        manager.startListening(
          ownerUid: 'user_A',
          onChanges: (c) => receivedBatches.add(c),
        );

        // Stop and restart under same user
        manager.stopListening();

        // Restart — new session generation
        manager.startListening(
          ownerUid: 'user_A',
          onChanges: (c) => receivedBatches.add(c),
        );

        // Emit one event (belongs to NEW session)
        fakeGateway.emitDocs([_makeDoc('303', 'user_A')]);
        await Future.delayed(Duration.zero);

        // Only one batch (from the new generation) must be received
        expect(receivedBatches.length, equals(1));
        manager.dispose();
      },
    );

    test(
      'Guest / null ownerUid delivers onError(AppFailure.auth) instead of opening stream',
      () async {
        final manager = SyncListenerManager(
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => null,
        );

        AppFailure? capturedFailure;
        manager.startListening(
          ownerUid: null,
          onChanges: (_) {},
          onError: (f) => capturedFailure = f,
        );

        expect(manager.isListening, isFalse);
        expect(capturedFailure, isNotNull);
        expect(capturedFailure!.type, equals(FailureType.auth));
      },
    );

    test(
      'Auth UID mismatch on startListening delivers onError(AppFailure.auth)',
      () async {
        final manager = SyncListenerManager(
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_B',
        );

        AppFailure? capturedFailure;
        manager.startListening(
          ownerUid: 'user_A',
          onChanges: (_) {},
          onError: (f) => capturedFailure = f,
        );

        expect(manager.isListening, isFalse);
        expect(capturedFailure, isNotNull);
        expect(capturedFailure!.type, equals(FailureType.auth));
      },
    );

    test(
      'Permanent permission error emitted from stream is forwarded as AppFailure to onError',
      () async {
        final manager = SyncListenerManager(
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        AppFailure? capturedFailure;
        manager.startListening(
          ownerUid: 'user_A',
          onChanges: (_) {},
          onError: (f) => capturedFailure = f,
        );

        final permissionError = AppFailure.database(
          message: 'permission-denied',
          code: 'permission-denied',
        );
        fakeGateway.emitError(permissionError);
        await Future.delayed(Duration.zero);

        expect(capturedFailure, isNotNull);
        expect(capturedFailure!.type, equals(FailureType.database));
        manager.dispose();
      },
    );

    test(
      'Non-AppFailure stream error is wrapped and forwarded as AppFailure to onError',
      () async {
        final manager = SyncListenerManager(
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        AppFailure? capturedFailure;
        manager.startListening(
          ownerUid: 'user_A',
          onChanges: (_) {},
          onError: (f) => capturedFailure = f,
        );

        fakeGateway.emitError(Exception('Unknown network exception'));
        await Future.delayed(Duration.zero);

        expect(capturedFailure, isNotNull);
        manager.dispose();
      },
    );
  });
}
