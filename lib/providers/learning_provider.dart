import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:libmuyenglish/providers/service_locator.dart';
import 'package:libmuyenglish/utils/errors.dart';
import 'package:libmuyenglish/utils/utils.dart';

import 'package:simple_logging/simple_logging.dart';
import 'auth_provider.dart';
import '../domain/entities.dart';
import '../domain/global.dart';
import 'cache_provider.dart';

final _log = Logger('LearningProvider', level: LogLevel.debug);

class LearningProvider {
  late AuthProvider _authProvider;
  late CacheProvider _cacheProvider;

  final List<Category> _categories = [];
  List<Course> favoriteCourses = [];
  List<Episode> favoriteEpisodes = [];
  List<Course> recentCourses = [];
  List<Episode> recentEpisodes = [];
  String? _errorMessage;
  final ValueNotifier<bool> _fetchingNotifier = ValueNotifier<bool>(false);

  ValueNotifier<bool> get fetchingNotifier => _fetchingNotifier;
  bool get fetching => _fetchingNotifier.value;
  final LinkedHashMap<SentenceSource, SentenceFetchResult> _sentenceCache =
      LinkedHashMap();
  Map<ResourceType, List<ResourceEntity>>? _favResourceCache;

  LearningProvider() {
    _authProvider = getIt<AuthProvider>();
    _cacheProvider = getIt<CacheProvider>();
  }

  List<Category> get categories => _categories;
  String? get errorMessage => _errorMessage;

  // ======================================================
  // 📄 fetch CATEGORY
  // ======================================================
  Future<Category> fetchCategory(int? categoryId) async {
    final cacheKey = 'category_$categoryId';
    final cachedData = await _cacheProvider.fetch(cacheKey);
    if (cachedData != null) {
      return Category.fromJson(jsonDecode(utf8.decode(cachedData)));
    }

    final response = await httpRequest(
      'get_category.php',
      body: jsonEncode({
        'category_id': categoryId,
      }),
    );

    final data = jsonDecode(response.body);
    final ret = Category.fromJson(data);
    await fetchFavoriteResource();
    _updateResourceFav(ret);

    // Cache the response
    await _cacheProvider.add(cacheKey, Uint8List.fromList(response.bodyBytes));
    return ret;
  }

  // ======================================================
  // 📄 fetch COURSE
  // ======================================================
  Future<Course> fetchCourse(int courseId) async {
    final response = await httpRequest(
      'get_course.php',
      body: jsonEncode({
        'course_id': courseId,
      }),
    );

    final data = jsonDecode(response.body);
    final ret = Course.fromJson(data);
    await fetchFavoriteResource();
    _updateResourceFav(ret);
    return ret;
  }

  // ======================================================
  // 📄 fetch AUDIO
  // ======================================================
  Future<Uint8List> fetchAudio(int episodeId) async {
    final cacheKey = 'audio_$episodeId';
    final cachedData = await _cacheProvider.fetch(cacheKey, isBigData: true);
    if (cachedData != null) {
      return cachedData;
    }

    final response = await httpRequest(
      'get_audio.php',
      body: jsonEncode({
        'episode_id': episodeId,
      }),
    );

    // Cache the audio data
    await _cacheProvider.add(cacheKey, response.bodyBytes, isBigData: true);
    return response.bodyBytes;
  }

  // ======================================================
  // 📄 fetch FAVORITE RESOURCE
  // ======================================================
  Future<Map<ResourceType, List<ResourceEntity>>>
      fetchFavoriteResource() async {
    if (_favResourceCache != null) return _favResourceCache!;


    final response = await httpRequest('get_favorite_resource.php');

    Map<String, dynamic> data = jsonDecode(response.body);
    Map<ResourceType, List<ResourceEntity>> ret = {};
    for (var key in ResourceType.values) {
      final keyStr = key.toString();
      if (!data.containsKey(keyStr) || data[keyStr].isEmpty) {
        ret[key] = [];
      } else {
        ret[key] = data[keyStr].map<ResourceEntity>((j) {
          final res = key.gererateEntityFromJson(j);
          res.fav = true;
          return res;
        }).toList();
      }
    }

    _favResourceCache = ret;

    return ret;
  }

  // ======================================================
  // 📄 fetch FAVORITE LIST
  // ======================================================
  Future<List<FavoriteList>> fetchFavoriteLists() async {
    _log.debug('fetch favorite list');

    final response = await httpRequest('get_favorite_list.php');
    final data = jsonDecode(response.body);
    final ret = data.map<FavoriteList>((e) {
      return FavoriteList.fromJson(e);
    }).toList();

    return ret;
  }

