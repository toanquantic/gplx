import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/logic/exam.dart';
import 'package:on_thi_gplx/logic/insights.dart';
import 'package:on_thi_gplx/logic/review.dart';
import 'package:on_thi_gplx/monetization/entitlement.dart';
import 'package:on_thi_gplx/monetization/store_entitlement.dart';
import 'package:on_thi_gplx/state/progress.dart';
import 'package:on_thi_gplx/ui/app_scope.dart';
import 'package:on_thi_gplx/ui/screens/before_exam_screen.dart';
import 'package:on_thi_gplx/ui/screens/review_screen.dart';
import 'package:on_thi_gplx/ui/screens/stats_screen.dart';
import 'package:on_thi_gplx/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exam_test.dart' show loadBank;

void main() {
  final bank = loadBank();
  var now = DateTime(2026, 10, 12, 9);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 12, 9);
  });

  Future<Progress> load() => Progress.load(clock: () => now);

  group('lịch ôn lại', () {
    test('câu sai đến hạn hôm sau, ôn đúng thì giãn dần rồi rời lịch', () {
      final d = DateTime(2026, 10, 12);
      var card = ReviewCard.wrong(null, d);
      expect(card.due, DateTime(2026, 10, 13));
      expect(card.isDue(d), isFalse);

      // Ôn sớm không lên bậc.
      expect(card.correct(d), same(card));

      var day = card.due;
      final gaps = <int>[];
      while (true) {
        final next = card.correct(day);
        if (next == null) break;
        gaps.add(next.due.difference(day).inDays);
        card = next;
        day = card.due;
      }
      expect(gaps, reviewIntervals);

      // Sai lại thì về bậc đầu và tăng số lần sai.
      final again = ReviewCard.wrong(card, day);
      expect(again.step, 0);
      expect(again.lapses, 2);
    });

    test('tiến độ lưu lịch ôn, chuỗi ngày học và ngày thi', () async {
      final p = await load();
      p.recordAnswer(1, false);
      p.recordAnswer(2, true);
      expect(p.reviews.keys, [1]);

      now = DateTime(2026, 10, 13, 20);
      p.recordAnswer(3, false);
      p.setExamDate(DateTime(2026, 10, 20));
      p.markPlanStep(1);

      final again = await load();
      expect(again.reviews.keys, unorderedEquals([1, 3]));
      expect(again.reviews[1]!.isDue(again.today), isTrue);
      expect(studyStreak(again.studyDays, again.today), 2);
      expect(again.examDate, DateTime(2026, 10, 20));
      expect(again.isPlanStepDone(1), isTrue);
      again.selectClass('C');
      expect(again.isPlanStepDone(1), isFalse);

      await again.reset();
      expect((await load()).reviews, isEmpty);
    });

    test('kế hoạch ôn chỉ tính câu của hạng đang chọn và dự báo 7 ngày', () async {
      final p = await load();
      // Câu 1 thuộc mọi hạng, câu 300 (cấu tạo) không thuộc A1.
      p.recordAnswers({1: false, 300: false, 5: false});
      now = DateTime(2026, 10, 13, 8);
      p.recordAnswer(5, true); // lên bậc 1, hạn sau 3 ngày.

      final plan = ReviewPlan.of(bank, p, 'A1');
      expect(plan.due.map((q) => q.id), [1]);
      expect(plan.wrongYesterday, 1);
      expect(plan.forecast[0], 1);
      expect(plan.forecast[3], 1);
      expect(plan.streak, 2);
      expect(ReviewPlan.of(bank, p, 'B').due.map((q) => q.id), unorderedEquals([1, 300]));
    });
  });

  group('thống kê và dự đoán', () {
    test('điểm theo chương tính theo lần làm gần nhất', () async {
      final p = await load();
      p.recordAnswers({1: true, 2: false, 181: true});
      final stats = chapterStats(bank, p, 'A1');
      expect(stats.first.answered, 2);
      expect(stats.first.correct, 1);
      expect(stats.first.accuracy, 0.5);
      expect(stats.every((s) => s.total > 0), isTrue);
    });

    test('dự đoán tăng khi làm đúng nhiều, giảm khi sai câu điểm liệt', () async {
      final p = await load();
      final fresh = predictPass(bank, p, 'A1')!;
      expect(fresh.enoughData, isFalse);
      expect(predictionLabel(fresh), 'Chưa đủ dữ liệu');

      p.recordAnswers({for (final q in bank.forClass('A1')) q.id: true});
      final good = predictPass(bank, p, 'A1')!;
      expect(good.enoughData, isTrue);
      expect(good.probability, greaterThan(0.75));
      expect(good.probability, greaterThan(fresh.probability));

      p.recordAnswers({for (final q in bank.criticalFor('A1').take(10)) q.id: false});
      expect(predictPass(bank, p, 'A1')!.probability, lessThan(good.probability));
    });
  });

  test('đề ưu tiên câu yếu giữ đúng cấu trúc và rút câu sai nhiều hơn', () async {
    final p = await load();
    final ids = [for (final q in bank.forClass('A1')) q.id];
    // Cứ 4 câu có 1 câu sai, rải đều mọi nhóm.
    final wrong = [for (var i = 0; i < ids.length; i += 4) ids[i]];
    p.recordAnswers({for (final id in ids) id: true});
    p.recordAnswers({for (final id in wrong) id: false});
    final wrongSet = wrong.toSet();

    var smartHits = 0;
    var randomHits = 0;
    final rng = Random(7);
    for (var i = 0; i < 100; i++) {
      final smart = generateSmartExam(bank, p, 'A1', random: rng);
      expect(smart.smart, isTrue);
      expect(smart.questions.length, 25);
      expect(smart.questions.map((q) => q.id).toSet().length, 25);
      for (final MapEntry(key: g, value: n) in smart.config.structure.entries) {
        final inGroup = smart.questions.where((q) => smart.config.groups[g]!.contains(q.id));
        expect(inGroup.length, n, reason: g);
      }
      smartHits += smart.questions.where((q) => wrongSet.contains(q.id)).length;
      randomHits += generateExam(
        bank,
        'A1',
        random: rng,
      ).questions.where((q) => wrongSet.contains(q.id)).length;
    }
    expect(smartHits, greaterThan(randomHits * 2));
  });

  group('màn Pro', () {
    Future<Progress> pump(WidgetTester tester, Widget screen, {bool pro = true}) async {
      final progress = (await tester.runAsync(load))!;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      progress.recordAnswers({1: false, 2: false});
      now = DateTime(2026, 10, 13, 9);
      await tester.pumpWidget(
        AppScope(
          bank: bank,
          progress: progress,
          entitlement: pro ? const ForcedProEntitlementService() : const FreeEntitlementService(),
          child: MaterialApp(theme: buildTheme(Brightness.light), home: screen),
        ),
      );
      await tester.pumpAndSettle();
      return progress;
    }

    testWidgets('bản miễn phí thấy giới thiệu và nút xem bản Pro', (tester) async {
      await pump(tester, const ReviewTodayScreen(), pro: false);
      expect(find.text('2 câu đến hạn ôn hôm nay'), findsOneWidget);
      expect(find.text('Xem bản Pro'), findsOneWidget);
      expect(find.textContaining('Bắt đầu ôn'), findsNothing);
    });

    testWidgets('ôn lại hôm nay: ôn hết câu đến hạn thì không còn câu nào', (tester) async {
      await pump(tester, const ReviewTodayScreen());
      expect(find.text('Bắt đầu ôn 2 câu'), findsOneWidget);
      expect(find.text('2 câu sai hôm qua'), findsOneWidget);
      expect(find.text('Hay quên nhất'), findsOneWidget);

      await tester.tap(find.text('Bắt đầu ôn 2 câu'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        final q = bank.questions[i + 1]!;
        await tester.tap(find.text(String.fromCharCode(65 + q.correctIndex)).last);
        await tester.pumpAndSettle();
        if (i == 0) {
          await tester.tap(find.text('Câu tiếp'));
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Không còn câu nào cần ôn hôm nay.'), findsOneWidget);
    });

    testWidgets('thống kê theo chương và dự đoán khả năng đỗ', (tester) async {
      await pump(tester, const StatsScreen());
      expect(find.text('Tỉ lệ đúng theo chương'), findsOneWidget);
      expect(find.text('0/20'), findsOneWidget);
      expect(find.text('Ôn ngay: chương 1'), findsOneWidget);
      await tester.tap(find.text('Dự đoán khả năng đỗ'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa đủ dữ liệu'), findsOneWidget);
      expect(find.text('Làm nốt 248 câu chưa gặp'), findsOneWidget);
    });

    testWidgets('ngày trước khi thi: 4 bước, xong bước điểm liệt khi làm hết', (tester) async {
      final progress = await pump(tester, const BeforeExamScreen());
      expect(find.text('Bạn thi ngày nào?'), findsOneWidget);
      expect(find.text('20 câu điểm liệt'), findsOneWidget);
      expect(find.text('2 câu từng làm sai'), findsOneWidget);
      expect(find.text('15 câu biển báo hay nhầm'), findsOneWidget);
      expect(find.text('0/4 bước'), findsOneWidget);

      progress.setExamDate(DateTime(2026, 10, 14));
      progress.markPlanStep(1);
      await tester.pumpAndSettle();
      expect(find.text('Thi vào ngày mai'), findsOneWidget);
      expect(find.text('1/4 bước'), findsOneWidget);
    });
  });
}
