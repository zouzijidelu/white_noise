import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../services/api_service.dart';
import '../services/audio_cache_service.dart';
import '../services/audio_service.dart';

/// 单个已选音效（用于混音）：id、标题、音频路径、音量
class SelectedDiyAudio {
  SelectedDiyAudio({
    required this.id,
    required this.title,
    required this.audioFile,
    this.volume = 0.5,
  });

  final int id;
  final String title;
  final String audioFile;
  double volume;

  String get fullUrl => ApiConstants.resourceUrl(audioFile);
}

/// DIY 页状态：分类与音效、已选最多 3 个、混音播放
class DiyProvider extends ChangeNotifier {
  DiyProvider({
    required ApiService apiService,
    required AudioService audioService,
    required AudioCacheService audioCacheService,
  })  : _api = apiService,
        _audio = audioService,
        _cache = audioCacheService;

  final ApiService _api;
  final AudioService _audio;
  final AudioCacheService _cache;

  static const int maxMixCount = 3;

  List<Map<String, dynamic>> _cateDetailList = [];
  List<Map<String, dynamic>> get cateDetailList => _cateDetailList;

  int? _selectedCateId;
  int? get selectedCateId => _selectedCateId;

  final List<SelectedDiyAudio> _selectedAudios = [];
  List<SelectedDiyAudio> get selectedAudios => List.unmodifiable(_selectedAudios);

  bool _isPlayingMix = false;
  bool get isPlayingMix => _isPlayingMix;

  /// 正在准备混音（缓存中），显示加载圈
  bool _preparingMix = false;
  bool get preparingMix => _preparingMix;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<Map<String, dynamic>> get currentAudios {
    if (_selectedCateId == null) return [];
    for (final cate in _cateDetailList) {
      if (cate['id'] == _selectedCateId) {
        final audios = cate['audios'];
        if (audios is List) {
          return audios
              .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList();
        }
        return [];
      }
    }
    return [];
  }

  int get currentAudiosCount => currentAudios.length;

  /// 是否已选中某音效（按 id）
  bool isSelected(int audioId) => _selectedAudios.any((a) => a.id == audioId);

  /// 获取已选音效的音量
  double getVolumeFor(int audioId) {
    final found = _selectedAudios.firstWhere(
      (a) => a.id == audioId,
      orElse: () => SelectedDiyAudio(id: -1, title: '', audioFile: ''),
    );
    return found.id >= 0 ? found.volume : 0.5;
  }

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
      debugPrint('DiyProvider loadData: $e $st');
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

  /// 切换音效选中：若已在列表中则移除；否则若未满 3 个则加入，满则返回 false（由 UI 弹窗）
  bool toggleSelection(Map<String, dynamic> audio) {
    final id = audio['id'] as int?;
    final title = audio['title'] as String? ?? '';
    final path = audio['audio_file'] as String? ?? '';
    if (id == null || path.isEmpty) return true;

    final index = _selectedAudios.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _selectedAudios.removeAt(index);
      notifyListeners();
      return true;
    }
    if (_selectedAudios.length >= maxMixCount) {
      return false;
    }
    _selectedAudios.add(SelectedDiyAudio(
      id: id,
      title: title,
      audioFile: path,
      volume: 0.5,
    ));
    notifyListeners();
    return true;
  }

  void setVolume(int audioId, double volume) {
    final v = volume.clamp(0.0, 1.0);
    for (final a in _selectedAudios) {
      if (a.id == audioId) {
        a.volume = v;
        break;
      }
    }
    if (_isPlayingMix) {
      final idx = _selectedAudios.indexWhere((a) => a.id == audioId);
      if (idx >= 0) _audio.setMixVolume(idx, v);
    }
    notifyListeners();
  }

  Future<void> playMix() async {
    if (_selectedAudios.isEmpty) return;
    _preparingMix = true;
    notifyListeners();
    try {
      final paths = <String>[];
      for (final a in _selectedAudios) {
        final url = a.fullUrl;
        final cached = await _cache.getCachedPath(url);
        if (cached != null) {
          paths.add(cached);
        } else {
          paths.add(await _cache.downloadToCache(url));
        }
      }
      final volumes = _selectedAudios.map((a) => a.volume).toList();
      await _audio.startMixFromFiles(paths, volumes);
      _isPlayingMix = true;
    } finally {
      _preparingMix = false;
      notifyListeners();
    }
  }

  Future<void> stopMix() async {
    await _audio.stopMix();
    _isPlayingMix = false;
    notifyListeners();
  }
}
