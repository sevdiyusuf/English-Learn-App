import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'performance_service.dart';

/// Riverpod provider for accessing the centralized [PerformanceService].
final performanceServiceProvider = Provider<PerformanceService>((ref) {
  return PerformanceService.instance;
});
