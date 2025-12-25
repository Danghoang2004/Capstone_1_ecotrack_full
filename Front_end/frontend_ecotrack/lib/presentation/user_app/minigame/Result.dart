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
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          toolbarHeight: 60,
          automaticallyImplyLeading: false,
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Kết quả Quiz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _buildMainCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _rankIcon(score),
              color: const Color.fromARGB(255, 217, 228, 5),
              size: 50,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _rankText(score),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 26),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'ĐIỂM SỐ',
                  '$score',
                  Icons.stars_rounded,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'STREAK',
                  '$bestStreak',
                  Icons.bolt_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),
          const Divider(height: 1, thickness: 1.1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 20),

          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kiến thức bổ ích:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 10),
                if (notes.isEmpty)
                  _buildNoteItem('Bạn đã nắm vững kiến thức bài này!')
                else
                  ...notes.map((e) => _buildNoteItem(e)),
              ],
            ),
          ),

          const SizedBox(height: 26),

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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
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
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'LÀM LẠI QUIZ',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
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

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.leaderboard_rounded, size: 20),
            label: const Text(
              'BẢNG XẾP HẠNG',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              side: const BorderSide(color: Color(0xFF4CAF50), width: 1.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {},
          ),
        ),

        const SizedBox(height: 14),

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
