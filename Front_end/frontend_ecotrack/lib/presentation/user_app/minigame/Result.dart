import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_ecotrack/presentation/user_app/minigame/HomeIntro.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int bestStreak;
  final List<String> notes;
  final int quizId;
  final int userId;

  const ResultScreen({
    super.key,
    required this.score,
    required this.bestStreak,
    required this.notes,
    required this.quizId,
    required this.userId,
  });

  String _rankText(int score) {
    if (score >= 90) return 'Thiên tài môi trường!';
    if (score >= 70) return 'Rất ấn tượng!';
    if (score >= 50) return 'Làm tốt lắm!';
    return 'Chúc mừng bạn đã hoàn thành!';
  }

  IconData _rankIcon(int score) {
    if (score >= 90) return Icons.auto_awesome;
    if (score >= 70) return Icons.military_tech;
    return Icons.emoji_events;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      // BỌC SCAFFOLD BẰNG CONTAINER MÀU TRẮNG Ở ĐÂY
      child: Container(
        color: const Color(0xFFF4FBF8),
        child: Scaffold(
          backgroundColor: const Color(0xFFF4FBF8),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(13),
              child: Column(
                children: [
                  const SizedBox(height: 0.1),

                  const Text(
                    "Kết quả Quiz",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),

                  const SizedBox(height: 8),

                  _buildMainCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Icon tròn giống hình
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2E7D32), width: 3),
            ),
            child: Icon(
              _rankIcon(score),
              color: const Color(0xFF2E7D32),
              size: 45,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _rankText(score),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Bạn đã trả lời đúng ${notes.length == 0 ? "tất cả" : ""}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 5),

          /// Box điểm + streak
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Điểm số',
                    '$score',
                    Icons.stars_rounded,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Streak tối đa',
                    '$bestStreak',
                    Icons.bolt_rounded,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// Notes giữ nguyên nội dung
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "💡 Bạn đã học được:",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 6),
                if (notes.isEmpty)
                  _buildNoteItem('Bạn đã nắm vững kiến thức bài này!')
                else
                  ...notes.map((e) => _buildNoteItem(e)),
              ],
            ),
          ),

          const SizedBox(height: 13),

          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'LÀM LẠI QUIZ',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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

        const SizedBox(height: 11),

        SizedBox(
          width: double.infinity,
          height: 35,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.leaderboard_rounded, size: 20),
            label: const Text(
              ' XEM BẢNG XẾP HẠNG',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            onPressed: () {},
          ),
        ),

        const SizedBox(height: 4),

        TextButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/user_app',
            (route) => false,
          ),
          icon: const Icon(Icons.home_rounded, color: Colors.grey, size: 20),
          label: const Text(
            'Quay lại màn hình chính',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
