import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'package:on_chain_bridge/web/api/api.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/storage/storage/chrome_storage.dart';
import 'package:on_chain_bridge/web/storage/storage/index_db_storage.dart';
import 'package:on_chain_bridge/web/storage/storage/web_storage.dart';
import 'package:on_chain_bridge/web/storage/constant/constant.dart';

import 'storage_item.dart';

class SafestorageUtils {
  static String encrypt(List<int> value, ChaCha20Poly1305 chacha) {
    final nonce = QuickCrypto.generateRandom(8);
    final encryptedValue = chacha.encrypt(nonce, value);
    final storage = StorageItem(nonce: nonce, encryptedValue: encryptedValue);
    return storage.toCbor().toCborHex();
  }

  static String? decrypt(String encryptedValue, ChaCha20Poly1305 chacha) {
    try {
      final item = StorageItem.fromStorage(encryptedValue);
      final decode = chacha.decrypt(item.nonce, item.encryptedValue);
      return StringUtils.tryDecode(decode);
    } catch (e) {
      return null;
    }
  }

  static (String, ChaCha20Poly1305) getOrCreateKey({String? key}) {
    final toBytes = BytesUtils.tryFromHexString(key);
    if (toBytes != null && toBytes.length == StorageConst.keyLength) {
      return (key!, ChaCha20Poly1305(toBytes));
    }
    final newKey = QuickCrypto.generateRandom(32);
    return (BytesUtils.toHexString(newKey), ChaCha20Poly1305(newKey));
  }

  static Future<void> migrateDatabase(
      {required SafeStorage newDb, required SafeStorage oldDb}) async {
    final data = await oldDb.all();
    for (final i in data.entries) {
      await newDb.save(i.key, i.value);
    }
    await oldDb.clear();
  }
}

abstract class SafeStorage {
  final ChaCha20Poly1305 _chacha;
  const SafeStorage(this._chacha);
  static Future<SafeStorage> getOldDb() async {
    if (isExtension) {
      return ChromeStorage.init();
    }
    return WebStorage.init();
  }

  static Future<IndexDbStorage?> init() async {
    if (indexedDB == null) return null;
    final key = await IndexDbStorage.init();
    return key.$1;
  }

  Future<void> clear();
  Future<void> save(String key, String value);
  Future<String?> read(String key);
  Future<String?> getItem(String key);
  Future<void> setItem(String key, String value);
  Future<Map<String, String>> reads(List<String> keys);
  Future<Map<String, String>> all({String? prefix});
  Future<List<String>> readKeys({String? prefix});
  Future<void> remove(String key);
  Future<void> removes(List<String> keys);
  String encrypt(String value) {
    return SafestorageUtils.encrypt(StringUtils.encode(value), _chacha);
  }

  String? decrypt(String encryptedValue) {
    return SafestorageUtils.decrypt(encryptedValue, _chacha);
  }
}
