import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/auth_store.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.authStore, {this.baseUrl = ApiConstants.baseUrl});
  final AuthStore authStore;
  final String baseUrl;

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    _logRequest('GET', uri);
    final res = await http.get(uri, headers: await _headers());
    _logResponse('GET', uri, res);
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = _uri(path);
    final payload = body == null ? null : jsonEncode(body);
    _logRequest('POST', uri, payload);
    final res = await http.post(uri, headers: await _headers(), body: payload);
    _logResponse('POST', uri, res);
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final uri = _uri(path);
    final payload = body == null ? null : jsonEncode(body);
    _logRequest('PUT', uri, payload);
    final res = await http.put(uri, headers: await _headers(), body: payload);
    _logResponse('PUT', uri, res);
    return _decode(res);
  }

  Future<dynamic> multipart(String path, File file, String fieldName) async {
    final uri = _uri(path);
    _logRequest('MULTIPART', uri, 'file=${file.path}');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _headers(json: false);
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _logResponse('MULTIPART', uri, res);
    return _decode(res);
  }

  Future<List<int>> download(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    _logRequest('DOWNLOAD', uri);
    final res = await http.get(uri, headers: await _headers(json: false));
    _logResponse('DOWNLOAD', uri, res);
    if (res.statusCode < 200 || res.statusCode >= 300) throw ApiException('Download failed (${res.statusCode})');
    return res.bodyBytes;
  }

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{if (json) 'Content-Type': 'application/json'};
    if (authStore.token != null && authStore.token!.isNotEmpty) headers['Authorization'] = 'Bearer ${authStore.token}';
    return headers;
  }

  dynamic _decode(http.Response res) {
    dynamic body;
    try {
      body = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      body = res.body;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = body is Map ? (body['message'] ?? body['error'] ?? 'Request failed') : 'Request failed';
      throw ApiException('$msg');
    }
    if (body is Map && body.containsKey('success')) {
      if (body['success'] == false) throw ApiException('${body['message'] ?? 'Request failed'}');
      return body['data'];
    }
    return body;
  }

  void _logRequest(String method, Uri uri, [Object? body]) {
    if (!kDebugMode) return;
    debugPrint('API $method $uri');
    if (body != null) debugPrint('API request: $body');
  }

  void _logResponse(String method, Uri uri, http.Response res) {
    if (!kDebugMode) return;
    debugPrint('API $method $uri -> ${res.statusCode}');
    debugPrint('API response: ${res.body}');
  }
}
