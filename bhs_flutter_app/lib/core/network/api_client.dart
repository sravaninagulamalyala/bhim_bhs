import 'dart:convert';
import 'dart:io';

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
    final res = await http.get(_uri(path, query), headers: await _headers());
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await http.post(_uri(path), headers: await _headers(), body: body == null ? null : jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res = await http.put(_uri(path), headers: await _headers(), body: body == null ? null : jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> multipart(String path, File file, String fieldName) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final headers = await _headers(json: false);
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
    final streamed = await request.send();
    return _decode(await http.Response.fromStream(streamed));
  }

  Future<List<int>> download(String path, {Map<String, String>? query}) async {
    final res = await http.get(_uri(path, query), headers: await _headers(json: false));
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
}
