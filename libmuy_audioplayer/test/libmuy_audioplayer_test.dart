import 'package:flutter_test/flutter_test.dart';
import 'package:libmuy_audioplayer/libmuy_audioplayer.dart';
import 'package:libmuy_audioplayer/libmuy_audioplayer_platform_interface.dart';
import 'package:libmuy_audioplayer/libmuy_audioplayer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLibmuyAudioplayerPlatform
    with MockPlatformInterfaceMixin
    implements LibmuyAudioplayerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LibmuyAudioplayerPlatform initialPlatform = LibmuyAudioplayerPlatform.instance;

  test('$MethodChannelLibmuyAudioplayer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLibmuyAudioplayer>());
  });

  test('getPlatformVersion', () async {
    LibmuyAudioplayer libmuyAudioplayerPlugin = LibmuyAudioplayer();
    MockLibmuyAudioplayerPlatform fakePlatform = MockLibmuyAudioplayerPlatform();
    LibmuyAudioplayerPlatform.instance = fakePlatform;

    expect(await libmuyAudioplayerPlugin.getPlatformVersion(), '42');
  });
}
