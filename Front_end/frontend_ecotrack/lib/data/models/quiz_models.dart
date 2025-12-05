class QuizDetail {
  final int id;
  final String title;
  final int? pointsReward;
  final List<QQuestion> questions;

  QuizDetail({
    required this.id,
    required this.title,
    required this.pointsReward,
    required this.questions,
  });

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    final rawQs = (json['questions'] as List?) ?? const [];
    return QuizDetail(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      pointsReward: json['pointsReward'] == null
          ? null
          : _asInt(json['pointsReward']),
      questions: rawQs
          .map((e) => QQuestion.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class QQuestion {
  final int id;
  final String text;
  final String correctKey;
  final List<QOption> options; // A/B/C/D

  QQuestion({
    required this.id,
    required this.text,
    required this.correctKey,
    required this.options,
  });

  factory QQuestion.fromJson(Map<String, dynamic> json) {
    // BE có thể dùng "text" hoặc "questionText" → lấy cái có sẵn
    final qText = (json['text'] ?? json['questionText'] ?? '').toString();

    // options có 2 dạng:
    // 1) List<Map>{key,text}
    // 2) Map { "A":"...", "B":"...", ... }
    final rawOpts = json['options'];
    List<QOption> opts;

    if (rawOpts is List) {
      opts = rawOpts
          .map((e) => QOption.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } else if (rawOpts is Map) {
      // chuyển {A:"...",B:"..."} -> List<QOption> và sắp theo A→D
      opts =
          (rawOpts as Map).entries
              .map(
                (e) => QOption(
                  key: e.key.toString(),
                  text: (e.value ?? '').toString(),
                ),
              )
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
    } else {
      opts = const <QOption>[];
    }

    return QQuestion(
      id: _asInt(json['id']),
      text: qText,
      correctKey: (json['correctKey'] ?? "").toString(),
      options: opts,
    );
  }
}

class QOption {
  final String key; // "A"/"B"/"C"/"D"
  final String text;

  QOption({required this.key, required this.text});

  factory QOption.fromJson(Map<String, dynamic> json) {
    return QOption(
      key: (json['key'] ?? '').toString(),
      text: (json['text'] ?? '').toString(), // tránh null -> String
    );
  }
}

// ===== helpers =====
int _asInt(Object? v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is num) return v.toInt();
  return 0;
}

/// Kết quả nộp bài từ BE:
/// - correct: số câu đúng
/// - total: tổng số câu
/// - passed: đậu / rớt (tuỳ logic BE)
/// - correctnessList: danh sách true/false theo từng câu → dùng để tính streak tối đa
class SubmitResponse {
  final int correct;
  final int total;
  final bool passed;
  final List<bool> correctnessList;

  SubmitResponse({
    required this.correct,
    required this.total,
    required this.passed,
    required this.correctnessList,
  });

  factory SubmitResponse.fromJson(Map<String, dynamic> json) {
    // correctnessList có thể là List<bool> hoặc List<int>/List<String> → quy về bool an toàn
    final raw = (json['correctnessList'] as List?) ?? const [];
    final list = raw.map<bool>((e) {
      if (e is bool) return e;
      if (e is num) return e != 0;
      final s = e?.toString().toLowerCase();
      return s == 'true' || s == '1';
    }).toList();

    return SubmitResponse(
      correct: _asInt(json['correct']),
      total: _asInt(json['total']),
      passed: (json['passed'] ?? false) == true,
      correctnessList: list,
    );
  }
}

// ================== QUIZ OVERVIEW / SUMMARY ==================

class QuizOverviewItem {
  final int quizId;
  final String title;
  final bool completed;
  final int? _percent; // cho phép null bên trong
  final int? _questionCount;
  final int? _timeSec;
  final int? _rewardPoints;

  QuizOverviewItem({
    required this.quizId,
    required this.title,
    required this.completed,
    int? percent,
    int? questionCount,
    int? timeSec,
    int? rewardPoints,
  }) : _percent = percent,
       _questionCount = questionCount,
       _timeSec = timeSec,
       _rewardPoints = rewardPoints;

  // ====== fromJson an toàn, tự convert mọi kiểu về int ======
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory QuizOverviewItem.fromJson(Map<String, dynamic> json) {
    return QuizOverviewItem(
      quizId: _toInt(json['quizId']),
      title: json['title'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      percent: _toInt(json['percent']),
      questionCount: 20,
      timeSec: _toInt(json['timeSec']),
      rewardPoints: _toInt(json['rewardPoints']),
    );
  }

  // ====== getter công khai, luôn trả về int (không null) ======

  int get percent => _percent ?? 0;
  int get questionCount => _questionCount ?? 0;
  int get timeSec => _timeSec ?? 0;
  int get rewardPoints => _rewardPoints ?? 0;

  // Giữ cho code cũ vẫn xài được:

  String get description => '';

  String get difficulty {
    if (questionCount <= 10) return 'Dễ';
    if (questionCount <= 15) return 'Trung bình';
    return 'Khó';
  }

  int get durationSeconds => timeSec;

  int get correctPercent => percent;
}

/// Tổng quan cho màn hình Overview (3 ô trên cùng + list quiz)
class QuizSummary {
  final int completed;
  final int total;
  final int totalPoints;
  final List<QuizOverviewItem> items;

  QuizSummary({
    required this.completed,
    required this.total,
    required this.totalPoints,
    required this.items,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      completed: json['completed'] as int,
      total: json['total'] as int,
      totalPoints: json['totalPoints'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => QuizOverviewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
