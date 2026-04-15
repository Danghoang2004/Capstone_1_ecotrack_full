import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/ai_classification/classification_history_service.dart';
import 'package:frontend_ecotrack/data/models/ai_classification/classification_history_models.dart';
import 'package:frontend_ecotrack/presentation/user_app/classification/classification_history_detail_page.dart';
import 'package:intl/intl.dart';

class ClassificationHistoryListPage extends StatefulWidget {
  const ClassificationHistoryListPage({super.key});

  @override
  State<ClassificationHistoryListPage> createState() =>
      _ClassificationHistoryListPageState();
}

class _ClassificationHistoryListPageState
    extends State<ClassificationHistoryListPage> {
  late Future<ClassificationHistoryListResponse> _historyFuture;
  final ClassificationHistoryService _historyService =
      ClassificationHistoryService();

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyService.getClassificationHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF062D2B),
        title: const Text('Lịch sử phân loại'),
        centerTitle: true,
      ),
      body: FutureBuilder<ClassificationHistoryListResponse>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không thể tải lịch sử: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8B1E1E)),
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.success ||
              snapshot.data!.data == null ||
              snapshot.data!.data!.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDEDE8)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_toggle_off, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có lịch sử phân loại nào.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            );
          }

          final histories = snapshot.data!.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            children: [
              ...histories.map(
                (history) => _buildHistoryCard(context, history),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    ClassificationHistoryListItem history,
  ) {
    final dateTime = DateTime.tryParse(history.createdAt);
    final formattedDate = dateTime != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
        : history.createdAt;
    final confidencePercent =
        '${(history.overallConfidence * 100).toStringAsFixed(1)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDEDE8)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ClassificationHistoryDetailPage(historyId: history.historyId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  history.originalImageUrl,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 88,
                    height: 88,
                    color: const Color(0xFFE5EEE9),
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.trashDetected
                          ? 'Phát hiện rác'
                          : 'Không phát hiện rác',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8FAF3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Độ tin cậy: $confidencePercent',
                        style: const TextStyle(
                          color: Color(0xFF0E6B57),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: Color(0xFF6C8A82),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Color(0xFF6C8A82),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Color(0xFF7C948E)),
            ],
          ),
        ),
      ),
    );
  }
}
