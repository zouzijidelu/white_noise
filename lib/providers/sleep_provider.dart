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

  void setTimerMinutes(int minutes) {
    if (_timerMinutes == minutes) return;
    _timerMinutes = minutes.clamp(1, 120);
    notifyListeners();
  }

  /// 播放或停止指定音效（先缓存再播放，已缓存则直接播）
  Future<void> toggleAudio(Map<String, dynamic> audio) async {
    final id = audio['id'] as int?;
    final path = audio['audio_file'] as String?;
    if (id == null || path == null || path.isEmpty) return;

    if (_playingAudioId == id) {
      await _audio.stop();
      _playingAudioId = null;
      notifyListeners();
      return;
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
    await _audio.playFile(localPath);
    _playingAudioId = id;
    notifyListeners();
  }

  void stopPlayback() {
    _audio.stop();
    _playingAudioId = null;
    notifyListeners();
  }
}
