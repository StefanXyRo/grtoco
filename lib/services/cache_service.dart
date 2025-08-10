import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class CacheService {
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB
  static const int maxCacheFiles = 20;

  final Map<String, File> _videoCache = {};
  final List<String> _videoAccessQueue = [];

  CacheService() {
    _initCache();
  }

  Future<void> _initCache() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/video_cache');
    if (await cacheDir.exists()) {
      final files = await cacheDir.list().toList();
      for (var file in files) {
        if (file is File) {
          final url = _getUrlFromFileName(file.path);
          if (url != null) {
            _videoCache[url] = file;
            _videoAccessQueue.add(url);
          }
        }
      }
      _enforceCacheLimits();
    } else {
      await cacheDir.create();
    }
  }

  String _getFileNameFromUrl(String url) {
    var bytes = utf8.encode(url);
    var digest = sha256.convert(bytes);
    return '${digest.toString()}.mp4';
  }

  String? _getUrlFromFileName(String filePath) {
    // This is a simple reverse mapping. For a real app, you might need a more robust solution
    // like storing metadata in a database or a manifest file.
    // For this implementation, we can't get the original URL from the filename.
    // We will rely on the in-memory map.
    return null;
  }

  Future<void> preloadImage(String url) async {
    if (url.isNotEmpty) {
      try {
        await CachedNetworkImageProvider(url).resolve(ImageConfiguration());
        if (kDebugMode) {
          print('Preloaded image: $url');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to preload image: $url, Error: $e');
        }
      }
    }
  }

  Future<File?> preloadVideo(String url) async {
    if (url.isEmpty || _videoCache.containsKey(url)) {
      if (_videoCache.containsKey(url)) {
        _updateAccessQueue(url);
      }
      return _videoCache[url];
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/video_cache');
      final fileName = _getFileNameFromUrl(url);
      final file = File('${cacheDir.path}/$fileName');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _videoCache[url] = file;
        _videoAccessQueue.add(url);
        if (kDebugMode) {
          print('Preloaded and cached video: $url');
        }
        await _enforceCacheLimits();
        return file;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to preload video: $url, Error: $e');
      }
    }
    return null;
  }

  void _updateAccessQueue(String url) {
    _videoAccessQueue.remove(url);
    _videoAccessQueue.add(url);
  }

  Future<File?> getCachedVideo(String url) async {
    if (_videoCache.containsKey(url)) {
       _updateAccessQueue(url);
      return _videoCache[url];
    }
    return null;
  }

  Future<void> _enforceCacheLimits() async {
    if (_videoAccessQueue.length > maxCacheFiles) {
      final filesToRemove = _videoAccessQueue.length - maxCacheFiles;
      for (int i = 0; i < filesToRemove; i++) {
        final urlToRemove = _videoAccessQueue.removeAt(0);
        final fileToRemove = _videoCache.remove(urlToRemove);
        if (fileToRemove != null) {
          try {
            await fileToRemove.delete();
            if (kDebugMode) {
              print('Removed oldest video from cache: ${fileToRemove.path}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error deleting cached video: $e');
            }
          }
        }
      }
    }

    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/video_cache');
    int currentSize = 0;
    final files = await cacheDir.list().toList();
    for (var file in files) {
      if (file is File) {
        currentSize += await file.length();
      }
    }

    while (currentSize > maxCacheSize && _videoAccessQueue.isNotEmpty) {
      final urlToRemove = _videoAccessQueue.removeAt(0);
      final fileToRemove = _videoCache.remove(urlToRemove);
      if (fileToRemove != null) {
        try {
          final fileSize = await fileToRemove.length();
          await fileToRemove.delete();
          currentSize -= fileSize;
           if (kDebugMode) {
            print('Removed video from cache to free up space: ${fileToRemove.path}');
           }
        } catch (e) {
          if (kDebugMode) {
            print('Error deleting cached video: $e');
          }
        }
      }
    }
  }
}
