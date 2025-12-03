// Web implementation using dart:html localStorage.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? getItem(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void setItem(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

void removeItem(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}


