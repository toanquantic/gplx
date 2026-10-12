import 'dart:math';

import '../data/question_bank.dart';
import '../models/models.dart';
import '../state/progress.dart';
import 'review.dart';

/// Kết quả làm bài của một chương, tính theo lần trả lời gần nhất mỗi câu.
class ChapterStat {
  const ChapterStat(this.chapter, this.total, this.answered, this.correct);

  final Chapter chapter;
  final int total;
  final int answered;
  final int correct;

  /// Tỉ lệ đúng trên số câu đã làm, null khi chưa làm câu nào.
  double? get accuracy => answered == 0 ? null : correct / answered;
}

List<ChapterStat> chapterStats(QuestionBank bank, Progress progress, String code) => [
  for (final ch in bank.chapters)
    if (bank.forChapter(code, ch.number) case final qs when qs.isNotEmpty)
      ChapterStat(
        ch,
        qs.length,
        qs.where((q) => progress.lastResult.containsKey(q.id)).length,
        qs.where((q) => progress.lastResult[q.id] == true).length,
      ),
];

/// Câu đến hạn ôn hôm nay và lịch 7 ngày tới, chỉ tính câu thuộc hạng đang chọn.
class ReviewPlan {
  ReviewPlan._(this.due, this.wrongYesterday, this.forecast, this.hardest, this.streak);

  factory ReviewPlan.of(QuestionBank bank, Progress progress, String code) {
    final today = progress.today;
    final yesterday = addDays(today, -1);
    final cards = <Question, ReviewCard>{
      for (final MapEntry(:key, :value) in progress.reviews.entries)
        if (bank.questions[key] case final q? when q.classes.contains(code)) q: value,
    };
    final due = cards.entries.where((e) => e.value.isDue(today)).toList()
      ..sort((a, b) {
        final byDue = a.value.due.compareTo(b.value.due);
        return byDue != 0 ? byDue : b.value.lapses.compareTo(a.value.lapses);
      });
    final forecast = List.filled(7, 0);
    for (final card in cards.values) {
      final days = card.due.difference(today).inHours / 24;
      final i = max(0, days.round());
      if (i < 7) forecast[i]++;
    }
    final hardest = cards.entries.toList()
      ..sort((a, b) {
        final byLapses = b.value.lapses.compareTo(a.value.lapses);
        return byLapses != 0 ? byLapses : a.value.step.compareTo(b.value.step);
      });
    return ReviewPlan._(
      [for (final e in due) e.key],
      due.where((e) => e.value.lastWrong == yesterday).length,
      forecast,
      [for (final e in hardest.take(3)) (e.key, e.value)],
      studyStreak(progress.studyDays, today),
    );
  }

  /// Câu cần ôn hôm nay, quá hạn lâu nhất trước.
  final List<Question> due;

  /// Trong số câu đến hạn, bao nhiêu câu mới sai hôm qua.
  final int wrongYesterday;

  /// Số câu đến hạn mỗi ngày, bắt đầu từ hôm nay (đã gồm câu quá hạn).
  final List<int> forecast;

  /// Những câu sai nhiều lần nhất.
  final List<(Question, ReviewCard)> hardest;
  final int streak;

  /// Ước lượng khoảng nửa phút mỗi câu.
  int get minutes => (due.length / 2).ceil();
}

/// Ước tính khả năng đỗ bài thi lý thuyết của một hạng.
class PassPrediction {
  const PassPrediction({
    required this.probability,
    required this.answered,
    required this.total,
    required this.examCount,
  });

  /// Từ 0 đến 1.
  final double probability;
  final int answered;
  final int total;
  final int examCount;

  /// Đủ dữ liệu để con số có ý nghĩa: làm ít nhất 1/5 bộ câu hoặc 2 đề thi.
  bool get enoughData => answered * 5 >= total || examCount >= 2;
}

/// Xác suất trả lời đúng một câu nếu gặp trong đề, theo lần làm gần nhất:
/// đã đúng vẫn có thể nhầm, đã sai vẫn có thể đoán trúng, chưa làm coi như
/// nửa biết nửa đoán. Đây là ước lượng đơn giản, chỉ để tham khảo.
double _knowChance(bool? last) => switch (last) {
  true => 0.95,
  false => 0.3,
  null => 0.5,
};

/// Ước tính khả năng đỗ, hoặc null khi hạng chưa có điểm đạt.
///
/// Mỗi nhóm trong `cau_truc` rút `n` câu, mỗi câu đúng với xác suất bằng trung
/// bình [_knowChance] của cả nhóm. Đỗ khi đúng hết câu điểm liệt và tổng số câu
/// đúng đạt điểm tối thiểu. Kết quả trộn thêm tỉ lệ đạt của tối đa 5 đề thi thử
/// gần nhất (trọng số tối đa một nửa).
PassPrediction? predictPass(QuestionBank bank, Progress progress, String code) {
  final config = bank.examConfigs[code];
  final passScore = config?.passScore;
  if (config == null || passScore == null) return null;

  double groupChance(String g) {
    final ids = config.groups[g] ?? const <int>[];
    if (ids.isEmpty) return 0.5;
    return ids.map((id) => _knowChance(progress.lastResult[id])).reduce((a, b) => a + b) /
        ids.length;
  }

  // Phân phối số câu đúng (không tính điểm liệt), cộng dồn qua từng nhóm.
  var dist = [1.0];
  var criticalOk = 1.0;
  var criticalCount = 0;
  config.structure.forEach((g, n) {
    final p = groupChance(g);
    if (g == 'diem_liet') {
      criticalOk *= pow(p, n);
      criticalCount += n;
      return;
    }
    for (var k = 0; k < n; k++) {
      final next = List.filled(dist.length + 1, 0.0);
      for (var i = 0; i < dist.length; i++) {
        next[i] += dist[i] * (1 - p);
        next[i + 1] += dist[i] * p;
      }
      dist = next;
    }
  });
  final need = passScore - criticalCount;
  var enough = 0.0;
  for (var i = max(0, need); i < dist.length; i++) {
    enough += dist[i];
  }
  var probability = criticalOk * enough;

  final exams = progress.exams.where((e) => e.classCode == code).toList();
  final recent = exams.take(5).toList();
  if (recent.isNotEmpty) {
    final passRate = recent.where((e) => e.passed).length / recent.length;
    final w = recent.length / 10;
    probability = probability * (1 - w) + passRate * w;
  }
  final all = bank.forClass(code);
  return PassPrediction(
    probability: probability.clamp(0, 1),
    answered: all.where((q) => progress.lastResult.containsKey(q.id)).length,
    total: all.length,
    examCount: exams.length,
  );
}

/// Nhãn ngắn cho mức khả năng đỗ.
String predictionLabel(PassPrediction p) {
  if (!p.enoughData) return 'Chưa đủ dữ liệu';
  final v = p.probability;
  if (v >= 0.9) return 'Rất chắc đỗ';
  if (v >= 0.75) return 'Khá chắc đỗ';
  if (v >= 0.5) return 'Cần ôn thêm';
  return 'Chưa sẵn sàng';
}
