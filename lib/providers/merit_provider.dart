import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

/// 功德（木鱼）状态，持久化到本地
class MeritProvider extends ChangeNotifier {
  MeritProvider({required StorageService storage}) : _storage = storage {
    _load();
  }

  final StorageService _storage;

  static const String _keyMeritCount = 'merit_count';

  int _count = 0;
  int get count => _count;

  void _load() {
    _count = _storage.getInt(_keyMeritCount) ?? 0;
    notifyListeners();
  }

  Future<void> increment() async {
    _count++;
    notifyListeners();
    await _storage.setInt(_keyMeritCount, _count);
  }

  Future<void> reset() async {
    _count = 0;
    notifyListeners();
    await _storage.setInt(_keyMeritCount, 0);
  }
}
