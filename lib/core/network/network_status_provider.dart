import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connection status
enum NetworkStatus { connected, disconnected, unknown }

/// Network status provider that monitors connectivity changes
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final connectivity = Connectivity();

  // Initial check
  final controller = StreamController<NetworkStatus>();

  // Check initial status
  connectivity.checkConnectivity().then((result) {
    controller.add(_getNetworkStatus(result));
  });

  // Listen to connectivity changes
  final subscription = connectivity.onConnectivityChanged.listen((result) {
    controller.add(_getNetworkStatus(result));
  });

  // Cleanup
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Convert ConnectivityResult to NetworkStatus
NetworkStatus _getNetworkStatus(List<ConnectivityResult> result) {
  if (result.isEmpty) {
    return NetworkStatus.unknown;
  }

  // Check if any connection type is available
  final hasConnection = result.any((r) => r != ConnectivityResult.none);

  return hasConnection ? NetworkStatus.connected : NetworkStatus.disconnected;
}

/// Simple boolean provider for network connectivity
final isConnectedProvider = Provider<bool>((ref) {
  final networkStatus = ref.watch(networkStatusProvider);
  return networkStatus.maybeWhen(
    data: (status) => status == NetworkStatus.connected,
    orElse: () => true, // Assume connected by default to avoid blocking
  );
});

/// Network status notifier for manual checks
class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  NetworkStatusNotifier() : super(NetworkStatus.unknown) {
    _init();
  }

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> _init() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    state = _getNetworkStatus(result);

    // Listen to changes
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      state = _getNetworkStatus(result);
    });
  }

  Future<void> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    state = _getNetworkStatus(result);
  }

  NetworkStatus _getNetworkStatus(List<ConnectivityResult> result) {
    if (result.isEmpty) {
      return NetworkStatus.unknown;
    }

    final hasConnection = result.any((r) => r != ConnectivityResult.none);

    return hasConnection ? NetworkStatus.connected : NetworkStatus.disconnected;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final networkStatusNotifierProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
      return NetworkStatusNotifier();
    });
