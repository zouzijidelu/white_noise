import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

/// 冥想课程模型
class MeditationCourse {
  MeditationCourse({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.intro,
    required this.desc,
    required this.audioFile,
    required this.duration,
    this.status = 1,
    this.sort = 0,
  });

  final int id;
  final String title;
  final String thumbnail;
  final String intro;
  final String desc;
  final String audioFile;
  final int duration; // 时长（秒）
  final int status;
  final int sort;

  String get fullThumbnailUrl => ApiConstants.resourceUrl(thumbnail);

  String get fullAudioUrl => ApiConstants.resourceUrl(audioFile);

  factory MeditationCourse.fromJson(Map<String, dynamic> json) {
    return MeditationCourse(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      audioFile: json['audio_file'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      status: json['status'] as int? ?? 1,
      sort: json['sort'] as int? ?? 0,
    );
  }
}

/// 冥想详情模型
class MeditationDetail extends MeditationCourse {
  MeditationDetail({
    required super.id,
    required super.title,
    required super.thumbnail,
    required super.intro,
    required super.desc,
    required super.audioFile,
    required super.duration,
    super.status = 1,
    super.sort = 0,
    this.content = '',
    this.tags = const [],
  });

  final String content; // 详细内容
  final List<String> tags; // 标签列表

  factory MeditationDetail.fromJson(Map<String, dynamic> json) {
    return MeditationDetail(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      audioFile: json['audio_file'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      status: json['status'] as int? ?? 1,
      sort: json['sort'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// 冥想页状态管理
class MeditationProvider extends ChangeNotifier {
  MeditationProvider({
    required ApiService apiService,
    required AudioService audioService,
  }) : _api = apiService,
       _audio = audioService;

  final ApiService _api;
  final AudioService _audio;

  // 冥想列表相关状态
  List<MeditationCourse> _meditationList = [];

  List<MeditationCourse> get meditationList => _meditationList;

  // 当前选中的冥想课程
  MeditationCourse? _selectedCourse;

  MeditationCourse? get selectedCourse => _selectedCourse;

  // 冥想详情
  MeditationDetail? _meditationDetail;

  MeditationDetail? get meditationDetail => _meditationDetail;

  // 播放状态
  bool _isPlaying = false;
  
  bool get isPlaying => _isPlaying;
  
  // 跟踪实际正在播放的课程 ID（用于判断是否需要停止）
  int? _playingCourseId;
  
  int? get playingCourseId => _playingCourseId;

  bool _preparing = false;
  
  bool get preparing => _preparing;

  // 加载状态
  bool _loadingList = false;

  bool get loadingList => _loadingList;

  bool _loadingDetail = false;

  bool get loadingDetail => _loadingDetail;

  // 错误信息
  String? _error;

  String? get error => _error;

  /// 加载冥想列表
  Future<void> loadMeditationList() async {
    if (_loadingList) return;
    _loadingList = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getMeditationList();
      if (res.isSuccess && res.data != null) {
        _meditationList =
            res.data!
                .map(
                  (item) =>
                      MeditationCourse.fromJson(item as Map<String, dynamic>),
                )
                .toList()
              ..sort((a, b) => a.sort.compareTo(b.sort));
      } else {
        _error = res.msg;
      }
    } catch (e, st) {
      _error = networkErrorMessage(e);
      debugPrint('MeditationProvider loadMeditationList: $e $st');
    } finally {
      _loadingList = false;
      notifyListeners();
    }
  }

  /// 加载冥想详情
  Future<void> loadMeditationDetail(int courseId) async {
    if (_loadingDetail) return;
    _loadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getMeditationDetail(courseId);
      if (res.isSuccess && res.data != null) {
        _meditationDetail = MeditationDetail.fromJson(
          res.data as Map<String, dynamic>,
        );

        // 同时更新选中的课程（但不停止播放）
        final course = _meditationList.firstWhere(
          (c) => c.id == courseId,
          orElse: () => _meditationDetail!,
        );
        _selectedCourse = course;
      } else {
        _error = res.msg;
      }
    } catch (e, st) {
      _error = networkErrorMessage(e);
      debugPrint('MeditationProvider loadMeditationDetail: $e $st');
    } finally {
      _loadingDetail = false;
      notifyListeners();
    }
  }

  /// 选择冥想课程（仅更新选中状态）
  void selectCourse(MeditationCourse course) {
    _selectedCourse = course;
    notifyListeners();
  }

  /// 播放指定课程（会先停止当前播放）
  Future<void> playCourse(MeditationCourse course) async {
    // 如果切换了课程，先停止当前播放
    if (_playingCourseId != null && _playingCourseId != course.id) {
      await stop();
    }
    
    _selectedCourse = course;
    notifyListeners();
    
    await play();
  }

  /// 播放冥想音频
  Future<void> play() async {
    if (_selectedCourse == null) return;

    // 如果当前课程已经在播放中，直接返回
    if (_isPlaying && _playingCourseId == _selectedCourse!.id) return;

    _preparing = true;
    notifyListeners();

    try {
      final url = _selectedCourse!.fullAudioUrl;
      
      // 如果是同一个课程只是暂停了，则恢复播放
      if (_playingCourseId == _selectedCourse!.id && !_isPlaying) {
        await resume();
      } else {
        // 否则从头播放
        await _audio.play(url, isAsset: false);
        _isPlaying = true;
        _playingCourseId = _selectedCourse!.id;
      }
    } catch (e, st) {
      _error = networkErrorMessage(e);
      debugPrint('MeditationProvider play: $e $st');
    } finally {
      _preparing = false;
      notifyListeners();
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    await _audio.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    await _audio.resume();
    _isPlaying = true;
    notifyListeners();
  }

  /// 停止播放
  Future<void> stop() async {
    await _audio.stop();
    _isPlaying = false;
    _playingCourseId = null; // 清除正在播放的课程 ID
    notifyListeners();
  }

  /// 暂停/继续播放
  Future<void> togglePlay() async {
    if (_selectedCourse == null) return;

    // 如果正在播放，则暂停
    if (_isPlaying) {
      await pause();
    } else {
      // 已暂停，恢复播放
      await resume();
    }
  }

  /// 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _meditationList = [];
    _selectedCourse = null;
    _meditationDetail = null;
    _isPlaying = false;
    _preparing = false;
    _loadingList = false;
    _loadingDetail = false;
    _error = null;
    notifyListeners();
  }
}

/// 网络错误消息处理函数
String networkErrorMessage(Object e, [String fallback = '请求失败，请重试']) {
  if (e is ApiException) {
    if (e.statusCode != null && e.statusCode! >= 500) return '服务器异常，请稍后重试';
    if (e.statusCode != null && e.statusCode! == 404) return '接口不存在';
    return e.message ?? fallback;
  }
  final msg = e.toString().toLowerCase();
  if (msg.contains('socket') ||
      msg.contains('host lookup') ||
      msg.contains('nodename') ||
      msg.contains('servname') ||
      msg.contains('connection')) {
    return '网络异常，请检查网络连接后重试';
  }
  if (msg.contains('timeout') || msg.contains('timed out')) {
    return '连接超时，请重试';
  }
  return fallback;
}

/// API异常类
class ApiException implements Exception {
  ApiException({this.statusCode, this.message, this.body});

  final int? statusCode;
  final String? message;
  final String? body;

  @override
  String toString() =>
      'ApiException: $message (statusCode: $statusCode, body: $body)';
}
