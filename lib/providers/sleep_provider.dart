import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../services/api_service.dart';
import '../services/audio_cache_service.dart';
import '../services/audio_service.dart';

/// 睡眠页状态：分类与音效列表、当前选中分类、定时时长、正在播放的音效
class SleepProvider extends ChangeNotifier {
  SleepProvider({
    required ApiService apiService,
    required AudioService audioService,
    required AudioCacheService audioCacheService,
  })  : _api = apiService,
        _audio = audioService,
        _cache = audioCacheService;

  final ApiService _api;
  final AudioService _audio;
  final AudioCacheService _cache;

  /// 所有分类及音效（来自 getCateDetailList）
  List<Map<String, dynamic>> _cateDetailList = [];
  List<Map<String, dynamic>> get cateDetailList => _cateDetailList;

  /// 当前选中的分类 id
  int? _selectedCateId;
  int? get selectedCateId => _selectedCateId;

  /// 定时时长（分钟）
  int _timerMinutes = 15;
  int get timerMinutes => _timerMinutes;

  /// 倒计时剩余秒数（0 表示未开始或已结束）
  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  Timer? _countdownTimer;

  /// 当前播放中的音效 id
  int? _playingAudioId;
  int? get playingAudioId => _playingAudioId;

  /// 正在加载/缓存的音效 id（显示加载圈）
  int? _loadingAudioId;
  int? get loadingAudioId => _loadingAudioId;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  /// 当前选中分类下的音效列表
  List<Map<String, dynamic>> get currentAudios {
    if (_selectedCateId == null) return [];
    for (final cate in _cateDetailList) {
      if (cate['id'] == _selectedCateId) {
        final audios = cate['audios'];
        if (audios is List) {
          return audios.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
        }
        return [];
      }
    }
    return [];
  }

  /// 加载分类与音效详情
  Future<void> loadData() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.getCateDetailList();
      if (res.isSuccess && res.data != null) {
        _cateDetailList = res.data!
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .toList();
        if (_cateDetailList.isNotEmpty && _selectedCateId == null) {
          _selectedCateId = _cateDetailList.first['id'] as int?;
        }
      } else {
        _error = res.msg;
      }
    } catch (e, st) {
      _error = networkErrorMessage(e);
      debugPrint('SleepProvider loadData: $e $st');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectCategory(int cateId) {
    if (_selectedCateId == cateId) return;
    _selectedCateId = cateId;
    notifyListeners();
  }

  /// 设置定时时长；若当前已有倒计时在进行，则按新时长重新倒计时
  void setTimerMinutes(int minutes) {
    final next = minutes.clamp(1, 120);
    if (_timerMinutes == next) return;
    _timerMinutes = next;
    if (_remainingSeconds > 0) {
      _remainingSeconds = _timerMinutes * 60;
    }
    notifyListeners();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickCountdown());
  }

  void _tickCountdown() {
    if (_remainingSeconds <= 0) return;
    _remainingSeconds--;
    if (_remainingSeconds <= 0) {
      _stopCountdownTimer();
      _audio.stop();
      _playingAudioId = null;
    }
    notifyListeners();
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// 播放或停止指定音效（先缓存再播放，已缓存则直接播）
  /// 点击播放开启倒计时；手动暂停只停播放，倒计时继续；切换音频倒计时继续
  Future<void> toggleAudio(Map<String, dynamic> audio) async {
    final id = audio['id'] as int?;
    final path = audio['audio_file'] as String?;
    if (id == null || path == null || path.isEmpty) return;

    if (_playingAudioId == id) {
      // 手动暂停：只停止播放，倒计时继续
      await _audio.stop();
      _playingAudioId = null;
      notifyListeners();
      return;
    }

    // 开始播放或切换音频：若尚未开始倒计时则开启，否则倒计时继续
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _timerMinutes * 60;
      _startCountdownTimer();
    }

    final url = ApiConstants.resourceUrl(path);
    String localPath;
    final cached = await _cache.getCachedPath(url);
    if (cached != null) {
      localPath = cached;
    } else {
      _loadingAudioId = id;
      notifyListeners();
      try {
        localPath = await _cache.downloadToCache(url);
      } catch (e) {
        _loadingAudioId = null;
        notifyListeners();
        rethrow;
      }
      _loadingAudioId = null;
      notifyListeners();
    }
    final title = audio['title'] as String? ?? '环境音';
    await _audio.playFile(localPath, title: title);
    _playingAudioId = id;
    notifyListeners();
  }

  void stopPlayback() {
    _stopCountdownTimer();
    _remainingSeconds = 0;
    _audio.stop();
    _playingAudioId = null;
    notifyListeners();
  }
}
