import 'dart:math';

/// Generates a unique, secure operation ID for Cloud Functions idempotency.
String generateOperationId() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
