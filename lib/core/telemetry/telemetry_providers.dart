import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'telemetry_service.dart';

/// Riverpod provider for accessing the centralized [TelemetryService].
final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  return TelemetryService.instance;
});
