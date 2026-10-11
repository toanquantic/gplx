import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/question_bank.dart';

class ExamRecord {
  const ExamRecord(this.classCode, this.time, this.correct, this.total, this.passed);

  final String classCode;
  final DateTime time;
  final int correct;
  final int total;
  final bool passed;

  Map<String, dynamic> toJson() => {
        'hang': classCode,
        't': time.toIso8601String(),
        'dung': correct,
        'tong': total,
        'dat': passed,
      };

  factory ExamRecord.fromJson(Map<String, dynamic> j) => ExamRecord(
      j['hang'] as String, DateTime.parse(j['t'] as String), j['dung'] as int,
      j['tong'] as int, j['dat'] as bool);
}

/// Tiến độ học lưu trên máy (không cần mạng, không cần tài khoản).
///
/// Kết quả từng câu dùng chung cho mọi hạng, vì cùng một câu hỏi có cùng đáp án.
class Progress extends ChangeNotifier {
  Progress._(this._prefs);

  static const _key = 'tien_do_v1';
  final SharedPreferences _prefs;

  String classCode = enabledClasses.first;

  /// Lần trả lời gần nhất của mỗi câu: true là đúng.
  final Map<int, bool> lastResult = {};
  final Set<int> bookmarks = {};
  final List<ExamRecord> exams = [];

  static Future<Progress> load() async {
    final p = Progress._(await SharedPreferences.getInstance());
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
    (j['ket_qua'] as Map<String, dynamic>? ?? {})
        .forEach((k, v) => lastResult[int.parse(k)] = v as bool);
    bookmarks.addAll((j['danh_dau'] as List? ?? []).cast<int>());
    exams.addAll((j['thi_thu'] as List? ?? [])
        .map((e) => ExamRecord.fromJson(e as Map<String, dynamic>)));
  }

  Future<void> _save() => _prefs.setString(
      _key,
      jsonEncode({
        'hang': classCode,
        'ket_qua': lastResult.map((k, v) => MapEntry('$k', v)),
        'danh_dau': bookmarks.toList(),
        'thi_thu': exams.map((e) => e.toJson()).toList(),
      }));

  void selectClass(String code) {
    classCode = code;
    notifyListeners();
    _save();
  }

  void recordAnswer(int questionId, bool correct) {
    lastResult[questionId] = correct;
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
    notifyListeners();
    await _save();
  }

  bool isWrong(int id) => lastResult[id] == false;
}
