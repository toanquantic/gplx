import 'package:flutter/material.dart';

import '../../logic/reminder_plan.dart';
import '../app_scope.dart';
import '../theme.dart';

/// Bật, tắt và chọn giờ nhắc học mỗi ngày. Ẩn trên máy không có thông báo.
class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key});

  Future<void> _toggle(BuildContext context, bool on) async {
    final scope = AppScope.read(context);
    if (!on) {
      scope.progress.setReminder(null);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (!await scope.reminders.requestPermission()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('App chưa được phép gửi thông báo. Bạn bật lại trong Cài đặt của máy.'),
        ),
      );
      return;
    }
    scope.progress.setReminder(defaultReminderMinutes);
  }

  Future<void> _pickTime(BuildContext context, int minutes) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: 'Giờ nhắc học',
    );
    if (picked != null && context.mounted) {
      AppScope.read(context).progress.setReminder(picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    if (!scope.reminders.supported) return const SizedBox.shrink();
    final minutes = scope.progress.reminderMinutes;
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      onTap: minutes == null ? null : () => _pickTime(context, minutes),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhắc học mỗi ngày',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  minutes == null ? 'Đang tắt' : 'Lúc ${formatMinutes(minutes)} · chạm để đổi giờ',
                  style: TextStyle(fontSize: 12.5, color: c.muted),
                ),
              ],
            ),
          ),
          Switch(value: minutes != null, onChanged: (on) => _toggle(context, on)),
        ],
      ),
    );
  }
}
