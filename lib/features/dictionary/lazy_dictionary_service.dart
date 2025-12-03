import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dictionary_service.dart';

/// Lazy-loading wrapper for DictionaryService
/// Loads the dictionary service in the background and provides it when ready
class LazyDictionaryService implements DictionaryService {
  LazyDictionaryService._(this._loadFunction);

  final Future<DictionaryService> Function() _loadFunction;
  DictionaryService? _service;
  Future<DictionaryService>? _loadingFuture;
  final Completer<DictionaryService> _readyCompleter =
      Completer<DictionaryService>();

  /// Factory method to create a lazy dictionary service
  static LazyDictionaryService create(
    Future<DictionaryService> Function() loadFunction,
  ) {
    final service = LazyDictionaryService._(loadFunction);
    // Start loading in the background
    service._startLoading();
    return service;
  }

  /// Start loading the dictionary service in the background
  void _startLoading() {
    if (_loadingFuture != null) {
      return; // Already loading
    }

    if (kDebugMode) {
      debugPrint('Starting background dictionary loading...');
    }

    // Create the future immediately to prevent race conditions
    // This ensures _loadingFuture is never null after this function returns
    _loadingFuture = _loadFunction()
        .then((service) {
          _service = service;
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.complete(service);
          }
          if (kDebugMode) {
            debugPrint('Dictionary service loaded successfully');
          }
          return service;
        })
        .catchError((error, stackTrace) {
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.completeError(error, stackTrace);
          }
          if (kDebugMode) {
            debugPrint('Error loading dictionary service: $error');
          }
          // Don't rethrow here - let the future complete with error
          // The caller can catch it
          throw error;
        });

    // At this point, _loadingFuture is guaranteed to be non-null
    // Even if _loadFunction() throws synchronously, the future will be set
    // before any await can happen
  }

  /// Ensure the dictionary service is loaded
  Future<DictionaryService> _ensureLoaded() async {
    // Safe access - check if service is already loaded
    final currentService = _service;
    if (currentService != null) {
      return currentService;
    }

    // If loading is already in progress, wait for it
    final currentLoadingFuture = _loadingFuture;
    if (currentLoadingFuture != null) {
      try {
        return await currentLoadingFuture;
      } catch (e) {
        // If loading failed, clear it and try again
        if (kDebugMode) {
          debugPrint('Previous loading failed, will retry: $e');
        }
        // Only clear if it's still the same future (not overwritten)
        if (_loadingFuture == currentLoadingFuture) {
          _loadingFuture = null;
        }
        // Fall through to start new loading
      }
    }

    // Start loading if not started
    // _startLoading() guarantees _loadingFuture is set before returning
    _startLoading();

    // _loadingFuture is guaranteed to be non-null after _startLoading()
    final loadingFuture = _loadingFuture;
    if (loadingFuture == null) {
      // This should never happen, but handle it safely for iOS Safari
      throw StateError('Failed to start dictionary loading - future is null');
    }

    return await loadingFuture;
  }

  /// Check if the dictionary service is ready
  bool get isReady => _service != null;

  /// Get a future that completes when the dictionary is ready
  Future<DictionaryService> get ready => _readyCompleter.future;

  @override
  Future<bool> validateWord({
    required String word,
    required String type,
  }) async {
    final service = await _ensureLoaded();
    return service.validateWord(word: word, type: type);
  }
}
