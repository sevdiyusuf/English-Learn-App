import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';

class TimerService extends StateNotifier<AsyncValue<Duration>> {
  TimerService(this._ref) : super(const AsyncValue.loading()) {
    _syncWithServer();
  }

  final Ref _ref;

  Duration get offset => state.value ?? Duration.zero;

  DateTime get now => DateTime.now().add(offset);

  Future<void> refresh() => _syncWithServer();

  Future<void> _syncWithServer() async {
    state = const AsyncValue.loading();
    try {
      final functions = _ref.read(firebaseFunctionsProvider);
      final callable = functions.httpsCallable('getServerTime');
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>?;
      final serverMillis = data?['now'] as int?;
      if (serverMillis == null) {
        state = const AsyncValue.data(Duration.zero);
        return;
      }
      final localMillis = DateTime.now().millisecondsSinceEpoch;
      final offsetMillis = serverMillis - localMillis;
      state = AsyncValue.data(Duration(milliseconds: offsetMillis));
    } on Object catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final timerServiceProvider =
    StateNotifierProvider<TimerService, AsyncValue<Duration>>((ref) {
      return TimerService(ref);
    });
