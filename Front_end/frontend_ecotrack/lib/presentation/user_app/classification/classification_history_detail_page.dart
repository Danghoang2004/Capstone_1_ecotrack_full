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

  String _getWasteTypeVietnamese(String rawName) {
    switch (rawName.trim().toLowerCase()) {
      case 'bi_rac':
        return 'Bì rác';
      case 'dong_rac':
        return 'Đống rác';
      case 'tuilong_rac':
      case 'tui_long_rac':
        return 'Túi nilon rác';
      case 'rac_thai_nhua':
        return 'Rác thải nhựa';
      case 'rac_thai_giay':
        return 'Rác thải giấy';
      case 'rac_thai_kim_loai':
        return 'Rác thải kim loại';
      case 'rac_thai_thuy_tinh':
        return 'Rác thải thủy tinh';
      case 'rac_thai_huu_co':
        return 'Rác thải hữu cơ';
      case 'rac_thai_vo_co':
        return 'Rác thải vô cơ';
      default:
        final normalized = rawName.trim();
        if (normalized.isEmpty) return '';
        return normalized
            .replaceAll('_', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    }
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
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF062D2B),
        title: const Text('Chi tiết lịch sử phân loại'),
        centerTitle: true,
      ),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDEDE8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: detail.trashDetected
                            ? const Color(0xFFE8FAF3)
                            : const Color(0xFFF2F5F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        detail.trashDetected
                            ? 'Phát hiện rác'
                            : 'Không phát hiện rác',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: detail.trashDetected
                              ? const Color(0xFF0E6B57)
                              : const Color(0xFF425466),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ngày phân loại: $formattedDate',
                      style: const TextStyle(color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Độ tin cậy: ${(detail.overallConfidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (detail.trashDetected && detectedWasteTypes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDDEDE8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Các loại rác được nhận diện',
                        style: const TextStyle(
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
                                label: Text(_getWasteTypeVietnamese(type)),
                                backgroundColor: const Color(0xFFE8FAF3),
                                side: const BorderSide(
                                  color: Color(0xFFC7ECDD),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (detail.trashDetected && detectedWasteTypes.isNotEmpty)
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
