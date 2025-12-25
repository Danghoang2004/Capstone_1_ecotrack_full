import 'package:flutter/material.dart';

class AnalysisReportsScreen extends StatelessWidget {
  const AnalysisReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopStats(),
            const SizedBox(height: 24),
            _buildCouponAnalysis(),
          ],
        ),
      ),
    );
  }

  /// =======================
  /// TOP STAT CARDS
  /// =======================
  Widget _buildTopStats() {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            title: 'Tổng Doanh Thu',
            value: '580.000.000đ',
            percent: '+18%',
            icon: Icons.attach_money,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Coupon Hoạt Động',
            value: '47',
            percent: '+5',
            icon: Icons.confirmation_num_outlined,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Lượt Sử Dụng Coupon',
            value: '1.234',
            percent: '+23%',
            icon: Icons.group_outlined,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'ROI',
            value: '340%',
            percent: '+12%',
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  /// =======================
  /// COUPON ANALYSIS
  /// =======================
  Widget _buildCouponAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân Tích Coupon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Thống kê sử dụng coupon theo từng loại',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          /// Fake chart (sau này gắn chart lib)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _CouponStat(label: 'ECO20OFF', value: '156'),
              _CouponStat(label: 'GREEN50', value: '89'),
              _CouponStat(label: 'CLEANUP15', value: '234'),
              _CouponStat(label: 'EARTH25', value: '145'),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// =======================
/// STAT CARD WIDGET
/// =======================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String percent;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.percent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              Icon(icon, size: 18, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                size: 14,
                color: Color(0xFF5EAC24),
              ),
              const SizedBox(width: 4),
              Text(
                '$percent so với tháng trước',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5EAC24)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// =======================
/// COUPON STAT ITEM
/// =======================
class _CouponStat extends StatelessWidget {
  final String label;
  final String value;

  const _CouponStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
