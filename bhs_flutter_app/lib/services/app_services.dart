import 'dart:io';

import '../core/network/api_client.dart';

class AppServices {
  AppServices(this.api);
  final ApiClient api;

  Future<dynamic> homeContent() => api.get('/public/home-content');
  Future<dynamic> counts() => api.get('/public/counts');
  Future<dynamic> login(Map<String, dynamic> body) => api.post('/auth/login', body: body);
  Future<dynamic> memberSearch(String keyword) => api.get('/members/search', query: {'keyword': keyword});
  Future<dynamic> memberFamilySearch(String keyword) => api.get('/search/member-family', query: {'keyword': keyword});
  Future<dynamic> uploadExcel(File file) => api.multipart('/admin/members/upload-excel', file, 'file');
}
