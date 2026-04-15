import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/ai_classification/recycle_suggestion_service.dart';
import 'package:frontend_ecotrack/data/models/ai_classification/recycle_suggestion_models.dart';
import 'package:frontend_ecotrack/presentation/user_app/classification/recycle_suggestion_video_page.dart';

class RecycleSuggestionDetailPage extends StatefulWidget {
  final int suggestionId;

  const RecycleSuggestionDetailPage({super.key, required this.suggestionId});

  @override
  State<RecycleSuggestionDetailPage> createState() =>
      _RecycleSuggestionDetailPageState();
}

class _RecycleSuggestionDetailPageState
    extends State<RecycleSuggestionDetailPage> {
  final RecycleSuggestionService _service = RecycleSuggestionService();
  late Future<RecycleSuggestionDetailResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getSuggestionDetail(widget.suggestionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết gợi ý tái chế')),
      body: FutureBuilder<RecycleSuggestionDetailResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          final response = snapshot.data;
          if (response == null || !response.success || response.data == null) {
            return Center(
              child: Text(response?.message ?? 'Không thể tải chi tiết gợi ý.'),
            );
          }

          final detail = response.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  detail.recycleImageUrl,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                detail.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${detail.wasteTypeLabel} • Độ khó: ${detail.difficultyLevel} • ${detail.estimatedTimeMinutes ?? 0} phút',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                detail.shortDescription,
                style: const TextStyle(color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nguyên liệu cần có',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (detail.materialsNeeded.isEmpty)
                const Text('Chưa có thông tin nguyên liệu.')
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    detail.materialsNeeded.join(', '),
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Các bước tái chế',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (detail.steps.isEmpty)
                const Text('Chưa có hướng dẫn từng bước cho gợi ý này.')
              else
                ...detail.steps.map(
                  (step) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bước ${step.stepOrder}: ${step.stepTitle}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(step.stepDescription),
                        if ((step.instructionImageUrl ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              step.instructionImageUrl!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 160,
                                color: const Color(0xFFE2E8F0),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Không tải được ảnh bước này',
                                ),
                              ),
                            ),
                          ),
                        ],
                        if ((step.instructionVideoUrl ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RecycleSuggestionVideoPage(
                                      url: step.instructionVideoUrl!,
                                      title: step.stepTitle,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_circle_outline),
                              label: const Text('Xem video hướng dẫn'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
