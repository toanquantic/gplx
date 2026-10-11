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

  testWidgets('ôn câu điểm liệt: chọn đáp án thì hiện đúng sai và lưu tiến độ',
      (tester) async {
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

  testWidgets('thi thử: vào đề, nộp bài, xem kết quả', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Thi thử'));
    await tester.pumpAndSettle();
    expect(find.text('25 câu'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu thi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Câu 1/25'), findsOneWidget);

    await tester.tap(find.text('Nộp bài'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(FilledButton, 'Nộp bài'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('KHÔNG ĐẠT'), findsOneWidget);
    expect(find.textContaining('0/25 câu đúng'), findsOneWidget);
  });
}
