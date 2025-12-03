// Stub implementation used on non-web platforms.
// This avoids importing any web-only libraries when building for mobile/desktop.

String? getItem(String key) => null;

void setItem(String key, String value) {}

void removeItem(String key) {}


