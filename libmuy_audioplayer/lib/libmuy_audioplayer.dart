
import 'libmuy_audioplayer_platform_interface.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'libmuy_audioplayer_web.dart' if (dart.library.html) 'libmuy_audioplayer_web.dart';

class LibmuyAudioplayer {
  Future<String?> getPlatformVersion() {
    return LibmuyAudioplayerPlatform.instance.getPlatformVersion();
  }

  final LibmuyAudioplayerWeb? _webPlayer = kIsWeb ? LibmuyAudioplayerWeb() : null;

  set src(String url) {
    if (_webPlayer != null) {
      _webPlayer.src = url;
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }




  void setSource(Uint8List audioData) {
    if (_webPlayer != null) {
      _webPlayer.setSource(audioData);
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  Future<void> play() async {
    if (_webPlayer != null) {
      await _webPlayer.play();
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  void pause() {
    if (_webPlayer != null) {
      _webPlayer.pause();
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  void stop() {
    if (_webPlayer != null) {
      _webPlayer.stop();
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  void seek(Duration pos) {
    if (_webPlayer != null) {
      _webPlayer.seek(pos);
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  double get speed {
    if (_webPlayer != null) {
      return _webPlayer.speed;
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  set speed(double value) {
    if (_webPlayer != null) {
      _webPlayer.speed = value;
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  Stream<Duration> get onPositionChanged {
    if (_webPlayer != null) {
      return _webPlayer.onPositionChanged;
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  bool get isPlaying {
    if (_webPlayer != null) {
      return _webPlayer.isPlaying;
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }

  void dispose() {
    if (_webPlayer != null) {
      _webPlayer.dispose();
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }
}
