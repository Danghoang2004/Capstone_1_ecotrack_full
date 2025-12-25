import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUtils {
  static String buildUrl(String? path) {
    if (path == null || path.isEmpty) return "";

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:8080";

    if (path.startsWith("http")) {
      return path;
    }

    // Đảm bảo không bị double slash
    if (path.startsWith("/")) {
      return "$baseUrl$path";
    }

    return "$baseUrl/$path";
  }
}
