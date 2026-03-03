import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/quiz_models.dart';
import 'Result.dart';

class QuizScreen extends StatefulWidget {
  final int quizId;
  final int userId;
  const QuizScreen({super.key, required this.quizId, required this.userId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final repo = QuizRepository();

  late Future<QuizDetail> _future;
  QuizDetail? _quiz;

  int idx = 0;
  String? selectedKey;
  final Map<int, String> answers = {};

  static const int perQSec = 30;
  int remain = perQSec;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _future = repo.getQuiz(widget.quizId);
    _future.then((q) {
      if (!mounted) return;
      setState(() => _quiz = q);
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      remain = perQSec;
      selectedKey = null; // Reset lựa chọn khi qua câu mới
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      if (remain <= 1) {
        t.cancel();
        // Hết giờ thì ép buộc sang câu tiếp theo hoặc nộp bài
        _nextOrSubmit();
        return;
      }

      setState(() => remain--);
    });
  }

  void _choose(String key) {
    if (selectedKey != null) return; // Đã chọn rồi thì không cho chọn lại

    setState(() {
      selectedKey = key;
    });

    _timer?.cancel(); // Dừng đồng hồ để người dùng xem đáp án đúng sai
  }

  Future<void> _nextOrSubmit() async {
    _timer?.cancel();

    final q = _quiz!.questions[idx];
    if (selectedKey != null) {
      answers[q.id] = selectedKey!;
    }

    if (!mounted) return;

    final isLast = idx == _quiz!.questions.length - 1;

    if (!isLast) {
      setState(() {
        idx++;
      });
      _startTimer();
    } else {
      await _submitToServer();
    }
  }

  Future<void> _submitToServer() async {
    try {
      final res = await repo.submit(widget.quizId, answers);

      int best = 0, cur = 0;
      for (final ok in res.correctnessList) {
        if (ok) {
          cur++;
          if (cur > best) best = cur;
        } else {
          cur = 0;
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            score: res.correct * 10,
            bestStreak: best,
            notes: const [],
            quizId: widget.quizId,
            userId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nộp bài lỗi: $e')));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuizDetail>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting || _quiz == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Lỗi tải quiz: ${snap.error}')),
          );
        }

        final total = _quiz!.questions.length;
        final q = _quiz!.questions[idx];
        final isLast = idx == total - 1;
        final bool isAnswered = selectedKey != null;

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: const Color(0xFFEAF3EC),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Câu ${idx + 1}/$total',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 18,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${remain}s',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  /// PROGRESS BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (idx + 1) / total,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),

                  /// CARD CHÍNH
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.help_outline,
                            color: Color(0xFF2E7D32),
                            size: 30,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            q.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 12),

                          /// OPTIONS
                          Expanded(
                            child: ListView.builder(
                              itemCount: q.options.length,
                              itemBuilder: (context, i) {
                                final op = q.options[i];

                                // LOGIC HIỂN THỊ ĐÚNG SAI
                                bool isSelected = selectedKey == op.key;
                                bool isCorrectOption = op.key == q.correctKey;

                                Color bgColor = const Color(
                                  0xFFF1F5F2,
                                ); // Mặc định xám nhạt
                                Color textColor = Colors.black87;
                                Color borderColor = Colors.transparent;
                                IconData iconData =
                                    Icons.radio_button_unchecked;
                                Color iconColor = Colors.grey;

                                if (isAnswered) {
                                  if (isCorrectOption) {
                                    bgColor = const Color(
                                      0xFF2E7D32,
                                    ); // Xanh lá
                                    textColor = Colors.white;
                                    iconData = Icons.check_circle;
                                    iconColor = Colors.white;
                                  } else if (isSelected) {
                                    bgColor = Colors.red.shade400; // Đỏ
                                    textColor = Colors.white;
                                    iconData = Icons.cancel;
                                    iconColor = Colors.white;
                                  } else {
                                    // Những đáp án không chọn và không đúng sẽ bị làm mờ đi
                                    bgColor = const Color(
                                      0xFFF1F5F2,
                                    ).withOpacity(0.5);
                                    textColor = Colors.black38;
                                    iconColor = Colors.grey.shade300;
                                  }
                                } else if (isSelected) {
                                  // Trường hợp hover/click (thường rất nhanh trước khi isAnswered có tác dụng)
                                  bgColor = const Color(0xFF2E7D32);
                                  textColor = Colors.white;
                                }

                                return Padding(
                                  key: ValueKey('${q.id}_${op.key}'),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: InkWell(
                                    onTap: () => _choose(op.key),
                                    borderRadius: BorderRadius.circular(14),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            iconData,
                                            color: iconColor,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              op.text,
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// BUTTON XÁC NHẬN / NEXT
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isAnswered
                                  ? _nextOrSubmit
                                  : null, // Chỉ được bấm khi đã trả lời
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAnswered
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: isAnswered ? 2 : 0,
                              ),
                              child: Text(
                                isLast ? "Hoàn thành" : "Câu tiếp theo",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isAnswered
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
