import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:frontend_ecotrack/data/models/DashboardStats.dart';
import 'package:frontend_ecotrack/data/models/campain.dart';
import '../../../core/services/api_client.dart';

class CampaignApi {
  final ApiClient _api;

  CampaignApi(this._api);

  Future<List<Campaign>> fetchCampaigns() async {
    final res = await _api.get('/api/admin/campaigns');
    final List data = _api.decodeUtf8Json(res);
    return data.map((e) => Campaign.fromJson(e, _api)).toList();
  }

  Future<Campaign> getDetail(int id) async {
    final res = await _api.get('/api/admin/campaigns/$id');
    final data = _api.decodeUtf8Json(res);
    return Campaign.fromJson(data, _api);
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _api.post('/api/admin/campaigns/create', payload);
  }

  Future<void> createMultipart({
    required Map<String, String> fields,
    required File imageFile,
  }) async {
    await _api.postMultipart('/api/admin/campaigns/create', fields, {
      'image': imageFile.path,
    });
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    await _api.put('/api/admin/campaigns/$id', payload);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/admin/campaigns/$id');
  }

  Future<List<dynamic>> fetchPartners() async {
    final res = await _api.get('/api/admin/partners');
    return _api.decodeUtf8Json(res);
  }

  Future<void> createMultipartFile({
    required Map<String, String> fields,
    required File imageFile,
  }) async {
    await _api.postMultipart('/api/admin/campaigns/create', fields, {
      'image': imageFile.path,
    });
  }

  // Trong CampaignApi.dart
  Future<void> createMultipartBytes({
    required Map<String, String> fields,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final String jsonData = jsonEncode(fields);
    await _api.postMultipartBytes(
      '/api/admin/campaigns/create',
      {'data': jsonData},
      {'image': imageBytes},
      fileName,
    );
  }

  Future<DashboardStats> fetchStats() async {
    final res = await _api.get('/api/admin/campaigns/stats');

    if (res.statusCode == 200) {
      final data = _api.decodeUtf8Json(res);
      return DashboardStats.fromJson(data);
    } else {
      throw Exception('Không thể tải thống kê: ${res.statusCode}');
    }
  }
}
