import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/data/models/ai_classification/recycle_suggestion_models.dart';
import 'package:frontend_ecotrack/presentation/user_app/classification/recycle_suggestion_detail_page.dart';

class RecycleSuggestionListPage extends StatelessWidget {
  final List<RecycleSuggestionListItem> suggestions;

  const RecycleSuggestionListPage({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<RecycleSuggestionListItem>>{};
    for (final item in suggestions) {
      final key = item.wasteTypeLabel.trim().isEmpty
          ? item.wasteTypeKey
          : item.wasteTypeLabel;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final sections = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách gợi ý tái chế'),
        centerTitle: true,
      ),
      body: sections.isEmpty
          ? const Center(
              child: Text('Chưa có gợi ý phù hợp với loại rác đã phân loại.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...section.value.map(
                        (item) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecycleSuggestionDetailPage(
                                    suggestionId: item.suggestionId,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      item.recycleImageUrl,
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 84,
                                        height: 84,
                                        color: const Color(0xFFE2E8F0),
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.shortDescription,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF4A5568),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Độ khó: ${item.difficultyLevel} • ${item.estimatedTimeMinutes ?? 0} phút',
                                          style: const TextStyle(
                                            color: Color(0xFF334155),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
