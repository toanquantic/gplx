import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/question_bank.dart';
import '../logic/review.dart';

class ExamRecord {
  const ExamRecord(
    this.classCode,
    this.time,
    this.correct,
    this.total,
    this.passed, {
    this.failedCritical = false,
    this.duration,
    this.questionIds,
    this.answers,
    this.correctAnswers,
    this.smart = false,
  });

  final String classCode;
  final DateTime time;
  final int correct;
  final int total;
  final bool passed;
  final bool failedCritical;

  /// Thời gian làm bài. Các trường dưới đây null ở bản ghi cũ.
  final Duration? duration;

  /// Id các câu trong đề và phương án đã chọn, để xem lại bài thi.
  final List<int>? questionIds;
  final List<int?>? answers;

  /// Đáp án đúng của từng câu lúc thi, để nhận ra khi bộ đề trong app đã đổi.
  final List<int>? correctAnswers;

  /// Đề ưu tiên câu yếu (bản Pro), khác đề rút ngẫu nhiên.
  final bool smart;

  Map<String, dynamic> toJson() => {
    'hang': classCode,
    't': time.toIso8601String(),
    'dung': correct,
    'tong': total,
    'dat': passed,
    'liet': failedCritical,
    if (duration != null) 'giay': duration!.inSeconds,
    if (questionIds != null) 'cau': questionIds,
    if (answers != null) 'chon': answers,
    if (correctAnswers != null) 'dap': correctAnswers,
    if (smart) 'uu_tien': true,
  };

  factory ExamRecord.fromJson(Map<String, dynamic> j) => ExamRecord(
    j['hang'] as String,
    DateTime.parse(j['t'] as String),
    j['dung'] as int,
    j['tong'] as int,
    j['dat'] as bool,
    failedCritical: j['liet'] as bool? ?? false,
    duration: j['giay'] == null ? null : Duration(seconds: j['giay'] as int),
    questionIds: (j['cau'] as List?)?.cast<int>(),
    answers: (j['chon'] as List?)?.cast<int?>(),
    correctAnswers: (j['dap'] as List?)?.cast<int>(),
    smart: j['uu_tien'] as bool? ?? false,
  );
}

/// Tiến độ học lưu trên máy (không cần mạng, không cần tài khoản).
///
/// Kết quả từng câu dùng chung cho mọi hạng, vì cùng một câu hỏi có cùng đáp án.
class Progress extends ChangeNotifier {
  Progress._(this._prefs, this.clock);

  static const _key = 'tien_do_v1';
  final SharedPreferences _prefs;

  /// Đồng hồ, test truyền giờ giả vào để kiểm tra lịch ôn.
  final DateTime Function() clock;

  String classCode = enabledClasses.first;

  /// Lần trả lời gần nhất của mỗi câu: true là đúng.
  final Map<int, bool> lastResult = {};
  final Set<int> bookmarks = {};
  final List<ExamRecord> exams = [];

  /// Lịch ôn lại các câu từng sai, theo id câu.
  final Map<int, ReviewCard> reviews = {};

  /// Những ngày có làm câu hỏi (dạng `yyyy-mm-dd`), để tính chuỗi ngày học.
  final Set<String> studyDays = {};

  /// Ngày thi người dùng chọn cho chế độ "ngày trước khi thi".
  DateTime? examDate;

  /// Lúc bắt đầu gói ôn trước ngày thi và các bước đã xong trong gói, theo
  /// hạng (khóa `hạng:bước`), vì mỗi hạng có bộ câu riêng.
  DateTime? planStart;
  final Set<String> planDone = {};

  /// Giờ nhắc học mỗi ngày, tính bằng phút từ nửa đêm; null là tắt.
  int? reminderMinutes;

  bool isPlanStepDone(int step) => planDone.contains('$classCode:$step');

  DateTime get today => dayOf(clock());

  static Future<Progress> load({DateTime Function()? clock}) async {
    final p = Progress._(await SharedPreferences.getInstance(), clock ?? DateTime.now);
    final raw = p._prefs.getString(_key);
    if (raw != null) {
      try {
        p._restore(jsonDecode(raw) as Map<String, dynamic>);
      } on FormatException {
        // Dữ liệu hỏng thì bắt đầu lại, không làm app dừng.
      }
    }
    return p;
  }

