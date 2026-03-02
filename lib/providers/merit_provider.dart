import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

/// 功德（木鱼）状态，持久化到本地
class MeritProvider extends ChangeNotifier {
  MeritProvider({required StorageService storage}) : _storage = storage {
    _load();
  }

  final StorageService _storage;

  static const String _keyTotalMeritCount = 'merit_count'; // 总功德数
  static const String _keySessionCount = 'session_count'; // 本次启动点击次数

  int _totalCount = 0; // 总功德数（持久化）
  int _sessionCount = 0; // 本次启动点击次数（临时）

  // 总功德数 getter
  int get totalCount => _totalCount;
  
  // 本次启动点击次数 getter
  int get sessionCount => _sessionCount;

  void _load() {
    // 加载总功德数
    _totalCount = _storage.getInt(_keyTotalMeritCount) ?? 0;
    // 本次启动次数初始化为0
    _sessionCount = 0;
    notifyListeners();
  }

  Future<void> increment() async {
    // 增加总功德数
    _totalCount++;
    // 增加本次启动点击次数
    _sessionCount++;
    
    notifyListeners();
    
    // 只持久化总功德数
    await _storage.setInt(_keyTotalMeritCount, _totalCount);
  }

  Future<void> reset() async {
    // 重置总功德数
    _totalCount = 0;
    // 重置本次启动点击次数
    _sessionCount = 0;
    
    notifyListeners();
    
    // 持久化重置
    await _storage.setInt(_keyTotalMeritCount, 0);
  }

  // 仅重置本次启动次数（不清除总功德）
  void resetSessionCount() {
    _sessionCount = 0;
    notifyListeners();
  }
}
