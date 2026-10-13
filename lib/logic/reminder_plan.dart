import 'review.dart';

/// Giờ nhắc mặc định: 20:00, tính bằng phút từ nửa đêm.
const defaultReminderMinutes = 20 * 60;

/// Số ngày đặt trước. Không mở app quá chừng ấy ngày thì app thôi nhắc.
const reminderDays = 7;

/// Một lời nhắc học đã tính sẵn nội dung cho đúng ngày nó hiện.
class ReminderMessage {
  const ReminderMessage(this.at, this.title, this.body);

  final DateTime at;
  final String title;
  final String body;
}

/// Lên lịch nhắc học cho [reminderDays] ngày tới, lúc [minutes] mỗi ngày.
///
/// Thông báo đặt trước không tự đổi nội dung, nên mỗi ngày có câu riêng tính
/// từ tiến độ hiện tại: số câu đến hạn ôn (bản Pro), số ngày còn lại đến ngày
/// thi, hoặc lời nhắc chung. Hôm nay đã học thì không nhắc nữa.
List<ReminderMessage> planReminders({
  required DateTime now,
  required int minutes,
  required Iterable<ReviewCard> reviews,
  required Set<String> studyDays,
  required bool pro,
  DateTime? examDate,
}) {
  final today = dayOf(now);
  final out = <ReminderMessage>[];
  for (var i = 0; i < reminderDays; i++) {
    final day = addDays(today, i);
    final at = DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
    if (!at.isAfter(now)) continue;
    if (i == 0 && studyDays.contains(formatDay(today))) continue;

    final due = pro ? reviews.where((r) => r.isDue(day)).length : 0;
    final daysLeft = examDate?.difference(day).inDays;
    final String body;
    if (daysLeft == 0) {
      body = 'Hôm nay thi rồi. Xem lại câu điểm liệt một lượt trước giờ thi nhé.';
    } else if (due > 0) {
      body = '$due câu đến hạn ôn lại hôm nay. Ôn vài phút để không quên.';
    } else if (daysLeft != null && daysLeft > 0 && daysLeft <= 30) {
      body = 'Còn $daysLeft ngày đến ngày thi. Làm một đề thi thử hôm nay nhé.';
    } else {
      body = 'Dành 10 phút ôn lý thuyết hôm nay để giữ chuỗi ngày học.';
    }
    out.add(ReminderMessage(at, 'Đến giờ ôn thi GPLX', body));
  }
  return out;
}

/// "20:00" từ số phút trong ngày.
String formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
