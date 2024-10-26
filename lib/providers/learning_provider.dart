import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:libmuyenglish/providers/service_locator.dart';
import 'package:libmuyenglish/utils/errors.dart';

import 'package:simple_logging/simple_logging.dart';
import 'auth_provider.dart';
import '../domain/entities.dart';
import '../domain/global.dart';

final _log = Logger('LearningProvider', level: LogLevel.debug);

class LearningProvider {
  late AuthProvider _authProvider;
  final List<Category> _categories = [];
  List<Course> favoriteCourses = [];
  List<Episode> favoriteEpisodes = [];
  List<Course> recentCourses = [];
  List<Episode> recentEpisodes = [];
  String? _errorMessage;
  final ValueNotifier<bool> _fetchingNotifier = ValueNotifier<bool>(false);

  ValueNotifier<bool> get fetchingNotifier => _fetchingNotifier;
  bool get fetching => _fetchingNotifier.value;
  final LinkedHashMap<int, Uint8List> _audioCache = LinkedHashMap();
  final LinkedHashMap<SentenceSource, SentenceFetchResult> _sentenceCache =
      LinkedHashMap();
  Map<ResourceType, List<ResourceEntity>>? _favResourceCache;

  LearningProvider() {
    _authProvider = getIt<AuthProvider>();
  }

  List<Category> get categories => _categories;
  String? get errorMessage => _errorMessage;

