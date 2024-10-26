
import 'package:flutter/material.dart';
import 'package:libmuy_audioplayer/libmuy_audioplayer.dart';
import 'package:libmuyenglish/providers/service_locator.dart';
import 'package:simple_logging/simple_logging.dart';

final _log = Logger('TEST', level: LogLevel.debug);

void main() {
  setupLocator();
  runApp(const AudioPlayerApp());
}

class AudioPlayerApp extends StatelessWidget {
  const AudioPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AudioPlayerPage(),
    );
  }
}

class AudioPlayerPage extends StatefulWidget {
  const AudioPlayerPage({super.key});

  @override
  createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  final _audioPlayer = getIt<LibmuyAudioplayer>();

  void _loadAudio() async {

    // final response = await http.post(
    //   Uri.parse('$kUrlPrefix/get_audio.php'),
    //   headers: <String, String>{
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({
    //     'episode_id': 1,
    //   }),
    // );

    // if (response.statusCode != 200) {
    //   _log.error('Failed to load audio, status:${response.statusCode}');
    //   return;
    // }
    // _log.debug('Audio loaded');
    // _audioPlayer.setSource(response.bodyBytes);

    _log.debug('Audio loaded');
    _audioPlayer.src = "https://english.libmuy.com/app-backend/get_audio2.php?episode_id=1";
  }

  void _playAudio() async {
    await _audioPlayer.play();
  }

  void _stopAudio()  {
   _audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Player Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _loadAudio,
              child: const Text('Load audio'),
            ),
            ElevatedButton(
              onPressed: _playAudio,
              child: const Text('Play'),
            ),
            ElevatedButton(
              onPressed: _stopAudio,
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}