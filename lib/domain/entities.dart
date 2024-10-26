import 'package:flutter/material.dart';
import 'package:libmuyenglish/domain/global.dart';
import 'package:libmuyenglish/providers/learning_provider.dart';
import 'package:libmuyenglish/providers/service_locator.dart';
import '../utils/utils.dart';

class Sentence {
  final int id;
  final int episodeId;
  final int sentenceIdx;
  final Duration start;
  final Duration end;
  final String chinese;
  final String english;
  bool haveDesc;
  String? desc;
  bool fav;

  Sentence(
      {required this.id,
      required this.episodeId,
      required this.sentenceIdx,
      required this.chinese,
      required this.english,
      required this.start,
      required this.end,
      required this.haveDesc,
      required this.fav});

  // Factory constructor to create an instance from JSON
  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'] as int,
      episodeId: json['episode_id'] as int,
      sentenceIdx: json['sentence_idx'] as int,
      chinese: json['chinese'] as String,
      english: json['english'] as String,
      start: Duration(milliseconds: json['start_time'] as int),
      end: Duration(milliseconds: json['end_time'] as int),
      haveDesc: json['has_description'] > 0,
      fav: json['is_fav'] > 0,
    );
  }
}

abstract class ResourceEntity {
  int id;
  final String name;
  ResourceEntity? parent;
  bool fav;
  bool hasIcon;

  final Image? icon;
  ResourceEntity({
    required this.id,
    required this.name,
    this.icon,
    this.fav = false,
    this.hasIcon = false,
  });

  ResourceType get type {
    if (this is Category) return ResourceType.category;
    if (this is Course) return ResourceType.course;
    if (this is Episode) return ResourceType.episode;
    if (this is FavoriteList) return ResourceType.favoriteList;
    if (this is ReviewSentences) return ResourceType.reviewSentences;
    if (this is BadResource) return ResourceType.bad;
    throw ArgumentError('this is not a expect resource: $this');
  }
}

class Category extends ResourceEntity {
  final String? desc;
  List<Course>? courses;
  List<Category>? subcategories;

  Category({
    required super.id,
    required super.name,
    this.desc,
    this.courses,
    this.subcategories,
    super.fav,
    super.hasIcon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final ret = Category(
      id: json['id'] ?? -1,
      desc: json['desc'],
      name: json['name'],
      fav: json['fav'] ?? false,
      hasIcon: json['has_icon'] ?? false,
    );

    if (json['courses'] != null) {
      ret.courses = (json['courses'] as List).map((course) {
        final c = Course.fromJson(course);
        c.parent = ret;
        return c;
      }).toList();
    }
    if (json['subcategories'] != null) {
      ret.subcategories = (json['subcategories'] as List).map((category) {
        final c = Category.fromJson(category);
        c.parent = ret;
        return c;
      }).toList();
    }
    return ret;
  }
}

class Course extends ResourceEntity {
  String? desc;
  List<Episode>? episodes;
  int episodeCount;

  Course({
    required super.id,
    required super.name,
    required this.episodeCount,
    this.desc,
    this.episodes,
    super.icon,
    super.fav,
    super.hasIcon,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final ret = Course(
      id: json['id'],
      name: json['name'],
      episodeCount: json['episode_count'],
      desc: json['desc'],
      fav: json['fav'] ?? false,
      hasIcon: json['has_icon'] ?? false,
    );

    if (json['episodes'] != null) {
      ret.episodes = (json['episodes'] as List).map((episode) {
        final e = Episode.fromJson(episode);
        e.parent = ret;
        return e;
      }).toList();
    }

    return ret;
  }
}

class Episode extends ResourceEntity {
  final int audioLength;
  int sentenceCount;

  Episode({
    required super.id,
    required super.name,
    required this.audioLength,
    required this.sentenceCount,
    super.icon,
    super.fav,
    super.hasIcon,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'],
      name: json['name'],
      audioLength: json['audio_length_sec'],
      sentenceCount: json['sentence_count'],
      fav: json['fav'] ?? false,
      hasIcon: json['has_icon'] ?? false,
    );
  }
}

class FavoriteList extends ResourceEntity {
  int sentenceCount;

