import 'dart:math';

import '../data/question_bank.dart';
import '../models/models.dart';

/// Một đề thi thử đã rút, cùng các câu trả lời của người thi.
class Exam {
  Exam({required this.classCode, required this.config, required this.questions})
      : answers = List<int?>.filled(questions.length, null);

  final String classCode;
  final ExamConfig config;
  final List<Question> questions;

  /// Chỉ số phương án đã chọn cho từng câu, null nếu chưa trả lời.
  final List<int?> answers;

  int get answeredCount => answers.where((a) => a != null).length;

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
