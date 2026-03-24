import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/ai_classification/ai_waste_classification_service.dart';
import 'package:frontend_ecotrack/data/models/ai_classification/ai_waste_classification_models.dart';
import 'package:image_picker/image_picker.dart';

class WasteAiClassificationPage extends StatefulWidget {
  const WasteAiClassificationPage({super.key});

  @override
  State<WasteAiClassificationPage> createState() =>
      _WasteAiClassificationPageState();
}

class _WasteAiClassificationPageState extends State<WasteAiClassificationPage> {
  final AiWasteClassificationService _service = AiWasteClassificationService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String _selectedFileName = 'waste_image.jpg';
  bool _isClassifying = false;
  String? _errorMessage;
  AiWasteClassificationData? _result;

  Future<void> _pickImage() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );

        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _selectedImageBytes = result.files.single.bytes;
            _selectedFileName = result.files.single.name;
            _result = null;
          });
        }
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedFileName = image.name;
          _result = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể chọn ảnh: $e';
      });
    }
  }

  Future<void> _classifyImage() async {
    if (_selectedImageBytes == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn ảnh trước khi phân loại.';
      });
      return;
    }

    setState(() {
      _isClassifying = true;
      _errorMessage = null;
      _result = null;
    });

    final response = await _service.classifyWasteImageBytes(
      imageBytes: _selectedImageBytes!,
      fileName: _selectedFileName,
    );

    if (!mounted) return;

    setState(() {
      _isClassifying = false;
      if (response.success && response.data != null) {
        _result = response.data;
      } else {
        _errorMessage = response.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Phân Lọai Rác'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildImagePreview(theme),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn Ảnh'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isClassifying ? null : _classifyImage,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  _isClassifying ? 'Đang Phân Loại...' : 'Phân Loại Bằng AI',
                ),
              ),
              if (_isClassifying) ...[
                const SizedBox(height: 18),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                _buildResultCard(_result!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0D0D0)),
      ),
      child: _selectedImageBytes == null
          ? const Center(child: Text('Chưa có ảnh được chọn'))
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
    );
  }

  Widget _buildResultCard(AiWasteClassificationData result) {
    final groupedCounts = _buildGroupedCounts(result);
    final averageConfidenceByType = _buildAverageConfidenceByType(result);
    final groupedEntries = groupedCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalGroupedCount = groupedCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    const int maxDisplayedGroups = 5;
    final displayedEntries = groupedEntries.take(maxDisplayedGroups).toList();
    final hiddenGroups = groupedEntries.length - displayedEntries.length;
    final hiddenCount = hiddenGroups > 0
        ? groupedEntries
              .skip(maxDisplayedGroups)
              .fold<int>(0, (sum, entry) => sum + entry.value)
        : 0;
    final topEntry = groupedEntries.isNotEmpty ? groupedEntries.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết Quả AI',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _infoRow('Phát hiện rác', result.trashDetected ? 'Có' : 'Không'),
          _infoRow(
            'Độ tin cậy tổng',
            '${(result.overallConfidence * 100).toStringAsFixed(1)}%',
          ),
          _infoRow(
            'Tổng vật thể nhận diện',
            result.totalObjectsDetected.toString(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tổng Hợp Theo Loại Rác',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (groupedEntries.isEmpty)
            const Text('Không có dữ liệu loại rác để tổng hợp.')
          else
            ...displayedEntries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${entry.value} vat | ${_toPercentText(entry.value, totalGroupedCount)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (averageConfidenceByType.containsKey(entry.key))
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '| ${(averageConfidenceByType[entry.key]! * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Color(0xFF4A5568)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (hiddenGroups > 0)
            Text(
              '... va $hiddenGroups loai khac ($hiddenCount vat)',
              style: const TextStyle(color: Color(0xFF4A5568)),
            ),
          if (topEntry != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                'Loại chiêm ưu thế: ${topEntry.key} (${topEntry.value} vat - ${_toPercentText(topEntry.value, totalGroupedCount)}).',
                style: const TextStyle(
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Thông tin đã được nhóm từ ${result.detections.length} vùng nhận diện để dễ theo dõi hơn.',
            style: const TextStyle(color: Color(0xFF4A5568)),
          ),
        ],
      ),
    );
  }

  Map<String, int> _buildGroupedCounts(AiWasteClassificationData result) {
    if (result.wasteTypes.isNotEmpty) {
      final rawCounts = <String, int>{};
      final sumFromWasteTypes = result.wasteTypes.values.fold<double>(
        0,
        (sum, value) => sum + value,
      );

      final looksLikeCounts =
          sumFromWasteTypes > 100 ||
          (result.totalObjectsDetected > 0 &&
              sumFromWasteTypes > result.totalObjectsDetected * 1.2);

      for (final entry in result.wasteTypes.entries) {
        final key = entry.key.trim();
        if (key.isEmpty) continue;

        final value = entry.value;
        if (looksLikeCounts) {
          rawCounts[key] = value.round();
        } else if (result.totalObjectsDetected > 0) {
          rawCounts[key] = ((value / 100) * result.totalObjectsDetected)
              .round();
        }
      }

      final hasPositiveCount = rawCounts.values.any((count) => count > 0);
      if (hasPositiveCount) {
        return rawCounts;
      }
    }

    final fallbackCounts = <String, int>{};
    for (final detection in result.detections) {
      final label = detection.classNameVietnamese.trim().isNotEmpty
          ? detection.classNameVietnamese.trim()
          : detection.classNameRaw.trim();
      if (label.isEmpty) continue;
      fallbackCounts[label] = (fallbackCounts[label] ?? 0) + 1;
    }
    return fallbackCounts;
  }

  Map<String, double> _buildAverageConfidenceByType(
    AiWasteClassificationData result,
  ) {
    if (result.detections.isEmpty) {
      return {};
    }

    final totalConfidence = <String, double>{};
    final counts = <String, int>{};

    for (final detection in result.detections) {
      final label = detection.classNameVietnamese.trim().isNotEmpty
          ? detection.classNameVietnamese.trim()
          : detection.classNameRaw.trim();
      if (label.isEmpty) continue;

      totalConfidence[label] =
          (totalConfidence[label] ?? 0) + detection.confidence;
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final averages = <String, double>{};
    for (final entry in counts.entries) {
      final total = totalConfidence[entry.key] ?? 0;
      averages[entry.key] = total / entry.value;
    }
    return averages;
  }

  String _toPercentText(int value, int total) {
    if (total <= 0) return '0%';
    final percentage = (value / total) * 100;
    return '${percentage.toStringAsFixed(1)}%';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF4A5568)),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
