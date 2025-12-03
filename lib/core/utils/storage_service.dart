import 'package:flutter/foundation.dart';

import 'browser_storage_stub.dart'
    if (dart.library.html) 'browser_storage_web.dart';

/// Storage service for persisting data across page refreshes
class StorageService {
  static const String _keyUsername = 'venividi_username';
  static const String _keyRoomId = 'venividi_room_id';
  static const String _keyRoomCode = 'venividi_room_code';

  /// Save username to storage
  static Future<void> saveUsername(String username) async {
    if (kIsWeb) {
      try {
        setItem(_keyUsername, username);
      } catch (e) {
        debugPrint('Error saving username: $e');
      }
    }
  }

  /// Get saved username from storage
  static String? getUsername() {
    if (kIsWeb) {
      try {
        final value = getItem(_keyUsername);
        // Return null if empty string (iOS Safari might return empty string)
        return value != null && value.isNotEmpty ? value : null;
      } catch (e) {
        // On iOS Safari, localStorage might not be available (private mode, etc.)
        debugPrint('Error getting username: $e');
        return null;
      }
    }
    return null;
  }

  /// Save room ID to storage
  static Future<void> saveRoomId(String roomId) async {
    if (kIsWeb) {
      try {
        setItem(_keyRoomId, roomId);
      } catch (e) {
        debugPrint('Error saving room ID: $e');
      }
    }
  }

  /// Get saved room ID from storage
  static String? getRoomId() {
    if (kIsWeb) {
      try {
        final value = getItem(_keyRoomId);
        // Return null if empty string (iOS Safari might return empty string)
        return value != null && value.isNotEmpty ? value : null;
      } catch (e) {
        // On iOS Safari, localStorage might not be available (private mode, etc.)
        debugPrint('Error getting room ID: $e');
        return null;
      }
    }
    return null;
  }

  /// Save room code to storage
  static Future<void> saveRoomCode(String roomCode) async {
    if (kIsWeb) {
      try {
        setItem(_keyRoomCode, roomCode);
      } catch (e) {
        debugPrint('Error saving room code: $e');
      }
    }
  }

  /// Get saved room code from storage
  static String? getRoomCode() {
    if (kIsWeb) {
      try {
        final value = getItem(_keyRoomCode);
        // Return null if empty string (iOS Safari might return empty string)
        return value != null && value.isNotEmpty ? value : null;
      } catch (e) {
        // On iOS Safari, localStorage might not be available (private mode, etc.)
        debugPrint('Error getting room code: $e');
        return null;
      }
    }
    return null;
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    if (kIsWeb) {
      try {
        removeItem(_keyUsername);
        removeItem(_keyRoomId);
        removeItem(_keyRoomCode);
      } catch (e) {
        debugPrint('Error clearing storage: $e');
      }
    }
  }

  /// Clear room data only
  static Future<void> clearRoomData() async {
    if (kIsWeb) {
      try {
        removeItem(_keyRoomId);
        removeItem(_keyRoomCode);
      } catch (e) {
        debugPrint('Error clearing room data: $e');
      }
    }
  }
}

