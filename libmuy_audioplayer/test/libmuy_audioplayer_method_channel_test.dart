import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmuy_audioplayer/libmuy_audioplayer_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelLibmuyAudioplayer platform = MethodChannelLibmuyAudioplayer();
  const MethodChannel channel = MethodChannel('libmuy_audioplayer');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
