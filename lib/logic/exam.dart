import 'dart:math';

import '../data/question_bank.dart';
import '../models/models.dart';
import '../state/progress.dart';

/// Một đề thi thử đã rút, cùng các câu trả lời của người thi.
class Exam {
  Exam({required this.classCode, required this.config, required this.questions, this.smart = false})
    : answers = List<int?>.filled(questions.length, null);

  final String classCode;

  /// Đề ưu tiên câu yếu (bản Pro).
  final bool smart;
  final ExamConfig config;
  final List<Question> questions;

  /// Chỉ số phương án đã chọn cho từng câu, null nếu chưa trả lời.
  final List<int?> answers;

  int get answeredCount => answers.where((a) => a != null).length;

  bool isCorrect(int i) => answers[i] == questions[i].correctIndex;

  /// Nhóm câu (khóa trong `cau_truc`) của câu thứ [i] trong đề.
  String groupOf(int i) {
    final id = questions[i].id;
    for (final g in config.structure.keys) {
      if (config.groups[g]?.contains(id) ?? false) return g;
    }
    return '';
  }

  /// Số câu đúng theo từng nhóm, theo thứ tự nhóm trong đề.
  List<GroupScore> scoreByGroup() {
    final scores = {for (final g in config.structure.keys) g: GroupScore(g)};
    for (var i = 0; i < questions.length; i++) {
      final s = scores[groupOf(i)];
      if (s == null) continue;
      s.total++;
      if (isCorrect(i)) s.correct++;
    }
    return [
      for (final s in scores.values)
        if (s.total > 0) s,
    ];
  }

  ExamResult grade() {
    var correct = 0;
    var failedCritical = false;
    final critical = config.criticalIds.toSet();
    for (var i = 0; i < questions.length; i++) {
      final ok = answers[i] == questions[i].correctIndex;
      if (ok) correct++;
      if (!ok && critical.contains(questions[i].id)) failedCritical = true;
    }
    final pass = config.passScore;
    return ExamResult(
      correct: correct,
      total: questions.length,
      passScore: pass,
      failedCritical: failedCritical,
      passed: pass != null && correct >= pass && !failedCritical,
    );
  }
}

class GroupScore {
  GroupScore(this.group);

  final String group;
  int correct = 0;
  int total = 0;
}

class ExamResult {
  const ExamResult({
    required this.correct,
    required this.total,
    required this.passScore,
    required this.failedCritical,
    required this.passed,
  });

  final int correct;
  final int total;
  final int? passScore;

  /// Trả lời sai (hoặc bỏ trống) câu điểm liệt: trượt dù đủ điểm.
  final bool failedCritical;
  final bool passed;
}

/// Rút đề theo `cau_truc` của hạng: mỗi nhóm lấy ngẫu nhiên đúng số câu quy định,
/// giữ thứ tự nhóm như đề thật. Nhóm điểm liệt đã được loại khỏi các nhóm khác
/// trong dữ liệu, nên đề không bị trùng câu.
Exam generateExam(QuestionBank bank, String classCode, {Random? random}) {
  final config = bank.examConfigs[classCode];
  if (config == null) {
    throw ArgumentError('Chưa có cấu hình đề thi cho hạng $classCode');
  }
  final rng = random ?? Random();
  final picked = <Question>[];
  config.structure.forEach((group, count) {
    final pool = List<int>.of(config.groups[group] ?? const [])..shuffle(rng);
    if (pool.length < count) {
      throw StateError('Nhóm $group của hạng $classCode chỉ có ${pool.length} câu');
    }
    final ids = pool.take(count).toList()..sort();
    picked.addAll(ids.map((id) => bank.questions[id]!));
  });
  return Exam(classCode: classCode, config: config, questions: picked);
}

/// Đề thi thử ưu tiên câu yếu (bản Pro): vẫn đúng `cau_truc` như đề thật, nhưng
/// trong mỗi nhóm câu làm sai, câu đến hạn ôn và câu chưa làm có nhiều khả năng
/// được rút hơn câu đã làm đúng. Câu điểm liệt từng sai được ưu tiên cao nhất.
Exam generateSmartExam(QuestionBank bank, Progress progress, String classCode, {Random? random}) {
  final config = bank.examConfigs[classCode];
  if (config == null) {
    throw ArgumentError('Chưa có cấu hình đề thi cho hạng $classCode');
  }
  final rng = random ?? Random();
  final today = progress.today;
  double weight(int id, bool critical) {
    final last = progress.lastResult[id];
    if (last == false) return critical ? 12 : 6;
    if (progress.reviews[id]?.isDue(today) ?? false) return 4;
    if (last == null) return 3;
    return 1;
  }

  final picked = <Question>[];
  config.structure.forEach((group, count) {
    final pool = config.groups[group] ?? const <int>[];
    if (pool.length < count) {
      throw StateError('Nhóm $group của hạng $classCode chỉ có ${pool.length} câu');
    }
    // Rút có trọng số, không lặp (Efraimidis–Spirakis): khóa u^(1/w), lấy khóa lớn nhất.
    final keyed = [
      for (final id in pool) (id, pow(rng.nextDouble(), 1 / weight(id, group == 'diem_liet'))),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final ids = [for (final k in keyed.take(count)) k.$1]..sort();
    picked.addAll(ids.map((id) => bank.questions[id]!));
  });
  return Exam(classCode: classCode, config: config, questions: picked, smart: true);
}

/// Dựng lại bài thi đã lưu trong lịch sử để xem kết quả và từng câu.
///
/// Trả về null với bản ghi cũ chưa lưu câu hỏi, hoặc khi bộ đề đã đổi (câu bị
/// xóa, đổi đáp án đúng hay số phương án) so với lúc thi.
Exam? restoreExam(QuestionBank bank, ExamRecord record) {
  final config = bank.examConfigs[record.classCode];
  final ids = record.questionIds;
  final answers = record.answers;
  final keys = record.correctAnswers;
  if (config == null ||
      ids == null ||
      answers == null ||
      keys == null ||
      ids.length != answers.length ||
      ids.length != keys.length) {
    return null;
  }
  final questions = <Question>[];
  for (var i = 0; i < ids.length; i++) {
    final q = bank.questions[ids[i]];
    final a = answers[i];
    if (q == null || q.correctIndex != keys[i]) return null;
    if (a != null && (a < 0 || a >= q.options.length)) return null;
    questions.add(q);
  }
  final exam = Exam(
    classCode: record.classCode,
    config: config,
    questions: questions,
    smart: record.smart,
  );
  for (var i = 0; i < answers.length; i++) {
    exam.answers[i] = answers[i];
  }
  return exam;
}
