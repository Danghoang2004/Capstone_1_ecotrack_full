import 'package:flutter/material.dart';

void main() {
  runApp(const EcoTrackApp());
}

class EcoTrackApp extends StatelessWidget {
  const EcoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF008A1E);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoTrack Đối Tác',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _SideBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _TopActions(),
                  SizedBox(height: 24),
                  _StatsRow(),
                  SizedBox(height: 32),
                  Expanded(child: _CampaignsCard()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryGreen,
                child: const Icon(Icons.eco, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'EcoTrack Đối Tác',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _SideBarItem(Icons.dashboard_outlined, 'Bảng Điều Khiển'),
          const _SideBarItem(Icons.card_giftcard_outlined, 'Quản Lý Coupon'),
          const _SideBarItem(
            Icons.radio_button_checked,
            'Tài Trợ Chiến Dịch',
            selected: true,
          ),
          const _SideBarItem(Icons.analytics_outlined, 'Phân Tích & Báo Cáo'),
          const Spacer(),
          const _SideBarItem(Icons.settings_outlined, 'Cài Đặt Đối Tác'),
        ],
      ),
    );
  }
}

class _SideBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _SideBarItem(this.icon, this.label, {this.selected = false, super.key});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF0F5F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(
          icon,
          size: 22,
          color: selected ? primaryGreen : Colors.black87,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primaryGreen : Colors.black87,
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Xuất Báo Cáo'),
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Text(
            'ĐT',
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            title: 'Tổng Doanh Thu',
            value: '580.000.000đ',
            subtitle: '+18% so với tháng trước',
            icon: Icons.attach_money,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Coupon Hoạt Động',
            value: '47',
            subtitle: '+5 so với tháng trước',
            icon: Icons.local_activity_outlined,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Lượt Sử Dụng Coupon',
            value: '1.234',
            subtitle: '+23% so với tháng trước',
            icon: Icons.people_outline,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'ROI',
            value: '340%',
            subtitle: '+12% so với tháng trước',
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: primaryGreen),
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignsCard extends StatelessWidget {
  const _CampaignsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài Trợ Chiến Dịch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hỗ trợ các chiến dịch môi trường và theo dõi ROI',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Tài Trợ Chiến Dịch'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _CampaignItem(
              title: 'Dọn Dẹp Bãi Biển 2024',
              subtitle: '156 người tham gia   Tài trợ: 120Mđ',
              roi: '280%',
              status: 'đang diễn ra',
            ),
            SizedBox(height: 12),
            const _CampaignItem(
              title: 'Phục Hồi Công Viên Thành Phố',
              subtitle: '89 người tham gia   Tài trợ: 72Mđ',
              roi: '320%',
              status: 'đang diễn ra',
            ),
            SizedBox(height: 12),
            const _CampaignItem(
              title: 'Sáng Kiến Dọn Dẹp Sông',
              subtitle: '234 người tham gia   Tài trợ: 192Mđ',
              roi: '450%',
              status: 'đã kết thúc',
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String roi;
  final String status;

  const _CampaignItem({
    required this.title,
    required this.subtitle,
    required this.roi,
    required this.status,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;
    final isEnded = status.toLowerCase().contains('kết thúc');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Icon(Icons.radio_button_checked, color: primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ROI: $roi',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isEnded ? Colors.grey[200] : primaryGreen,
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: isEnded ? Colors.black54 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
