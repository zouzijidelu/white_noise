import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 音频缓存：按 URL 下载到本地，再次播放时直接读本地文件
class AudioCacheService {
  AudioCacheService();
  static const String _dirName = 'audio_cache';
  Directory? _cacheDir;

  Future<Directory> _getCacheDir() async {
    _cacheDir ??= await _createCacheDir();
    return _cacheDir!;
  }

  Future<Directory> _createCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _cacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    final ext = _extensionFromUrl(url);
    return '${digest.toString()}$ext';
  }

  String _extensionFromUrl(String url) {
    try {
      final path = Uri.parse(url).path;
      final dot = path.lastIndexOf('.');
      if (dot >= 0 && dot < path.length - 1) {
        return path.substring(dot);
      }
    } catch (_) {}
    return '.mp3';
  }

  /// 若该 URL 已缓存则返回本地路径，否则返回 null
  Future<String?> getCachedPath(String url) async {
    if (url.isEmpty) return null;
    final dir = await _getCacheDir();
    final file = File('${dir.path}/${_cacheKey(url)}');
    if (await file.exists()) return file.path;
    return null;
  }

  /// 确保该 URL 已缓存：若已有则直接返回路径，否则下载后写入并返回路径
  Future<String> downloadToCache(String url) async {
    if (url.isEmpty) throw ArgumentError('url is empty');
    final existing = await getCachedPath(url);
    if (existing != null) return existing;

    final dir = await _getCacheDir();
    final filename = _cacheKey(url);
    final file = File('${dir.path}/$filename');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw AudioCacheException(
        'HTTP ${response.statusCode}',
        response.statusCode,
      );
    }
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
}

class AudioCacheException implements Exception {
  AudioCacheException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => 'AudioCacheException: $message';
}
