import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Quiz.dart';

class HomeQuiz extends StatefulWidget {
  final int quizId;
  final int userId;

  const HomeQuiz({super.key, required this.quizId, required this.userId});

  @override
  State<HomeQuiz> createState() => _HomeQuizState();
}

class _HomeQuizState extends State<HomeQuiz> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
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
                      quizId: widget.quizId,
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        // 👇 ĐẶT ĐỘ CAO KHOẢNG 70 NHƯ BẠN MUỐN
        toolbarHeight: 70,
        leadingWidth: 46,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/minigame',
              (route) => false,
            );
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EcoTrack Quiz',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2), // Tạo khoảng cách nhỏ giữa 2 dòng chữ
            Text(
              'Khám phá kiến thức môi trường',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