  void _restore(Map<String, dynamic> j) {
    final code = j['hang'] as String?;
    if (code != null && enabledClasses.contains(code)) classCode = code;
    (j['ket_qua'] as Map<String, dynamic>? ?? {}).forEach(
      (k, v) => lastResult[int.parse(k)] = v as bool,
    );
    bookmarks.addAll((j['danh_dau'] as List? ?? []).cast<int>());
    exams.addAll(
      (j['thi_thu'] as List? ?? []).map((e) => ExamRecord.fromJson(e as Map<String, dynamic>)),
    );
    (j['on_lai'] as Map<String, dynamic>? ?? {}).forEach(
      (k, v) => reviews[int.parse(k)] = ReviewCard.fromJson(v as Map<String, dynamic>),
    );
    studyDays.addAll((j['ngay_hoc'] as List? ?? []).cast<String>());
    final exam = j['ngay_thi'] as String?;
    if (exam != null) examDate = parseDay(exam);
    final start = j['bat_dau_on'] as String?;
    if (start != null) planStart = DateTime.parse(start);
    planDone.addAll((j['buoc_xong'] as List? ?? []).cast<String>());
    reminderMinutes = j['nhac'] as int?;
  }

  Future<void> _save() => _prefs.setString(
    _key,
    jsonEncode({
      'hang': classCode,
      'ket_qua': lastResult.map((k, v) => MapEntry('$k', v)),
      'danh_dau': bookmarks.toList(),
      'thi_thu': exams.map((e) => e.toJson()).toList(),
      'on_lai': reviews.map((k, v) => MapEntry('$k', v.toJson())),
      'ngay_hoc': studyDays.toList(),
      if (examDate != null) 'ngay_thi': formatDay(examDate!),
      if (planStart != null) 'bat_dau_on': planStart!.toIso8601String(),
      'buoc_xong': planDone.toList(),
      if (reminderMinutes != null) 'nhac': reminderMinutes,
    }),
  );

  void selectClass(String code) {
    classCode = code;
    notifyListeners();
    _save();
  }

  void recordAnswer(int questionId, bool correct) => recordAnswers({questionId: correct});

  /// Ghi nhiều câu một lần (ví dụ khi nộp bài thi), cập nhật cả lịch ôn.
  void recordAnswers(Map<int, bool> results) {
    if (results.isEmpty) return;
    final now = today;
    results.forEach((id, correct) {
      lastResult[id] = correct;
      final card = reviews[id];
      if (!correct) {
        reviews[id] = ReviewCard.wrong(card, now);
      } else if (card != null) {
        final next = card.correct(now);
        next == null ? reviews.remove(id) : reviews[id] = next;
      }
    });
    if (studyDays.add(formatDay(now))) {
      // Chỉ cần giữ đủ để tính chuỗi ngày học.
      final keep = formatDay(addDays(now, -400));
      studyDays.removeWhere((d) => d.compareTo(keep) < 0);
    }
    notifyListeners();
    _save();
  }

  /// Đặt ngày thi và bắt đầu lại gói ôn trước ngày thi.
  void setExamDate(DateTime? date) {
    examDate = date == null ? null : dayOf(date);
    planStart = date == null ? null : clock();
    planDone.clear();
    notifyListeners();
    _save();
  }

  void setReminder(int? minutes) {
    reminderMinutes = minutes;
    notifyListeners();
    _save();
  }

  void markPlanStep(int step) {
    if (!planDone.add('$classCode:$step')) return;
    notifyListeners();
    _save();
  }

  void toggleBookmark(int questionId) {
    if (!bookmarks.remove(questionId)) bookmarks.add(questionId);
    notifyListeners();
    _save();
  }

  void recordExam(ExamRecord record) {
    exams.insert(0, record);
    if (exams.length > 100) exams.removeLast();
    notifyListeners();
    _save();
  }

  Future<void> reset() async {
    lastResult.clear();
    bookmarks.clear();
    exams.clear();
    reviews.clear();
    studyDays.clear();
    examDate = null;
    planStart = null;
    planDone.clear();
    notifyListeners();
    await _save();
  }

  bool isWrong(int id) => lastResult[id] == false;
}
