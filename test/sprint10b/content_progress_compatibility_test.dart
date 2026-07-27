import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/content/content_progress_reference.dart';

void main() {
  test('legacy records remain readable', () {
    final reference = ContentProgressReference.fromJson({
      'ownerScope': 'user-a',
      'legacyKey': 'worksheet:A1:old-q1',
    });

    expect(reference.contentId, isNull);
    expect(reference.legacyKey, 'worksheet:A1:old-q1');
  });

  test('new progress serializes stable identity', () {
    const reference = ContentProgressReference(
      ownerScope: 'user-a',
      contentId: 'edu.item.000001',
    );

    expect(reference.toJson()['contentId'], 'edu.item.000001');
  });

  test('legacy resolution is deterministic and idempotent', () {
    final legacy = ContentProgressReference.fromJson({
      'ownerScope': 'user-a',
      'legacyKey': 'old-q1',
    });
    final mapping = {'old-q1': 'edu.item.000001'};

    final once = legacy.resolveLegacy(mapping);
    final twice = once.resolveLegacy(mapping);

    expect(twice.toJson(), once.toJson());
  });

  test('reordered content cannot transfer stable progress', () {
    const progress = ContentProgressReference(
      ownerScope: 'user-a',
      contentId: 'edu.item.000002',
    );
    final reorderedIds = ['edu.item.000003', 'edu.item.000002'];

    expect(reorderedIds.indexOf(progress.contentId!), 1);
    expect(progress.contentId, 'edu.item.000002');
  });

  test('unknown and partial legacy references fail safely', () {
    final partial = ContentProgressReference.fromJson({
      'ownerScope': 'user-a',
      'legacyKey': 'removed',
    });

    expect(partial.resolveLegacy(const {}).contentId, isNull);
    expect(ContentProgressReference.fromJson(const {}).ownerScope, 'unscoped');
  });

  test('owner scopes remain isolated', () {
    const first = ContentProgressReference(
      ownerScope: 'user-a',
      contentId: 'edu.item.000001',
    );
    const second = ContentProgressReference(
      ownerScope: 'user-b',
      contentId: 'edu.item.000001',
    );

    expect(first.ownerScope, isNot(second.ownerScope));
  });
}
