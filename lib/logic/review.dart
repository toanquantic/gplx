/// Lịch ôn lại câu sai theo kiểu lặp lại ngắt quãng (spaced repetition).
///
/// Câu trả lời sai vào lịch, đến hạn ngay hôm sau. Mỗi lần ôn đúng đúng hạn,
/// khoảng cách đến lần ôn kế tiếp giãn ra theo [reviewIntervals]; đúng hết các
/// bậc thì câu rời lịch. Sai lại thì về bậc đầu.
library;

/// Số ngày đến lần ôn kế tiếp sau mỗi lần ôn đúng, theo bậc.
const reviewIntervals = [3, 7, 14, 30];

/// Ngày (không có giờ) theo giờ máy, để so sánh hạn ôn.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Cộng ngày theo lịch (không lệch giờ khi đổi giờ mùa hè).
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

String formatDay(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDay(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// Trạng thái ôn của một câu trong lịch.
class ReviewCard {
  const ReviewCard({
    required this.step,
    required this.due,
    required this.lapses,
    required this.lastWrong,
  });

  /// Số lần đã ôn đúng liên tiếp đúng hạn, từ 0 đến độ dài [reviewIntervals].
  final int step;

  /// Ngày đến hạn ôn.
  final DateTime due;

  /// Tổng số lần trả lời sai câu này.
  final int lapses;
  final DateTime lastWrong;

  /// Độ nhớ ước lượng, từ 0 (mới sai) đến gần 1 (sắp rời lịch).
  double get strength => (step + 1) / (reviewIntervals.length + 2);

  /// Trả lời sai: về bậc đầu, ôn lại vào ngày mai.
  static ReviewCard wrong(ReviewCard? card, DateTime today) {
    final d = dayOf(today);
    return ReviewCard(step: 0, due: addDays(d, 1), lapses: (card?.lapses ?? 0) + 1, lastWrong: d);
  }

  /// Trả lời đúng. Chỉ lên bậc khi đã đến hạn (ôn sớm không tính), trả về null
  /// khi câu đã nhớ chắc và rời lịch.
  ReviewCard? correct(DateTime today) {
    final d = dayOf(today);
    if (due.isAfter(d)) return this;
    if (step >= reviewIntervals.length) return null;
    return ReviewCard(
      step: step + 1,
      due: addDays(d, reviewIntervals[step]),
      lapses: lapses,
      lastWrong: lastWrong,
    );
  }

  bool isDue(DateTime today) => !due.isAfter(dayOf(today));

  Map<String, dynamic> toJson() => {
    'b': step,
    'h': formatDay(due),
    's': lapses,
    'l': formatDay(lastWrong),
  };

  factory ReviewCard.fromJson(Map<String, dynamic> j) => ReviewCard(
    step: j['b'] as int,
    due: parseDay(j['h'] as String),
    lapses: j['s'] as int,
    lastWrong: parseDay(j['l'] as String),
  );
}

/// Số ngày học liên tiếp tính đến hôm nay (hoặc hôm qua, nếu hôm nay chưa học).
int studyStreak(Set<String> days, DateTime today) {
  var d = dayOf(today);
  if (!days.contains(formatDay(d))) d = addDays(d, -1);
  var n = 0;
  while (days.contains(formatDay(d))) {
    n++;
    d = addDays(d, -1);
  }
  return n;
}
