import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Quiz.dart';

class HomeQuiz extends StatefulWidget {
  /// Bạn có thể truyền quizId/userId từ màn trước (login) nếu muốn.
  final int quizId;
  final int userId;

  const HomeQuiz({
    super.key,
    required this.quizId, // ✅ bắt buộc truyền từ ngoài
    required this.userId, // ✅ bắt buộc truyền từ ngoài
  });

  @override
  State<HomeQuiz> createState() => _HomeQuizState();
}

class _HomeQuizState extends State<HomeQuiz> {
  @override
  void initState() {
    super.initState();

    // 🔥 ẨN luôn status bar khi vào màn HomeQuiz
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [], // không hiển thị status bar / nav bar
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(1, 14, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Nút thoát
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/user_app', // 👉 route về màn user main
                  (route) => false,
                );
              },
            ),
          ),

          const SizedBox(width: 0.1), // 👈 đẩy chữ sát hơn

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                'EcoTrack Quiz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 0.1),
              Text(
                'Khám phá kiến thức môi trường',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _introCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4CAF50),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 60),
          ),
          const SizedBox(height: 7),
          const Text(
            'Quiz môi trường',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Trả lời câu hỏi để kiểm tra kiến thức và nhận điểm thưởng!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 25),

          // 4 badge mô tả nhanh
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 4.0;
              final itemWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: const _Badge(
                      icon: Icons.format_list_numbered,
                      text: 'Câu hỏi',
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const _Badge(
                      icon: Icons.bolt,
                      text: 'Năng lượng',
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const _Badge(
                      icon: Icons.emoji_events,
                      text: 'Sinh thái',
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const _Badge(
                      icon: Icons.timer,
                      text: '30s/câu',
                      color: Colors.indigo,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // Nút bắt đầu: chuyển sang QuizScreen và truyền quizId + userId
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      quizId: widget.quizId, // <-- dùng widget.quizId
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              child: const Text('Bắt đầu Quiz'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Không bọc SafeArea để không tự chừa top padding nữa
      body: Column(
        children: [
          _header(context),
          Expanded(child: SingleChildScrollView(child: _introCard(context))),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Badge({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.4, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      constraints: const BoxConstraints(minHeight: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
