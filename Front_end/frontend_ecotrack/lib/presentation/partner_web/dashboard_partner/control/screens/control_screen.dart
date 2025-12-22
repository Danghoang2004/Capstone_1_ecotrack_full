import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5EAC24);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = (constraints.maxWidth - (20 * 3)) / 4;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildStatCard(
                        "Tổng Doanh Thu",
                        "580.000.000đ",
                        "-18%",
                        Icons.attach_money,
                        cardWidth,
                        isNegative: true,
                      ),
                      _buildStatCard(
                        "Coupon Hoạt Động",
                        "47",
                        "+5",
                        Icons.confirmation_number_outlined,
                        cardWidth,
                      ),
                      _buildStatCard(
                        "Lượt Sử Dụng Coupon",
                        "1.234",
                        "+23%",
                        Icons.people_outline,
                        cardWidth,
                      ),
                      _buildStatCard(
                        "ROI",
                        "340%",
                        "+12%",
                        Icons.trending_up,
                        cardWidth,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildSectionContainer(
                        title: "Hoạt Động Gần Đây",
                        subtitle: "Hoạt động và giao dịch đối tác mới nhất",
                        child: Column(
                          children: [
                            _buildActivityItem(
                              "ECO20OFF được sử dụng bởi Nguyễn Văn A",
                              "2 phút trước",
                              "1.080.000đ",
                              Colors.green,
                            ),
                            _buildActivityItem(
                              "12 người tham gia mới vào Dọn Dẹp Bãi Biển",
                              "1 giờ trước",
                              "",
                              Colors.blue,
                            ),
                            _buildActivityItem(
                              "Coupon mới GREEN50 đã được tạo",
                              "3 giờ trước",
                              "",
                              Colors.purple,
                            ),
                            _buildActivityItem(
                              "Đã tài trợ chiến dịch Phục Hồi Công Viên",
                              "1 ngày trước",
                              "72.000.000đ",
                              Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildSectionContainer(
                        title: "Chỉ Số Hiệu Suất",
                        subtitle: "Tổng quan hiệu suất đối tác của bạn",
                        child: Column(
                          children: [
                            _buildPerformanceItem(
                              "Tỷ Lệ Chuyển Đổi Coupon",
                              0.235,
                              "23.5%",
                            ),
                            _buildPerformanceItem(
                              "Tương Tác Chiến Dịch",
                              0.78,
                              "78%",
                            ),
                            _buildPerformanceItem(
                              "Hài Lòng Khách Hàng",
                              0.94,
                              "94%",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildSectionContainer(
                        title: "Doanh Thu 6 Tháng",
                        subtitle: "Biểu đồ doanh thu theo tháng",
                        child: Container(
                          height: 250,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.show_chart,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildSectionContainer(
                        title: "ROI Chiến Dịch",
                        subtitle: "Tỷ lệ lợi nhuận của các chiến dịch",
                        child: SizedBox(
                          height: 250,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBarChartItem("Dọn Bãi Biển", 280, 120),
                              _buildBarChartItem(
                                "Phục Hồi Công Viên",
                                320,
                                150,
                              ),
                              _buildBarChartItem("Dọn Sông", 450, 200),
                              _buildBarChartItem("Phố Thành Phố", 380, 170),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String trend,
    IconData icon,
    double width, {
    bool isNegative = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              Icon(icon, color: Colors.black54, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isNegative ? Icons.trending_down : Icons.trending_up,
                size: 14,
                color: isNegative ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: isNegative ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "so với tháng trước",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String text,
    String time,
    String amount,
    Color dotColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          if (amount.isNotEmpty)
            Text(
              amount,
              style: const TextStyle(
                color: Color(0xFF5EAC24),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String label, double percent, String trailing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(
                trailing,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartItem(String label, int value, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: 25,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF5EAC24).withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
