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
      appBar: AppBar(title: const Text('Lịch sử phân loại'), centerTitle: true),
      body: FutureBuilder<ClassificationHistoryListResponse>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              !snapshot.data!.success ||
              snapshot.data!.data == null ||
              snapshot.data!.data!.isEmpty) {
            return const Center(child: Text('Chưa có lịch sử phân loại nào.'));
          }

          final histories = snapshot.data!.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final history = histories[index];
              final dateTime = DateTime.tryParse(history.createdAt);
              final formattedDate = dateTime != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
                  : history.createdAt;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassificationHistoryDetailPage(
                          historyId: history.historyId,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    history.trashDetected
                                        ? 'Phát hiện rác'
                                        : 'Không phát hiện rác',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Độ tự tin: ${(history.overallConfidence * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                history.originalImageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số lượng: ${history.totalObjectsDetected}',
                              style: const TextStyle(
                                color: Color(0xFF4A5568),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
