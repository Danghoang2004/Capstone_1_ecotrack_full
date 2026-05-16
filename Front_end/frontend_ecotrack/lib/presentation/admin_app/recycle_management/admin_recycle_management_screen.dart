import 'dart:async';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/core/services/admin_recycle_service.dart';

class _StepDraft {
  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController imageUrlCtrl;
  final TextEditingController videoUrlCtrl;

  _StepDraft({
    String title = '',
    String description = '',
    String imageUrl = '',
    String videoUrl = '',
  }) : titleCtrl = TextEditingController(text: title),
       descriptionCtrl = TextEditingController(text: description),
       imageUrlCtrl = TextEditingController(text: imageUrl),
       videoUrlCtrl = TextEditingController(text: videoUrl);

  void dispose() {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    imageUrlCtrl.dispose();
    videoUrlCtrl.dispose();
  }
}

class AdminRecycleManagementScreen extends StatefulWidget {
  const AdminRecycleManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminRecycleManagementScreen> createState() =>
      _AdminRecycleManagementScreenState();
}

class _AdminRecycleManagementScreenState
    extends State<AdminRecycleManagementScreen> {
  final AdminRecycleService _service = AdminRecycleService.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();
  bool _loading = true;
  bool _isRefreshing = false;
  List<RecycleGuideDto> _guides = [];
  final Set<int> _selectedGuideIds = <int>{};
  Timer? _refreshTimer;
  int _currentPage = 1;
  static const int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _load();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableScrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _load(silent: true);
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted || _isRefreshing) return;
    if (!silent) setState(() => _loading = true);
    _isRefreshing = true;
    try {
      final list = await _service.listGuides();
      if (!mounted) return;
      setState(() {
        _guides = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guides = [];
        _loading = false;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  List<RecycleGuideDto> _filtered() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _guides;
    return _guides
        .where(
          (g) =>
              g.name.toLowerCase().contains(q) ||
              g.description.toLowerCase().contains(q),
        )
        .toList();
  }

  bool _isGuideSelected(int guideId) {
    return _selectedGuideIds.contains(guideId);
  }

  void _toggleGuideSelection(int guideId, bool selected) {
    setState(() {
      if (selected) {
        _selectedGuideIds.add(guideId);
      } else {
        _selectedGuideIds.remove(guideId);
      }
    });
  }

  void _toggleSelectAll(List<RecycleGuideDto> guides, bool selected) {
    setState(() {
      if (selected) {
        _selectedGuideIds.addAll(guides.map((g) => g.guideId));
      } else {
        _selectedGuideIds.removeAll(guides.map((g) => g.guideId));
      }
    });
  }

  Future<void> _deleteSelectedGuides() async {
    final selectedGuides = _guides
        .where((guide) => _selectedGuideIds.contains(guide.guideId))
        .toList();

    if (selectedGuides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một hướng dẫn để xóa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (confirmCtx) => AlertDialog(
            title: const Text('Xác nhận xóa hàng loạt'),
            content: Text(
              'Bạn có chắc chắn muốn xóa ${selectedGuides.length} hướng dẫn đã chọn không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmCtx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(confirmCtx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Xóa ngay',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    if (!mounted) return;
    try {
      for (final guide in selectedGuides) {
        await _service.deleteGuide(guide.guideId);
      }
      if (mounted) {
        setState(() {
          _selectedGuideIds.removeAll(selectedGuides.map((g) => g.guideId));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa ${selectedGuides.length} hướng dẫn thành công'),
            backgroundColor: Colors.green,
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<RecycleGuideDto> _getPageItems(
    List<RecycleGuideDto> source,
    int safePage,
  ) {
    final start = (safePage - 1) * _itemsPerPage;
    return source.skip(start).take(_itemsPerPage).toList();
  }

  void _setPage(int page, int totalPages) {
    setState(() {
      _currentPage = page.clamp(1, totalPages);
    });
  }

  // Helper to determine category color and icon based on waste type
  Map<String, dynamic> _getCategoryInfo(
    String wasteTypeKey,
    String wasteTypeLabel,
  ) {
    switch (wasteTypeKey.toLowerCase()) {
      case 'nhua':
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFF4CAF50),
          'icon': Icons.shopping_bag_outlined,
        };
      case 'giay':
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFF66BB6A),
          'icon': Icons.description_outlined,
        };
      case 'kim loai':
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFF42A5F5),
          'icon': Icons.category_outlined,
        };
      case 'pin':
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFFFFA726),
          'icon': Icons.battery_charging_full_outlined,
        };
      case 'thuy tinh':
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFF66BB6A),
          'icon': Icons.water_drop_outlined,
        };
      case 'vai':
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFFAB47BC),
          'icon': Icons.checkroom_outlined,
        };
      case 'dien tu':
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFF29B6F6),
          'icon': Icons.devices_outlined,
        };
      case 'huu co':
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFFFFCA28),
          'icon': Icons.eco_outlined,
        };
      case 'dau an':
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFFFFB300),
          'icon': Icons.local_drink_outlined,
        };
      default:
        return {
          'name': wasteTypeLabel,
          'color': const Color(0xFF90A4AE),
          'icon': Icons.recycling_outlined,
        };
    }
  }

  Future<void> _showGuideDialog({RecycleGuideDto? guide}) async {
    final isEdit = guide != null;
    final nameCtrl = TextEditingController(text: guide?.name ?? '');
    final descCtrl = TextEditingController(text: guide?.description ?? '');
    final imageCtrl = TextEditingController(text: guide?.imageUrl ?? '');
    final difficultyCtrl = TextEditingController(
      text: guide?.difficultyLevel ?? '',
    );
    final timeCtrl = TextEditingController(
      text: guide?.estimatedTimeMinutes?.toString() ?? '',
    );
    final materialsCtrl = TextEditingController(
      text: guide?.materialsNeeded ?? '',
    );
    final List<_StepDraft> stepDrafts = guide != null && guide.steps.isNotEmpty
        ? guide.steps
              .map(
                (step) => _StepDraft(
                  title: step.stepTitle,
                  description: step.stepDescription,
                  imageUrl: step.instructionImageUrl ?? '',
                  videoUrl: step.instructionVideoUrl ?? '',
                ),
              )
              .toList()
        : <_StepDraft>[_StepDraft()];

    final List<Map<String, String>> wasteTypes = [
      {'key': 'nhua', 'label': 'Nhựa'},
      {'key': 'giay', 'label': 'Giấy'},
      {'key': 'kim loai', 'label': 'Kim loại'},
      {'key': 'pin', 'label': 'Pin & Ắc quy'},
      {'key': 'thuy tinh', 'label': 'Thủy tinh'},
      {'key': 'vai', 'label': 'Vải'},
      {'key': 'dien tu', 'label': 'Điện tử'},
      {'key': 'huu co', 'label': 'Rác hữu cơ'},
    ];
    final ScrollController dialogScrollCtrl = ScrollController();

    String? selectedWasteKey = guide?.wasteTypeKey;
    bool saving = false;
    bool uploadingMedia = false;
    String? wasteTypeError;
    String? nameError;
    String? imageError;
    String? materialsError;
    final List<String?> stepTitleErrors = List<String?>.filled(
      stepDrafts.length,
      null,
      growable: true,
    );
    final List<String?> stepDescriptionErrors = List<String?>.filled(
      stepDrafts.length,
      null,
      growable: true,
    );

    Future<void> pickAndUploadToController(
      TextEditingController controller, {
      required FileType fileType,
      required void Function(VoidCallback fn) dialogSetState,
      List<String>? allowedExtensions,
      String folder = 'ecotrack/recycle',
    }) async {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không đọc được file đã chọn'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      dialogSetState(() => uploadingMedia = true);
      try {
        final fileName = file.name;
        final url = await _service.uploadMedia(
          bytes: bytes,
          fileName: fileName,
          folder: folder,
        );
        dialogSetState(() {
          controller.text = url;
          imageError = null;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          dialogSetState(() => uploadingMedia = false);
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDlg) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.adminAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.recycling_outlined,
                      color: AppColors.adminAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Chỉnh sửa hướng dẫn' : 'Thêm hướng dẫn tái chế',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(ctx).size.width * 0.88,
                child: SingleChildScrollView(
                  controller: dialogScrollCtrl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedWasteKey,
                        decoration: InputDecoration(
                          errorText: wasteTypeError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.adminSurface,
                        ),
                        items: wasteTypes.map((type) {
                          return DropdownMenuItem(
                            value: type['key'],
                            child: Text(type['label'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDlg(() {
                            selectedWasteKey = value;
                            wasteTypeError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tên',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameCtrl,
                        onChanged: (_) {
                          if (nameError != null) {
                            setStateDlg(() => nameError = null);
                          }
                        },
                        decoration: InputDecoration(
                          errorText: nameError,
                          hintText: 'Nhập tên hướng dẫn',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.adminAccent,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.adminSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Mô tả',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nhập mô tả chi tiết',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.adminAccent,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.adminSurface,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Ảnh đại diện hướng dẫn',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: imageCtrl,
                        readOnly: true,
                        onChanged: (_) {
                          if (imageError != null) {
                            setStateDlg(() => imageError = null);
                          }
                        },
                        decoration: InputDecoration(
                          errorText: imageError,
                          hintText: 'https://... (URL ảnh đại diện)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.adminAccent,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.adminSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: (saving || uploadingMedia)
                              ? null
                              : () => pickAndUploadToController(
                                  imageCtrl,
                                  fileType: FileType.image,
                                  dialogSetState: setStateDlg,
                                  folder: 'ecotrack/recycle/guide-images',
                                ),
                          icon: uploadingMedia
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file_rounded),
                          label: const Text('Chọn ảnh từ máy'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Độ khó',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: difficultyCtrl,
                        decoration: InputDecoration(
                          hintText: 'VD: Dễ, Trung bình, Khó',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.adminAccent,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.adminSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Thời gian ước tính (phút)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: timeCtrl,
                        decoration: InputDecoration(
                          hintText: 'VD: 30',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.adminAccent,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.adminSurface,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Nguyên liệu cần thiết',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: materialsCtrl,
                        onChanged: (_) {
                          if (materialsError != null) {
                            setStateDlg(() => materialsError = null);
                          }
                        },
                        decoration: InputDecoration(
                          errorText: materialsError,
                          hintText: 'VD: Chai nhựa, keo, đất trồng cây',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.adminAccent,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.adminSurface,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Các bước hướng dẫn (${stepDrafts.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setStateDlg(() {
                                stepDrafts.add(_StepDraft());
                                stepTitleErrors.add(null);
                                stepDescriptionErrors.add(null);
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (dialogScrollCtrl.hasClients) {
                                  dialogScrollCtrl.animateTo(
                                    dialogScrollCtrl.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Thêm bước'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(stepDrafts.length, (index) {
                        final step = stepDrafts[index];
                        return Container(
                          key: ValueKey(
                            'step_${index}_${step.titleCtrl.hashCode}',
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.adminBorder),
                            color: AppColors.adminSurface,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Bước ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (stepDrafts.length > 1)
                                    IconButton(
                                      onPressed: () {
                                        setStateDlg(() {
                                          stepDrafts.removeAt(index);
                                          stepTitleErrors.removeAt(index);
                                          stepDescriptionErrors.removeAt(index);
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Xóa bước này',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: step.titleCtrl,
                                onChanged: (_) {
                                  if (stepTitleErrors[index] != null) {
                                    setStateDlg(
                                      () => stepTitleErrors[index] = null,
                                    );
                                  }
                                },
                                decoration: InputDecoration(
                                  errorText: stepTitleErrors[index],
                                  hintText: 'Tiêu đề bước',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: step.descriptionCtrl,
                                maxLines: 3,
                                onChanged: (_) {
                                  if (stepDescriptionErrors[index] != null) {
                                    setStateDlg(
                                      () => stepDescriptionErrors[index] = null,
                                    );
                                  }
                                },
                                decoration: InputDecoration(
                                  errorText: stepDescriptionErrors[index],
                                  hintText: 'Nội dung chi tiết bước này',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: step.imageUrlCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Ảnh bước (tự upload từ máy)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: (saving || uploadingMedia)
                                      ? null
                                      : () => pickAndUploadToController(
                                          step.imageUrlCtrl,
                                          fileType: FileType.image,
                                          dialogSetState: setStateDlg,
                                          folder:
                                              'ecotrack/recycle/step-images',
                                        ),
                                  icon: const Icon(Icons.image_outlined),
                                  label: const Text('Chọn ảnh bước từ máy'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: step.videoUrlCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Video bước (tự upload từ máy)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: (saving || uploadingMedia)
                                      ? null
                                      : () => pickAndUploadToController(
                                          step.videoUrlCtrl,
                                          fileType: FileType.video,
                                          dialogSetState: setStateDlg,
                                          folder:
                                              'ecotrack/recycle/step-videos',
                                        ),
                                  icon: const Icon(
                                    Icons.video_library_outlined,
                                  ),
                                  label: const Text('Chọn video bước từ máy'),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setStateDlg(() {
                            saving = true;
                            wasteTypeError = null;
                            nameError = null;
                            imageError = null;
                            materialsError = null;
                            for (int i = 0; i < stepTitleErrors.length; i++) {
                              stepTitleErrors[i] = null;
                              stepDescriptionErrors[i] = null;
                            }
                          });

                          bool hasValidationError = false;
                          if (selectedWasteKey == null ||
                              selectedWasteKey!.isEmpty) {
                            wasteTypeError = 'Vui lòng chọn loại rác';
                            hasValidationError = true;
                          }
                          if (nameCtrl.text.trim().isEmpty) {
                            nameError = 'Vui lòng nhập tên hướng dẫn';
                            hasValidationError = true;
                          }
                          if (imageCtrl.text.trim().isEmpty) {
                            imageError = 'Vui lòng nhập ảnh đại diện hướng dẫn';
                            hasValidationError = true;
                          }
                          if (materialsCtrl.text.trim().isEmpty) {
                            materialsError =
                                'Vui lòng nhập nguyên liệu cần thiết';
                            hasValidationError = true;
                          }

                          for (int i = 0; i < stepDrafts.length; i++) {
                            final step = stepDrafts[i];
                            if (step.titleCtrl.text.trim().isEmpty) {
                              stepTitleErrors[i] = 'Vui lòng nhập tiêu đề bước';
                              hasValidationError = true;
                            }
                            if (step.descriptionCtrl.text.trim().isEmpty) {
                              stepDescriptionErrors[i] =
                                  'Vui lòng nhập mô tả bước';
                              hasValidationError = true;
                            }
                          }

                          if (hasValidationError) {
                            setStateDlg(() {
                              saving = false;
                            });
                            return;
                          }

                          try {
                            final stepsPayload = <Map<String, dynamic>>[];
                            for (int i = 0; i < stepDrafts.length; i++) {
                              final step = stepDrafts[i];
                              stepsPayload.add({
                                'stepTitle': step.titleCtrl.text.trim(),
                                'stepDescription': step.descriptionCtrl.text
                                    .trim(),
                                'instructionImageUrl':
                                    step.imageUrlCtrl.text.trim().isEmpty
                                    ? null
                                    : step.imageUrlCtrl.text.trim(),
                                'instructionVideoUrl':
                                    step.videoUrlCtrl.text.trim().isEmpty
                                    ? null
                                    : step.videoUrlCtrl.text.trim(),
                              });
                            }

                            final wasteLabel =
                                wasteTypes.firstWhere(
                                  (t) => t['key'] == selectedWasteKey,
                                )['label'] ??
                                selectedWasteKey;
                            final payload = {
                              'wasteTypeKey': selectedWasteKey,
                              'wasteTypeLabel': wasteLabel,
                              'name': nameCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'imageUrl': imageCtrl.text.trim(),
                              'difficultyLevel':
                                  difficultyCtrl.text.trim().isEmpty
                                  ? null
                                  : difficultyCtrl.text.trim(),
                              'estimatedTimeMinutes':
                                  int.tryParse(timeCtrl.text.trim()) ?? 0,
                              'materialsNeeded': materialsCtrl.text.trim(),
                              'steps': stepsPayload,
                            };
                            if (isEdit) {
                              await _service.updateGuide(
                                guide!.guideId,
                                payload,
                              );
                            } else {
                              await _service.createGuide(payload);
                            }
                            if (mounted) {
                              Navigator.pop(ctx);
                              await _load();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setStateDlg(() => saving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit ? 'Lưu' : 'Thêm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    // NOTE: Avoid disposing dialog controllers immediately after pop.
    // In some Flutter web rebuild timings this can trigger framework assertions.
  }

  Future<void> _showGuideDetailsDialog(RecycleGuideDto guide) async {
    final catInfo = _getCategoryInfo(guide.wasteTypeKey, guide.wasteTypeLabel);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (catInfo['color'] as Color).withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                catInfo['icon'] as IconData,
                color: catInfo['color'] as Color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Chi tiết hướng dẫn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.64,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (catInfo['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      catInfo['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: catInfo['color'] as Color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (guide.imageUrl != null &&
                      guide.imageUrl!.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        guide.imageUrl!.trim(),
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mô tả',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(guide.description),
                  const SizedBox(height: 10),
                  const Text(
                    'Nguyên liệu',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (guide.materialsNeeded ?? '').trim().isEmpty
                        ? '(Chưa có)'
                        : guide.materialsNeeded!,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Các bước',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (guide.steps.isEmpty)
                    const Text('(Chưa có bước)')
                  else
                    ...guide.steps.map(
                      (step) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.adminSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.adminBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bước ${step.stepOrder}: ${step.stepTitle}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(step.stepDescription),
                            if ((step.instructionImageUrl ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  step.instructionImageUrl!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.adminBorder.withOpacity(
                                        0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_rounded,
                                          color: AppColors.adminTextSecondary,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Không tải được ảnh',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.adminTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if ((step.instructionVideoUrl ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.video_library_outlined,
                                    size: 16,
                                    color: AppColors.adminTextSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Tooltip(
                                      message: 'Tap để mở video',
                                      child: GestureDetector(
                                        onTap: () {
                                          final url = step.instructionVideoUrl!
                                              .trim();
                                          html.window.open(url, '_blank');
                                        },
                                        child: Text(
                                          step.instructionVideoUrl!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.adminAccent,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGuide(int id) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa hướng dẫn này không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Xóa'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    try {
      await _service.deleteGuide(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa thành công'),
            backgroundColor: Colors.green,
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages == 0 ? 1 : totalPages);
    final pageItems = _getPageItems(filtered, safePage);
    final allSelected =
        pageItems.isNotEmpty &&
        pageItems.every((g) => _selectedGuideIds.contains(g.guideId));
    final someSelected = pageItems.any(
      (g) => _selectedGuideIds.contains(g.guideId),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản Lý Tái Chế',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.adminTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tạo và quản lý hướng dẫn tái chế cho người dùng',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.adminTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  cursorColor: AppColors.adminAccent,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm hướng dẫn...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.adminTextSecondary,
                    ),
                    hintStyle: const TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: AppColors.adminSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.adminBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.adminBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.adminAccent,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) => setState(() => _currentPage = 1),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showGuideDialog(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Thêm mới',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_selectedGuideIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.adminSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.adminBorder),
              ),
              child: Row(
                children: [
                  Checkbox(
                    tristate: true,
                    value: allSelected ? true : (someSelected ? null : false),
                    onChanged: (_) => _toggleSelectAll(pageItems, !allSelected),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Chọn tất cả',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${_selectedGuideIds.length} mục đã chọn',
                    style: const TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _deleteSelectedGuides,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xóa đã chọn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.adminAccent,
                    ),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.recycling_outlined,
                          size: 64,
                          color: AppColors.adminBorder,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có hướng dẫn nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.adminTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bấm "Thêm mới" để tạo hướng dẫn tái chế đầu tiên',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.adminTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.adminSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.adminBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          Container(
                            color: AppColors.adminSurfaceMuted,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Checkbox(
                                    tristate: true,
                                    value: allSelected
                                        ? true
                                        : (someSelected ? null : false),
                                    onChanged: (_) => _toggleSelectAll(
                                      pageItems,
                                      !allSelected,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Hướng dẫn',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Mô tả',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text(
                                      'Số bước',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: Text(
                                      'Mã',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 170,
                                  child: Center(
                                    child: Text(
                                      'Hành động',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _tableScrollController,
                              child: Column(
                                children: pageItems.map((guide) {
                                  final catInfo = _getCategoryInfo(
                                    guide.wasteTypeKey,
                                    guide.wasteTypeLabel,
                                  );
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: AppColors.adminBorder
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 48,
                                            child: Checkbox(
                                              value: _isGuideSelected(
                                                guide.guideId,
                                              ),
                                              onChanged: (v) =>
                                                  _toggleGuideSelection(
                                                    guide.guideId,
                                                    v ?? false,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (catInfo['color']
                                                                as Color)
                                                            .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child:
                                                      (guide.imageUrl != null &&
                                                          guide.imageUrl!
                                                              .trim()
                                                              .isNotEmpty)
                                                      ? Image.network(
                                                          guide.imageUrl!
                                                              .trim(),
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) => Icon(
                                                                catInfo['icon']
                                                                    as IconData,
                                                                color:
                                                                    catInfo['color']
                                                                        as Color,
                                                                size: 20,
                                                              ),
                                                        )
                                                      : Icon(
                                                          catInfo['icon']
                                                              as IconData,
                                                          color:
                                                              catInfo['color']
                                                                  as Color,
                                                          size: 20,
                                                        ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        guide.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              (catInfo['color']
                                                                      as Color)
                                                                  .withOpacity(
                                                                    0.12,
                                                                  ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          catInfo['name']
                                                              as String,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                catInfo['color']
                                                                    as Color,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              guide.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .adminTextSecondary,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF4CAF50,
                                                  ).withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '${guide.stepCount}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Color(
                                                          0xFF4CAF50,
                                                        ),
                                                      ),
                                                    ),
                                                    const Text(
                                                      'bước',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: Color(
                                                          0xFF4CAF50,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: Center(
                                              child: Text(
                                                '#${guide.guideId}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .adminTextSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 170,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  onTap: () =>
                                                      _showGuideDetailsDialog(
                                                        guide,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF2196F3,
                                                      ).withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.visibility_rounded,
                                                      size: 18,
                                                      color: Color(0xFF2196F3),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  onTap: () => _showGuideDialog(
                                                    guide: guide,
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.edit_note_rounded,
                                                      size: 18,
                                                      color: Color(0xFF5F6B6B),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  onTap: () => _deleteGuide(
                                                    guide.guideId,
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.delete_rounded,
                                                      size: 18,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          _buildPaginationControls(totalPages, safePage),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages, int safePage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trang $safePage / $totalPages',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.adminTextPrimary,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: safePage > 1
                    ? () => _setPage(safePage - 1, totalPages)
                    : null,
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: safePage < totalPages
                    ? () => _setPage(safePage + 1, totalPages)
                    : null,
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
