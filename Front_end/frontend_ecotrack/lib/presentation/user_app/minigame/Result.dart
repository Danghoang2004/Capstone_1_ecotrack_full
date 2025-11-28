import 'package:flutter/material.dart';
import 'HomeIntro.dart';

class ResultScreen extends StatelessWidget {
  final int score; // ví dụ: res.correct * 10
  final int bestStreak; // tạm thời 0 nếu chưa tính ở FE/BE
  final List<String> notes; // có thể [] nếu BE chưa trả “học thêm”
  final int quizId;
  final int userId;

  const ResultScreen({
    super.key,
    required this.score,
    required this.bestStreak,
    required this.notes,
    required this.quizId, // 👈 bắt buộc truyền
    required this.userId, // 👈 bắt buộc truyền
  });

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 8, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT
          const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 30),
              SizedBox(width: 8),
              Text(
                'Kết quả Quiz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              padding: EdgeInsets.zero, // 👈 bỏ padding mặc định
              constraints:
                  BoxConstraints(), // 👈 icon nhỏ gọn, không bị dư viền
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/user_app');
              },
            ),
          ),
          SizedBox(width: 4), // chỉnh xíu nếu muốn sát hơn hoặc xa hơn
        ],
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE8F5E8),
                child: Icon(Icons.public, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(width: 8),
              Text(
                _rank(score),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _scoreBox('Điểm số', '$score'),
                _scoreBox('Streak tối đa', '$bestStreak'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn đã học được:',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (notes.isEmpty)
            const Text('— Chưa có ghi chú.')
          else
            ...notes.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(e),
              ),
            ),
          const SizedBox(height: 18),

          // Nút chơi lại
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.recycling),
              label: const Text('Chơi lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeQuiz(quizId: quizId, userId: userId),
                ),
                (_) => false,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Nút leaderboard
          OutlinedButton.icon(
            icon: const Icon(Icons.leaderboard, color: Color(0xFF4CAF50)),
            label: const Text('Xem leaderBoard'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF4CAF50), width: 1),
              foregroundColor: const Color(0xFF4CAF50),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Leaderboard sẽ có sau khi kết nối BE.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _scoreBox(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  static String _rank(int score) {
    if (score >= 90) return 'Quá Giỏi luôn';
    if (score >= 70) return 'Cũng Khá';
    if (score >= 50) return 'Hơi Non';
    return 'Cục Vàng Giỏi Quá';
    // Bạn có thể đổi chuỗi này theo hệ thống rank của EcoTrack
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(context),
          Expanded(child: SingleChildScrollView(child: _card(context))),
        ],
      ),
    );
  }
}
