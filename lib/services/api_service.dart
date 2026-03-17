import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// 将网络相关异常转为用户可读的提示文案
String networkErrorMessage(Object e, [String fallback = '请求失败，请重试']) {
  if (e is ApiException) {
    if (e.statusCode != null && e.statusCode! >= 500) return '服务器异常，请稍后重试';
    if (e.statusCode != null && e.statusCode! == 404) return '接口不存在';
    return e.message ?? fallback;
  }
  final msg = e.toString().toLowerCase();
  if (msg.contains('socket') ||
      msg.contains('host lookup') ||
      msg.contains('nodename') ||
      msg.contains('servname') ||
      msg.contains('connection') ||
      msg.contains('offline') ||
      msg.contains('-1009')) {
    return '网络异常，请检查网络连接后重试';
  }
  if (msg.contains('timeout') || msg.contains('timed out')) return '连接超时，请重试';
  return fallback;
}

/// 接口统一响应结构：code、msg、data
class ApiResponse<T> {
  const ApiResponse({required this.code, required this.msg, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int? ?? 0,
      msg: json['msg'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  final int code;
  final String msg;
  final T? data;

  bool get isSuccess => code == 1;
}

bool _isNetworkError(Object e) {
  final msg = e.toString().toLowerCase();
  return msg.contains('host lookup') ||
      msg.contains('nodename') ||
      msg.contains('servname') ||
      msg.contains('offline') ||
      msg.contains('-1009') ||
      msg.contains('socket') ||
      msg.contains('connection');
}

/// 网络请求工具类：基于 Base URL 的 GET 请求
class ApiService {
  ApiService({String baseUrl = ApiConstants.baseUrl, http.Client? client})
    : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  String _buildUrl(String base, String path, [Map<String, String>? queryParameters]) {
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final pathStr = path.startsWith('/') ? path : '/$path';
    var url = '$b$pathStr';
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final query = queryParameters.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');
      url = '$url?$query';
    }
    return url;
  }

  /// 通用 GET 请求，返回原始 JSON Map
  /// 域名失败时自动回退到 IP（与测试项目一致，绕过 DNS）
  Future<Map<String, dynamic>> getRaw(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      return await _getRawOnce(_baseUrl, path,
          queryParameters: queryParameters, headers: headers);
    } catch (e) {
      if (Platform.isIOS &&
          _isNetworkError(e) &&
          _baseUrl.contains('audio.3dmaxmo.com')) {
        await Future<void>.delayed(const Duration(seconds: 2));
        return await _getRawOnce(ApiConstants.fallbackBaseUrl, path,
            queryParameters: queryParameters, headers: headers);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getRawOnce(
    String base,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(base, path, queryParameters);
    final response = await _client.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json', ...?headers},
    );
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        body: response.body,
        message: 'HTTP ${response.statusCode}',
      );
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>?;
    if (decoded == null) {
      throw ApiException(message: 'Invalid JSON', body: response.body);
    }
    return decoded;
  }

  /// GET 请求并解析为 [ApiResponse<T>]
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJsonT,
  }) async {
    final json = await getRaw(
      path,
      queryParameters: queryParameters,
      headers: headers,
    );
    return ApiResponse.fromJson(json, fromJsonT);
  }

  // --------------- 业务接口 ---------------

  /// 分类列表 GET /jty/index/cateList
  /// 返回 data: List<{ id, title, icon }>
  Future<ApiResponse<List<dynamic>>> getCateList() async {
    return get<List<dynamic>>(
      ApiConstants.cateList,
      fromJsonT: (d) => d is List ? d : <dynamic>[],
    );
  }

  /// 所有分类及音效详情 GET /jty/cate/list
  /// 返回 data: List<{ id, title, icon, sort, status, audios: [...] }>
  Future<ApiResponse<List<dynamic>>> getCateDetailList() async {
    return get<List<dynamic>>(
      ApiConstants.cateDetailList,
      fromJsonT: (d) => d is List ? d : <dynamic>[],
    );
  }

  /// 冥想列表 GET /jty/Meditation/list
  /// 返回 data: List<{ id, title, thumbnail, intro, desc, audio_file, duration, status, sort }>
  Future<ApiResponse<List<dynamic>>> getMeditationList() async {
    return get<List<dynamic>>(
      ApiConstants.meditationList,
      fromJsonT: (d) => d is List ? d : <dynamic>[],
    );
  }

  /// 冥想详情 GET /jty/Meditation/detail
  /// 详情参数：id
  /// 详情返回：{ id, title, thumbnail, intro, desc, audio_file, duration, status, sort }
  Future<ApiResponse<dynamic>> getMeditationDetail(int id) async {
    return get<dynamic>(
      ApiConstants.meditationDetail,
      queryParameters: {'id': id.toString()},
    );
  }
}

/// 请求异常
class ApiException implements Exception {
  ApiException({this.statusCode, this.message, this.body});

  final int? statusCode;
  final String? message;
  final String? body;

  @override
  String toString() =>
      'ApiException: $message (statusCode: $statusCode, body: $body)';
}
