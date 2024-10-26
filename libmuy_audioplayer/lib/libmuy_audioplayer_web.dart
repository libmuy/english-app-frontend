// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;
import 'libmuy_audioplayer_platform_interface.dart';
import 'package:simple_logging/simple_logging.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

final _log = Logger('AUDIO PLAYER', level: LogLevel.info);

/// A web implementation of the LibmuyAudioplayerPlatform of the LibmuyAudioplayer plugin.
class LibmuyAudioplayerWeb extends LibmuyAudioplayerPlatform {
  static void registerWith(Registrar registrar) {
    LibmuyAudioplayerPlatform.instance = LibmuyAudioplayerWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  final html.AudioElement _audioElement = html.AudioElement();
  Timer? _posTimer;
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  bool _isPlaying = false;
  double _lastPos = 0;

  LibmuyAudioplayerWeb() {
    _audioElement.onPlay.listen((_) {
      _isPlaying = true;
    });
    _audioElement.onPause.listen((_) {
      _isPlaying = false;
    });
    _audioElement.onEnded.listen((_) {
      _isPlaying = false;
    });
  }

  // Start the timer
  void _startTimer() {
    _posTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      final currentPos = _audioElement.currentTime;
      if (_lastPos != currentPos) {
        _positionController
            .add(Duration(microseconds: (currentPos * 1000 * 1000).round()));
        _lastPos = currentPos.toDouble();
      }
    });
  }

  // Pause the timer
  void _stopTimer() {
    _posTimer?.cancel();
  }

  void setSource(Uint8List audioData) {
    final blob =
        html.Blob([audioData], 'audio/mpeg'); // Ensure correct MIME type
    final url = html.Url.createObjectUrl(blob);
    _audioElement.src = url;

    // _audioElement.onCanPlay.first.then((_) async {
    //   _log.debug('can play');
    // });
  }

  Future<void> play() async {
        await _audioElement.play();
        _startTimer();
        _log.debug('readyState:${_audioElement.readyState}, HAVE_ENOUGH_DATA:${html.MediaElement.HAVE_ENOUGH_DATA}');
    // if (_audioElement.readyState >= html.MediaElement.HAVE_ENOUGH_DATA) {
    //   // If audio is already ready, play it immediately
    //   _log.debug('play audio');
    //   await _audioElement.play();
    //   _startTimer();
    // } else {
    //   // If audio is not ready, wait for the 'canplay' event
    //   _log.debug('play audio when it can');
    //   _audioElement.onCanPlayThrough.first.then((_) async {
    //     _log.debug('after can, play audio');
    //     await _audioElement.play();
    //     _startTimer();
    //   });
    // }
  }

  void pause() {
    _log.debug('pause');
    _audioElement.pause();
    _stopTimer();
  }

  void stop() {
    _log.debug('stop');
    _audioElement.pause();
    _audioElement.currentTime = 0;
    _stopTimer();
  }

  void seek(Duration pos) {
    _log.debug('seek');
    final mill = pos.inMilliseconds.toDouble();
    _audioElement.currentTime = mill / 1000;
  }

  Stream<Duration> get onPositionChanged => _positionController.stream;

  bool get isPlaying => _isPlaying;

  double get speed => _audioElement.playbackRate.toDouble();
  set speed(double speed) => _audioElement.playbackRate = speed;

  set src(String url) => _audioElement.src = url;

  void dispose() {
    _audioElement.pause();
    html.Url.revokeObjectUrl(_audioElement.src);
    _audioElement.remove();
    _positionController.close();
  }
}
