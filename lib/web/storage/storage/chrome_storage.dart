import 'dart:async';
import 'package:on_chain_bridge/web/api/chrome/chrome.dart';
import 'package:on_chain_bridge/web/storage/safe_storage/safestorage.dart';
import 'package:on_chain_bridge/web/storage/constant/constant.dart';

class ChromeStorage extends SafeStorage {
  ChromeStorage._(super.chacha);
  static Future<ChromeStorage> init() async {
    final keyHex = await extension.storage.local.getStorage_(StorageConst.key);
    final key = SafestorageUtils.getOrCreateKey(key: keyHex);
    if (key.$1 != keyHex) {
      await extension.storage.local.setStorage_(StorageConst.key, key.$1);
    }
    return ChromeStorage._(key.$2);
  }

  //
  StorageArea get _storage => extension.storage.local;
  @override
  Future<void> clear() async {
    await _storage.clear_();
    final key = SafestorageUtils.getOrCreateKey();
    await setItem(StorageConst.key, key.$1);
  }

  @override
  Future<String?> read(String key) async {
    if (key == StorageConst.key) return null;
    final value = await _storage.getStorage_(key);
    if (value != null) {
      return decrypt(value);
    }
    return null;
  }

  @override
  Future<Map<String, String>> reads(List<String> keys) async {
    keys = keys.where((e) => e != StorageConst.key).toList();
    final items = await _storage.getMultipleStorage_(keys);
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
    await _storage.remove_(key);
  }

  @override
  Future<void> removes(List<String> keys) async {
    keys = keys.where((e) => e != StorageConst.key).toList();
    await _storage.removeMultiple_(keys);
  }

  @override
  Future<void> save(String key, String value) async {
    if (key == StorageConst.key) return;
    final encryptValue = encrypt(value);
    await _storage.setStorage_(key, encryptValue);
  }

  @override
  Future<Map<String, String>> all({String? prefix}) async {
    Map<String, String> items = await _storage.getAll_();
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
    List<String> items = (await _storage.getAll_()).keys.toList();
    items.remove(StorageConst.key);
    if (prefix == null || prefix.isEmpty) {
      return items;
    }
    return items.where((e) => e.startsWith(prefix)).toList();
  }

  @override
  Future<String?> getItem(String key) async {
    return await _storage.getStorage_(key);
  }

  @override
  Future<void> setItem(String key, String value) async {
    await _storage.setStorage_(key, value);
  }
}
