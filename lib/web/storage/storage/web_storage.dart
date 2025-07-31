import 'package:on_chain_bridge/web/api/mozila/api/storage.dart';
import 'package:on_chain_bridge/web/storage/safe_storage/safestorage.dart';
import 'package:on_chain_bridge/web/storage/constant/constant.dart';

class WebStorage extends SafeStorage {
  const WebStorage._(super._chacha);
  static Future<WebStorage> init() async {
    final keyHex = localStorage.getItem(StorageConst.key);
    final key = SafestorageUtils.getOrCreateKey(key: keyHex);
    if (key.$1 != keyHex) {
      localStorage.setItem(StorageConst.key, key.$1);
    }
    return WebStorage._(key.$2);
  }

  @override
  Future<void> clear() async {
    localStorage.clear();
    final key = SafestorageUtils.getOrCreateKey();
    localStorage.setItem(StorageConst.key, key.$1);
  }

  @override
  Future<String?> read(String key) async {
    if (key == StorageConst.key) return null;
    final value = localStorage.getItem(key);
    if (value != null) {
      return decrypt(value);
    }
    return null;
  }

  @override
  Future<Map<String, String>> reads(List<String> keys) async {
    keys = keys.where((e) => e != StorageConst.key).toList();
    final items = localStorage.getItems(keys);
    final Map<String, String> decryptedData = {};
    for (final i in items.entries) {
      final decryptValue = decrypt(i.value);
      if (decryptValue != null) {
        decryptedData[i.key] = decryptValue;
      }
    }
    return decryptedData;
  }

  @override
  Future<void> remove(String key) async {
    if (key == StorageConst.key) return;
    localStorage.removeItem(key);
  }

  @override
  Future<void> removes(List<String> keys) async {
    keys = keys.where((e) => e != StorageConst.key).toList();
    localStorage.removeItems(keys);
  }

  @override
  Future<void> save(String key, String value) async {
    if (key == StorageConst.key) return;
    final encryptValue = encrypt(value);
    localStorage.setItem(key, encryptValue);
  }

  @override
  Future<Map<String, String>> all({String? prefix}) async {
    Map<String, String> items = localStorage.getAll();
    items.remove(StorageConst.key);
    if (prefix != null) {
      items = items..removeWhere((k, v) => !k.startsWith(prefix));
    }
    final Map<String, String> decryptedData = {};
    for (final i in items.entries) {
      final decryptValue = decrypt(i.value);
      if (decryptValue != null) {
        decryptedData[i.key] = decryptValue;
      }
    }
    return decryptedData;
  }

  @override
  Future<List<String>> readKeys({String? prefix}) async {
    List<String> items = localStorage.getAll().keys.toList();
    items.remove(StorageConst.key);
    if (prefix == null || prefix.isEmpty) {
      return items;
    }
    return items.where((e) => e.startsWith(prefix)).toList();
  }

  @override
  Future<String?> getItem(String key) async {
    return localStorage.getItem(key);
  }

  @override
  Future<void> setItem(String key, String value) async {
    localStorage.setItem(key, value);
  }
}
