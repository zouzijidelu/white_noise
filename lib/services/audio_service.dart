import 'package:audioplayers/audioplayers.dart';

/// 基于 audioplayers 的音频播放封装，供环境音/冥想/DIY 混音等使用
class AudioService {
  AudioService() {
    _player = AudioPlayer();
    _player.onPlayerComplete.listen((_) {
      _currentUrl = null;
    });
    for (var i = 0; i < _maxMix; i++) {
      final p = AudioPlayer();
      p.setReleaseMode(ReleaseMode.loop);
      _mixPlayers.add(p);
    }
  }

  static const int _maxMix = 3;
  late final AudioPlayer _player;
  final List<AudioPlayer> _mixPlayers = [];
  String? _currentUrl;

  AudioPlayer get player => _player;

  /// 播放指定资源（asset 或 URL）
  Future<void> play(String source, {bool isAsset = true}) async {
    await stopMix();
    if (_currentUrl == source) return;
    await _player.stop();
    if (isAsset) {
      await _player.play(AssetSource(source));
    } else {
      await _player.play(UrlSource(source));
    }
    _currentUrl = source;
  }

  /// 播放本地文件（用于缓存后的音频，全项目复用缓存后均走此路径）
  Future<void> playFile(String path) async {
    await stopMix();
    if (_currentUrl == path) return;
    await _player.stop();
    await _player.play(DeviceFileSource(path));
    _currentUrl = path;
  }

  /// 暂停
  Future<void> pause() => _player.pause();

  /// 恢复
  Future<void> resume() => _player.resume();

  /// 停止并释放
  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
  }

  /// 设置音量 0.0 ~ 1.0
  Future<void> setVolume(double volume) => _player.setVolume(volume.clamp(0.0, 1.0));

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
  Future<void> startMixFromFiles(List<String> localPaths, List<double> volumes) async {
    await stopMix();
    final count = localPaths.length.clamp(0, _maxMix);
    for (var i = 0; i < count; i++) {
      final path = localPaths[i];
      final vol = i < volumes.length ? volumes[i].clamp(0.0, 1.0) : 1.0;
      await _mixPlayers[i].setVolume(vol);
      await _mixPlayers[i].play(DeviceFileSource(path));
    }
  }

  /// 设置混音某一路音量，[index] 0~2
  Future<void> setMixVolume(int index, double volume) async {
    if (index >= 0 && index < _maxMix) {
      await _mixPlayers[index].setVolume(volume.clamp(0.0, 1.0));
    }
  }

  /// 停止所有混音
  Future<void> stopMix() async {
    for (final p in _mixPlayers) {
      await p.stop();
    }
  }

  /// 释放资源
  void dispose() {
    _player.dispose();
    for (final p in _mixPlayers) {
      p.dispose();
    }
  }
}
