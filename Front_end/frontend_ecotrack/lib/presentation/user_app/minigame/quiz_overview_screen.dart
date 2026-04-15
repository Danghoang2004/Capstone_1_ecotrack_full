import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'HomeIntro.dart'; // HomeQuiz
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/quiz_models.dart';

class QuizOverviewScreen extends StatefulWidget {
  final int userId;

  const QuizOverviewScreen({super.key, required this.userId});

  @override
  State<QuizOverviewScreen> createState() => _QuizOverviewScreenState();
}

class _QuizOverviewScreenState extends State<QuizOverviewScreen> {
  final ApiClient _api = ApiClient(storage: const FlutterSecureStorage());

  late Future<QuizSummary> _future;
  int _filterIndex = 0; // 0 = tất cả, 1 = hoàn thành, 2 = chưa làm

  @override
  void initState() {
    super.initState();
    _future = _fetchQuizOverview();
  }

  // ====== GỌI API /api/quizzes/summary ======
  Future<QuizSummary> _fetchQuizOverview() async {
    final res = await _api.get('/api/quizzes/summary');
    final data = _api.decodeUtf8Json(res);
    return QuizSummary.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuizSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text(
                'Lỗi tải tổng quan quiz:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final summary = snapshot.data!;
        final allQuizzes = summary.items;

        final completed = allQuizzes.where((q) => q.completed).length;
        final total = allQuizzes.length;
        final totalPoint = summary.totalPoints;

        final filtered = allQuizzes.where((q) {
          if (_filterIndex == 1) return q.completed;
          if (_filterIndex == 2) return !q.completed;
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF4FBF8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            forceMaterialTransparency: true,
            toolbarHeight: 66,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF12352E),
                size: 20,
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/user_app',
                  (route) => false,
                );
              },
            ),
            title: const Text(
              'Minigame',
              style: TextStyle(
                color: Color(0xFF12352E),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF4FBF8), Color(0xFFFFFFFF)],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                    child: _buildSummaryCard(
                      total: total,
                      completed: completed,
                      points: totalPoint,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final q = filtered[index];
                        return _buildQuizCard(context, q);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required int total,
    required int completed,
    required int points,
  }) {
    final double progress = total == 0 ? 0 : completed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEBE4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A3B2D).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FAF3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan thử thách',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12352E),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Làm quiz để tích điểm và theo dõi tiến độ.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7C75)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE7F1EC),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(label: 'Tổng bài', value: '$total'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(label: 'Đã làm', value: '$completed'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(label: 'Điểm', value: '$points'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================== 1 ITEM QUIZ (Giữ nguyên) ==================
  Widget _buildQuizCard(BuildContext context, QuizOverviewItem q) {
    final bool isCompleted = q.completed;
    final Color accentColor = isCompleted
        ? const Color(0xFF2E7D32)
        : const Color(0xFF6B8F73);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF7FBF9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEBE4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3B2C).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomeQuiz(quizId: q.quizId, userId: widget.userId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE8FAF3)
                          : const Color(0xFFF1F7F4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.quiz_outlined,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                q.title,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF12352E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4D6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                q.difficulty,
                                style: const TextStyle(
                                  color: Color(0xFF8A6510),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q.description.isNotEmpty
                              ? q.description
                              : 'Bài kiểm tra kiến thức về môi trường',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5A6C64),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.help_outline,
                    text: '${q.questionCount} câu',
                  ),
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    text: '${q.durationSeconds}s',
                  ),
                  _InfoChip(icon: Icons.star, text: '${q.rewardPoints} điểm'),
                  if (q.correctPercent > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8FAF3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Đúng ${q.correctPercent}%',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (q.correctPercent) / 100.0,
                        backgroundColor: const Color(0xFFE7F1EC),
                        color: const Color(0xFF2E7D32),
                        minHeight: 5.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Vào chơi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= WIDGET PHỤ (Giữ nguyên hoàn toàn) =======================

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEBE4)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E7D32) : const Color(0xFFF4FBF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFD3E2DA),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCEBE4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF5C7269)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF32433D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
