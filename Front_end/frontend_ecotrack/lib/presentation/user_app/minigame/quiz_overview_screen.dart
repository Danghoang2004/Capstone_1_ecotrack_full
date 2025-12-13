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
  // 👉 dùng trực tiếp ApiClient, không qua QuizRepository nữa
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
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(
            children: [
              _buildHeader(context),
              _buildStatsRow(completed, total, totalPoint),
              _buildFilterRow(completed, total - completed),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final q = filtered[index];
                    return _buildQuizCard(context, q);
                  },
                ),
              ),
            ],
          ),
          // bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF00994D),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false, // Không cần padding dưới cho SafeArea
        child: Padding(
          padding: const EdgeInsets.only(
            top: 10,
          ), // Thêm chút khoảng cách từ status bar xuống
          child: Row(
            // 👇 QUAN TRỌNG: Căn giữa theo chiều dọc
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // NÚT THOÁT
              Transform.translate(
                offset: const Offset(
                  -10,
                  0,
                ), // Dịch sang trái 5 đơn vị (x = -5)
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
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
              ),
              const Expanded(
                child: Column(
                  // 👇 QUAN TRỌNG: Co cụm chiều cao cột lại vừa đủ nội dung
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EcoTrack',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2, // Điều chỉnh dòng để chữ không bị lệch
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bảo vệ môi trường cùng nhau',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================ STATS 3 Ô TRÊN =================
  Widget _buildStatsRow(int done, int total, int points) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 1),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(label: 'Đã hoàn thành', value: '$done'),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _StatCard(label: 'Tổng quiz', value: '$total'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(label: 'Điểm tích luỹ', value: '$points'),
          ),
        ],
      ),
    );
  }

  // ================ FILTER (TẤT CẢ / HOÀN THÀNH / CHƯA LÀM) ================
  Widget _buildFilterRow(int done, int notDone) {
    return Container(
      color: const Color(0xFFF5F6FA),
      padding: const EdgeInsets.fromLTRB(9, 4, 6, 3),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tất cả',
            selected: _filterIndex == 0,
            onTap: () => setState(() => _filterIndex = 0),
          ),
          const SizedBox(width: 4),
          _FilterChip(
            label: 'Hoàn thành ($done)',
            selected: _filterIndex == 1,
            onTap: () => setState(() => _filterIndex = 1),
          ),
          const SizedBox(width: 4),
          _FilterChip(
            label: 'Chưa làm ($notDone)',
            selected: _filterIndex == 2,
            onTap: () => setState(() => _filterIndex = 2),
          ),
        ],
      ),
    );
  }

  // ================== 1 ITEM QUIZ ==================
  Widget _buildQuizCard(BuildContext context, QuizOverviewItem q) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== TIÊU ĐỀ + MÔ TẢ =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      "Bài kiểm tra kiến thức về môi trường",
                      style: TextStyle(fontSize: 10, color: Colors.black45),
                    ),

                    Text(
                      q.description,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 2),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  q.difficulty,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                q.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: q.completed ? Colors.green : Colors.grey,
                size: 16,
              ),
            ],
          ),

          const SizedBox(height: 1),

          // ===== DÒNG GIỮA =====
          Row(
            children: [
              _InfoChip(
                icon: Icons.help_outline,
                text: '${q.questionCount} câu',
              ),
              const SizedBox(width: 6),
              _InfoChip(
                icon: Icons.timer_outlined,
                text: '${q.durationSeconds}s',
              ),
              const SizedBox(width: 6),
              _InfoChip(icon: Icons.star, text: '${q.rewardPoints} điểm'),
              const Spacer(),
              if (q.correctPercent > 0)
                Text(
                  '${q.correctPercent}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 2),

          // ===== PROGRESS BAR + MŨI TÊN =====
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (q.correctPercent) / 100.0,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                  minHeight: 2,
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HomeQuiz(quizId: q.quizId, userId: widget.userId),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============== BOTTOM BAR (chỉ là UI giống hình) ===============
  // Widget _buildBottomBar() {
  //   return Container(
  //     height: 60,
  //     decoration: const BoxDecoration(
  //       color: Colors.white,
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black12,
  //           blurRadius: 8,
  //           offset: Offset(0, -2),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       children: const [
  //         _BottomItem(icon: Icons.campaign, label: 'Chiến dịch', active: false),
  //         _BottomItem(
  //           icon: Icons.emoji_events,
  //           label: 'Huy hiệu',
  //           active: false,
  //         ),
  //         _BottomItem(icon: Icons.menu_book, label: 'Kiến thức', active: true),
  //       ],
  //     ),
  //   );
  // }
}

// ======================= WIDGET PHỤ =======================

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 6, // 👈 giảm chiều cao
        horizontal: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00994D),
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00C853) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 8, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00C853) : Colors.grey;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
