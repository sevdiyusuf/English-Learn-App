import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_environment.dart';
import '../core/performance/performance_service.dart';
import '../core/services/app_check_service.dart';
import '../core/telemetry/telemetry_service.dart';
import '../features/dictionary/dictionary_service.dart';
import '../features/dictionary/lazy_dictionary_service.dart';
import '../firebase_options.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  try {
    return FirebaseAuth.instance;
  } catch (e) {
    // This should never happen if Firebase is initialized, but handle it safely
    throw StateError(
      'FirebaseAuth is not available. Ensure Firebase is initialized: $e',
    );
  }
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  try {
    return FirebaseFirestore.instance;
  } catch (e) {
    // This should never happen if Firebase is initialized, but handle it safely
    throw StateError(
      'Firestore is not available. Ensure Firebase is initialized: $e',
    );
  }
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  try {
    // Use us-central1 region to match Functions deployment
    return FirebaseFunctions.instanceFor(region: 'us-central1');
  } catch (e) {
    // This should never happen if Firebase is initialized, but handle it safely
    throw StateError(
      'FirebaseFunctions is not available. Ensure Firebase is initialized: $e',
    );
  }
});

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  throw UnimplementedError('DictionaryService has not been initialised');
});

class AppBootstrapData {
  AppBootstrapData({required this.dictionaryService});

  final DictionaryService dictionaryService;
}

Future<AppBootstrapData> bootstrapApp() async {
  try {
    // Step 1: Initialize Firebase with better error handling for iOS Safari
    // Check if Firebase is already initialized safely
    bool isFirebaseInitialized = false;
    try {
      // Firebase.apps might throw on iOS Safari if not ready
      final apps = Firebase.apps;
      isFirebaseInitialized = apps.isNotEmpty;
    } catch (e) {
      // If Firebase.apps throws, assume it's not initialized
      if (kDebugMode) {
        debugPrint('Firebase.apps check failed (assuming not initialized): $e');
      }
      isFirebaseInitialized = false;
    }

    if (!isFirebaseInitialized) {
      try {
        // Double-check kIsWeb for iOS Safari compatibility
        if (kIsWeb) {
          if (kDebugMode) {
            debugPrint(
              'Initializing Firebase for web platform (iOS Safari)...',
            );
          }
        }

        // Get Firebase options safely
        FirebaseOptions options;
        try {
          options = DefaultFirebaseOptions.currentPlatform;
          if (kDebugMode) {
            debugPrint('Firebase options retrieved: ${options.projectId}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error getting Firebase options: $e');
          }
          throw Exception('Failed to get Firebase options: $e');
        }

        // Validate options
        if (options.apiKey.isEmpty ||
            options.appId.isEmpty ||
            options.projectId.isEmpty) {
          throw Exception(
            'Firebase options are invalid: apiKey, appId, or projectId is empty',
          );
        }

        // Initialize Firebase
        await Firebase.initializeApp(options: options);
        if (kDebugMode) {
          debugPrint('Firebase initialized successfully');
        }

        // Activate App Check securely
        await AppCheckService.activateAppCheck();

        // Configure Emulators if explicitly enabled
        await AppEnvironment.configureEmulators();

        // Initialize Telemetry and Performance Services
        await TelemetryService.instance.initialize();
        await PerformanceService.instance.initialize();
      } catch (e, stackTrace) {
        // On iOS Safari, Firebase initialization might fail in certain contexts
        if (kDebugMode) {
          debugPrint('Firebase initialization error: $e');
          debugPrint('Error type: ${e.runtimeType}');
          debugPrint('Stack trace: $stackTrace');
        }
        throw Exception('Firebase initialization failed: $e');
      }
    } else {
      if (kDebugMode) {
        debugPrint('Firebase already initialized');
      }
    }

    // Step 2: Get Firestore instance
    FirebaseFirestore firestore;
    try {
      firestore = FirebaseFirestore.instance;
      if (kDebugMode) {
        debugPrint('Firestore instance retrieved');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting Firestore instance: $e');
      }
      throw Exception('Failed to get Firestore instance: $e');
    }

    // Step 3: Configure Firestore settings with error handling
    try {
      firestore.settings = const Settings(persistenceEnabled: true);
      if (kDebugMode) {
        debugPrint('Firestore persistence enabled');
      }
    } catch (e) {
      // On iOS Safari web, persistence might not be supported
      // This is safe to ignore - Firestore will work without persistence
      if (kDebugMode) {
        debugPrint('Firestore persistence not available (non-critical): $e');
      }
    }

    // Step 4: Create lazy dictionary service that loads in the background
    // This doesn't block app startup - dictionary loads asynchronously
    LazyDictionaryService dictionaryService;
    try {
      if (kDebugMode) {
        debugPrint('Creating dictionary service...');
      }
      dictionaryService = LazyDictionaryService.create(createDictionaryService);
      if (kDebugMode) {
        debugPrint('Dictionary service created (loading in background)');
      }
    } catch (e, stackTrace) {
      // If dictionary service creation fails, provide detailed error
      if (kDebugMode) {
        debugPrint('Dictionary service creation error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      throw Exception('Dictionary service creation failed: $e');
    }

    // Step 5: Start loading dictionary in background (non-blocking)
    // The service will be ready when first validation is needed
    dictionaryService.ready.catchError((error, stackTrace) {
      // Log error but don't block app startup
      // Dictionary loading errors will be handled when validation is attempted
      if (kDebugMode) {
        debugPrint('Dictionary loading error (non-blocking): $error');
        debugPrint('Stack trace: $stackTrace');
      }
      TelemetryService.instance.recordNonFatalError(
        error,
        stackTrace: stackTrace,
        reason: 'educational_content_load_corruption',
        attributes: {'feature': 'dictionary', 'stage': 'background_load'},
      );
      // Return the service anyway - it will handle errors gracefully
      return dictionaryService;
    });

    if (kDebugMode) {
      debugPrint('Bootstrap completed successfully');
    }

    return AppBootstrapData(dictionaryService: dictionaryService);
  } catch (e, stackTrace) {
    // Re-throw with more context for debugging
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('Bootstrap error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('========================================');
    }
    // Wrap in Exception to provide consistent error handling
    throw Exception('Bootstrap failed: $e');
  }
}
