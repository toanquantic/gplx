import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/models.dart';

/// Các nhóm hạng đang mở trong app, theo thứ tự hiện trong danh sách chọn hạng
/// (đủ 15 hạng của Điều 57 Luật 36/2024).
const classGroups = {
  'Mô tô': ['A1', 'A', 'B1'],
  'Ô tô con, ô tô tải': ['B', 'C1', 'C'],
  'Ô tô chở người': ['D1', 'D2', 'D'],
  'Kéo rơ moóc': ['BE', 'C1E', 'CE', 'D1E', 'D2E', 'DE'],
};

/// Các hạng đang mở trong app.
final enabledClasses = [for (final codes in classGroups.values) ...codes];

/// Toàn bộ dữ liệu ôn thi, nạp một lần từ assets và giữ trong bộ nhớ.
class QuestionBank {
  QuestionBank._({
    required this.questions,
    required this.chapters,
    required this.classes,
    required this.examConfigs,
    required this.signs,
    required this.tipGroups,
    required this.sourceNote,
  });

  final Map<int, Question> questions;
  final List<Chapter> chapters;
  final Map<String, LicenseClass> classes;
  final Map<String, ExamConfig> examConfigs;
  final List<TrafficSign> signs;
  final List<TipGroup> tipGroups;
  final String sourceNote;

  static Future<QuestionBank> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    Future<String> read(String name) => b.loadString('assets/data/$name');
    return QuestionBank.parse(
      questionsJson: await read('cau_hoi_600.json'),
      explanationsJson: await read('giai_thich_cong_dong.json'),
      examConfigJson: await read('cau_hinh_de_thi.json'),
      classesJson: await read('hang_gplx.json'),
      signsJson: await read('bien_bao.json'),
      tipsJson: await read('meo_nho.json'),
      reviewJson: await read('giai_thich_ra_soat.json'),
    );
  }

  factory QuestionBank.parse({
    required String questionsJson,
    required String explanationsJson,
    required String examConfigJson,
    required String classesJson,
    required String signsJson,
    required String tipsJson,
    required String reviewJson,
  }) {
    final explanations = <int, String>{
      for (final e in (jsonDecode(explanationsJson)['giai_thich'] as List))
        if (e['giai_thich'] != null) e['id'] as int: e['giai_thich'] as String,
    };
    // Bản rà soát: thay lời giải thích sai hoặc khó hiểu, đánh dấu câu đã đọc lại.
    final review = jsonDecode(reviewJson) as Map<String, dynamic>;
    for (final e in (review['sua'] as List).cast<Map<String, dynamic>>()) {
      explanations[e['id'] as int] = e['giai_thich'] as String;
    }
    final reviewed = (review['da_ra_soat'] as List).cast<int>().toSet();

    final qj = jsonDecode(questionsJson) as Map<String, dynamic>;
    final questions = <int, Question>{
      for (final j in (qj['cau_hoi'] as List).cast<Map<String, dynamic>>())
        j['id'] as int: Question.fromJson(
          j,
          explanation: explanations[j['id']],
          explanationReviewed: reviewed.contains(j['id']),
        ),
    };
    final source = qj['_nguon'] as Map<String, dynamic>;

    final classes = <String, LicenseClass>{
      for (final j in (jsonDecode(classesJson)['hang'] as List).cast<Map<String, dynamic>>())
        j['ma'] as String: LicenseClass.fromJson(j),
    };

    // Một số khóa gộp nhiều hạng, ví dụ "D1_D2_D_BE_..."; tách ra từng hạng.
    final examConfigs = <String, ExamConfig>{};
    final cj = jsonDecode(examConfigJson)['hang'] as Map<String, dynamic>;
    cj.forEach((key, value) {
      final config = ExamConfig.fromJson(value as Map<String, dynamic>);
      for (final code in key.split('_')) {
        examConfigs.putIfAbsent(code, () => config);
      }
      examConfigs[key] = config;
    });

    return QuestionBank._(
      questions: questions,
      chapters: [
        for (final c in (qj['chuong'] as List).cast<Map<String, dynamic>>()) Chapter.fromJson(c),
      ],
      classes: classes,
      examConfigs: examConfigs,
      signs: [
        for (final s in (jsonDecode(signsJson) as List).cast<Map<String, dynamic>>())
          TrafficSign.fromJson(s),
      ],
      tipGroups: [
        for (final t in (jsonDecode(tipsJson)['nhom'] as List).cast<Map<String, dynamic>>())
          TipGroup.fromJson(t),
      ],
      sourceNote: '${source['ten']}, ${source['co_quan']}. ${source['van_ban']}.',
    );
  }

  /// Các câu thuộc bộ câu hỏi của hạng, theo thứ tự id.
  List<Question> forClass(String code) =>
      questions.values.where((q) => q.classes.contains(code)).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  List<Question> forChapter(String code, int chapter) =>
      forClass(code).where((q) => q.chapter == chapter).toList();

  /// Câu điểm liệt của hạng: A1/A dùng 20 câu, B1 30 câu, ô tô 60 câu.
  List<Question> criticalFor(String code) {
    final ids = examConfigs[code]?.criticalIds ?? const <int>[];
    return [for (final id in ids) questions[id]!]..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Các nhóm mẹo có câu thuộc hạng [code], mỗi nhóm chỉ giữ câu của hạng đó.
  List<(TipGroup, List<Question>)> tipsForClass(String code) => [
    for (final g in tipGroups)
      if (_tipQuestions(g, code) case final qs when qs.isNotEmpty) (g, qs),
  ];

  List<Question> _tipQuestions(TipGroup g, String code) => [
    for (final id in g.questionIds)
      if (questions[id]!.classes.contains(code)) questions[id]!,
  ];

  /// Nhóm mẹo đầu tiên có câu [id], hoặc null.
  TipGroup? tipFor(int id) {
    for (final g in tipGroups) {
      if (g.questionIds.contains(id)) return g;
    }
    return null;
  }

  bool isCritical(String code, int id) => examConfigs[code]?.criticalIds.contains(id) ?? false;
}
