import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/partner_dashboard_models.dart';

class PartnerApi {
  final ApiClient client;

  PartnerApi({ApiClient? client})
    : client = client ?? ApiClient(storage: const FlutterSecureStorage());
  Future<PartnerSponsorshipDashboard> fetchDashboard() async {
    final response = await client.get('/api/partner/dashboard/sponsorship');

    if (response.statusCode != 200) {
      throw Exception('Lỗi gọi API: ${response.statusCode} - ${response.body}');
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return PartnerSponsorshipDashboard.fromJson(json);
  }

  Future<Map<String, dynamic>> getSettings() async {
    final res = await client.get('/api/partner/settings');

    if (res.statusCode != 200) {
      throw Exception('Failed to load partner settings');
    }

    return client.decodeUtf8Json(res);
  }

  Future<void> updateSettings(Map<String, dynamic> body) async {
    final res = await client.put('/api/partner/settings', body);

    if (res.statusCode != 200) {
      throw Exception('Failed to update partner settings');
    }
  }
}
