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

  bool _isTimeUp = false;
  bool _showTimeUpMessage = false;

  @override
  void initState() {
    super.initState();

    // BẮT BUỘC bật lại status bar
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
      _isTimeUp = false;
      _showTimeUpMessage = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      if (remain <= 1) {
        t.cancel();
        setState(() {
          remain = 0;
          _isTimeUp = true;
          _showTimeUpMessage = true;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _showTimeUpMessage = false);
          }
        });

        return;
      }

      setState(() => remain--);
    });
  }

  void _choose(String key) {
    if (selectedKey != null) return;

    setState(() {
      selectedKey = key;
    });
  }

  void _nextOrSubmit() async {
    _timer?.cancel();

    final q = _quiz!.questions[idx];
    if (selectedKey != null) {
      answers[q.id] = selectedKey!;
    }

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final isLast = idx == _quiz!.questions.length - 1;

    if (!isLast) {
      setState(() {
        idx++;
        selectedKey = null;
        _isTimeUp = false;
        _showTimeUpMessage = false;
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

  Widget _progressBar(int total) {
    final v = (idx + (selectedKey != null ? 1 : 0)) / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: v.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: Colors.white.withOpacity(0.3),
          color: Colors.white,
        ),
      ),
    );
  }

  // ================================================
  // MÀU LỰA CHỌN (Giữ nguyên)
  // ================================================
  Color _tileColor(QQuestion q, String key) {
    if (selectedKey == null) return Colors.grey.shade200;

    final correct = q.correctKey;

    if (key == correct) return Colors.green;
    if (key == selectedKey && key != correct) return Colors.red;

    return Colors.grey.shade200;
  }

  Widget _questionCard(QQuestion q) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            q.text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final op in q.options)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: () => _choose(op.key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _tileColor(q, op.key),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${op.key}. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: (selectedKey == op.key)
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          op.text,
                          style: TextStyle(
                            color: (selectedKey == op.key)
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================================
  // NÚT NEXT / NỘP BÀI (ĐÃ ĐỒNG BỘ)
  // ================================
  Widget _nextButton(bool isLast) {
    final bool canGoNext = selectedKey != null || _isTimeUp;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
      child: SizedBox(
        width: double.infinity,
        height: 52, // 👈 BẰNG chiều cao option tile
        child: ElevatedButton(
          onPressed: () {
            if (!canGoNext) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hãy chọn đáp án trước khi chuyển câu.'),
                  duration: Duration(seconds: 1),
                ),
              );
              return;
            }
            _nextOrSubmit();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: canGoNext ? const Color(0xFF4CAF50) : Colors.grey,
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // 👈 giống option
            ),
          ),
          child: Text(
            isLast ? 'Hoàn thành' : 'Câu tiếp theo',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
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
            body: Center(
              child: Text(
                'Lỗi tải quiz: ${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final total = _quiz!.questions.length;

        if (total == 0) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Quiz hiện chưa có câu hỏi.\nVui lòng thử lại sau.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final q = _quiz!.questions[idx];
        final isLast = idx == total - 1;

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF2E7D32),
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Câu ${idx + 1} / $total',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$remain s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Timer',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: _progressBar(total),
              ),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _questionCard(q),
                            const SizedBox(height: 6),
                            _nextButton(isLast),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (_showTimeUpMessage)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Hết thời gian!\n'
                        'Bạn có thể chọn đáp án hoặc bấm "Câu tiếp theo".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
