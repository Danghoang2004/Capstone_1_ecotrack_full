// lib/core/services/partner_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/partner_dashboard_models.dart';

class PartnerApi {
  final ApiClient client;

  /// Nếu bạn không truyền gì: PartnerApi()
  /// nó sẽ tự tạo ApiClient với FlutterSecureStorage.
  PartnerApi({ApiClient? client})
    : client = client ?? ApiClient(storage: const FlutterSecureStorage());

  /// Gọi BE lấy dữ liệu dashboard tài trợ
  Future<PartnerSponsorshipDashboard> fetchDashboard() async {
    final response = await client.get('/api/partner/dashboard/sponsorship');

    if (response.statusCode != 200) {
      throw Exception('Lỗi gọi API: ${response.statusCode} - ${response.body}');
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return PartnerSponsorshipDashboard.fromJson(json);
  }

  // Sau này nếu cần thêm API khác (tạo tài trợ, tạo chiến dịch, …)
  // bạn thêm method vào đây.
}
