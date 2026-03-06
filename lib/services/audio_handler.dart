import 'package:audio_service/audio_service.dart';

import 'audio_service.dart' as app_audio;

/// 通知栏 / 锁屏控制的 AudioHandler，将 play/pause/stop 委托给 AppAudioService
class WhiteNoiseAudioHandler extends BaseAudioHandler {
  WhiteNoiseAudioHandler(this._appAudio);

  final app_audio.AudioService _appAudio;

  @override
  Future<void> play() async {
    await _appAudio.resumeFromNotification();
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [MediaControl.pause, MediaControl.stop],
    ));
  }

  @override
  Future<void> pause() async {
    await _appAudio.pauseFromNotification();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [MediaControl.play, MediaControl.stop],
    ));
  }

  @override
  Future<void> stop() async {
    await _appAudio.stopFromNotification();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      controls: [],
    ));
    mediaItem.add(null);
  }
}
