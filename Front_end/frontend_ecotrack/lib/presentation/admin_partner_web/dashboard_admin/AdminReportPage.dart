import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/ReportService.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:frontend_ecotrack/data/utils/ImageUtils.dart';
import 'package:intl/intl.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  final ReportServiceAdmin _reportService = ReportServiceAdmin();
  final TextEditingController _searchController = TextEditingController();
  final ApiClient apiClient = ApiClient(storage: const FlutterSecureStorage());
  List<Report> _reports = [];
  List<Report> _filteredReports = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  DateTime? _lastSyncedAt;
  Timer? _refreshTimer;
  int _currentPage = 1;

  static const int _itemsPerPage = 10;
  static const Duration _refreshInterval = Duration(seconds: 35);

  // Bộ lọc
  String _selectedStatus = 'ALL';
  String _selectedLevel = 'ALL';

  int get _totalPages =>
      math.max(1, (_filteredReports.length / _itemsPerPage).ceil());

  List<Report> get _currentPageReports {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, _filteredReports.length);

    if (start >= _filteredReports.length || start < 0) {
      return const [];
    }
    return _filteredReports.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _fetchReports(silent: true);
    });
  }

  Future<void> _fetchReports({bool silent = false}) async {
    if (!mounted || _isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final data = await _reportService.fetchAllReports();
      if (mounted) {
        setState(() {
          _reports = data;
          _filterReports();
          _isLoading = false;
          _lastSyncedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _isLoading = false);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _filterReports() {
    setState(() {
      _filteredReports = _reports.where((report) {
        // Lọc theo trạng thái
        bool statusMatch =
            _selectedStatus == 'ALL' || report.status == _selectedStatus;

        // Lọc theo từ khóa tìm kiếm (Tiêu đề hoặc Mô tả)
        String query = _searchController.text.toLowerCase();
        bool searchMatch =
            query.isEmpty ||
            report.title.toLowerCase().contains(query) ||
            report.description.toLowerCase().contains(query);

        return statusMatch && searchMatch;
      }).toList();
      _currentPage = 1;
    });
  }

  Future<void> _updateStatus(int reportId, String newStatus) async {
    bool success = await _reportService.updateReportStatus(reportId, newStatus);
    if (mounted) {
      if (success) {
        _showStatusTableDialog(reportId, newStatus);
        _fetchReports();
      } else {
        _showErrorDialog();
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'VERIFIED':
        return 'Đã xác minh';
      case 'CLEANED':
        return 'Đã dọn dẹp';
      case 'REJECTED':
        return 'Đã từ chối';
      default:
        return status;
    }
  }

  void _showStatusTableDialog(int reportId, String newStatus) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF169B52)),
                    SizedBox(width: 8),
                    Text(
                      'Cập nhật trạng thái thành công',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.adminTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.adminBorder),
                  ),
                  child: Table(
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: AppColors.adminBorder),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFF4F6F8)),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Trường',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.adminTextPrimary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Giá trị',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.adminTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text('Task ID'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text('#$reportId'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text('Trạng thái mới'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(_statusLabel(newStatus)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F)),
              SizedBox(width: 8),
              Text('Lỗi cập nhật'),
            ],
          ),
          content: const Text(
            'Không thể cập nhật trạng thái task. Vui lòng thử lại.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.adminAccentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'EcoTrack Admin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.adminAccentDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Bản Đồ Báo Cáo Rác",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: AppColors.adminTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Theo dõi và quản lý các điểm báo cáo rác thải từ người dùng",
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.adminTextSecondary,
                  ),
                ),
                const SizedBox(height: 26),
                _buildStatCards(),
                const SizedBox(height: 26),
                _buildToolbar(),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredReports.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text("Không tìm thấy báo cáo nào"),
                        ),
                      )
                    : Column(
                        children: [
                          _buildReportTable(),
                          const SizedBox(height: 14),
                          _buildPagination(),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget: Các thẻ thống kê (Chờ xử lý, Đã xác minh...)
  Widget _buildStatCards() {
    // Tính toán số liệu thực tế từ list _reports
    int pending = _reports.where((r) => r.status == 'PENDING').length;
    int verified = _reports.where((r) => r.status == 'VERIFIED').length;
    int cleaned = _reports.where((r) => r.status == 'CLEANED').length;
    int total = _reports.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        const minCardWidth = 280.0;
        final width = constraints.maxWidth;
        final calculatedCardWidth = (width - (spacing * 3)) / 4;
        final cardWidth = calculatedCardWidth > minCardWidth
            ? calculatedCardWidth
            : minCardWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: cardWidth,
                child: _statCard(
                  "Chờ xử lý",
                  "$pending",
                  Icons.access_time,
                  AppColors.adminAccentWarm,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _statCard(
                  "Đã xác minh",
                  "$verified",
                  Icons.warning_amber_rounded,
                  AppColors.adminAccentSky,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _statCard(
                  "Đã dọn dẹp",
                  "$cleaned",
                  Icons.check_circle_outline,
                  AppColors.adminAccent,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _statCard(
                  "Tổng báo cáo",
                  "$total",
                  Icons.location_on_outlined,
                  const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.adminSurface, color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.adminTextSecondary,
                  fontSize: 15,
                ),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: AppColors.adminTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget: Thanh tìm kiếm và bộ lọc
  Widget _buildToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useInlineFilters = constraints.maxWidth >= 1040;
        final compactFilters = constraints.maxWidth < 760;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.adminSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.adminBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _filterReports(),
                        decoration: const InputDecoration(
                          hintText: "Tìm kiếm theo địa điểm, mô tả...",
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.search_rounded,
                            color: AppColors.adminTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (useInlineFilters) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: _buildDropdownButton(
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text("Tất cả trạng thái"),
                          ),
                          DropdownMenuItem(
                            value: 'PENDING',
                            child: Text("Chờ xử lý"),
                          ),
                          DropdownMenuItem(
                            value: 'VERIFIED',
                            child: Text("Đã xác minh"),
                          ),
                          DropdownMenuItem(
                            value: 'CLEANED',
                            child: Text("Đã dọn dẹp"),
                          ),
                          DropdownMenuItem(
                            value: 'REJECTED',
                            child: Text("Đã từ chối"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStatus = val;
                              _filterReports();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _buildDropdownButton(
                        value: _selectedLevel,
                        items: const [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text("Tất cả mức độ"),
                          ),
                          DropdownMenuItem(
                            value: 'HIGH',
                            child: Text("Nghiêm trọng"),
                          ),
                          DropdownMenuItem(
                            value: 'MEDIUM',
                            child: Text("Trung bình"),
                          ),
                          DropdownMenuItem(value: 'LOW', child: Text("Thấp")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedLevel = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
            if (!useInlineFilters) ...[
              const SizedBox(height: 12),
              compactFilters
                  ? Column(
                      children: [
                        _buildDropdownButton(
                          value: _selectedStatus,
                          items: const [
                            DropdownMenuItem(
                              value: 'ALL',
                              child: Text("Tất cả trạng thái"),
                            ),
                            DropdownMenuItem(
                              value: 'PENDING',
                              child: Text("Chờ xử lý"),
                            ),
                            DropdownMenuItem(
                              value: 'VERIFIED',
                              child: Text("Đã xác minh"),
                            ),
                            DropdownMenuItem(
                              value: 'CLEANED',
                              child: Text("Đã dọn dẹp"),
                            ),
                            DropdownMenuItem(
                              value: 'REJECTED',
                              child: Text("Đã từ chối"),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedStatus = val;
                                _filterReports();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildDropdownButton(
                          value: _selectedLevel,
                          items: const [
                            DropdownMenuItem(
                              value: 'ALL',
                              child: Text("Tất cả mức độ"),
                            ),
                            DropdownMenuItem(
                              value: 'HIGH',
                              child: Text("Nghiêm trọng"),
                            ),
                            DropdownMenuItem(
                              value: 'MEDIUM',
                              child: Text("Trung bình"),
                            ),
                            DropdownMenuItem(value: 'LOW', child: Text("Thấp")),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _selectedLevel = val);
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildDropdownButton(
                            value: _selectedStatus,
                            items: const [
                              DropdownMenuItem(
                                value: 'ALL',
                                child: Text("Tất cả trạng thái"),
                              ),
                              DropdownMenuItem(
                                value: 'PENDING',
                                child: Text("Chờ xử lý"),
                              ),
                              DropdownMenuItem(
                                value: 'VERIFIED',
                                child: Text("Đã xác minh"),
                              ),
                              DropdownMenuItem(
                                value: 'CLEANED',
                                child: Text("Đã dọn dẹp"),
                              ),
                              DropdownMenuItem(
                                value: 'REJECTED',
                                child: Text("Đã từ chối"),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedStatus = val;
                                  _filterReports();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdownButton(
                            value: _selectedLevel,
                            items: const [
                              DropdownMenuItem(
                                value: 'ALL',
                                child: Text("Tất cả mức độ"),
                              ),
                              DropdownMenuItem(
                                value: 'HIGH',
                                child: Text("Nghiêm trọng"),
                              ),
                              DropdownMenuItem(
                                value: 'MEDIUM',
                                child: Text("Trung bình"),
                              ),
                              DropdownMenuItem(
                                value: 'LOW',
                                child: Text("Thấp"),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _selectedLevel = val);
                            },
                          ),
                        ),
                      ],
                    ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDropdownButton({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildReportTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1220
            ? 1220.0
            : constraints.maxWidth;
        const sidePadding = 16.0;
        const idWidth = 120.0;
        const leadWidth = 170.0;
        const taskStateWidth = 210.0;
        const reportStateWidth = 210.0;
        const timeWidth = 180.0;
        final titleWidth =
            tableWidth -
            (sidePadding * 2) -
            idWidth -
            leadWidth -
            taskStateWidth -
            reportStateWidth -
            timeWidth;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.adminSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.adminBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF1F3F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: sidePadding,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          _buildTableHeaderCell("Task ID", idWidth),
                          _buildTableHeaderCell("Báo cáo", titleWidth),
                          _buildTableHeaderCell("Lead xử lý", leadWidth),
                          _buildTableHeaderCell(
                            "Trạng thái task",
                            taskStateWidth,
                          ),
                          _buildTableHeaderCell(
                            "Trạng thái report",
                            reportStateWidth,
                          ),
                          _buildTableHeaderCell("Giao lúc", timeWidth),
                        ],
                      ),
                    ),
                    ..._currentPageReports.asMap().entries.map((entry) {
                      final index = entry.key;
                      final report = entry.value;
                      final isLast = index == _currentPageReports.length - 1;

                      return InkWell(
                        onTap: () => _showDetailDialog(report),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: sidePadding,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? AppColors.adminSurface
                                : const Color(0xFFFCFDFC),
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: AppColors.adminBorder,
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              _buildTableCell("#${report.reportId}", idWidth),
                              _buildTableCell(
                                report.title,
                                titleWidth,
                                maxLines: 1,
                              ),
                              _buildTableCell("env_lead_01", leadWidth),
                              SizedBox(
                                width: taskStateWidth,
                                child: _buildTaskStateBadge(report.status),
                              ),
                              _buildTableCell(
                                report.status,
                                reportStateWidth,
                                fontWeight: FontWeight.w500,
                              ),
                              _buildTableCell(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(report.createdAt),
                                timeWidth,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "Trang $_currentPage/$_totalPages",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.adminTextSecondary,
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Trang trước',
          onPressed: _currentPage > 1
              ? () => setState(() => _currentPage -= 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          tooltip: 'Trang sau',
          onPressed: _currentPage < _totalPages
              ? () => setState(() => _currentPage += 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String title, double width) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.adminTextPrimary,
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text,
    double width, {
    int maxLines = 1,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: fontWeight,
          color: AppColors.adminTextPrimary,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildTaskStateBadge(String status) {
    late final Color bg;
    late final Color text;
    late final String label;

    switch (status) {
      case 'CLEANED':
        bg = const Color(0xFFDAF4E6);
        text = const Color(0xFF169B52);
        label = "Đã làm";
        break;
      case 'VERIFIED':
        bg = const Color(0xFFE3F0FF);
        text = const Color(0xFF0A66C2);
        label = "Đang làm";
        break;
      case 'PENDING':
        bg = const Color(0xFFFFF0DD);
        text = const Color(0xFFED8B00);
        label = "Chờ xử lý";
        break;
      case 'REJECTED':
        bg = const Color(0xFFFFE5E5);
        text = const Color(0xFFD32F2F);
        label = "Từ chối";
        break;
      default:
        bg = const Color(0xFFEFEFEF);
        text = Colors.black54;
        label = status;
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
      ),
    );
  }

  // Widget: Item Báo cáo (Giống thiết kế)
  Widget _buildReportItem(Report report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: Tiêu đề + Badge + Nút bấm
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(report.status),
                        // Nếu có mức độ nghiêm trọng (ví dụ từ AI), hiển thị thêm badge ở đây
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Nút hành động
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _showDetailDialog(report);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.adminTextPrimary,
                      side: const BorderSide(
                        color: AppColors.adminBorderStrong,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text("Xem chi tiết"),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(report),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dòng 2: Thông tin người gửi, thời gian
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                "Báo cáo bởi: Người dùng #${report.reportId}",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ), // Thay bằng tên user thật nếu có
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm dd/MM/yyyy').format(report.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              if (report.imageUrl.isNotEmpty) ...[
                Icon(
                  Icons.camera_alt_outlined,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  "Có hình ảnh",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case 'PENDING':
        bg = Colors.orange.withOpacity(0.1);
        text = Colors.orange;
        label = "Chờ xử lý";
        icon = Icons.access_time;
        break;
      case 'VERIFIED':
        bg = Colors.blue.withOpacity(0.1);
        text = Colors.blue;
        label = "Đã xác minh";
        icon = Icons.warning_amber_rounded;
        break;
      case 'CLEANED':
        bg = Colors.green.withOpacity(0.1);
        text = Colors.green;
        label = "Đã dọn dẹp";
        icon = Icons.check_circle_outline;
        break;
      case 'REJECTED':
        bg = Colors.red.withOpacity(0.1);
        text = Colors.red;
        label = "Từ chối";
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = Colors.grey.withOpacity(0.1);
        text = Colors.grey;
        label = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Report report) {
    if (report.status == 'PENDING') {
      return ElevatedButton(
        onPressed: () => _updateStatus(report.reportId, 'VERIFIED'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminAccentSky,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: const Text("Xác nhận"),
      );
    } else if (report.status == 'VERIFIED') {
      return ElevatedButton(
        onPressed: () => _updateStatus(report.reportId, 'CLEANED'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: const Text("Đã dọn xong"),
      );
    }
    return const SizedBox.shrink(); // Đã dọn hoặc từ chối thì không hiện nút chính
  }

  // Hàm hiển thị Popup chi tiết
  void _showDetailDialog(Report report) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: 600, // Chiều rộng cố định cho đẹp trên Web
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header ảnh
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      ImageUtils.buildUrl(report.imageUrl),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Nội dung chi tiết
              Flexible(
                // Cho phép cuộn nếu nội dung dài
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge trạng thái + Ngày giờ
                      Row(
                        children: [
                          _buildStatusBadge(report.status),
                          const Spacer(),
                          Text(
                            DateFormat(
                              'HH:mm - dd/MM/yyyy',
                            ).format(report.createdAt),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tiêu đề
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thông tin chi tiết (Grid 2 cột)
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _detailItem(
                            Icons.person,
                            "Người báo cáo",
                            "User #${report.reportId}",
                          ), // Thay ID thật nếu có
                          if (report.aiConfidence != null)
                            _detailItem(
                              Icons.smart_toy,
                              "Độ tin cậy AI",
                              "${(report.aiConfidence! * 100).toStringAsFixed(1)}%",
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Mô tả
                      const Text(
                        "Mô tả chi tiết:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.description.isEmpty
                            ? "Không có mô tả"
                            : report.description,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Footer Nút hành động (Duyệt/Xóa ngay trong popup)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "Đóng",
                        style: TextStyle(
                          color: Color.fromARGB(255, 54, 54, 54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (report.status == 'PENDING') ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text("Từ chối"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _updateStatus(report.reportId, 'REJECTED');
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Duyệt bài"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _updateStatus(report.reportId, 'VERIFIED');
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                    if (report.status == 'VERIFIED')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cleaning_services, size: 18),
                        label: const Text("Đã dọn xong"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _updateStatus(report.reportId, 'CLEANED');
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Container(
      width: 250, // Độ rộng mỗi mục
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
