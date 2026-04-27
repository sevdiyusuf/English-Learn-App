// Stub implementation used on non-web platforms (and during tests).
// This acts as an in-memory storage for testing purposes.

final Map<String, String> _memoryStorage = {};

String? getItem(String key) => _memoryStorage[key];

void setItem(String key, String value) {
  _memoryStorage[key] = value;
}

void removeItem(String key) {
  _memoryStorage.remove(key);
}

// Helper for testing
void clearStorage() {
  _memoryStorage.clear();
}

String? getAppStartUrl() => null;
