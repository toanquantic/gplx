/// Một câu hỏi trong bộ 600 câu của Cục CSGT.
class Question {
  const Question({
    required this.id,
    required this.chapter,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.criticalByGroup,
    required this.classes,
    this.image,
    this.explanation,
  });

  final int id;
  final int chapter;
  final String text;
  final List<String> options;

  /// Chỉ số phương án đúng, đánh từ 0 (trong JSON `dung` đánh từ 1).
  final int correctIndex;

  /// `diem_liet_theo_hang`: khóa `A1_A`, `B1`, `o_to`.
  final Map<String, bool> criticalByGroup;

  /// Các hạng áp dụng câu này.
  final Set<String> classes;

  /// Đường dẫn asset của hình, ví dụ `assets/data/images/q036.webp`.
  final String? image;
  final String? explanation;

  factory Question.fromJson(Map<String, dynamic> j, {String? explanation}) {
    final hinh = j['hinh'] as String?;
    return Question(
      id: j['id'] as int,
      chapter: j['chuong'] as int,
      text: j['noi_dung'] as String,
      options: (j['dap_an'] as List).cast<String>(),
      correctIndex: (j['dung'] as int) - 1,
      criticalByGroup: (j['diem_liet_theo_hang'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as bool)),
      classes: (j['hang'] as List).cast<String>().toSet(),
      image: hinh == null ? null : 'assets/data/$hinh',
      explanation: explanation ?? j['giai_thich'] as String?,
    );
  }
}

class Chapter {
  const Chapter(this.number, this.name, this.firstId, this.lastId);

  final int number;
  final String name;
  final int firstId;
  final int lastId;

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
      j['so'] as int, j['ten'] as String, j['tu_cau'] as int, j['den_cau'] as int);
}

/// Một hạng GPLX theo Điều 57 Luật 36/2024.
class LicenseClass {
  const LicenseClass({
    required this.code,
    required this.kind,
    required this.description,
    this.oldEquivalent,
  });

  final String code;

  /// `mo_to` hoặc `o_to`.
  final String kind;
  final String description;
  final String? oldEquivalent;

  factory LicenseClass.fromJson(Map<String, dynamic> j) => LicenseClass(
        code: j['ma'] as String,
        kind: j['loai'] as String,
        description: j['mo_ta'] as String,
        oldEquivalent: j['hang_cu_tuong_ung'] as String?,
      );
}

/// Cấu hình đề thi lý thuyết của một hạng (từ `cau_hinh_de_thi.json`).
class ExamConfig {
  const ExamConfig({
    required this.questionCount,
    required this.minutes,
    required this.passScore,
    required this.structure,
    required this.groups,
  });

  final int questionCount;
  final int minutes;

  /// Null khi chưa xác minh được điểm đạt (ví dụ hạng B1).
  final int? passScore;

  /// Số câu rút từ mỗi nhóm, theo đúng thứ tự trong đề.
  final Map<String, int> structure;

  /// Danh sách id câu hỏi của mỗi nhóm.
  final Map<String, List<int>> groups;

  List<int> get criticalIds => groups['diem_liet'] ?? const [];

  factory ExamConfig.fromJson(Map<String, dynamic> j) => ExamConfig(
        questionCount: j['so_cau'] as int,
        minutes: j['thoi_gian_phut'] as int,
        passScore: j['diem_dat_toi_thieu'] as int?,
        structure: (j['cau_truc'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
        groups: (j['nhom_cau_hoi'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as List).cast<int>())),
      );
}

class TrafficSign {
  const TrafficSign(this.code, this.name, this.group, this.meaning);

  final String code;
  final String name;
  final String group;
  final String? meaning;

  factory TrafficSign.fromJson(Map<String, dynamic> j) => TrafficSign(
      j['ma'] as String, j['ten'] as String, j['nhom'] as String,
      j['y_nghia'] as String?);
}

const groupLabels = {
  'quy_dinh_chung': 'Quy định chung',
  'diem_liet': 'Câu điểm liệt',
  'van_hoa': 'Văn hóa, đạo đức',
  'ky_thuat': 'Kỹ thuật lái xe',
  'cau_tao': 'Cấu tạo, sửa chữa',
  'ky_thuat_cau_tao': 'Kỹ thuật, cấu tạo',
  'bao_hieu': 'Báo hiệu đường bộ',
  'sa_hinh': 'Sa hình',
};