  // ======================================================
  // 📄 fetch CATEGORY
  // ======================================================
  Future<Category> fetchCategory(int? categoryId) async {
    final token = _authProvider.token;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_category.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'category_id': categoryId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Category: $categoryId', response.statusCode,
          error: data['error']);
    }
    final ret = Category.fromJson(data);
    await fetchFavoriteResource();
    _updateResourceFav(ret);
    return ret;
  }

  // ======================================================
  // 📄 fetch COURSE
  // ======================================================
  Future<Course> fetchCourse(int courseId) async {
    final token = _authProvider.token;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_course.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'course_id': courseId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Course: $courseId', response.statusCode,
          error: data['error']);
    }

    final ret = Course.fromJson(data);
    await fetchFavoriteResource();
    _updateResourceFav(ret);
    return ret;
  }

  // ======================================================
  // 📄 fetch AUDIO
  // ======================================================
  Future<Uint8List> fetchAudio(int episodeId) async {
    final token = _authProvider.token;

    // Check if the audio is already cached
    if (_audioCache.containsKey(episodeId)) {
      return _audioCache[episodeId]!;
    }

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_audio.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'episode_id': episodeId,
      }),
    );

    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Audio: $episodeId', response.statusCode);
    }

    // Store in cache
    _addDataToCache(
        _audioCache, episodeId, response.bodyBytes, kMaxAudioCacheCount);

    return response.bodyBytes;
  }

  // ======================================================
  // 📄 fetch FAVORITE RESOURCE
  // ======================================================
  Future<Map<ResourceType, List<ResourceEntity>>>
      fetchFavoriteResource() async {
    if (_favResourceCache != null) return _favResourceCache!;
    final token = _authProvider.token;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_favorite_resource.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    Map<String, dynamic> data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Favorite Resource', response.statusCode,
          error: data['error']);
    }
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
    final token = _authProvider.token;

    _log.debug('fetch favorite list');

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_favorite_list.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Favorite List', response.statusCode,
          error: data['error']);
    }
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
    final token = _authProvider.token;

    if (_sentenceCache.containsKey(src)) return _sentenceCache[src]!;

    final srcData = src.toJson();
    srcData['page_size'] = pageSize;
    srcData['offset'] = offset;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_sentence.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(srcData),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Sentence: $src', response.statusCode,
          error: data['error']);
    }

    final ret = SentenceFetchResult.fromJson(data);

    // Store in cache
    _addDataToCache(_sentenceCache, src, ret, kMaxSentenceCacheCount);

    return ret;
  }

  // ======================================================
  // 📄 fetch SENTENCE
  // ======================================================
  Future<SentenceFetchResult> fetchReviewSentences(
      {int pageSize = kSentencePageSize, int offset = 0}) async {
    final token = _authProvider.token;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_review_sentence.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
    final token = _authProvider.token;
    _log.debug('fetch history, count:$kHistoryCount');

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_history.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch History', response.statusCode,
          error: data['error']);
    }
    if (data.isEmpty) return [];
    return data.map<History>((json) => History.fromJson(json)).toList();
  }

  // ======================================================
  // 📄 fetch DESCRIPTION
  // ======================================================
  Future<String> fetchDescription(int episodeId, int sentenceIdx) async {
    final token = _authProvider.token;

    _log.debug('fetch desc');

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_desc.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: {'episode_id': episodeId, 'sentence_idx': sentenceIdx},
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw HttpStatusError('Fetch Desc', response.statusCode,
          error: data['error']);
    }

    return response.body;
  }

  // ======================================================
  // 📄 fetch LEARNING DATA
  // ======================================================
  Future<LearningData?> fetchLearningData(int sentenceId) async {
    final token = _authProvider.token;
    _log.debug('fetch Learning Data');

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_learning_data.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'sentence_id': sentenceId}),
    );

    if (response.statusCode == 404) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Learning Data', response.statusCode,
          error: data['error']);
    }

    return LearningData.fromJson(data);
  }

  // ======================================================
  // 📄 fetch REVIEW SENTENCE COUNT
  // ======================================================
  Future<int> fetchReviewSentenceCount() async {
    final token = _authProvider.token;
    _log.debug('fetch Learning Data');

    final response = await http.post(
      Uri.parse('$kUrlPrefix/get_review_sentence_count.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Learning Data', response.statusCode,
          error: data['error']);
    }

    return data['count'];
  }

  // ======================================================
  // 📄 update FAVORITE RESOURCE
  // ======================================================
  Future<void> updateFavoriteResource(ResourceEntity entity, bool fav) async {
    final token = _authProvider.token;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/update_favorite_resource.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'resource_type': entity.type.toString(),
        'resource_id': entity.id,
        'fav': fav,
      }),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw HttpStatusError('Update Favorite Resource', response.statusCode,
          error: data['error']);
    }

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
    final token = _authProvider.token;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/add_favorite_list.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'name': name,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpStatusError('Fetch Desc', response.statusCode,
          error: data['error']);
    }

    return data['id'];
  }

  // ======================================================
  // 📄 update FAVORITE LIST
  // ======================================================
  Future<void> updateFavoriteList(int listId, String name) async {
    final token = _authProvider.token;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/update_favorite_list.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'list_id': listId,
        'name': name,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw HttpStatusError('Fetch Desc', response.statusCode,
          error: data['error']);
    }
  }

  // ======================================================
  // 📄 delete FAVORITE LIST
  // ======================================================
  Future<void> deleteFavoriteList(int listId) async {
    final token = _authProvider.token;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/update_favorite_list.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'list_id': listId,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw HttpStatusError('Fetch Desc', response.statusCode,
          error: data['error']);
    }
  }

  // ======================================================
  // 📄 update FAVORITE SENTENCE
  // ======================================================
  Future<void> updateFavoriteSentence(
      int favoriteListId, Sentence sentence, bool fav) async {
    final token = _authProvider.token;

    final response = await http.post(
      Uri.parse('$kUrlPrefix/update_favorite_sentence.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'favorite_list_id': favoriteListId,
        'sentence_id': sentence.id,
        'fav': fav,
      }),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw HttpStatusError('Update Favorite Sentence', response.statusCode,
          error: data['error']);
    }
    
    sentence.fav = fav;
    _sentenceCache.forEach((key, val) {
      if (key.type == SentenceSourceType.favorite && key.favoriteListId == favoriteListId) {
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
    final token = _authProvider.token;
    _log.debug('update history, count:$kHistoryCount');

    final args = history.toJson();

    if (history.src.type == SentenceSourceType.episode &&
        history.audioLenth == null) {
      throw ArgumentError('Audio have no audio length');
    }

    final json = jsonEncode(args);

    final response = await http.post(
      Uri.parse('$kUrlPrefix/update_history.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json,
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw HttpStatusError('Update History', response.statusCode,
          error: data['error']);
    }
  }

  // ======================================================
  // 📄 remove HISTORY
  // ======================================================
  Future<void> removeHistory(
      {SentenceSource? src, bool removeAll = false}) async {
    final token = _authProvider.token;
    Map<String, dynamic> args;

    _log.debug('remove history');

    if (removeAll) {
      args = {};
      args['remove_all'] = true;
    } else {
      if (src == null) throw ArgumentError.notNull('src');
      args = src.toJson();
    }

    final response = await http.post(
      Uri.parse('$kUrlPrefix/remove_history.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(args),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw HttpStatusError('Remove History', response.statusCode,
          error: data['error']);
    }
  }

  // ======================================================
  // 📄 update Learning Data
  // ======================================================
  Future<void> updateLearningData(LearningData data) async {
    final token = _authProvider.token;
    final json = data.toJson();

    _log.debug('update Learning Data');

    final response = await http.post(
      Uri.parse('$kUrlPrefix/update_learning_data.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(json),
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw HttpStatusError('Fetch Learning Data', response.statusCode,
          error: json['error']);
    }
  }

  // ======================================================
  // 📄 review Sentence
  // ======================================================
  Future<void> reviewSentence(int sentenceId, ReviewResult reviewResult) async {
    final token = _authProvider.token;

    _log.debug('review Sentence');

    final response = await http.post(
      Uri.parse('$kUrlPrefix/review_sentence.php'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'sentence_id': sentenceId,
        'review_result': reviewResult.toString(),
      }),
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw HttpStatusError('Fetch Learning Data', response.statusCode,
          error: json['error']);
    }
  }

  // 🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰
  //　Utils for doing some common work
  // 🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰🧰
  // ======================================================
  // 📄 Add new audio to the cache, maintaining max cache size
  // ======================================================
  void _addDataToCache(LinkedHashMap cache, key, data, int max) {
    cache[key] = data;
    if (cache.length >= max) {
      // Remove the oldest entry
      cache.remove(cache.keys.first);
    }
  }

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
