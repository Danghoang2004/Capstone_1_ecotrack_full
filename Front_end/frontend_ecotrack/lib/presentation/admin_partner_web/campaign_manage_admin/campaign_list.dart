import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignApi.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/data/models/campain.dart';

class CampaignList extends StatefulWidget {
  final VoidCallback onCreate;
  final Function(int) onEdit;
  final Function(int) onView;
  final bool showHeader;

  const CampaignList({
    super.key,
    required this.onCreate,
    required this.onEdit,
    required this.onView,
    this.showHeader = true,
  });

  @override
  State<CampaignList> createState() => _CampaignListState();
}

class _CampaignListState extends State<CampaignList> {
  static const int _itemsPerPage = 5;

  late CampaignApi _campaignApi;
  late Future<List<Campaign>> _campaignsFuture;
  final ScrollController _tableScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _campaignApi = CampaignApi(
      ApiClient(storage: const FlutterSecureStorage()),
    );
    _refreshList();
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshList() {
    setState(() {
      _campaignsFuture = _campaignApi.fetchCampaigns();
    });
  }

  List<Campaign> _filterCampaigns(List<Campaign> campaigns) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return campaigns;

    return campaigns.where((campaign) {
      return campaign.title.toLowerCase().contains(query) ||
          campaign.location.toLowerCase().contains(query) ||
          (campaign.partnerName ?? '').toLowerCase().contains(query) ||
          campaign.startDate.toLowerCase().contains(query) ||
          campaign.endDate.toLowerCase().contains(query);
    }).toList();
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _formatMoney(int amount) {
    final raw = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} đ';
  }

  String _campaignStatusLabel(Campaign campaign) {
    final now = DateTime.now();
    final start = DateTime.tryParse(campaign.startDate) ?? now;
    final end = DateTime.tryParse(campaign.endDate) ?? now;

    if (now.isBefore(start)) return 'Sắp diễn ra';
    if (now.isAfter(end)) return 'Đã kết thúc';
    return 'Đang diễn ra';
  }

  Color _campaignStatusColor(String status) {
    switch (status) {
      case 'Đang diễn ra':
        return Colors.green;
      case 'Sắp diễn ra':
        return Colors.blue;
      case 'Đã kết thúc':
        return Colors.grey;
      default:
        return AppColors.adminAccentDeep;
    }
  }

  void _setPage(int page, int totalPages) {
    setState(() {
      _currentPage = page.clamp(1, totalPages) as int;
    });
  }

  // 1. Overlay thông báo xóa thành công (Tự đóng)
  void _showDeleteSuccessOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever, color: Colors.redAccent, size: 64),
                SizedBox(height: 16),
                Text(
                  "Đã xóa!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Chiến dịch đã được loại bỏ khỏi hệ thống.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Hàm xóa chiến dịch với Dialog xác nhận ở giữa
  Future<void> _deleteCampaign(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "Xác nhận xóa",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Bạn có chắc chắn muốn xóa chiến dịch này không? Hành động này không thể hoàn tác.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        "Hủy bỏ",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Xác nhận xóa",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _campaignApi.delete(id);
        if (mounted) {
          _showDeleteSuccessOverlay(context); // Hiển thị overlay thành công
          _refreshList(); // Tải lại danh sách
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Lỗi khi xóa: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[_buildHeader(), const SizedBox(height: 24)],
        _buildSearchBar(),
        const SizedBox(height: 20),
        FutureBuilder<List<Campaign>>(
          future: _campaignsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError)
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            if (!snapshot.hasData || snapshot.data!.isEmpty)
              return const Center(child: Text("Không có chiến dịch nào"));

            final filtered = _filterCampaigns(snapshot.data!);
            final totalPages = math.max(
              1,
              (filtered.length / _itemsPerPage).ceil(),
            );
            final safePage = _currentPage.clamp(1, totalPages) as int;
            final start = (safePage - 1) * _itemsPerPage;
            final pageItems = filtered.skip(start).take(_itemsPerPage).toList();

            if (filtered.isEmpty) {
              return const Center(child: Text("Không tìm thấy chiến dịch nào"));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCampaignTable(pageItems),
                if (filtered.length > _itemsPerPage) ...[
                  const SizedBox(height: 14),
                  _buildPagination(
                    safePage: safePage,
                    totalPages: totalPages,
                    startIndex: start,
                    totalItems: filtered.length,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  // --- Các Widget thành phần đã được tách ra cho gọn ---

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quản Lý Chiến Dịch",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: AppColors.adminTextPrimary,
              ),
            ),
            Text(
              "Tạo, chỉnh sửa và theo dõi các chiến dịch thực tế",
              style: TextStyle(
                fontSize: 17,
                color: AppColors.adminTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Tạo chiến dịch mới"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() => _currentPage = 1),
      decoration: InputDecoration(
        hintText: "Tìm kiếm chiến dịch...",
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.adminSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.adminBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.adminBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.adminAccent,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignTable(List<Campaign> campaigns) {
    const sidePadding = 8.0;
    const titleWidth = 220.0;
    const statusWidth = 120.0;
    const locationWidth = 180.0;
    const dateWidth = 120.0;
    const participantWidth = 120.0;
    const budgetWidth = 130.0;
    const rewardWidth = 110.0;
    const partnerWidth = 180.0;
    const actionWidth = 120.0;

    final tableWidth =
        sidePadding * 2 +
        titleWidth +
        statusWidth +
        locationWidth +
        dateWidth +
        dateWidth +
        participantWidth +
        budgetWidth +
        rewardWidth +
        partnerWidth +
        actionWidth;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Scrollbar(
          controller: _tableScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _tableScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF1F3F6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: sidePadding,
                      vertical: 10,
                    ),
                    child: const Row(
                      children: [
                        _TableHeaderCell('Chiến dịch', titleWidth),
                        _TableHeaderCell('Trạng thái', statusWidth),
                        _TableHeaderCell('Địa điểm', locationWidth),
                        _TableHeaderCell('Bắt đầu', dateWidth),
                        _TableHeaderCell('Kết thúc', dateWidth),
                        _TableHeaderCell('Tham gia', participantWidth),
                        _TableHeaderCell('Kinh phí', budgetWidth),
                        _TableHeaderCell('Điểm thưởng', rewardWidth),
                        _TableHeaderCell('Tổ chức', partnerWidth),
                        _TableHeaderCell('Thao tác', actionWidth),
                      ],
                    ),
                  ),
                  ...campaigns.asMap().entries.map((entry) {
                    final index = entry.key;
                    final campaign = entry.value;
                    final status = _campaignStatusLabel(campaign);
                    final statusColor = _campaignStatusColor(status);
                    final progress = campaign.maxParticipants > 0
                        ? (campaign.currentParticipants /
                                  campaign.maxParticipants)
                              .clamp(0.0, 1.0)
                        : 0.0;
                    final isLast = index == campaigns.length - 1;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: sidePadding,
                        vertical: 10,
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
                          _tableCell(
                            campaign.title,
                            titleWidth,
                            maxLines: 1,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(
                            width: statusWidth,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _tableCell(campaign.location, locationWidth),
                          _tableCell(
                            _formatDate(campaign.startDate),
                            dateWidth,
                          ),
                          _tableCell(_formatDate(campaign.endDate), dateWidth),
                          _tableCell(
                            '${campaign.currentParticipants}/${campaign.maxParticipants}',
                            participantWidth,
                          ),
                          _tableCell(_formatMoney(15000000), budgetWidth),
                          _tableCell(
                            '${campaign.rewardPoints} điểm',
                            rewardWidth,
                          ),
                          _tableCell(
                            campaign.partnerName ?? 'Đang cập nhật...',
                            partnerWidth,
                          ),
                          SizedBox(
                            width: actionWidth,
                            child: Row(
                              children: [
                                _tableActionButton(
                                  icon: Icons.visibility_outlined,
                                  color: AppColors.adminAccentSky,
                                  onPressed: () => widget.onView(campaign.id),
                                ),
                                const SizedBox(width: 8),
                                _tableActionButton(
                                  icon: Icons.edit_note,
                                  color: AppColors.adminTextSecondary,
                                  onPressed: () => widget.onEdit(campaign.id),
                                ),
                                const SizedBox(width: 8),
                                _tableActionButton(
                                  icon: Icons.delete_outline,
                                  color: Colors.redAccent,
                                  onPressed: () => _deleteCampaign(campaign.id),
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildPagination({
    required int safePage,
    required int totalPages,
    required int startIndex,
    required int totalItems,
  }) {
    final endIndex = math.min(startIndex + _itemsPerPage, totalItems);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Trang $safePage/$totalPages',
          style: const TextStyle(
            color: AppColors.adminTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: safePage == 1
                  ? null
                  : () => _setPage(safePage - 1, totalPages),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Trước'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: safePage >= totalPages
                  ? null
                  : () => _setPage(safePage + 1, totalPages),
              icon: const Icon(Icons.chevron_right),
              label: const Text('Sau'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCampaignCard(Campaign c) {
    final now = DateTime.now();
    final start = DateTime.tryParse(c.startDate) ?? now;
    String status = now.isAfter(start) ? "Đang diễn ra" : "Sắp diễn ra";
    Color statusColor = now.isAfter(start) ? Colors.green : Colors.blue;
    double progress = (c.maxParticipants > 0)
        ? (c.currentParticipants / c.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _statusBadge(status, statusColor),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => widget.onView(c.id),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.adminAccentSky.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.adminAccentSky,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onEdit(c.id),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.adminSurfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        color: AppColors.adminTextSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteCampaign(c.id),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            c.description ?? "Không có mô tả",
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(c),
          const SizedBox(height: 24),
          Wrap(
            spacing: 28,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 280,
                child: _buildStatItem(
                  "Người tham gia",
                  "${c.currentParticipants}/${c.maxParticipants}",
                  progress,
                  AppColors.adminAccentSky,
                ),
              ),
              SizedBox(
                width: 280,
                child: _buildStatItem(
                  "Kinh phí",
                  "15.000.000 đ",
                  0.75,
                  AppColors.adminAccent,
                ),
              ),
              SizedBox(
                width: 160,
                child: _buildSimpleStat(
                  "Điểm thưởng",
                  "${c.rewardPoints} điểm",
                  Icons.stars_rounded,
                  AppColors.adminAccentWarm,
                ),
              ),
              SizedBox(
                width: 220,
                child: _buildSimpleStat(
                  "Tổ chức",
                  c.partnerName ?? "Đang cập nhật...",
                  Icons.account_balance_outlined,
                  const Color(0xFF8E24AA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(Campaign c) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.adminTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              c.location,
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.adminTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              "${c.startDate} - ${c.endDate}",
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_work_outlined, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _tableCell(
    String value,
    double width, {
    int maxLines = 1,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.adminTextPrimary,
          fontSize: 13,
          fontWeight: fontWeight,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _tableActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String label;
  final double width;

  const _TableHeaderCell(this.label, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.adminTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}