import 'dart:async';
import 'dart:collection';

import 'learning_provider.dart';
import 'service_locator.dart';
import 'package:simple_logging/simple_logging.dart';
import '../domain/entities.dart';
import '../domain/global.dart';

final _log = Logger('HistoryManager', level: LogLevel.debug);

enum _HistoryUpdateType {
  update,
  remove,
  noaction,
}

class HistoryManager {
  late final _learningProvider = getIt<LearningProvider>();
  // LinkedHashMap: Maintains the insertion order, which is useful for 
  // identifying and removing the oldest history entry when the map exceeds kMaxHistoryCount.
  final LinkedHashMap<SentenceSource, History> _historyMap = LinkedHashMap();
  final Map<SentenceSource, _HistoryUpdateType> _updated = {};
  bool _removeAll = false;

  Timer? _syncTimer;
  void _startSyncTimer() {
    if (_syncTimer != null) return;

    _syncTimer = Timer(const Duration(seconds: kHistorySaveIntervalSec), _syncHandler);
  }

  Future<void> _syncHandler() async {
    _log.debug('history syncd: started');
    if (_removeAll) {
      _log.debug('history syncd: remove all history');
      await _learningProvider.removeHistory(removeAll: true);
      _removeAll = false;
      _updated.clear();
      return;
    }
  
    final keysUpdate = _updated.keys.where((k)=>_updated[k] != _HistoryUpdateType.noaction);
    for (var k in keysUpdate) {
      switch(_updated[k]!) {
        case _HistoryUpdateType.remove:
        _log.debug('history syncd: remove');
        await _learningProvider.removeHistory(src: k);
        break;
        
        case _HistoryUpdateType.update:
        _log.debug('history syncd: update');
        await _learningProvider.updateHistory(_historyMap[k]!);
        break;
        
        case _HistoryUpdateType.noaction:
        _log.debug('history syncd: noaction');
        break;
      }

      _updated[k] = _HistoryUpdateType.noaction;
    }

    _syncTimer = null;
  }

  /// Adds a new history item or updates an existing one.
  void addOrUpdateHistory(History history) {
    var key = history.src;

    //for keep order of the list
    if (_historyMap.containsKey(key)) _historyMap.remove(key);

    _historyMap[key] = history;
    _updated[key] = _HistoryUpdateType.update;

    // Enforce the maximum history count
    if (_historyMap.length > kHistoryCount) {
      key = _historyMap.keys.first;
      _historyMap.remove(key);
      _updated[key] = _HistoryUpdateType.remove;
    }

    _startSyncTimer();
  }

  /// Retrieves all history items as a list, ordered from newest to oldest.
  List<History> getHistoryList() {
    // Since LinkedHashMap maintains insertion order,
    // and we insert/update by moving to the end,
    // reverse the list to have newest first.
    return _historyMap.values.toList().reversed.toList();
  }

  /// Clears all history items.
  void clearHistory() async {
    _historyMap.clear();
    _removeAll = true;
    _startSyncTimer();
  }

  /// Removes a specific history item by SentenceSource.
  Future<void> removeHistory(SentenceSource src) async {
    _historyMap.remove(src);
    _updated[src] = _HistoryUpdateType.remove;
    _startSyncTimer();
  }

  /// Loads history from persistent storage.
  Future<List<History>> loadHistory() async {
    final loadedHistories = await _learningProvider.fetchHistory();
    loadedHistories.sort((a, b) => a.lastLearned.compareTo(b.lastLearned));
    int i;
    int shouldBeRemoved = loadedHistories.length - kHistoryCount;

    for (i = 0; i < shouldBeRemoved; i++) {
      _log.info('history count is over limitation, remove old one(${loadedHistories[i].src.toJson()})');
      await _learningProvider.removeHistory(src: loadedHistories[i].src);
    }

    for (; i < loadedHistories.length; i++) {
      _historyMap[loadedHistories[i].src] = loadedHistories[i];
    }

    return getHistoryList();
  }

  Future<void> sync() async{
    await _syncHandler();
  }

  int? lastSentenceId(SentenceSource src) {
    return _historyMap[src]?.lastSentenceId;
  }
}
