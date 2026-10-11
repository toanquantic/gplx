import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/data/question_bank.dart';
import 'package:on_thi_gplx/logic/exam.dart';

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

  for (final code in [...enabledClasses, 'C1', 'C']) {
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

    int wrongOption(int i) => (exam.questions[i].correctIndex + 1) % exam.questions[i].options.length;

    test('đúng hết thì đạt', () {
      answerAll();
      final r = exam.grade();
      expect(r.correct, 30);
      expect(r.passed, isTrue);
    });

    test('vừa đủ điểm đạt (27/30) thì đạt', () {
      answerAll();
      final normal = [for (var i = 0; i < 30; i++) if (i != criticalIndex) i];
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
}
