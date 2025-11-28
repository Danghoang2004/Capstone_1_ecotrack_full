import 'package:flutter/material.dart';

void main() {
  runApp(const EcoTrackApp());
}

class EcoTrackApp extends StatelessWidget {
  const EcoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class Campaign {
  final String title;
  final String description;
  final double progress;
  final String progressText;
  final String participants;
  final String daysLeft;
  final String image;
  final String status; // "ongoing" hoặc "upcoming"

  Campaign({
    required this.title,
    required this.description,
    required this.progress,
    required this.progressText,
    required this.participants,
    required this.daysLeft,
    required this.image,
    required this.status,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedFilter = "all";

  List<Campaign> campaigns = [
    Campaign(
      title: "Thu gom rác thải điện tử",
      description: "Tham gia chiến dịch thu gom điện thoại cũ để tái chế",
      progress: 0.75,
      progressText: "75%",
      participants: "1,240 người tham gia",
      daysLeft: "5 ngày còn lại",
      image:
          "Back_end/Ecotrack_backend/uploads/reports/CampaignImg/cyberTrash.png",
      status: "ongoing",
    ),
    Campaign(
      title: "Trồng cây xanh tháng 11",
      description:
          "Cùng nhau trồng 1000 cây để tạo không gian xanh cho thành phố",
      progress: 0.45,
      progressText: "45%",
      participants: "850 người tham gia",
      daysLeft: "12 ngày còn lại",
      image:
          "Back_end/Ecotrack_backend/uploads/reports/CampaignImg/plant1000Tree.png",
      status: "ongoing",
    ),
    Campaign(
      title: "Chiến dịch làm sạch bờ biển 2025",
      description: "Cùng nhau thu gom rác thải nhựa tại bờ biển",
      progress: 0.0,
      progressText: "0%",
      participants: "120 người đăng ký",
      daysLeft: "Bắt đầu sau 3 ngày",
      image:
          "Back_end/Ecotrack_backend/uploads/reports/CampaignImg/cleanBeach.png",
      status: "upcoming",
    ),
  ];

  List<Campaign> get filteredCampaigns {
    if (selectedFilter == "ongoing") {
      return campaigns.where((c) => c.status == "ongoing").toList();
    } else if (selectedFilter == "upcoming") {
      return campaigns.where((c) => c.status == "upcoming").toList();
    }
    return campaigns;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Column(
        children: [
          // =================== HEADER ===================
          Container(
            height: 110,
            padding: const EdgeInsets.only(top: 40, left: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF2EAD57),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.eco, color: Colors.green),
                ),
                SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "EcoTrack",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Bảo vệ môi trường cùng nhau",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =================== FILTER TABS ===================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTab("Tất cả", "all"),
                const SizedBox(width: 10),
                _buildTab("Đang diễn ra", "ongoing"),
                const SizedBox(width: 10),
                _buildTab("Sắp tới", "upcoming"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =================== CONTENT ===================
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: filteredCampaigns
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildCampaignCard(c),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================ TAB BUTTON ============================
  Widget _buildTab(String text, String value) {
    bool selected = selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2EAD57) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================ CAMPAIGN CARD ============================
  Widget _buildCampaignCard(Campaign c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Image.asset(c.image, height: 60)),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.status == "ongoing"
                      ? const Color(0xFFE2F7EA)
                      : const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  c.status == "ongoing" ? "Đang diễn ra" : "Sắp tới",
                  style: TextStyle(
                    color: c.status == "ongoing"
                        ? const Color(0xFF2EAD57)
                        : const Color(0xFFFFA500),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),
          Text(
            c.description,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 15),

          const Text(
            "Tiến độ",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),

          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width:
                    MediaQuery.of(context).size.width *
                    0.7 *
                    c.progress, // Responsive width
                decoration: BoxDecoration(
                  color: const Color(0xFF2EAD57),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.group, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    c.participants,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Text(
                c.daysLeft,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2EAD57),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: const Text(
                "Tham gia ngay",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
