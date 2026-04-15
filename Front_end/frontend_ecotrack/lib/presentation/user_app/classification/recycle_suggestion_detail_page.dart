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
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF062D2B),
        title: const Text('Chi tiết gợi ý tái chế'),
        centerTitle: true,
      ),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              _buildHeroImage(detail),
              const SizedBox(height: 16),
              Text(
                detail.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D3F39),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.delete_outline, detail.wasteTypeLabel),
                  _buildInfoChip(
                    Icons.tune_rounded,
                    'Độ khó: ${detail.difficultyLevel}',
                  ),
                  _buildInfoChip(
                    Icons.schedule_outlined,
                    '${detail.estimatedTimeMinutes ?? 0} phút',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD9EBE3)),
                ),
                child: Text(
                  detail.shortDescription,
                  style: const TextStyle(color: Color(0xFF1E293B), height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(
                title: 'Nguyên liệu cần có',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 10),
              if (detail.materialsNeeded.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD9EBE3)),
                  ),
                  child: const Text('Chưa có thông tin nguyên liệu.'),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FAF3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBCE8D6)),
                  ),
                  child: Text(
                    detail.materialsNeeded.join(', '),
                    style: const TextStyle(
                      color: Color(0xFF0E6B57),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildSectionTitle(
                title: 'Các bước tái chế',
                icon: Icons.format_list_numbered_rounded,
              ),
              const SizedBox(height: 10),
              if (detail.steps.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD9EBE3)),
                  ),
                  child: const Text(
                    'Chưa có hướng dẫn từng bước cho gợi ý này.',
                  ),
                )
              else
                ...detail.steps.map((step) => _buildStepCard(context, step)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroImage(RecycleSuggestionDetail detail) {
    final imageUrl = detail.recycleImageUrl.trim();

    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1DAD63), Color(0xFF146C49)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F146C49),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.06),
                  Colors.black.withValues(alpha: 0.32),
                ],
              ),
            ),
          ),
          if (imageUrl.isEmpty)
            const Center(
              child: Icon(
                Icons.recycling_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ý tưởng tái chế thông minh',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE8FAF3),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF0E6B57)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FAF3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0E6B57)),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0E6B57),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, RecycleSuggestionStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9EBE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${step.stepOrder}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.stepTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D4F45),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step.stepDescription,
            style: const TextStyle(height: 1.4, color: Color(0xFF334155)),
          ),
          if ((step.instructionImageUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                step.instructionImageUrl!,
                height: 168,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 168,
                  color: const Color(0xFFE2E8F0),
                  alignment: Alignment.center,
                  child: const Text('Không tải được ảnh bước này'),
                ),
              ),
            ),
          ],
          if ((step.instructionVideoUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
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
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
