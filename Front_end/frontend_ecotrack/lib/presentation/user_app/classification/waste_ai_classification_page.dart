import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/ai_classification/ai_waste_classification_service.dart';
import 'package:frontend_ecotrack/core/services/ai_classification/recycle_suggestion_service.dart';
import 'package:frontend_ecotrack/data/models/ai_classification/ai_waste_classification_models.dart';
import 'package:frontend_ecotrack/presentation/user_app/classification/classification_history_list_page.dart';
import 'package:frontend_ecotrack/presentation/user_app/classification/recycle_suggestion_list_page.dart';
import 'package:image_picker/image_picker.dart';

class WasteAiClassificationPage extends StatefulWidget {
  const WasteAiClassificationPage({super.key});

  @override
  State<WasteAiClassificationPage> createState() =>
      _WasteAiClassificationPageState();
}

class _WasteAiClassificationPageState extends State<WasteAiClassificationPage> {
  final AiWasteClassificationService _service = AiWasteClassificationService();
  final RecycleSuggestionService _recycleSuggestionService =
      RecycleSuggestionService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String _selectedFileName = 'waste_image.jpg';
  bool _isClassifying = false;
  bool _isLoadingSuggestions = false;
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
      _isLoadingSuggestions = false;
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

  Future<void> _loadRecycleSuggestions() async {
    if (_result == null) {
      setState(() {
        _errorMessage = 'Chưa có kết quả phân loại để lấy gợi ý tái chế.';
      });
      return;
    }

    final groupedCounts = _buildGroupedCounts(_result!);
    final wasteTypes = groupedCounts.keys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (wasteTypes.isEmpty) {
      setState(() {
        _errorMessage = 'Không có loại rác hợp lệ để truy vấn gợi ý tái chế.';
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    final response = await _recycleSuggestionService.querySuggestions(
      wasteTypes: wasteTypes,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingSuggestions = false;
    });

    if (!response.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      return;
    }

    if (response.data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa có gợi ý tái chế phù hợp cho kết quả phân loại này.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecycleSuggestionListPage(suggestions: response.data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF062D2B),
        title: const Text('AI Phân Loại Rác'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử phân loại',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClassificationHistoryListPage(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _result == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: FloatingActionButton.extended(
                onPressed: (_isClassifying || _isLoadingSuggestions)
                    ? null
                    : _loadRecycleSuggestions,
                icon: _isLoadingSuggestions
                    ? const SizedBox(
                        width: 18,
                        height: 18,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAFBF3), Color(0xFFF7FCFA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 14),
                _buildActionPanel(),
                if (_isClassifying) ...[
                  const SizedBox(height: 16),
                  _buildLoadingCard(),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorCard(_errorMessage!),
                ],
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _result == null
                      ? const SizedBox.shrink()
                      : _buildResultCard(_result!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E15803D),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phân loại bằng AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tải ảnh rác thải để nhận diện nhanh và gợi ý tái chế phù hợp.',
                  style: TextStyle(color: Color(0xFFE5F7F1), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDF1EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImagePreview(),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _pickImage,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text(
              'Chọn ảnh',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isClassifying ? null : _classifyImage,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0A6358),
              side: const BorderSide(color: Color(0xFF8BD8BF)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              _isClassifying ? 'Đang phân loại...' : 'Phân loại bằng AI',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4ECE4)),
      ),
      child: _selectedImageBytes == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 34,
                    color: Color(0xFF76A89A),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chưa có ảnh được chọn',
                    style: TextStyle(
                      color: Color(0xFF4A7168),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDF1EA)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI đang phân tích ảnh, vui lòng đợi trong giây lát...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD1D1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
    final shouldShowGroupedDetails =
        result.trashDetected && groupedEntries.isNotEmpty;

    return Container(
      key: const ValueKey('classification-result-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDEDE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14003A2F),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết Quả AI',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F3C36),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow('Phát hiện rác', result.trashDetected ? 'Có' : 'Không'),
          _infoRow(
            'Độ tin cậy tổng',
            '${(result.overallConfidence * 100).toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 12),
          const Text(
            'Tổng Hợp Theo Loại Rác',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (!shouldShowGroupedDetails)
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
                  color: const Color(0xFFF5FBF8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD8ECE5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getWasteTypeVietnamese(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _toPercentText(entry.value, totalGroupedCount),
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
              '... và $hiddenGroups loại khác ($hiddenCount vật)',
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
                'Loại chiếm ưu thế: ${_getWasteTypeVietnamese(topEntry.key)} (${topEntry.value} vật - ${_toPercentText(topEntry.value, totalGroupedCount)}).',
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
