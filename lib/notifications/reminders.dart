import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../logic/reminder_plan.dart';

/// Đặt và hủy thông báo nhắc học trên máy.
abstract class ReminderScheduler {
  /// Máy có hỗ trợ thông báo không (Android, iOS). Không thì ẩn phần cài đặt.
  bool get supported;

  /// Xin quyền gửi thông báo, trả về true nếu được phép.
  Future<bool> requestPermission();

  /// Hủy các lời nhắc cũ rồi đặt [messages] (rỗng là tắt nhắc).
  Future<void> replace(List<ReminderMessage> messages);
}

/// Web, desktop và test: không có thông báo.
class NoReminderScheduler implements ReminderScheduler {
  const NoReminderScheduler();

  @override
  bool get supported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replace(List<ReminderMessage> messages) async {}
}

ReminderScheduler createReminderScheduler() =>
    !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)
    ? LocalReminderScheduler()
    : const NoReminderScheduler();

/// Thông báo cục bộ qua `flutter_local_notifications`, không cần máy chủ.
class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'nhac_hoc',
      'Nhắc học mỗi ngày',
      channelDescription: 'Nhắc ôn thi lý thuyết vào giờ bạn chọn',
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Chỉ xin quyền khi người dùng bật nhắc học, không hỏi ngay lúc mở app.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> replace(List<ReminderMessage> messages) async {
    await _init();
    for (var id = 1; id <= reminderDays; id++) {
      await _plugin.cancel(id: id);
    }
    for (var i = 0; i < messages.length && i < reminderDays; i++) {
      final m = messages[i];
      await _plugin.zonedSchedule(
        id: i + 1,
        scheduledDate: tz.TZDateTime.from(m.at, tz.local),
        notificationDetails: _details,
        // Không cần đúng từng giây, nên không phải xin quyền báo thức chính xác.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: m.title,
        body: m.body,
      );
    }
  }
}
