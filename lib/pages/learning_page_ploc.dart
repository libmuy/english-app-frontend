import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libmuy_audioplayer/libmuy_audioplayer.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../providers/auth_provider.dart';
import '../providers/history.dart';
import '../utils/utils.dart';
import '../providers/service_locator.dart';
import '../providers/learning_provider.dart';
import '../providers/setting_provider.dart';
import '../domain/entities.dart';
import 'package:simple_logging/simple_logging.dart';
import 'favorite_list_selection_sheet.dart';

const _kStopOffset = Duration(milliseconds: 200);
const _kSaveSettingDelay = Duration(seconds: 10);

final _log = Logger('LearningPagePloc', level: LogLevel.debug);

class LearningPagePloc {
  // Private members
  late final String _title;
  late final int? _audioLength;
  late SentenceSource _src;

  final _settingProvider = getIt<SettingProvider>();
  final _learningProvider = getIt<LearningProvider>();
  final HistoryManager _historyMgr = getIt<HistoryManager>();
  final _audioPlayer = getIt<LibmuyAudioplayer>();
  late final StreamSubscription _audioPlayerPosSub;
  final _authProvider = getIt<AuthProvider>();

  late void Function(VoidCallback) _setState;
  SentenceFetchResult? _fetchResult;
  Timer? _settingSaveTimer;
  int? _currentEpisodeId;

  final _countDownStr = ValueNotifier("");
  bool _newPlaybackStarted = false;
  bool _completingPlayback = false;
  Duration _playEndTime = Duration.zero;
  Duration _playStartTime = Duration.zero;
  int _playCount = 0;

  // Public members
  final playingNotifier = ValueNotifier(false);
  final learningDataNotifier = ValueNotifier<LearningData?>(null);
  int index = 0;
  Future<SentenceFetchResult>? sentencesFuture;
  PageController? pageController;
  List<PageData>? pages;

  List<Sentence>? get sentences => _fetchResult?.sentences;
  Sentence? get currentSentence => _fetchResult?.sentences[index];
  int? get sentenceCount => _fetchResult?.totalCount;
  int? get sentenceOffset => _fetchResult?.offset;
  AppSettings get settings => _settingProvider.settings;
  ValueNotifier<String> get countDownStr => _countDownStr;
  bool get isAdmin => _authProvider.isAdmin;

  void init(SentenceSource sentenceSrc, String title, int? audioLength,
      void Function(VoidCallback) setState) {
    _src = sentenceSrc;
    sentencesFuture = _learningProvider.fetchSentences(_src);
    _audioPlayerPosSub =
        _audioPlayer.onPositionChanged.listen(_audioPositionListener);
    _title = title;
    _audioLength = audioLength;
    _setState = setState;
  }

  void dispose() {
    pageController?.dispose();
    pages = null;
    _audioPlayerPosSub.cancel();
    stopAudio();
  }

  void saveSettings() => _settingProvider.saveSettings();

