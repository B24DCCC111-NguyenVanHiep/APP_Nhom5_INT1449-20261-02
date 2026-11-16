// FILE NÀY ĐỂ LÀM GÌ: Cầu nối điều hướng lưu trữ web tương thích đa nền tảng.
// Người phụ trách: Người 2 (Database)

import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart' as storage;

String? getWebStorage(String key) => storage.getStorageItem(key);
void setWebStorage(String key, String value) =>
    storage.setStorageItem(key, value);
void removeWebStorage(String key) => storage.removeStorageItem(key);
