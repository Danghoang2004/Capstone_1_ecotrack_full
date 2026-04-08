import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/ai_classification/classification_history_service.dart';
import 'package:frontend_ecotrack/core/services/ai_classification/recycle_suggestion_service.dart';
import 'package:frontend_ecotrack/data/models/ai_classification/classification_history_models.dart';
import 'package:frontend_ecotrack/presentation/user_app/classification/recycle_suggestion_list_page.dart';
import 'package:intl/intl.dart';

class ClassificationHistoryDetailPage extends StatefulWidget {
  final int historyId;

  const ClassificationHistoryDetailPage({super.key, required this.historyId});

  @override
  State<ClassificationHistoryDetailPage> createState() =>
      _ClassificationHistoryDetailPageState();
}

class _ClassificationHistoryDetailPageState
    extends State<ClassificationHistoryDetailPage> {
  final ClassificationHistoryService _historyService =
      ClassificationHistoryService();
  final RecycleSuggestionService _recycleSuggestionService =
      RecycleSuggestionService();
  late Future<ClassificationHistoryDetailResponse> _future;
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _future = _historyService.getHistoryDetail(widget.historyId);
  }

  List<String> _extractWasteTypeNames(ClassificationHistoryDetail detail) {
    final names = <String>{};

    final raw = detail.wasteTypesJson.trim();
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final key in decoded.keys) {
            final label = key.toString().trim();
            if (label.isNotEmpty) {
              names.add(label);
            }
          }
        } else if (decoded is List) {
          for (final item in decoded) {
            final label = item.toString().trim();
            if (label.isNotEmpty) {
              names.add(label);
            }
          }
        }
      } catch (_) {
        // Ignore malformed JSON and fallback to parsed wasteTypes.
      }
    }

    if (names.isEmpty) {
      for (final item in detail.wasteTypes) {
        final label = item.trim();
        if (label.isNotEmpty) {
          names.add(label);
        }
      }
    }

    return names.toList();
  }

  Future<void> _loadRecycleSuggestions(List<String> wasteTypes) async {
    if (wasteTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có loại rác nào để lấy gợi ý.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    final response = await _recycleSuggestionService.querySuggestions(
      wasteTypes: wasteTypes,
    );

    setState(() {
      _isLoadingSuggestions = false;
    });

    if (!mounted) return;

    if (response.success &&
        response.data != null &&
        response.data!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RecycleSuggestionListPage(suggestions: response.data!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Không có gợi ý phù hợp.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết lịch sử phân loại')),
      body: FutureBuilder<ClassificationHistoryDetailResponse>(
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
              child: Text(
                response?.message ?? 'Không thể tải chi tiết lịch sử.',
              ),
            );
          }

          final detail = response.data!;
          final detectedWasteTypes = _extractWasteTypeNames(detail);
          final dateTime = DateTime.tryParse(detail.createdAt);
          final formattedDate = dateTime != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
              : detail.createdAt;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  detail.originalImageUrl,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 240,
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.trashDetected
                            ? 'Phát hiện rác'
                            : 'Không phát hiện rác',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ngày phân loại: $formattedDate',
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Độ tự tin: ${(detail.overallConfidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Số lượng phát hiện: ${detail.totalObjectsDetected}',
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (detectedWasteTypes.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Các loại rác được nhận diện',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detectedWasteTypes
                          .map(
                            (type) => Chip(
                              label: Text(type),
                              backgroundColor: const Color(0xFFE2E8F0),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              if (detectedWasteTypes.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingSuggestions
                        ? null
                        : () => _loadRecycleSuggestions(detectedWasteTypes),
                    icon: _isLoadingSuggestions
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.recycling),
                    label: Text(
                      _isLoadingSuggestions
                          ? 'Đang tải gợi ý...'
                          : 'Xem gợi ý tái chế',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
