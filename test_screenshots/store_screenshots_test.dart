// Chụp ảnh màn hình cho trang store, đúng kích thước Google Play và App Store.
// Không nằm trong test/ nên `flutter test` thường không chạy file này.
//
//   flutter test --update-goldens test_screenshots/store_screenshots_test.dart
//
// Ảnh ra ở store/screenshots/<thiết bị>/.

// Thư mục này không phải test/ nên analyzer không coi đây là file test.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/data/remote_content.dart';
import 'package:on_thi_gplx/main.dart';
import 'package:on_thi_gplx/monetization/store_entitlement.dart';
import 'package:on_thi_gplx/notifications/reminders.dart';
import 'package:on_thi_gplx/ui/screens/home_screen.dart';
import 'package:on_thi_gplx/ui/screens/practice_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kích thước điểm ảnh store yêu cầu và tỉ lệ điểm ảnh để bố cục giống máy thật.
const devices = {
  // Google Play: cạnh dài không quá 2 lần cạnh ngắn.
  'android': (Size(1080, 2160), 2.625),
  // App Store iPhone 6,9 inch.
  'iphone': (Size(1320, 2868), 3.0),
};

Future<void> loadFonts() async {
  final family = FontLoader('BeVietnamPro');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    family.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$w.ttf'));
  }
  await family.load();
  // flutter_tester nằm ở bin/cache/artifacts/engine/<nền tảng>/, phông icon ở bin/cache/artifacts/material_fonts/.
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
  final icons = File('${artifacts.path}/material_fonts/MaterialIcons-Regular.otf');
  await (FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then(ByteData.sublistView)))
      .load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadFonts();
  });

  for (final MapEntry(key: device, value: (size, ratio)) in devices.entries) {
    testWidgets('ảnh store $device', (tester) async {
      debugDisableShadows = false;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'tien_do_v1': '{"hang":"B"}'});

      final (bank, progress) = (await tester.runAsync(loadAppData))!;
      // Tiến độ mẫu: đã làm 230 câu đầu của hạng B, sai khoảng 1/8.
      final done = bank.forClass('B').take(230).toList();
      progress.recordAnswers({for (final (i, q) in done.indexed) q.id: i % 8 != 3});

      await tester.pumpWidget(
        OnThiApp(
          loader: () => Future.value((bank, progress)),
          entitlement: const ForcedProEntitlementService(),
          reminders: const NoReminderScheduler(),
          content: const NoRemoteContent(),
        ),
      );
      await settle(tester);

      Future<void> shot(String name) async {
        await settle(tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../store/screenshots/$device/$name.png'),
        );
      }

      Future<void> back() async {
        await tester.tap(find.byType(BackButton).last);
        await settle(tester);
      }

      final homeList = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
      await shot('01_trang_chu');

      // Câu có hình, đã chọn đúng đáp án để hiện lời giải thích.
      final q = bank.forClass('B').firstWhere(
        (q) =>
            q.image != null &&
            q.explanation != null &&
            q.options.length == 4 &&
            q.options.join().length < 160,
      );
      Navigator.of(tester.element(find.byType(HomeScreen))).push(
        MaterialPageRoute<void>(builder: (_) => PracticeScreen(title: 'Ôn theo chương', questions: [q])),
      );
      await settle(tester);
      final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last;
      final answer = find.text(String.fromCharCode(65 + q.correctIndex));
      await tester.scrollUntilVisible(answer, 200, scrollable: list);
      await tester.tap(answer.last);
      await shot('02_on_tap');
      await back();

      await tester.tap(find.text('Thi thử'));
      await settle(tester);
      await tester.tap(find.text('Bắt đầu thi'));
      await settle(tester);
      final examList = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last;
      await tester.scrollUntilVisible(find.text('A'), 200, scrollable: examList);
      await tester.tap(find.text('A').last);
      await tester.drag(examList, const Offset(0, 3000));
      await shot('03_thi_thu');
      // Về thẳng trang chủ, bỏ qua hộp hỏi thoát đề đang làm.
      Navigator.of(tester.element(find.byType(HomeScreen, skipOffstage: false))).popUntil((r) => r.isFirst);
      await settle(tester);

      await tester.scrollUntilVisible(find.text('Tra cứu biển báo'), 300, scrollable: homeList);
      await tester.tap(find.text('Tra cứu biển báo'));
      await shot('04_bien_bao');
      await back();

      await tester.scrollUntilVisible(find.text('Thống kê'), -300, scrollable: homeList);
      await tester.tap(find.text('Thống kê'));
      await shot('05_thong_ke');
      await back();
      // Phải trả lại trước khi test kết thúc, flutter_test kiểm tra biến này.
      debugDisableShadows = true;
    });
  }
}

/// Chờ hình asset giải mã xong (I/O thật, ngoài fake async) rồi dựng lại khung hình.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = (element.widget as Image).image;
      await precacheImage(image, element);
    }
  });
  await tester.pumpAndSettle();
}