  FavoriteList({
    required super.id,
    required super.name,
    required this.sentenceCount,
    super.icon,
    super.hasIcon,
  });

  factory FavoriteList.fromJson(Map<String, dynamic> json) {
    return FavoriteList(
      id: json['id'],
      name: json['name'],
      sentenceCount: json['sentence_count'],
      hasIcon: json['has_icon'] ?? false,
    );
  }
}

class ReviewSentences extends ResourceEntity {
  int sentenceCount;

  ReviewSentences({
    required this.sentenceCount,
    super.icon,
    super.hasIcon,
  }):super(id: -1, name: 'Review Sentences');

  factory ReviewSentences.fromJson(Map<String, dynamic> json) {
    return ReviewSentences(
      sentenceCount: json['sentence_count'],
      hasIcon: json['has_icon'] ?? false,
    );
  }
}

class BadResource extends ResourceEntity {
  BadResource({
    required super.id,
    required super.name,
  });

  factory BadResource.instance() {
    return BadResource(
      id: -1,
      name: "Bad Resource",
    );
  }
}

enum ResourceType {
  category,
  course,
  episode,
  favoriteList,
  reviewSentences,
  bad;

  @override
  String toString() {
    switch (this) {
      case ResourceType.category:
        return 'category';
      case ResourceType.course:
        return 'course';
      case ResourceType.episode:
        return 'episode';
      case ResourceType.favoriteList:
        return 'favoriteList';
      case ResourceType.reviewSentences:
        return 'reviewSentences';
      case ResourceType.bad:
        return 'bad';
    }
  }

  static ResourceType fromString(String value) {
    switch (value) {
      case 'category':
        return ResourceType.category;
      case 'course':
        return ResourceType.course;
      case 'episode':
        return ResourceType.episode;
      case 'favoriteList':
        return ResourceType.favoriteList;
      case 'bad':
        return ResourceType.bad;
      default:
        throw ArgumentError('Invalid ResourceType: $value');
    }
  }

  ResourceEntity gererateEntityFromJson(Map<String, dynamic> json) {
    switch (this) {
      case ResourceType.category:
        return Category.fromJson(json);
      case ResourceType.course:
        return Course.fromJson(json);
      case ResourceType.episode:
        return Episode.fromJson(json);
      case ResourceType.favoriteList:
        return FavoriteList.fromJson(json);
      default:
        throw ArgumentError('Invalid ResourceType: $json');
    }
  }
}

enum SentenceSourceType {
  episode,
  favorite,
  review;

  @override
  String toString() {
    switch (this) {
      case SentenceSourceType.episode:
        return 'episode';
      case SentenceSourceType.favorite:
        return 'favorite';
      case SentenceSourceType.review:
        return 'review';
      default:
        return 'unknown';
    }
  }

  factory SentenceSourceType.guessFromJson(Map<String, dynamic> json) {
    if (json.containsKey('favorite_list_id')) return SentenceSourceType.favorite;
    if (json.containsKey('episode_id')) return SentenceSourceType.episode;
    if (json.containsKey('review_sentence_count')) {
      return SentenceSourceType.review;
    }
    throw ArgumentError('Invalid SentenceSourceType: $json');
  }
}

class SentenceSource implements Comparable<SentenceSource> {
  final SentenceSourceType type;
  int? courseId;
  int? episodeId;
  int? favoriteListId;
  int? pageSize;
  int? pageNumber;

  // Constructor
  SentenceSource({
    required this.type,
    this.courseId,
    this.episodeId,
    this.favoriteListId,
    this.pageNumber,
    this.pageSize,
  });

  // Factory constructor to create an instance from JSON
  factory SentenceSource.fromJson(Map<String, dynamic> json) {
    return SentenceSource(
      type: json['type'] ?? SentenceSourceType.guessFromJson(json),
      courseId: json['course_id'],
      episodeId: json['episode_id'],
      favoriteListId: json['favorite_list_id'],
      pageSize: json['page_size'],
      pageNumber: json['page_number'],
    );
  }

