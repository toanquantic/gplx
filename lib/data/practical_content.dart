import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

/// Một trung tâm dạy lái xe trong danh sách giới thiệu.
class DrivingSchool {
  const DrivingSchool({
    required this.name,
    required this.province,
    required this.address,
    this.phone,
    this.website,
  });

  final String name;
  final String province;
  final String address;
  final String? phone;
  final String? website;

  factory DrivingSchool.fromJson(Map<String, dynamic> j) => DrivingSchool(
    name: j['ten'] as String,
    province: j['tinh'] as String,
    address: j['dia_chi'] as String,
    phone: j['dien_thoai'] as String?,
    website: j['website'] as String?,
  );
}

class DrivingSchoolList {
  const DrivingSchoolList({required this.note, required this.schools});

  final String note;
  final List<DrivingSchool> schools;

  /// Các tỉnh, thành có trong danh sách, theo thứ tự xuất hiện.
  List<String> get provinces => schools.map((s) => s.province).toSet().toList();

  factory DrivingSchoolList.parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    return DrivingSchoolList(
      note: j['ghi_chu'] as String,
      schools: [
        for (final s in j['trung_tam'] as List) DrivingSchool.fromJson(s as Map<String, dynamic>),
      ],
    );
  }

  static Future<DrivingSchoolList> load(AssetBundle bundle) async =>
      DrivingSchoolList.parse(await bundle.loadString('assets/data/trung_tam_dao_tao.json'));
}

/// Một video YouTube hướng dẫn thực hành.
class PracticeVideo {
  const PracticeVideo({required this.id, required this.title});

  /// Mã video YouTube (phần sau `watch?v=`).
  final String id;
  final String title;

  Uri get watchUrl => Uri.https('www.youtube.com', '/watch', {'v': id});
  String get thumbnailUrl => 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
}

class VideoGroup {
  const VideoGroup({required this.title, required this.classes, required this.videos});

  final String title;

  /// Các hạng mà nhóm video này dùng được.
  final List<String> classes;
  final List<PracticeVideo> videos;
}

class PracticeVideoList {
  const PracticeVideoList({required this.note, required this.groups});

  final String note;
  final List<VideoGroup> groups;

  /// Nhóm video hợp với hạng đang học; hạng không có nhóm nào thì trả về tất cả.
  List<VideoGroup> forClass(String code) {
    final matched = groups.where((g) => g.classes.contains(code)).toList();
    return matched.isEmpty ? groups : matched;
  }

  factory PracticeVideoList.parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    return PracticeVideoList(
      note: j['ghi_chu'] as String,
      groups: [
        for (final g in (j['nhom'] as List).cast<Map<String, dynamic>>())
          VideoGroup(
            title: g['ten'] as String,
            classes: (g['hang'] as List).cast<String>(),
            videos: [
              for (final v in (g['video'] as List).cast<Map<String, dynamic>>())
                PracticeVideo(id: v['id'] as String, title: v['tieu_de'] as String),
            ],
          ),
      ],
    );
  }

  static Future<PracticeVideoList> load(AssetBundle bundle) async =>
      PracticeVideoList.parse(await bundle.loadString('assets/data/video_thuc_hanh.json'));
}
