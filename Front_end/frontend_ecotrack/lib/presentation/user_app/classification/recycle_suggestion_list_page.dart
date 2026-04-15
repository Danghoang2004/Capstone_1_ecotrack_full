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
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF062D2B),
        title: const Text('Danh sách gợi ý tái chế'),
        centerTitle: true,
      ),
      body: sections.isEmpty
          ? Center(
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
                    Icon(Icons.recycling_outlined, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có gợi ý phù hợp với loại rác đã phân loại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              children: [
                ...sections.map(
                  (section) => _buildSectionCard(
                    context,
                    label: section.key,
                    items: section.value,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String label,
    required List<RecycleSuggestionListItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDEDE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D4F45),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FAF3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length} gợi ý',
                  style: const TextStyle(
                    color: Color(0xFF0E6B57),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => _buildSuggestionItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(
    BuildContext context,
    RecycleSuggestionListItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8ECE5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RecycleSuggestionDetailPage(suggestionId: item.suggestionId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  item.recycleImageUrl,
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 86,
                    height: 86,
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
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1C2C29),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF526F67),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildTag('Độ khó: ${item.difficultyLevel}'),
                        _buildTag('${item.estimatedTimeMinutes ?? 0} phút'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFF6C8A82)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FAF3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0E6B57),
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
