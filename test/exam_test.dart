import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/data/question_bank.dart';
import 'package:on_thi_gplx/logic/exam.dart';
import 'package:on_thi_gplx/state/progress.dart';

QuestionBank loadBank() {
  String read(String name) => File('assets/data/$name').readAsStringSync();
  return QuestionBank.parse(
    questionsJson: read('cau_hoi_600.json'),
    explanationsJson: read('giai_thich_cong_dong.json'),
    examConfigJson: read('cau_hinh_de_thi.json'),
    classesJson: read('hang_gplx.json'),
    signsJson: read('bien_bao.json'),
  );
}

void main() {
  final bank = loadBank();

  test('nạp đủ 600 câu, đáp án hợp lệ, hình tồn tại', () {
    expect(bank.questions.length, 600);
    for (final q in bank.questions.values) {
      expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1), reason: 'câu ${q.id}');
      if (q.image != null) {
        expect(File(q.image!).existsSync(), isTrue, reason: q.image);
      }
    }
    expect(bank.chapters.length, 6);
    expect(bank.signs, isNotEmpty);
  });

  test('bộ câu và câu điểm liệt theo hạng', () {
    expect(bank.forClass('A1').length, 250);
    expect(bank.forClass('A').length, 250);
    expect(bank.forClass('B').length, 600);
    expect(bank.criticalFor('A1').length, 20);
    expect(bank.criticalFor('B').length, 60);
    expect(bank.forClass('C1').length, 600);
    expect(bank.forClass('C').length, 600);
    expect(bank.criticalFor('C').length, 60);
    expect(bank.examConfigs['C1']?.questionCount, 35);
    expect(bank.examConfigs['C']?.passScore, 36);
    // Câu 73 là điểm liệt với ô tô nhưng là câu thường với A1/A.
    expect(bank.isCritical('B', 73), isTrue);
    expect(bank.isCritical('A1', 73), isFalse);
  });

  test('các hạng đang mở đều có cấu hình đề và điểm đạt', () {
    for (final code in enabledClasses) {
      final c = bank.examConfigs[code];
      expect(c, isNotNull, reason: code);
      expect(c!.passScore, isNotNull, reason: code);
      expect(c.structure.values.fold<int>(0, (a, b) => a + b), c.questionCount, reason: code);
    }
    expect(bank.examConfigs['D']?.questionCount, 45);
  });

  for (final code in enabledClasses) {
    test('rút đề hạng $code: đủ câu, 1 câu điểm liệt, không trùng, đúng bộ câu', () {
      final rng = Random(42);
      for (var round = 0; round < 200; round++) {
        final exam = generateExam(bank, code, random: rng);
        final ids = exam.questions.map((q) => q.id).toList();
        expect(ids.length, exam.config.questionCount);
        expect(ids.toSet().length, ids.length);
        expect(ids.where((id) => bank.isCritical(code, id)).length, 1);
        expect(exam.questions.every((q) => q.classes.contains(code)), isTrue);
      }
    });
  }

  group('chấm điểm', () {
    late Exam exam;
    late int criticalIndex;

    setUp(() {
      exam = generateExam(bank, 'B', random: Random(1));
      criticalIndex = exam.questions.indexWhere((q) => bank.isCritical('B', q.id));
    });

    void answerAll() {
      for (var i = 0; i < exam.questions.length; i++) {
        exam.answers[i] = exam.questions[i].correctIndex;
      }
    }

    int wrongOption(int i) =>
        (exam.questions[i].correctIndex + 1) % exam.questions[i].options.length;

    test('đúng hết thì đạt', () {
      answerAll();
      final r = exam.grade();
      expect(r.correct, 30);
      expect(r.passed, isTrue);
    });

    test('vừa đủ điểm đạt (27/30) thì đạt', () {
      answerAll();
      final normal = [
        for (var i = 0; i < 30; i++)
          if (i != criticalIndex) i,
      ];
      for (final i in normal.take(3)) {
        exam.answers[i] = wrongOption(i);
      }
      expect(exam.grade().passed, isTrue);
      exam.answers[normal[3]] = wrongOption(normal[3]);
      expect(exam.grade().correct, 26);
      expect(exam.grade().passed, isFalse);
    });

    test('sai câu điểm liệt thì trượt dù đủ điểm', () {
      answerAll();
      exam.answers[criticalIndex] = wrongOption(criticalIndex);
      final r = exam.grade();
      expect(r.correct, 29);
      expect(r.failedCritical, isTrue);
      expect(r.passed, isFalse);
    });

    test('bỏ trống câu điểm liệt cũng là trượt', () {
      answerAll();
      exam.answers[criticalIndex] = null;
      expect(exam.grade().failedCritical, isTrue);
    });
  });

  test('điểm theo nhóm cộng lại bằng tổng điểm và đúng cấu trúc đề', () {
    final exam = generateExam(bank, 'B', random: Random(7));
    for (var i = 0; i < exam.questions.length; i += 2) {
      exam.answers[i] = exam.questions[i].correctIndex;
    }
    final groups = exam.scoreByGroup();
    expect([for (final g in groups) g.group], exam.config.structure.keys.toList());
    for (final g in groups) {
      expect(g.total, exam.config.structure[g.group]);
    }
    expect(groups.fold(0, (s, g) => s + g.correct), exam.grade().correct);
  });

  test('bài thi lưu vào lịch sử dựng lại được y như cũ', () {
    final exam = generateExam(bank, 'A1', random: Random(3));
    exam.answers[0] = exam.questions[0].correctIndex;
    exam.answers[5] = (exam.questions[5].correctIndex + 1) % exam.questions[5].options.length;
    final result = exam.grade();
    final record = ExamRecord.fromJson(
      ExamRecord(
        'A1',
        DateTime(2026, 10, 12, 9, 30),
        result.correct,
        result.total,
        result.passed,
        failedCritical: result.failedCritical,
        duration: const Duration(minutes: 3, seconds: 4),
        questionIds: [for (final q in exam.questions) q.id],
        answers: List.of(exam.answers),
        correctAnswers: [for (final q in exam.questions) q.correctIndex],
      ).toJson(),
    );

    expect(record.duration, const Duration(minutes: 3, seconds: 4));
    expect(record.failedCritical, isTrue);
    final restored = restoreExam(bank, record)!;
    expect([for (final q in restored.questions) q.id], [for (final q in exam.questions) q.id]);
    expect(restored.answers, exam.answers);
    expect(restored.grade().correct, result.correct);
  });

  test('không dựng lại bài thi khi bộ đề đã đổi đáp án hoặc số phương án', () {
    final exam = generateExam(bank, 'A1', random: Random(5));
    final ids = [for (final q in exam.questions) q.id];
    final keys = [for (final q in exam.questions) q.correctIndex];
    ExamRecord record({List<int>? correct, List<int?>? answers}) => ExamRecord(
      'A1',
      DateTime(2026, 10, 12),
      0,
      ids.length,
      false,
      questionIds: ids,
      answers: answers ?? List<int?>.filled(ids.length, null),
      correctAnswers: correct ?? keys,
    );

    expect(restoreExam(bank, record()), isNotNull);
    final changedKey = List.of(keys)..[0] = (keys[0] + 1) % exam.questions[0].options.length;
    expect(restoreExam(bank, record(correct: changedKey)), isNull);
    final outOfRange = List<int?>.filled(ids.length, null)..[0] = 9;
    expect(restoreExam(bank, record(answers: outOfRange)), isNull);
  });

  test('bản ghi lịch sử cũ (chưa lưu câu hỏi) vẫn đọc được', () {
    final record = ExamRecord.fromJson({
      'hang': 'B',
      't': '2026-10-01T08:00:00.000',
      'dung': 28,
      'tong': 30,
      'dat': true,
    });
    expect(record.failedCritical, isFalse);
    expect(record.questionIds, isNull);
    expect(restoreExam(bank, record), isNull);
  });
}
