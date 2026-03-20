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
      appBar: AppBar(title: const Text('AI Phan Loai Rac'), centerTitle: true),
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
                label: const Text('Chon Anh'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isClassifying ? null : _classifyImage,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  _isClassifying ? 'Dang Phan Loai...' : 'Phan Loai Bang AI',
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
          ? const Center(child: Text('Chua co anh duoc chon'))
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
    final sortedWasteTypes = result.wasteTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            'Ket Qua AI',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _infoRow('Phat hien rac', result.trashDetected ? 'Co' : 'Khong'),
          _infoRow(
            'Do tin cay tong',
            '${(result.overallConfidence * 100).toStringAsFixed(2)}%',
          ),
          _infoRow('So doi tuong', result.totalObjectsDetected.toString()),
          const SizedBox(height: 12),
          const Text(
            'Ti Le Loai Rac',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (sortedWasteTypes.isEmpty)
            const Text('Khong co du lieu loai rac.')
          else
            ...sortedWasteTypes.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value.toStringAsFixed(2)}%'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Danh Sach Doi Tuong Nhan Dien',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (result.detections.isEmpty)
            const Text('Khong co doi tuong nao duoc nhan dien.')
          else
            ...result.detections.map(
              (detection) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '- ${detection.classNameVietnamese.isNotEmpty ? detection.classNameVietnamese : detection.classNameRaw} (${(detection.confidence * 100).toStringAsFixed(1)}%)',
                ),
              ),
            ),
        ],
      ),
    );
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