  // ======================================================
  // 📄 fetch SENTENCE
  // ======================================================
  Future<SentenceFetchResult> fetchSentences(SentenceSource src,
      {int pageSize = kSentencePageSize, int offset = 0}) async {
    final cacheKey = 'sentence_${src.hashCode}_${pageSize}_$offset';
    final cachedData = await _cacheProvider.fetch(cacheKey);
    if (cachedData != null) {
      return SentenceFetchResult.fromJson(
          jsonDecode(utf8.decode(cachedData)));
    }

    if (_sentenceCache.containsKey(src)) return _sentenceCache[src]!;

    final srcData = src.toJson();
    srcData['page_size'] = pageSize;
    srcData['offset'] = offset;

    final response = await httpRequest(
      'get_sentence.php',
      body: jsonEncode(srcData),
    );
    final data = jsonDecode(response.body);
    final ret = SentenceFetchResult.fromJson(data);

    // Cache the response
    await _cacheProvider.add(cacheKey, Uint8List.fromList(response.bodyBytes));
    return ret;
  }

  // ======================================================
  // 📄 fetch SENTENCE
  // ======================================================
  Future<SentenceFetchResult> fetchReviewSentences(
      {int pageSize = kSentencePageSize, int offset = 0}) async {
    final response = await httpRequest(
      'get_review_sentence.php',
      body: jsonEncode({
        'page_size': pageSize,
        'offset': offset,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Review Sentence', response.statusCode,
          error: data['error']);
    }
    final ret = SentenceFetchResult.fromJson(data);

    return ret;
  }

  // ======================================================
  // 📄 fetch HISTORY
  // ======================================================
  Future<List<History>> fetchHistory() async {
    _log.debug('fetch history, count:$kHistoryCount');

    final response = await httpRequest('get_history.php');
    final data = jsonDecode(response.body);
    if (data.isEmpty) return [];
    return data.map<History>((json) => History.fromJson(json)).toList();
  }

  // ======================================================
  // 📄 fetch DESCRIPTION
  // ======================================================
  Future<String?> fetchDescription(int sentenceId) async {
    _log.debug('fetch desc');

    try {
      final response = await httpRequest(
        '$sentenceId.md',
        useGet: true,
        baseUrl: 'https://app.english.libmuy.com/desc',
        // baseUrl: 'https://english.libmuy.com/app-gh-page/desc',
      );
      return response.body;
    } catch (e) {
      return null;
    }
  }

  // ======================================================
  // 📄 fetch LEARNING DATA
  // ======================================================
  Future<LearningData?> fetchLearningData(int sentenceId) async {
    _log.debug('fetch Learning Data');

    final response = await httpRequest(
      'get_learning_data.php',
      permitStatus404: true,
      body: jsonEncode({'sentence_id': sentenceId}),
    );

    if (response.statusCode == 404) return null;

    final data = jsonDecode(response.body);
    return LearningData.fromJson(data);
  }

  // ======================================================
  // 📄 fetch REVIEW SENTENCE COUNT
  // ======================================================
  Future<ReviewInfo> fetchReviewInfo({DateTime? date}) async { // Added optional date parameter
    _log.debug('fetch Review Info Data${date == null ? "" : " for date $date"}'); // Modified log

    Map<String, dynamic> requestBody = {};
    if (date != null) {
      // Format date to 'YYYY-MM-DD'
      String formattedDate = "${date.year.toString().padLeft(4, '0')}-"
                             "${date.month.toString().padLeft(2, '0')}-"
                             "${date.day.toString().padLeft(2, '0')}";
      requestBody['date'] = formattedDate;
    }

    final response = await httpRequest(
      'get_review_info.php',
      // Send body only if it's not empty, otherwise an empty string might be sent
      // depending on httpRequest implementation.
      // Assuming httpRequest handles null or empty body appropriately for GET if no body is needed,
      // or sends an empty JSON {} for POST if that's how it's set up.
      // For this PHP script, it's likely expecting POST with JSON body.
      body: jsonEncode(requestBody), 
    );
    final data = jsonDecode(response.body);

    return ReviewInfo.fromJson(data);
  }

  // ======================================================
  // 📄 update FAVORITE RESOURCE
  // ======================================================
  Future<void> updateFavoriteResource(ResourceEntity entity, bool fav) async {
    await httpRequest(
      'update_favorite_resource.php',
      body: jsonEncode(<String, dynamic>{
        'resource_type': entity.type.toString(),
        'resource_id': entity.id,
        'fav': fav,
      }),
    );

    if (_favResourceCache != null) {
      final cache = _favResourceCache![entity.type]!;
      final isFav = isFavResource(entity)!;
      if (fav && !isFav) cache.add(entity);
      if (!fav && isFav) cache.removeWhere((e) => e.id == entity.id);
    }
  }

  // ======================================================
  // 📄 add FAVORITE LIST
  // ======================================================
  Future<int> addFavoriteList(String name) async {
    final response = await httpRequest(
      'add_favorite_list.php',
      body: jsonEncode(<String, dynamic>{
        'name': name,
      }),
    );

    final data = jsonDecode(response.body);
    return data['id'];
  }

  // ======================================================
  // 📄 update FAVORITE LIST
  // ======================================================
  Future<void> updateFavoriteList(int listId, String name) async {
    await httpRequest(
      'update_favorite_list.php',
      body: jsonEncode(<String, dynamic>{
        'list_id': listId,
        'name': name,
      }),
    );
  }

  // ======================================================
  // 📄 delete FAVORITE LIST
  // ======================================================
  Future<void> deleteFavoriteList(int listId) async {
    await httpRequest(
      'update_favorite_list.php',
      body: jsonEncode(<String, dynamic>{
        'list_id': listId,
      }),
    );
  }

  // ======================================================
  // 📄 update FAVORITE SENTENCE
  // ======================================================
  Future<void> updateFavoriteSentence(
      int favoriteListId, Sentence sentence, bool fav) async {
    await httpRequest(
      'update_favorite_sentence.php',
      body: jsonEncode(<String, dynamic>{
        'favorite_list_id': favoriteListId,
        'sentence_id': sentence.id,
        'fav': fav,
      }),
    );

    sentence.fav = fav;
    _sentenceCache.forEach((key, val) {
      if (key.type == SentenceSourceType.favorite &&
          key.favoriteListId == favoriteListId) {
        if (val.sentences.any((s) => s.id == sentence.id)) {
          if (fav) {
            // If the sentence is already in the list, do nothing
            // This should not happen
            // throw ArgumentError('Sentence already in favorite list');
            _log.warning('Sentence already in favorite list');
            return;
          } else {
            val.sentences.removeWhere((s) => s.id == sentence.id);
            val.totalCount -= 1;
          }
        } else {
          if (fav) {
            val.sentences.add(sentence);
            val.totalCount += 1;
          } else {
            // If the sentence is not in the list, do nothing
            // This should not happen
            // throw ArgumentError('Sentence not in favorite list');
            _log.warning('Sentence not in favorite list');
            return;
          }
        }
      } else {
        for (var s in val.sentences) {
          if (s.id == sentence.id) s.fav = fav;
        }
      }
    });
  }

  // ======================================================
  // 📄 update HISTORY
  // ======================================================
  Future<void> updateHistory(History history) async {
    _log.debug('update history, count:$kHistoryCount');

    final args = history.toJson();

    if (history.src.type == SentenceSourceType.episode &&
        history.audioLenth == null) {
      throw ArgumentError('Audio have no audio length');
    }

    final json = jsonEncode(args);

    await httpRequest(
      'update_history.php',
      body: json,
    );
  }

  // ======================================================
  // 📄 remove HISTORY
  // ======================================================
  Future<void> removeHistory(
      {SentenceSource? src, bool removeAll = false}) async {
    Map<String, dynamic> args;

    _log.debug('remove history');

    if (removeAll) {
      args = {};
      args['remove_all'] = true;
    } else {
      if (src == null) throw ArgumentError.notNull('src');
      args = src.toJson();
    }

    await httpRequest(
      'remove_history.php',
      body: jsonEncode(args),
    );
  }

  // ======================================================
  // 📄 update Learning Data
  // ======================================================
  Future<void> updateLearningData(LearningData data) async {
    final json = data.toJson();
    _log.debug('update Learning Data');

    await httpRequest(
      'update_learning_data.php',
      body: jsonEncode(json),
    );
  }

  // ======================================================
  // 📄 review Sentence
  // ======================================================
  Future<void> reviewSentence(int sentenceId, ReviewResult reviewResult) async {
    _log.debug('review Sentence');

    await httpRequest(
      'review_sentence.php',
      body: jsonEncode({
        'sentence_id': sentenceId,
        'review_result': reviewResult.toString(),
      }),
    );
  }

  // ======================================================
  // 📄 update SENTENCE DESCRIPTION
  // ======================================================
  Future<void> updateSentenceDescription(int sentenceId, String data) async {
    _log.debug('update Sentence description');

    await httpRequest(
      'update_desc.php',
      body: jsonEncode({
        'sentence_id': sentenceId,
        'desc': data,
      }),
    );
  }

  // 🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰
  //　Utils for doing some common work
  // 🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰

  // ======================================================
  // 📄 check if a resource is favorited
  // ======================================================
  bool? isFavResource(ResourceEntity res) {
    if (_favResourceCache == null) return null;

    final idx = _favResourceCache![res.type]!.indexWhere((r) => r.id == res.id);
    return idx >= 0;
  }

  // ======================================================
  // 📄 update resource's fav status including the sub objects
  // ======================================================
  void _updateResourceFav(ResourceEntity res) {
    if (res is Category) {
      res.fav = isFavResource(res) ?? false;
      res.courses?.forEach((c) => _updateResourceFav(c));
      res.subcategories?.forEach((c) => _updateResourceFav(c));
    }
    if (res is Course) {
      res.fav = isFavResource(res) ?? false;
      res.episodes?.forEach((c) => _updateResourceFav(c));
    }

    if (res is Episode) {
      res.fav = isFavResource(res) ?? false;
    }
  }
}

class ReviewInfo {
  final int needToReviewCount;
  final int learnedCount; // Renamed from todayLearnedCount

  ReviewInfo(this.needToReviewCount, this.learnedCount); // Renamed parameter

  factory ReviewInfo.fromJson(Map<String, dynamic> json) {
    return ReviewInfo(
      json['need_to_review_count'] as int,
      json['learned_count'] as int, // Updated to use 'learned_count'
    );
  }
}
