import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'libmuy_audioplayer_method_channel.dart';

abstract class LibmuyAudioplayerPlatform extends PlatformInterface {
  /// Constructs a LibmuyAudioplayerPlatform.
  LibmuyAudioplayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static LibmuyAudioplayerPlatform _instance = MethodChannelLibmuyAudioplayer();

  /// The default instance of [LibmuyAudioplayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelLibmuyAudioplayer].
  static LibmuyAudioplayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LibmuyAudioplayerPlatform] when
  /// they register themselves.
  static set instance(LibmuyAudioplayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