  Future<void> fetchDesc(Sentence sentence) async {
    int retry = 5;
    while (retry-- > 0) {
      _log.debug('fetching description');
      try {
        sentence.desc ??= await _learningProvider.fetchDescription(sentence.id);
        if (sentence.desc != null) break;
      } catch (e) {
        _log.warning('Error fetching description: $e');
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Future<void> _loadAudioIfNeed(int episodeId) async {
    if (_currentEpisodeId == episodeId) return;
    final audio = await _learningProvider.fetchAudio(episodeId);
    _log.debug('set audio src ${audio.length} bytes');
    _audioPlayer.setSource(audio);
    _currentEpisodeId = episodeId;
  }

  void initializeOnDataChanged(SentenceFetchResult result) async {
    if (_fetchResult == result) return;
    _log.debug('initializeOnDataChanged');
    _fetchResult = result;
    pages?.forEach((p) => p.dispose());
    pages = List.generate(
        sentences!.length, (index) => PageData(sentences![index].english));
    final lastSentenceId = _historyMgr.lastSentenceId(_src);
    if (lastSentenceId == null) {
      index = 0;
    } else {
      index = sentences!.indexWhere((s) => s.id == lastSentenceId);
      _log.debug('lastSentenceId: $lastSentenceId, index: $index');
      if (index == -1) index = 0;
    }
    // _fetchLearningData();
    // sentencesFuture = null;
    pageController?.dispose();
    pageController = PageController(initialPage: index, viewportFraction: 1);

    if (sentences!.isEmpty) return;

    if (settings.isAutoPlayAfterSwitch) playAudio();
    updateHistory();
  }

  void updateHistory() {
    if (_src.type == SentenceSourceType.review) return;
    final history = History(
        src: _src,
        lastSentenceId: sentences![index].id,
        lastLearned: DateTime.now(),
        sentenceCount: sentenceCount!,
        audioLenth: _audioLength,
        title: _title);

    _historyMgr.addOrUpdateHistory(history);
    _log.debug('update history, sentenceId: ${sentences![index].id}, index: $index');
  }

  void _audioPositionListener(Duration pos) {
    _log.verbose(
        'pos: $pos, end: $_playEndTime, completing: $_completingPlayback');
    final offset = _kStopOffset * settings.playbackSpeed;
    if (pos + offset >= _playEndTime && !_completingPlayback) {
      _completeHandler();
    }
  }

  Future<void> playAudio() async {
    _log.debug('play Audio');
    await _loadAudioIfNeed(sentences![index].episodeId);
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final kPlaybackOffsetMS = isMobile ? 0 : 1;
    // Get playback settings
    final playbackTimes = settings.playbackTimes;
    final autoPlayNextSentence = settings.isAutoPlayNext;

    final offset = Duration(milliseconds: kPlaybackOffsetMS);
    _playStartTime = sentences![index].start - offset;
    _playEndTime = sentences![index].end + offset;
    _log.debug('set end : $_playEndTime');

    _playCount = 0;
    _newPlaybackStarted = true;
    playingNotifier.value = true;
    _countDownStr.value = '';

    _log.debug('Playback index:$index, '
        'times:$playbackTimes, '
        'interval:${settings.playbackInterval} '
        'autoNext:$autoPlayNextSentence '
        'start:$_playStartTime, '
        'end:$_playEndTime  -------------');

    _playAudioOnce();
  }

  void stopAudio() {
    _log.debug('stop Audio');
    playingNotifier.value = false;
    _audioPlayer.pause();
    _countDownStr.value = '';
  }

  void _playAudioOnce() async {
    final playbackSpeed = settings.playbackSpeed;
    _log.debug('  playCount:$_playCount');
    try {
      // if (_audioPlayer.playing) {
      //   _log.verbose('  playing, pause it');
      //   await _audioPlayer.pause();
      // }

      _log.verbose('  seek to $_playStartTime');
      _audioPlayer.seek(_playStartTime);
      if (_audioPlayer.speed != playbackSpeed) {
        _log.verbose('  set playback speed to $playbackSpeed');
        await _audioPlayer.setSpeed(playbackSpeed);
      }
      _log.verbose('  start to play');
      _audioPlayer.play();
    } catch (e) {
      _log.debug('Error during audio playback: $e');
    }
  }

  void _completeHandler() async {
    final playbackTimes = settings.playbackTimes;
    final autoPlayNextSentence = settings.isAutoPlayNext;

    _newPlaybackStarted = false;
    _completingPlayback = true;
    _log.debug('  playback complete, playCount:$_playCount');
    _audioPlayer.pause();
    _playCount++;

    for (var i = 0; i < settings.playbackInterval; i++) {
      _countDownStr.value = "${settings.playbackInterval - i}s";
      _log.debug('  wait 1 second');
      await Future.delayed(const Duration(seconds: 1));
      _log.debug('  waked up');
      if (_newPlaybackStarted || playingNotifier.value == false) {
        if (_newPlaybackStarted) {
          _log.debug('  new playback started, stop playback completer');
        }
        if (playingNotifier.value == false) {
          _log.debug('  user stoped playback, stop playback completer');
        }
        _completingPlayback = false;
        return;
      }
    }
    _countDownStr.value = '';
    if (_playCount < playbackTimes || playbackTimes == 0) {
      _log.debug(
          '  current playCount:$_playCount, playTimes setting:$playbackTimes, start a new playback');
      _playAudioOnce();
    } else if (_playCount == playbackTimes) {
      _log.debug(
          '  current playCount:$_playCount, playTimes setting:$playbackTimes, Playback completed');
      if (autoPlayNextSentence) {
        _log.debug('  Switch to next sentence');
        switchToNextSentence();
      } else {
        playingNotifier.value = false;
      }
    }
    _completingPlayback = false;
  }

  void switchToPreviousSentence() => switchToSentence(index - 1);

  void switchToNextSentence() => switchToSentence(index + 1);

  void switchToSentence(int i) {
    if (i < sentences!.length && i >= 0) {
      // index = i;
      // _fetchLearningData();
      pageController?.animateToPage(
        i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void onPlaySpeedChanged(double value) {
    _audioPlayer.setSpeed(value);
    if (_settingSaveTimer != null) _settingSaveTimer?.cancel();
    _settingSaveTimer = Timer(_kSaveSettingDelay, () {
      _settingProvider.saveSettings();
      _settingSaveTimer = null;
    });
  }

  void onPageChanged(int i) {
    stopAudio();
    index = i;
    updateHistory();
    // state.pages![index].textController!.clear();
    if (settings.isAutoPlayAfterSwitch) playAudio();
  }

  void _addFavSentence(int favListId, Sentence sentence) async {
    try {
      await _learningProvider.updateFavoriteSentence(favListId, sentence, true);
      // showSnackBar(context, 'Added to favorite list.');
      _setState(() {
        sentence.fav = true;
      });
    } catch (error) {
      _log.error('Error adding to default favorite list: $error');
      // showSnackBar(context, 'Failed to add to favorite list.');
    }
  }

  void _removeFavSentence(int favListId, Sentence sentence) async {
    try {
      await _learningProvider.updateFavoriteSentence(
          favListId, sentence, false);
      // showSnackBar(context, 'Added to favorite list.');
      if (_src.favoriteListId != null) {
        if (index > 0) {
          index -= 1;
          updateHistory();
        }
        sentencesFuture = _learningProvider.fetchSentences(_src);
      }
      _setState(() {});
    } catch (error) {
      _log.error('Error adding to default favorite list: $error');
      // showSnackBar(context, 'Failed to add to favorite list.');
    }
  }

  void onFavoriteIconTap(Sentence sentence) async {
    final defaultListId = settings.defaultFavoriteList;
    if (sentence.fav) {
      _removeFavSentence(defaultListId, sentence);
    } else {
      _addFavSentence(defaultListId, sentence);
    }
  }

  void onFavoriteIconLongPress(BuildContext context, Sentence sentence) async {
    if (sentence.fav) return onFavoriteIconTap(sentence);
    final favoriteLists = await _learningProvider.fetchFavoriteLists();
    try {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return FavoriteListSelectionSheet(
            favoriteLists: favoriteLists,
            onSelect: (selectedList) async {
              _addFavSentence(selectedList.id, sentence);
              Navigator.of(context).pop();
            },
          );
        },
      );
    } catch (error) {
      _log.error('Error fetching favorite lists: $error');
      showSnackBar(context, 'Failed to load favorite lists.');
    }
  }

  void reviewSentence(ReviewResult reviewResult) async {
    // final data = learningDataNotifier.value ?? LearningData.defaultData(sentences![index].id);
    // final (easeFactor, intervalDays) = reviewAlgrithm(data, rate);
    // data.easeFactor = easeFactor;
    // data.intervalDays = intervalDays;
    // await _learningProvider.updateLearningData(data);

    await _learningProvider.reviewSentence(sentences![index].id, reviewResult);
  }
}

class PageData {
  bool isVisibleTextEn = false;
  bool isVisibleTextCn = false;
  ReviewResult? reviewResult;
  final List<String> selectedWords = [];
  List<String> shuffledWords = [];
  List<String> englishWords = [];
  String? englishText;
  QuillController? textController;
  PageData(String sentence) {
    englishText = sentence;
    englishWords = englishText!.split(' ');
    shuffledWords = List.from(englishWords);
    shuffledWords.shuffle(Random());
  }

  void init() {
    if (textController != null) return;
    textController = QuillController.basic();
    textController!.changes.listen(_textChanged);
  }

  void dispose() {
    textController?.dispose();
    textController = null;
    englishText = null;
  }

  void _textChanged(DocChange event) {
    _log.debug("text changed");
    final before = Document.fromDelta(event.before).toPlainText();
    final after = textController!.document.toPlainText();
    int i;
    int len = after.length;
    if (after.isEmpty || englishText!.isEmpty) return;
    if (before == after) return;

    for (i = 0; i < len && i < englishText!.length; i++) {
      if (after[i] != englishText![i]) break;
    }

    final cnt = len - i;
    if (cnt == 0) return;

    String hex = Colors.red.value.toRadixString(16).padLeft(8, '0');
    textController!.formatText(i, cnt, ColorAttribute('#${hex.toUpperCase()}'));
  }

  int checkOrder() {
    int i;
    for (i = 0; i < selectedWords.length; i++) {
      if (englishWords[i] != selectedWords[i]) break;
    }
    return i;
  }

  void selectWord(int index, String word) {
    selectedWords.add(word);
    shuffledWords.removeAt(index);
  }

  void deselectWord(int index, String word) {
    selectedWords.removeAt(index);
    shuffledWords.add(word);
  }
}
