import 'dart:async';

import '../logic/reminder_plan.dart';
import '../monetization/entitlement.dart';
import '../state/progress.dart';
import 'reminders.dart';

/// Giữ lịch nhắc học khớp với tiến độ: mỗi khi tiến độ hay quyền Pro đổi thì
/// tính lại nội dung các ngày tới và đặt lại thông báo.
class ReminderSync {
  ReminderSync(this.progress, this.entitlement, this.scheduler) {
    progress.addListener(_schedule);
    _pro = entitlement.isPro.listen((_) => _schedule());
    _schedule();
  }

  final Progress progress;
  final EntitlementService entitlement;
  final ReminderScheduler scheduler;
  late final StreamSubscription<bool> _pro;
  Timer? _debounce;

  /// Đã từng đặt nhắc trong lần chạy này; chưa thì tắt nhắc không cần hủy gì.
  bool _scheduled = false;

  void _schedule() {
    if (!scheduler.supported) return;
    if (progress.reminderMinutes == null && !_scheduled) return;
    // Trả lời liên tiếp nhiều câu chỉ cần đặt lại một lần.
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      final minutes = progress.reminderMinutes;
      _scheduled = true;
      scheduler.replace(
        minutes == null
            ? const []
            : planReminders(
                now: progress.clock(),
                minutes: minutes,
                reviews: progress.reviews.values,
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
