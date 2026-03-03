import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/UserCouponItem.dart';

class UserCouponApi {
  final ApiClient _api;

  UserCouponApi(this._api);

  Future<List<UserCouponItem>> fetchMyCoupons() async {
    final res = await _api.get('/api/user/coupons/me');

    dynamic json;
    if (res is http.Response) {
      json = jsonDecode(utf8.decode(res.bodyBytes));
    } else {
      json = res;
    }
    if (json is List) {
      return json.map((e) => UserCouponItem.fromJson(e, _api)).toList();
    }
    if (json is Map && json['data'] is List) {
      return (json['data'] as List)
          .map((e) => UserCouponItem.fromJson(e, _api))
          .toList();
    }

    throw Exception('Invalid coupon response format');
  }
}
