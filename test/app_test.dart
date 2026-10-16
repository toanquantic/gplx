import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/data/remote_content.dart';
import 'package:on_thi_gplx/main.dart';
import 'package:on_thi_gplx/notifications/reminders.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Đã chọn hạng A1 từ lần trước, để vào thẳng trang chủ.
  setUp(() => SharedPreferences.setMockInitialValues({'tien_do_v1': '{"hang":"A1"}'}));

  /// [fresh] dựng lại app từ đầu, như đóng rồi mở lại (giữ dữ liệu đã lưu).
  Future<void> pumpApp(WidgetTester tester, {bool fresh = false}) async {
    if (fresh) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    // Nạp asset là I/O thật, phải chạy ngoài fake async của widget test.
    final data = (await tester.runAsync(loadAppData))!;
    await tester.pumpWidget(
      OnThiApp(
        loader: () => Future.value(data),
        reminders: const NoReminderScheduler(),
        content: const NoRemoteContent(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Bấm "Đổi hạng" trên thẻ hạng rồi chọn [code] trong danh sách.
  Future<void> pickClass(WidgetTester tester, String code) async {
    await tester.tap(find.text('Đổi hạng'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn hạng bằng'), findsOneWidget);
    final inSheet = find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.text(code),
    );
    await tester.scrollUntilVisible(inSheet, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(inSheet);
    await tester.pumpAndSettle();
  }

  testWidgets('trang chủ hiện hạng và các mục ôn tập', (tester) async {
    await pumpApp(tester);
    expect(find.text('Ôn thi GPLX'), findsOneWidget);
    expect(find.text('Hạng A1'), findsOneWidget);
    expect(find.text('Thi thử'), findsOneWidget);
    expect(find.textContaining('Đã làm 0/250'), findsOneWidget);

    await pickClass(tester, 'B');
    await tester.tap(find.text('Ghi nhớ'));
    await tester.pumpAndSettle();
    expect(find.text('Hạng B'), findsOneWidget);
    expect(find.textContaining('Đã làm 0/600'), findsOneWidget);

    await pickClass(tester, 'C1');
    await tester.tap(find.text('Ghi nhớ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('35 câu · 22 phút'), findsOneWidget);
    expect(find.textContaining('Ôn lại hôm nay'), findsOneWidget);
  });

  testWidgets('chọn hạng khác trong danh sách: D và B1', (tester) async {
    await pumpApp(tester);
    await pickClass(tester, 'D');
    await tester.tap(find.text('Ghi nhớ'));
    await tester.pumpAndSettle();
    expect(find.text('Hạng D'), findsOneWidget);
    expect(find.textContaining('Đã làm 0/600'), findsOneWidget);
    expect(find.textContaining('45 câu · 26 phút'), findsOneWidget);

    await pickClass(tester, 'B1');
    await tester.tap(find.text('Ghi nhớ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã làm 0/300'), findsOneWidget);
  });

  testWidgets('lần đầu mở app phải chọn hạng, lần sau vào thẳng hạng đó', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);
    expect(find.text('Bạn ôn thi hạng nào?'), findsOneWidget);
    // Không đóng được khi chưa chọn.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Bạn ôn thi hạng nào?'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('B')));
    await tester.pumpAndSettle();
    expect(find.text('Bạn ôn thi hạng nào?'), findsNothing);
    expect(find.textContaining('Đã làm 0/600'), findsOneWidget);

    // Mở lại app: không hỏi nữa, vào thẳng hạng B.
    await pumpApp(tester, fresh: true);
    expect(find.text('Bạn ôn thi hạng nào?'), findsNothing);
    expect(find.textContaining('Đã làm 0/600'), findsOneWidget);
  });

  testWidgets('đổi hạng qua link Đổi hạng: chỉ lần này hoặc ghi nhớ', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Đổi hạng'));
    await tester.pumpAndSettle();
    expect(find.text('Mặc định khi mở app'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await pickClass(tester, 'B');
    expect(find.text('Ghi nhớ hạng B?'), findsOneWidget);
    await tester.tap(find.text('Chỉ lần này'));
    await tester.pumpAndSettle();
    expect(find.text('Đang ôn thử'), findsOneWidget);
    expect(find.textContaining('Đã làm 0/600'), findsOneWidget);
    expect(find.textContaining('Mở app lần sau sẽ vào hạng A1'), findsOneWidget);

    // Mở lại app: vẫn là hạng A1.
    await pumpApp(tester, fresh: true);
    expect(find.textContaining('Đã làm 0/250'), findsOneWidget);

    await pickClass(tester, 'C');
    await tester.tap(find.text('Ghi nhớ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mở app lần sau'), findsNothing);

    await pumpApp(tester, fresh: true);
    expect(find.textContaining('Tiến độ hạng C'), findsOneWidget);
  });

  testWidgets('ôn câu điểm liệt: chọn đáp án thì hiện đúng sai và lưu tiến độ', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Câu điểm liệt'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1/20'), findsOneWidget);

    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Đáp án:'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã làm 1/250'), findsOneWidget);
  });

  testWidgets('thi thử: vào đề, nộp bài, xem kết quả, xem lại và mở lại từ lịch sử', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Thi thử'));
    await tester.pumpAndSettle();
    expect(find.text('câu hỏi'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu thi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Câu 1/25'), findsOneWidget);

    // Trả lời câu 1 rồi nộp bài.
    await tester.tap(find.text('A').last);
    await tester.pump();
    await tester.tap(find.text('Nộp bài'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Bạn còn 24 câu chưa trả lời.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Nộp bài').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Không đạt'), findsOneWidget);
    expect(find.text('Theo nhóm câu'), findsOneWidget);
    expect(find.text('Câu điểm liệt'), findsWidgets);
    expect(find.text('Bỏ trống'), findsOneWidget);

    await tester.tap(find.textContaining('câu sai'));
    await tester.pumpAndSettle();
    expect(find.text('Xem lại bài thi'), findsOneWidget);
    expect(find.text('Tất cả 25'), findsOneWidget);

    // Về trang thi thử: lịch sử có bài vừa làm, mở lại được kết quả.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Về trang chủ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thi thử'));
    await tester.pumpAndSettle();
    expect(find.text('Lịch sử thi'), findsOneWidget);
    await tester.tap(find.textContaining('/25 đúng'));
    await tester.pumpAndSettle();
    expect(find.text('Không đạt'), findsOneWidget);
    expect(find.text('Thi đề mới'), findsNothing);
  });

  testWidgets('danh sách câu lọc được câu chưa làm và nhảy tới câu đã chọn', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Câu điểm liệt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Danh sách câu'));
    await tester.pumpAndSettle();
    expect(find.text('Đã làm 1/20'), findsOneWidget);
    await tester.tap(find.text('Câu chưa làm'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Câu 1,')), findsNothing);
    await tester.tap(find.bySemanticsLabel('Câu 5, chưa làm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5/20'), findsOneWidget);
  });

  testWidgets('tra biển báo theo nhóm và từ khóa', (tester) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(
      find.text('Tra cứu biển báo'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Tra cứu biển báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tra cứu biển báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biển cấm'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'P.102');
    await tester.pumpAndSettle();
    expect(find.text('Cấm đi ngược chiều'), findsOneWidget);
    // Mỗi biển hiện hình riêng cắt từ QCVN 41:2024, không phải hình chung của nhóm.
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/data/signs/p_102.webp');

    // Chạm vào hình biển mở màn xem phóng to được.
    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);

    await tester.tap(find.text('Nguy hiểm'));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy biển nào.'), findsOneWidget);
  });

  testWidgets('trang chủ mở được danh sách trung tâm dạy lái', (tester) async {
    await pumpApp(tester);
    final tile = find.text('Trung tâm dạy lái');
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Video thực hành'), findsOneWidget);
    await tester.tap(tile);
    // Đọc file JSON là I/O thật, chạy ngoài fake async rồi mới dựng lại khung hình.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('Trung tâm dạy lái xe'), findsOneWidget);
    expect(find.text('Hà Nội'), findsOneWidget);
    await tester.tap(find.text('TP. Hồ Chí Minh'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hiệp Phát'), findsOneWidget);
    expect(find.textContaining('Lạc Hồng'), findsNothing);
  });

  testWidgets('mặc định giao diện sáng, đổi sang tối và giữ khi mở lại', (tester) async {
    // Máy bật chế độ tối nhưng app vẫn sáng cho tới khi người dùng chọn khác.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    Brightness brightness() => Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
    expect(brightness(), Brightness.light);

    await tester.scrollUntilVisible(
      find.text('Theo máy'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    await pumpApp(tester, fresh: true);
    expect(brightness(), Brightness.dark);
  });
}
