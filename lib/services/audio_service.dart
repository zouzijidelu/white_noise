import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// 基于 audioplayers 的音频播放封装，供环境音/冥想/DIY 混音等使用
class AudioService {
  AudioService() {
    _player = AudioPlayer();
    _player.setPlayerMode(PlayerMode.mediaPlayer);
    _player.setReleaseMode(ReleaseMode.loop);
    _player.onPlayerComplete.listen((_) {
      _currentUrl = null;
    });
    final mixContext = AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    );
    for (var i = 0; i < _maxMix; i++) {
      final p = AudioPlayer();
      p.setPlayerMode(PlayerMode.mediaPlayer);
      p.setReleaseMode(ReleaseMode.loop);
      p.setAudioContext(mixContext);
      _mixPlayers.add(p);
    }
  }

  static const int _maxMix = 3;
  late final AudioPlayer _player;
  final List<AudioPlayer> _mixPlayers = [];
  String? _currentUrl;
  bool _isMixMode = false;
  BaseAudioHandler? _notificationHandler;

  AudioPlayer get player => _player;

  /// 设置通知栏 Handler（由 main 在 audio_service 初始化后调用）
  void setNotificationHandler(BaseAudioHandler handler) {
    _notificationHandler = handler;
  }

  /// 更新通知栏 / 锁屏显示（标题、播放状态）
  void updateMediaNotification(String title) {
    final h = _notificationHandler;
    if (h == null) return;
    h.mediaItem.add(MediaItem(
      id: 'white_noise',
      title: title,
      artist: 'White Noise',
    ));
    h.playbackState.add(PlaybackState(
      controls: [MediaControl.pause, MediaControl.stop],
      processingState: AudioProcessingState.ready,
      playing: true,
    ));
  }

  /// 通知栏点击「播放」时恢复
  Future<void> resumeFromNotification() async {
    if (_isMixMode) {
      for (final p in _mixPlayers) {
        await p.resume();
      }
    } else {
      await _player.resume();
    }
  }

  /// 通知栏点击「暂停」时暂停
  Future<void> pauseFromNotification() async {
    if (_isMixMode) {
      for (final p in _mixPlayers) {
        await p.pause();
      }
    } else {
      await _player.pause();
    }
  }

  /// 通知栏点击「停止」时停止
  Future<void> stopFromNotification() async {
    await _player.stop();
    await stopMix();
    _currentUrl = null;
    _isMixMode = false;
  }

  /// 播放指定资源（asset 或 URL）
  Future<void> play(String source, {bool isAsset = true, String? title}) async {
    await stopMix();
    _isMixMode = false;
    if (_currentUrl == source) return;
    await _player.stop();
    if (isAsset) {
      await _player.play(AssetSource(source));
    } else {
      await _player.play(UrlSource(source));
    }
    _currentUrl = source;
    if (title != null && title.isNotEmpty) {
      updateMediaNotification(title);
    }
  }

  /// 播放本地文件（用于缓存后的音频，全项目复用缓存后均走此路径）
  Future<void> playFile(String path, {String? title}) async {
    await stopMix();
    _isMixMode = false;
    if (_currentUrl == path) return;
    await _player.stop();
    await _player.play(DeviceFileSource(path));
    _currentUrl = path;
    if (title != null && title.isNotEmpty) {
      updateMediaNotification(title);
    }
  }

  /// 暂停
  Future<void> pause() async {
    await _player.pause();
    _updateNotificationPlaying(false);
  }

  /// 恢复
  Future<void> resume() async {
    await _player.resume();
    _updateNotificationPlaying(true);
  }

  /// 停止并释放
  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
    _isMixMode = false;
    _clearNotification();
  }

  /// 设置音量 0.0 ~ 1.0
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 1.0));

  // --------------- 混音（最多 3 路，供 DIY 页） ---------------

  /// 开始混音播放（远程 URL）
  Future<void> startMix(List<String> urls, List<double> volumes) async {
    await stopMix();
    final count = urls.length.clamp(0, _maxMix);
    for (var i = 0; i < count; i++) {
      final url = urls[i];
      final vol = i < volumes.length ? volumes[i].clamp(0.0, 1.0) : 1.0;
      await _mixPlayers[i].setVolume(vol);
      await _mixPlayers[i].play(UrlSource(url));
    }
  }

  /// 从本地文件路径混音播放（缓存后的音频）
  Future<void> startMixFromFiles(
    List<String> localPaths,
    List<double> volumes, {
    String title = 'DIY 白噪音',
  }) async {
    await stopMix();
    _isMixMode = true;
    final count = localPaths.length.clamp(0, _maxMix);
    for (var i = 0; i < count; i++) {
      final path = localPaths[i];
      final vol = i < volumes.length ? volumes[i].clamp(0.0, 1.0) : 1.0;
      await _mixPlayers[i].setVolume(vol);
      await _mixPlayers[i].play(DeviceFileSource(path));
    }
    updateMediaNotification(title);
  }

  /// 设置混音某一路音量，[index] 0~2
  Future<void> setMixVolume(int index, double volume) async {
    if (index >= 0 && index < _maxMix) {
      await _mixPlayers[index].setVolume(volume.clamp(0.0, 1.0));
    }
  }

  /// 单路启动混音（用于选中音频时追加播放），[slotIndex] 0~2
  Future<void> startMixSingle(
    int slotIndex,
    String path,
    double volume, {
    String title = 'DIY 白噪音',
  }) async {
    if (slotIndex >= 0 && slotIndex < _maxMix) {
      _isMixMode = true;
      final vol = volume.clamp(0.0, 1.0);
      await _mixPlayers[slotIndex].setVolume(vol);
      await _mixPlayers[slotIndex].play(DeviceFileSource(path));
      updateMediaNotification(title);
    }
  }

  /// 单路停止混音（用于取消选中时只停当前），[slotIndex] 0~2
  Future<void> stopMixSingle(int slotIndex) async {
    if (slotIndex >= 0 && slotIndex < _maxMix) {
      await _mixPlayers[slotIndex].stop();
    }
  }

  /// 停止所有混音
  Future<void> stopMix() async {
    for (final p in _mixPlayers) {
      await p.stop();
    }
    if (_isMixMode) {
      _isMixMode = false;
      _clearNotification();
    }
  }

  void _clearNotification() {
    final h = _notificationHandler;
    if (h == null) return;
    h.playbackState.add(PlaybackState(
      processingState: AudioProcessingState.idle,
      controls: [],
    ));
    h.mediaItem.add(null);
  }

  void _updateNotificationPlaying(bool playing) {
    final h = _notificationHandler;
    if (h == null) return;
    h.playbackState.add(h.playbackState.value.copyWith(
      playing: playing,
      controls: playing
          ? [MediaControl.pause, MediaControl.stop]
          : [MediaControl.play, MediaControl.stop],
    ));
  }

  /// 释放资源
  void dispose() {
    _player.dispose();
    for (final p in _mixPlayers) {
      p.dispose();
    }
  }
}
