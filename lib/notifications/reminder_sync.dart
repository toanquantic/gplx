import 'dart:async';

import '../data/question_bank.dart';
import '../logic/reminder_plan.dart';
import '../monetization/entitlement.dart';
import '../state/progress.dart';
import 'reminders.dart';

/// Giữ lịch nhắc học khớp với tiến độ: mỗi khi tiến độ hay quyền Pro đổi thì
/// tính lại nội dung các ngày tới và đặt lại thông báo.
class ReminderSync {
  ReminderSync(this.bank, this.progress, this.entitlement, this.scheduler) {
    progress.addListener(_schedule);
    _pro = entitlement.isPro.listen((_) => _schedule());
    _schedule();
  }

  final QuestionBank bank;
  final Progress progress;
  final EntitlementService entitlement;
  final ReminderScheduler scheduler;
  late final StreamSubscription<bool> _pro;
  Timer? _debounce;

  /// Đã hủy nhắc từ lúc tắt; tắt rồi thì không cần hủy lại mỗi lần tiến độ đổi.
  /// Lần chạy đầu vẫn hủy một lần, phòng khi lần trước tắt nhắc rồi đóng app
  /// trước khi kịp hủy thông báo đã đặt.
  bool _cleared = false;

  void _schedule() {
    if (!scheduler.supported) return;
    if (progress.reminderMinutes == null && _cleared) return;
    // Trả lời liên tiếp nhiều câu chỉ cần đặt lại một lần.
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      final minutes = progress.reminderMinutes;
      _cleared = minutes == null;
      // Chỉ đếm câu thuộc hạng đang học, khớp với màn Ôn lại hôm nay.
      final code = progress.classCode;
      final reviews = [
        for (final MapEntry(:key, :value) in progress.reviews.entries)
          if (bank.questions[key]?.classes.contains(code) ?? false) value,
      ];
      scheduler.replace(
        minutes == null
            ? const []
            : planReminders(
                now: progress.clock(),
                minutes: minutes,
                reviews: reviews,
                studyDays: progress.studyDays,
                pro: entitlement.currentIsPro,
                examDate: progress.examDate,
              ),
      );
    });
  }

  void dispose() {
    _debounce?.cancel();
    _pro.cancel();
    progress.removeListener(_schedule);
  }
}
