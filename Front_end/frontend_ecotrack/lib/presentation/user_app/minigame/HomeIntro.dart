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
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 210,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 18),

                        /// CARD CHÍNH
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              /// TITLE
                              const Text(
                                'Quiz môi trường',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 2),

                              const Text(
                                'Trả lời 4 câu hỏi về môi trường để kiểm tra kiến thức và nhận điểm thưởng!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 25),

                              /// BOX THÔNG TIN
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.list_alt,
                                          size: 18,
                                          color: Color(0xFF2E7D32),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "4 câu hỏi",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 18,
                                          color: Color(0xFF2E7D32),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "30s / câu",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          selectionColor: Color(0xFF2E7D32),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 13),

                              /// CATEGORY CHIPS
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final itemWidth =
                                      (constraints.maxWidth - 8) / 2;

                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      SizedBox(
                                        width: itemWidth,
                                        child: const _CategoryChip(
                                          icon: Icons.recycling,
                                          text: "Chất thải",
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: const _CategoryChip(
                                          icon: Icons.water_drop,
                                          text: "Nước",
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: const _CategoryChip(
                                          icon: Icons.bolt,
                                          text: "Năng lượng",
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: const _CategoryChip(
                                          icon: Icons.spa,
                                          text: "Sinh học",
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 25),

                              /// BUTTON BẮT ĐẦU
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 4,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.black26,
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
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4CAF50),
                                          Color(0xFF2E7D32),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Bắt đầu",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
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
                );
              },
            ),
            Positioned(
              top: 2,
              left: 0,
              child: IconButton(
                iconSize: 20,
                splashRadius: 20,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CHIP DANH MỤC MỚI
class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CategoryChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 1),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