  // Method to convert instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'course_id': courseId,
      'episode_id': episodeId,
      'favorite_list_id': favoriteListId,
      'page_size': pageSize,
      'page_number': pageNumber,
    };
  }

  // Implement Comparable
  @override
  int compareTo(SentenceSource other) {
    int res = _compareNullableInts(favoriteListId, other.favoriteListId);
    if (res != 0) return res;

    res = _compareNullableInts(episodeId, other.episodeId);
    if (res != 0) return res;

    res = _compareNullableInts(courseId, other.courseId);
    if (res != 0) return res;

    res = _compareNullableInts(pageSize, other.pageSize);
    if (res != 0) return res;

    return _compareNullableInts(pageNumber, other.pageNumber);
  }

  // Helper method to compare nullable integers
  int _compareNullableInts(int? a, int? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1; // Define null as less than any number
    if (b == null) return 1;
    return a.compareTo(b);
  }

  // Override == operator for equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SentenceSource &&
        other.courseId == courseId &&
        other.episodeId == episodeId &&
        other.favoriteListId == favoriteListId &&
        other.pageSize == pageSize &&
        other.pageNumber == pageNumber;
  }

  // Override hashCode
  @override
  int get hashCode =>
      courseId.hashCode ^
      episodeId.hashCode ^
      favoriteListId.hashCode ^
      pageSize.hashCode ^
      pageNumber.hashCode;
}

class History {
  SentenceSource src;
  int lastSentenceId;
  DateTime lastLearned;
  String title;
  int? audioLenth;
  int sentenceCount;

  // Constructor
  History({
    required this.src,
    required this.lastSentenceId,
    required this.lastLearned,
    required this.sentenceCount,
    required this.title,
    this.audioLenth,
  });

  // Factory constructor to create an instance from JSON
  factory History.fromJson(Map<String, dynamic> json) {
    final String dateStr = json['last_learned'];
    return History(
      src: SentenceSource.fromJson({
        'course_id': json['course_id'],
        'episode_id': json['episode_id'],
        'favorite_list_id': json['favorite_list_id'],
        'page_size': json['page_size'],
        'page_number': json['page_number'],
      }),
      lastSentenceId: json['last_sentence_id'] as int,
      lastLearned: DateTime.parse(dateStr.replaceFirst(' ', 'T')),
      title: json['title'],
      audioLenth: json['audio_length_sec'],
      sentenceCount: json['sentence_count'],
    );
  }

  // Method to convert instance to JSON
  Map<String, dynamic> toJson() {
    final ret = src.toJson();

    if (ret.containsKey('page_size')) ret.remove('page_size');
    if (ret.containsKey('page_number')) ret.remove('page_number');

    ret['last_sentence_id'] = lastSentenceId;
    ret['last_learned'] = formatDateTimeForMySQL(lastLearned);
    ret['title'] = title;
    ret['audio_length_sec'] = audioLenth;
    ret['sentence_count'] = sentenceCount;

    return ret;
  }

  ResourceEntity generateResource() {
    ResourceEntity? ret;
    if (src.favoriteListId == null) {
      ret = _generateEpisod();
    } else {
      ret = _generateFavoriteList();
    }

    ret ??= BadResource.instance();

    return ret;
  }

  Episode? _generateEpisod() {
    if (src.episodeId == null || audioLenth == null) {
      return null;
    }
    final episode = Episode(
        id: src.episodeId!,
        name: title,
        audioLength: audioLenth!,
        sentenceCount: sentenceCount);
    episode.fav = getIt<LearningProvider>().isFavResource(episode) ?? false;
    return episode;
  }

  FavoriteList? _generateFavoriteList() {
    if (src.favoriteListId == null) {
      return null;
    }
    return FavoriteList(
        id: src.favoriteListId!, name: title, sentenceCount: sentenceCount);
  }
}

