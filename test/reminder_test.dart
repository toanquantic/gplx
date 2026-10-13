import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/logic/reminder_plan.dart';
import 'package:on_thi_gplx/logic/review.dart';
import 'package:on_thi_gplx/monetization/entitlement.dart';
import 'package:on_thi_gplx/monetization/store_entitlement.dart';
import 'package:on_thi_gplx/notifications/reminder_sync.dart';
import 'package:on_thi_gplx/notifications/reminders.dart';
import 'package:on_thi_gplx/state/progress.dart';
import 'package:on_thi_gplx/ui/app_scope.dart';
import 'package:on_thi_gplx/ui/theme.dart';
import 'package:on_thi_gplx/ui/widgets/reminder_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exam_test.dart' show loadBank;

/// Ghi lại các lần đặt nhắc thay vì gọi plugin thông báo.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.allow = true});

  final bool allow;
  final calls = <List<ReminderMessage>>[];
  int permissionAsks = 0;

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return allow;
  }

  @override
  Future<void> replace(List<ReminderMessage> messages) async => calls.add(messages);
}

void main() {
  final now = DateTime(2026, 10, 12, 9);

  group('lên lịch nhắc học', () {
    test('7 ngày lúc 20:00, hôm nay đã học thì bỏ hôm nay', () {
      final plan = planReminders(
        now: now,
        minutes: defaultReminderMinutes,
        reviews: const [],
        studyDays: {},
        pro: false,
      );
      expect(plan.length, reminderDays);
      expect(plan.first.at, DateTime(2026, 10, 12, 20));
      expect(plan.last.at, DateTime(2026, 10, 18, 20));
      expect(plan.first.body, contains('10 phút'));

      final studied = planReminders(
        now: now,
        minutes: defaultReminderMinutes,
        reviews: const [],
        studyDays: {formatDay(now)},
        pro: false,
      );
      expect(studied.first.at, DateTime(2026, 10, 13, 20));
    });

    test('đã qua giờ nhắc hôm nay thì bắt đầu từ ngày mai', () {
      final plan = planReminders(
        now: DateTime(2026, 10, 12, 21),
        minutes: defaultReminderMinutes,
        reviews: const [],
        studyDays: {},
        pro: false,
      );
      expect(plan.first.at, DateTime(2026, 10, 13, 20));
      expect(plan.length, reminderDays - 1);
    });

    test('Pro thấy số câu đến hạn của đúng ngày đó; có ngày thi thì đếm ngược', () {
      final card = ReviewCard.wrong(null, now); // đến hạn 13/10
      final plan = planReminders(
        now: now,
        minutes: defaultReminderMinutes,
        reviews: [card],
        studyDays: {},
        pro: true,
        examDate: DateTime(2026, 10, 15),
      );
      expect(plan[0].body, contains('Còn 3 ngày'));
      expect(plan[1].body, startsWith('1 câu đến hạn'));
      expect(plan[3].body, contains('Hôm nay thi'));
      // Câu chưa ôn thì vẫn đến hạn những ngày sau.
      expect(plan[4].body, startsWith('1 câu đến hạn'));

      final free = planReminders(
        now: now,
        minutes: defaultReminderMinutes,
        reviews: [card],
        studyDays: {},
        pro: false,
      );
      expect(free[1].body, contains('10 phút'));
    });
  });

  group('cài đặt nhắc học', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<Progress> pump(WidgetTester tester, ReminderScheduler reminders) async {
      final progress = (await tester.runAsync(() => Progress.load(clock: () => now)))!;
      await tester.pumpWidget(
        AppScope(
          bank: loadBank(),
          progress: progress,
          reminders: reminders,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(body: ReminderTile()),
          ),
        ),
      );
      return progress;
    }

    testWidgets('bật nhắc thì xin quyền, lưu 20:00 và đặt lịch; tắt thì hủy', (tester) async {
      final fake = FakeReminderScheduler();
      final progress = await pump(tester, fake);
      final sync = ReminderSync(loadBank(), progress, const FreeEntitlementService(), fake);
      addTearDown(sync.dispose);
      expect(find.text('Đang tắt'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(seconds: 3));
      expect(fake.permissionAsks, 1);
      expect(progress.reminderMinutes, defaultReminderMinutes);
      expect(find.text('Lúc 20:00 · chạm để đổi giờ'), findsOneWidget);
      expect(fake.calls.last.length, reminderDays);

      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(seconds: 3));
      expect(progress.reminderMinutes, isNull);
      expect(fake.calls.last, isEmpty);
    });

    test('mở app khi nhắc đang tắt thì vẫn hủy thông báo cũ một lần', () async {
      final progress = await Progress.load(clock: () => now);
      final fake = FakeReminderScheduler();
      final sync = ReminderSync(loadBank(), progress, const FreeEntitlementService(), fake);
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(fake.calls, [isEmpty]);
      progress.recordAnswer(1, true);
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(fake.calls.length, 1);
      sync.dispose();
    });

    test('Pro chỉ đếm câu đến hạn của hạng đang học', () async {
      final progress = await Progress.load(clock: () => DateTime(2026, 10, 12, 9));
      // Câu 300 chỉ thuộc bộ ô tô, câu 1 thuộc mọi hạng.
      progress.recordAnswers({300: false, 1: false});
      progress.setReminder(defaultReminderMinutes);
      final fake = FakeReminderScheduler();
      final sync = ReminderSync(loadBank(), progress, const ForcedProEntitlementService(), fake);
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(progress.classCode, 'A1');
      expect(fake.calls.last[1].body, startsWith('1 câu đến hạn'));
      sync.dispose();
    });

    testWidgets('không được phép gửi thông báo thì giữ trạng thái tắt', (tester) async {
      final fake = FakeReminderScheduler(allow: false);
      final progress = await pump(tester, fake);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(progress.reminderMinutes, isNull);
      expect(find.textContaining('chưa được phép gửi thông báo'), findsOneWidget);
    });

    testWidgets('máy không có thông báo thì ẩn', (tester) async {
      await pump(tester, const NoReminderScheduler());
      expect(find.byType(Switch), findsNothing);
    });
  });
}
