import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/telemetry/telemetry_service.dart';
import 'core/utils/error_logger.dart';
import 'features/dictionary/load_dictionary.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire global crashlytics handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    TelemetryService.instance.recordFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    TelemetryService.instance.recordPlatformError(error, stackTrace);
    return true;
  };

  // --- KRİTİK DEĞİŞİKLİK: Veritabanı (Isar) Başlatma (Force Await) ---
  // Uygulama açılmadan önce veritabanının hazır olmasını bekliyoruz.
  // Bu sayede Deep Link ile gelen kullanıcılar "Isar null" hatası almayacak.
  try {
    debugPrint('🚀 Isar Başlatılıyor (Force Await)...');

    // Web veya Mobil fark etmeksizin Isar'ı başlatmaya zorluyoruz.
    if (kIsWeb) {
      // 5 saniye yerine sadece 200ms bekle, sonra pes et ve devam et
      await openDictionaryStore().timeout(
        const Duration(milliseconds: 200),
        onTimeout: () => throw TimeoutException('Web WASM eksik'),
      );
    } else {
      await openDictionaryStore();
    }

    debugPrint('✅ Isar Başarıyla Başlatıldı!');
  } catch (e) {
    debugPrint('❌ Isar Başlatma Hatası (WASM eksik olabilir): $e');
    // debugPrint('$stack'); // Stack trace'i gizle, kullanıcıyı korkutma
    // Hata olsa bile uygulama açılmaya devam etsin (Sessizce)
  }
  // -----------------------------------------------------

  // Show app immediately with loading state
  final bootstrapFuture = bootstrapApp();

  // Run app with a provider that handles bootstrap
  runApp(
    ProviderScope(
      overrides: [],
      observers: const [],
      child: BootstrapWrapper(bootstrapFuture: bootstrapFuture),
    ),
  );
}

class BootstrapWrapper extends ConsumerStatefulWidget {
  const BootstrapWrapper({required this.bootstrapFuture, super.key});

  final Future<AppBootstrapData> bootstrapFuture;

  @override
  ConsumerState<BootstrapWrapper> createState() => _BootstrapWrapperState();
}

class _BootstrapWrapperState extends ConsumerState<BootstrapWrapper> {
  AppBootstrapData? _bootstrapData;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _loadBootstrap();
  }

  Future<void> _loadBootstrap() async {
    try {
      final data = await widget.bootstrapFuture;
      if (mounted) {
        setState(() {
          _bootstrapData = data;
        });
      }
    } catch (e, st) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: st,
        context: 'Bootstrap Error',
      );
      TelemetryService.instance.recordNonFatalError(
        e,
        stackTrace: st,
        reason: 'bootstrap_failed',
        attributes: {'stage': 'bootstrap'},
      );
      if (mounted) {
        setState(() {
          _error = e;
          _stackTrace = st;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Uygulama başlatılırken hata oluştu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      '$_error',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    if (kDebugMode && _stackTrace != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            'Stack trace:\n$_stackTrace',
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_bootstrapData == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Uygulama başlatılıyor...'),
                if (kIsWeb) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '(Bu ilk yüklemede biraz zaman alabilir)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Bootstrap complete, show the app
    // Safe access - we already checked _bootstrapData is not null above
    final bootstrapData = _bootstrapData;
    if (bootstrapData == null) {
      // This should never happen, but handle it safely for iOS Safari
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Bootstrap data is missing'),
              ],
            ),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        dictionaryServiceProvider.overrideWithValue(
          bootstrapData.dictionaryService,
        ),
      ],
      child: const VeniVidiApp(),
    );
  }
}