class SentenceFetchResult {
  /// The total number of sentences available.
  int totalCount;

  /// The offset from where the sentences are fetched.
  final int offset;

  /// A list of fetched sentences.
  final List<Sentence> sentences;

  /// Constructs a [SentenceFetchResult] with the given [totalCount], [offset], and [sentences].
  SentenceFetchResult({
    required this.totalCount,
    required this.offset,
    required this.sentences,
  });

  /// Creates a new instance of [SentenceFetchResult] from a JSON map.
  factory SentenceFetchResult.fromJson(Map<String, dynamic> json) {
    return SentenceFetchResult(
      totalCount: json['total_count'] as int,
      offset: json['offset'] as int,
      sentences: (json['sentences'] as List<dynamic>)
          .map<Sentence>(
              (item) => Sentence.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LearningData {
  final int sentenceId;
  double easeFactor;
  int intervalDays;
  DateTime learnedDate;
  bool isGraduated;
  bool isSkipped;
  int failureCount;

  LearningData({
    required this.sentenceId,
    required this.easeFactor,
    required this.intervalDays,
    required this.learnedDate,
    this.isGraduated = false,
    this.isSkipped = false,
    this.failureCount = 0,
  });

  // Convert a LearningData object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'sentence_id': sentenceId,
      'ease_factor':
          (easeFactor * 100).toInt(), // Convert to 1-byte unsigned int
      'interval_days': intervalDays,
      'learned_date': learnedDate.difference(kBaseDate).inDays,
      'is_graduated': isGraduated,
      'is_skipped': isSkipped,
      'failure_count': failureCount,
    };
  }

  factory LearningData.defaultData(int sentenceId) {
    return LearningData(
      sentenceId: sentenceId,
      easeFactor: 2.5,
      intervalDays: 1,
      learnedDate: DateTime.now(),
      isGraduated: false,
      isSkipped: false,
      failureCount: 0,
    );
  }

  // Create a LearningData object from a Map object
  factory LearningData.fromJson(Map<String, dynamic> json) {
    return LearningData(
      sentenceId: json['sentence_id'],
      easeFactor:
          (json['ease_factor'] as int) / 100.0, // Convert back to double
      intervalDays: json['interval_days'],
      learnedDate: kBaseDate.add(Duration(days: json['learned_date'])),
      isGraduated: json['is_graduated'],
      isSkipped: json['is_skipped'],
      failureCount: json['failure_count'] ?? 0,
    );
  }

  int calculateIntervalDays(ReviewResult review) {
    const initialIntervals = [1, 3, 7];
    const graduatedInterval = 14;

    int ret = intervalDays;
    if (!isGraduated) {
      if (review == ReviewResult.again) {
        ret = initialIntervals[0];
      } else {
        int currentIndex = initialIntervals.indexOf(intervalDays);
        if (currentIndex < initialIntervals.length - 1) {
          ret = initialIntervals[currentIndex + 1];
        } else {
          ret = graduatedInterval;
        }
      }
    } else {
      switch (review) {
        case ReviewResult.again:
          ret = 1;
        case ReviewResult.hard:
          ret = (intervalDays * 1.2).round();
        case ReviewResult.good:
          ret = (intervalDays * easeFactor).round();
        case ReviewResult.easy:
          ret = (intervalDays * 1.3).round();
        case ReviewResult.skip:
          break;
      }
    }

    // Handle late reviews
    final daysLate = DateTime.now().difference(learnedDate).inDays;
    if (daysLate > 7) {
      return (intervalDays * 0.75).round();
    }

    return ret;
  }
}

enum ReviewResult {
  skip,
  easy,
  good,
  hard,
  again;

  @override
  String toString() {
    switch (this) {
      case ReviewResult.skip:
        return 'skip';
      case ReviewResult.easy:
        return 'easy';
      case ReviewResult.good:
        return 'good';
      case ReviewResult.hard:
        return 'hard';
      case ReviewResult.again:
        return 'again';
      default:
        return 'unknown';
    }
  }
}
