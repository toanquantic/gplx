import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/data/practical_content.dart';
import 'package:on_thi_gplx/data/question_bank.dart';

void main() {
  test('danh sách trung tâm dạy lái đủ thông tin liên hệ', () {
    final list = DrivingSchoolList.parse(
      File('assets/data/trung_tam_dao_tao.json').readAsStringSync(),
    );
    expect(list.schools, isNotEmpty);
    expect(list.provinces, containsAll(['Hà Nội', 'TP. Hồ Chí Minh']));
    for (final s in list.schools) {
      expect(s.address, isNotEmpty, reason: s.name);
      expect(s.phone, matches(RegExp(r'^0\d{9,10}$')), reason: s.name);
      if (s.website != null) expect(Uri.parse(s.website!).scheme, 'https', reason: s.name);
    }
  });

  test('video thực hành có mã YouTube hợp lệ, không trùng, mọi hạng đều có video', () {
    final list = PracticeVideoList.parse(
      File('assets/data/video_thuc_hanh.json').readAsStringSync(),
    );
    final ids = [for (final g in list.groups) for (final v in g.videos) v.id];
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[A-Za-z0-9_-]{11}$')));
    }
    for (final code in enabledClasses) {
      expect(
        list.groups.where((g) => g.classes.contains(code)),
        isNotEmpty,
        reason: 'hạng $code chưa có nhóm video',
      );
    }
    expect(list.forClass('A1').map((g) => g.title), ['Xe máy (A1, A)']);
  });
}
