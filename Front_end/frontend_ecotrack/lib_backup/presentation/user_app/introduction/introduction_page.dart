import 'package:flutter/material.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  _IntroductionPageState createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  // Hàm giả lập gửi mail (Trong thực tế nên dùng package url_launcher)
  void _sendEmail() {
    debugPrint("Điều hướng tới: mailto:support@ecotrack.vn");
    // Thực tế: launchUrl(Uri.parse('mailto:support@ecotrack.vn'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9), // Nền trắng xanh dịu nhẹ
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B4332)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Giới Thiệu Về Nhóm Thực Hiện",
          style: TextStyle(
            color: Color(0xFF1B4332),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // 1. Brand Identity Section
            _buildHeroSection(),
            const SizedBox(height: 30),

            // 2. Mission & Vision (Sử dụng Grid-like Layout)
            _buildMissionVision(),
            const SizedBox(height: 30),

            // 3. Contact Support (Gmail Integration) - MỚI
            _buildContactSection(),
            const SizedBox(height: 40),

            // 4. Team Members
            _buildSectionHeader(Icons.groups_rounded, "Đội Ngũ Phát Triển"),
            const SizedBox(height: 15),
            _buildTeamList(),
            const SizedBox(height: 35),

            // 5. Tech Stack
            _buildSectionHeader(Icons.terminal_rounded, "Công Nghệ Cốt Lõi"),
            const SizedBox(height: 15),
            _buildTechStack(),

            const SizedBox(height: 40),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // --- COMPONENT WIDGETS ---

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'assets/icons/leaf.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "EcoTrack",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B4332),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Số hóa hành trình bảo vệ môi trường, kết nối cộng đồng vì một tương lai bền vững.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissionVision() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            "Sứ Mệnh",
            "Tối ưu hóa quản lý rác thải thông qua công nghệ.",
            const Color(0xFFD8EADF),
            Icons.lightbulb_rounded,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildInfoCard(
            "Tầm Nhìn",
            "Trở thành nền tảng xanh phổ biến nhất tại Việt Nam.",
            const Color(0xFFD1E9F0),
            Icons.auto_awesome_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String desc, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1B4332)),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Bạn có thắc mắc?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Chúng tôi luôn sẵn sàng lắng nghe phản hồi của bạn.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _sendEmail,
            icon: const Icon(Icons.mail_outline_rounded, size: 20),
            label: const Text("Liên hệ qua Gmail : dangvanhoanghk@gmail.com"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B4332),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2D6A4F), size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTeamList() {
    final members = [
      {"name": "Đặng Văn Hoàng", "role": "Project Manager"},
      {"name": "Dương Văn Hùng", "role": "Lead Developer"},
      {"name": "Trần Quý", "role": "UI/UX Designer"},
      {"name": "Lê Đức Vinh Khánh", "role": "Backend Engineer"},
      {"name": "Trần Hữu Kỳ", "role": "Mobile Developer"},
    ];
    return Column(
      children: members
          .map((m) => _buildMemberTile(m['name']!, m['role']!))
          .toList(),
    );
  }

  Widget _buildMemberTile(String name, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD8EADF),
          child: Text(
            name[0],
            style: const TextStyle(
              color: Color(0xFF1B4332),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(role, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildTechStack() {
    final techs = [
      "Flutter",
      "Dart",
      "Firebase",
      "Node.js",
      "Google Maps API",
      "Figma",
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: techs
          .map(
            (t) => Chip(
              label: Text(t, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.green[100]!),
            ),
          )
          .toList(),
    );
  }
  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: Colors.grey[300]),
        const SizedBox(height: 10),
        Text(
          "© 2025 EcoTeam - Ecotrack Project",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: () {}, child: const Text("Điều khoản")),
            const Text("•"),
            TextButton(onPressed: () {}, child: const Text("Bảo mật")),
          ],
        ),
      ],
    );
  }
}
