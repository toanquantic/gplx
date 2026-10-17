import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/data/practical_content.dart';
import 'package:on_thi_gplx/data/question_bank.dart';
import 'package:on_thi_gplx/data/remote_content.dart';
import 'package:on_thi_gplx/ui/screens/videos_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('tải bản mới từ GitHub', _remoteContentTests);
  group('trình phát YouTube chuyển trang', _playerNavigationTests);

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

  test('video thực hành có mã YouTube hợp lệ, không trùng, hạng ô tô và xe máy đều có video', () {
    final list = PracticeVideoList.parse(
      File('assets/data/video_thuc_hanh.json').readAsStringSync(),
    );
    final ids = [
      for (final g in list.groups)
        for (final v in g.videos) v.id,
    ];
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[A-Za-z0-9_-]{11}$')));
    }
    // B1 là mô tô ba bánh, thi khác vòng số 8 của A1 nên chưa có video.
    for (final code in enabledClasses.where((c) => c != 'B1')) {
      expect(
        list.groups.where((g) => g.classes.contains(code)),
        isNotEmpty,
        reason: 'hạng $code chưa có nhóm video',
      );
    }
    expect(list.forClass('A1').map((g) => g.title), ['Xe máy (A1, A)']);
    expect(list.forClass('B1'), isEmpty);
  });
}

class _FakeSource implements ContentSource {
  _FakeSource(this.body);

  final String? body;

  @override
  Future<String?> fetch(String file) async => body;
}

class _FakeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(utf8.encode(File(key).readAsStringSync()));
}

Future<List<String>> _notes(ContentSource source) async => [
  await for (final list in DrivingSchoolList.load(_FakeBundle(), source)) list.note,
];

String _schools(String note) => jsonEncode({
  'ghi_chu': note,
  'trung_tam': [
    {'ten': 'A', 'tinh': 'Hà Nội', 'dia_chi': 'x', 'dien_thoai': '0912345678'},
  ],
});

void _remoteContentTests() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('không tải được thì dùng bản đóng gói sẵn', () async {
    final notes = await _notes(_FakeSource(null));
    expect(notes, hasLength(1));
    expect(notes.single, startsWith('Danh sách khởi đầu'));
  });

  test('tải được bản mới thì hiện ngay và lần sau dùng bản đã lưu', () async {
    expect((await _notes(_FakeSource(_schools('mới')))).last, 'mới');
    // Lần mở sau không có mạng: hiện bản đã tải lần trước.
    expect(await _notes(_FakeSource(null)), ['mới']);
  });

  test('bản tải về sai cấu trúc hoặc rỗng thì bỏ qua', () async {
    expect(await _notes(_FakeSource('{"ghi_chu": 1}')), hasLength(1));
    final empty = jsonEncode({'ghi_chu': 'rỗng', 'trung_tam': []});
    expect(await _notes(_FakeSource(empty)), hasLength(1));
    expect(
      () => PracticeVideoList.parse(
        jsonEncode({
          'ghi_chu': '',
          'nhom': [
            {
              'ten': 'x',
              'hang': ['B'],
              'video': [
                {'id': 'https://youtu.be/abc', 'tieu_de': 't'},
              ],
            },
          ],
        }),
      ),
      throwsFormatException,
    );
  });
}

void _playerNavigationTests() {
  Uri u(String s) => Uri.parse(s);
  PlayerNavigation main(String s) => decidePlayerNavigation(u(s), isMainFrame: true);

  test('trang của trình phát và iframe bên trong được tải bình thường', () {
    expect(main('https://www.youtube-nocookie.com'), isA<AllowNavigation>());
    expect(main('https://www.youtube-nocookie.com/embed/9kFINMCJ58w'), isA<AllowNavigation>());
    expect(main('about:blank'), isA<AllowNavigation>());
    expect(
      decidePlayerNavigation(u('https://googleads.g.doubleclick.net/x'), isMainFrame: false),
      isA<AllowNavigation>(),
    );
  });

  test('video liên quan phát tiếp ngay trong trình phát', () {
    final nav = main('https://www.youtube.com/watch?v=koPYGFOVGnY&feature=emb_rel_end');
    expect(nav, isA<PlayInPlayer>().having((n) => n.videoId, 'videoId', 'koPYGFOVGnY'));
  });

  test('logo, tiêu đề, kênh mở trong WebView của app chứ không rời app', () {
    for (final link in [
      'https://www.youtube.com/watch?v=koPYGFOVGnY&feature=emb_title',
      'https://www.youtube.com/watch?v=koPYGFOVGnY&feature=emb_logo',
      'https://www.youtube.com/@ThayTam',
      'https://m.youtube.com/',
      'https://accounts.google.com/ServiceLogin',
    ]) {
      expect(main(link), isA<OpenInApp>(), reason: link);
    }
  });
}
