import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    // Nạp asset là I/O thật, phải chạy ngoài fake async của widget test.
    final data = (await tester.runAsync(loadAppData))!;
    await tester.pumpWidget(OnThiApp(loader: () => Future.value(data)));
    await tester.pumpAndSettle();
  }

  testWidgets('trang chủ hiện hạng và các mục ôn tập', (tester) async {
    await pumpApp(tester);
    expect(find.text('Ôn thi GPLX'), findsOneWidget);
    expect(find.text('Thi thử'), findsOneWidget);
    expect(find.textContaining('Đã làm 0/250'), findsOneWidget);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã làm 0/600'), findsOneWidget);
  });

  testWidgets('ôn câu điểm liệt: chọn đáp án thì hiện đúng sai và lưu tiến độ', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Câu điểm liệt'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1/20'), findsOneWidget);

    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Đáp án:'), findsOneWidget);

    await tester.pageBack();
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
    await tester.pageBack();
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
    await tester.tap(find.text('Tra cứu biển báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biển cấm'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'P.102');
    await tester.pumpAndSettle();
    expect(find.text('Cấm đi ngược chiều'), findsOneWidget);

    await tester.tap(find.text('Nguy hiểm'));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy biển nào.'), findsOneWidget);
  });
}
