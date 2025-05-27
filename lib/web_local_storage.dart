// lib/web_local_storage.dart
import 'dart:html' as html;

/// Зберігає значення у локальному сховищі браузера
void setItem(String key, String value) {
  html.window.localStorage[key] = value;
}

/// Отримує значення з локального сховища браузера
String? getItem(String key) {
  return html.window.localStorage[key];
}