class FormatNumber {
  /// Format số điểm thành dạng ngắn gọn
  /// Ví dụ: 1000 -> 1k, 1000000 -> 1m, 1000000000 -> 1b
  static String formatPoints(int points) {
    if (points >= 1000000000) {
      return '${(points / 1000000000).toStringAsFixed(points % 1000000000 == 0 ? 0 : 1)}b';
    } else if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(points % 1000000 == 0 ? 0 : 1)}m';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(points % 1000 == 0 ? 0 : 1)}k';
    } else {
      return points.toString();
    }
  }
}
