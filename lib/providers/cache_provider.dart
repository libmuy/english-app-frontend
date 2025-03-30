import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../utils/snack_bar_service.dart';
import 'service_locator.dart';

class CacheProvider {
  static const _kDataCacheKey = 'DataCache';
  static const _kDataCacheDuration = Duration(days: 30);
  static const _kMetaInfoCacheKey = 'MetaInfoCache';
  static const _kMetaInfoCacheDuration = Duration(days: 7);

  final CacheManager _cacheData;
  final CacheManager _cacheMetaInfo;
  final SnackBarService _snackBarService = getIt<SnackBarService>();

  CacheProvider()
      : _cacheData = CacheManager(
          Config(
            _kDataCacheKey,
            stalePeriod: _kDataCacheDuration,
          ),
        ),
        _cacheMetaInfo = CacheManager(
          Config(
            _kMetaInfoCacheKey,
            stalePeriod: _kMetaInfoCacheDuration,
          ),
        );

  /// Clears all cached files from the specified cache.
  Future<void> clear({bool isBigData = false}) async {
    final cacheManager = isBigData ? _cacheData : _cacheMetaInfo;
    await cacheManager.emptyCache();
    _snackBarService.showMessage('Cache cleared for ${isBigData ? 'big data' : 'meta info'}');
  }

  /// Retrieves the content of a file from the specified cache if it exists, otherwise returns null.
  Future<Uint8List?> fetch(String url, {bool isBigData = false}) async {
    final cacheManager = isBigData ? _cacheData : _cacheMetaInfo;
    final fileInfo = await cacheManager.getFileFromCache(url);
    if (fileInfo?.file != null) {
      return await fileInfo!.file.readAsBytes(); // Read and return the file's content as Uint8List
    }

    // Emit a cache miss event
    _snackBarService.showMessage('Cache miss for $url');
    return null; // Return null if the file is not in the cache
  }

  /// Adds data to the cache manually.
  Future<void> add(String key, Uint8List data, {bool isBigData = false}) async {
    final cacheManager = isBigData ? _cacheData : _cacheMetaInfo;
    await cacheManager.putFile(key, data);
    _snackBarService.showMessage('Data added to cache with key: $key');
  }
}