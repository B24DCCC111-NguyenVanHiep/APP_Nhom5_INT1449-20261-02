// FILE NÀY ĐỂ LÀM GÌ: Bản lưu trữ web dạng localStorage cho trình duyệt Chrome.
// Người phụ trách: Người 2 (Database)

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? getStorageItem(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void setStorageItem(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

void removeStorageItem(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}
