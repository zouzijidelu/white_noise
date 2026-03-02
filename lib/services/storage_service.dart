import 'package:shared_preferences/shared_preferences.dart';

/// 基于 shared_preferences 的本地存储封装
class StorageService {
  StorageService._();
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  SharedPreferences get _store {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call getInstance() first.');
    }
    return _prefs!;
  }

  Future<bool> setInt(String key, int value) => _store.setInt(key, value);
  int? getInt(String key) => _store.getInt(key);

  Future<bool> setString(String key, String value) => _store.setString(key, value);
  String? getString(String key) => _store.getString(key);

  Future<bool> setBool(String key, bool value) => _store.setBool(key, value);
  bool? getBool(String key) => _store.getBool(key);

  Future<bool> remove(String key) => _store.remove(key);
  Future<bool> clear() => _store.clear();
}
