// ignore_for_file: unnecessary_no_such_method
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';

import 'package:yunoo/features/educational_content/content_report_service.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class FakeHttpsCallableResult<T> implements HttpsCallableResult<T> {
  FakeHttpsCallableResult(this.data);
  @override
  final T data;
}

/// Configurable fake HttpsCallable: returns success or throws a given error.
class _FakeCallable extends Fake implements HttpsCallable {
  _FakeCallable({Object? throws}) : _throws = throws;
  final Object? _throws;
  Map<String, dynamic>? lastArgs;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    lastArgs = parameters as Map<String, dynamic>?;
    if (_throws != null) throw _throws;
    return FakeHttpsCallableResult<T>({'success': true} as T);
  }
}

class _FakeFunctions extends Fake implements FirebaseFunctions {
  _FakeFunctions({Object? throws}) : _callable = _FakeCallable(throws: throws);
  final _FakeCallable _callable;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _callable;
}

// ignore: subtype_of_sealed_class
class _FakeFirebaseAuth extends Fake implements firebase_auth.FirebaseAuth {
  _FakeFirebaseAuth({firebase_auth.User? user}) : _user = user;
  final firebase_auth.User? _user;

  @override
  firebase_auth.User? get currentUser => _user;
}

// ignore: subtype_of_sealed_class
class _FakeUser extends Fake implements firebase_auth.User {
  @override
  String get uid => 'test-uid';
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ContentReportService.submit', () {
    ContentReportService svc({Object? throws, bool signedIn = true}) {
      return ContentReportService(
        _FakeFunctions(throws: throws),
        _FakeFirebaseAuth(user: signedIn ? _FakeUser() : null),
      );
    }

    test('returns unauthenticated when no user is signed in', () async {
      final result = await svc(signedIn: false).submit(
        contentId: 'edu.item.000001',
        contentVersion: 1,
        contentType: 'irregular_verb',
        category: ContentReportCategory.typo,
      );
      expect(result, ContentReportResult.unauthenticated);
    });

    test('returns success on successful callable invocation', () async {
      final result = await svc().submit(
        contentId: 'edu.item.000001',
        contentVersion: 1,
        contentType: 'irregular_verb',
        category: ContentReportCategory.typo,
      );
      expect(result, ContentReportResult.success);
    });

    test(
      'returns alreadyReported on already-exists FirebaseFunctionsException',
      () async {
        final err = FirebaseFunctionsException(
          code: 'already-exists',
          message: 'report-already-submitted',
        );
        final result = await svc(throws: err).submit(
          contentId: 'edu.item.000001',
          contentVersion: 1,
          contentType: 'irregular_verb',
          category: ContentReportCategory.incorrectAnswer,
        );
        expect(result, ContentReportResult.alreadyReported);
      },
    );

    test(
      'returns unauthenticated on unauthenticated FirebaseFunctionsException',
      () async {
        final err = FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'auth',
        );
        final result = await svc(throws: err).submit(
          contentId: 'edu.item.000001',
          contentVersion: 1,
          contentType: 'irregular_verb',
          category: ContentReportCategory.audioIssue,
        );
        expect(result, ContentReportResult.unauthenticated);
      },
    );

    test('returns failure on generic FirebaseFunctionsException', () async {
      final err = FirebaseFunctionsException(
        code: 'internal',
        message: 'server error',
      );
      final result = await svc(throws: err).submit(
        contentId: 'edu.item.000001',
        contentVersion: 1,
        contentType: 'irregular_verb',
        category: ContentReportCategory.other,
      );
      expect(result, ContentReportResult.failure);
    });

    test('returns failure on unexpected exception', () async {
      final result = await svc(throws: Exception('network failure')).submit(
        contentId: 'edu.item.000001',
        contentVersion: 1,
        contentType: 'irregular_verb',
        category: ContentReportCategory.unclearExplanation,
      );
      expect(result, ContentReportResult.failure);
    });

    test('includes comment in request payload when provided', () async {
      final fns = _FakeFunctions();
      final svc = ContentReportService(
        fns,
        _FakeFirebaseAuth(user: _FakeUser()),
      );
      await svc.submit(
        contentId: 'edu.item.000001',
        contentVersion: 1,
        contentType: 'irregular_verb',
        category: ContentReportCategory.typo,
        comment: 'V2 form is misspelled',
      );
      expect(fns._callable.lastArgs?['comment'], 'V2 form is misspelled');
      expect(fns._callable.lastArgs?['contentType'], 'irregular_verb');
    });

    test('omits comment from request payload when empty', () async {
      final fns = _FakeFunctions();
      final svc = ContentReportService(
        fns,
        _FakeFirebaseAuth(user: _FakeUser()),
      );
      await svc.submit(
        contentId: 'edu.item.000001',
        contentVersion: 1,
        contentType: 'irregular_verb',
        category: ContentReportCategory.typo,
      );
      expect(fns._callable.lastArgs?.containsKey('comment'), isFalse);
    });

    test('ContentReportCategory.value returns correct wire strings', () {
      expect(ContentReportCategory.typo.value, 'typo');
      expect(ContentReportCategory.incorrectAnswer.value, 'incorrect_answer');
      expect(
        ContentReportCategory.unclearExplanation.value,
        'unclear_explanation',
      );
      expect(ContentReportCategory.audioIssue.value, 'audio_issue');
      expect(
        ContentReportCategory.wrongLevelOrCategory.value,
        'wrong_level_or_category',
      );
      expect(ContentReportCategory.other.value, 'other');
    });
  });
}
