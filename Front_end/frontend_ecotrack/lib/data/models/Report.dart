class Report {
  final int id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String status;
  final String category;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.status,
    required this.category,
  });

  factory Report.fromJson(Map<String, dynamic> j) {
    return Report(
      id: (j['reportId'] as num).toInt(),
      title: j['title'] ?? '',
      description: j['description'] ?? '',
      latitude: (j['gpsLat'] as num?)?.toDouble() ?? 0.0,
      longitude: (j['gpsLong'] as num?)?.toDouble() ?? 0.0,
      imageUrl: j['imageUrl'] ?? '',
      status: j['status'] ?? '',
      category: j['category'] ?? '',
    );
  }
}
