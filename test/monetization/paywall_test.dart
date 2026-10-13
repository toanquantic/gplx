import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show PurchaseStatus;
import 'package:on_thi_gplx/monetization/entitlement.dart';
import 'package:on_thi_gplx/monetization/paywall.dart';
import 'package:on_thi_gplx/monetization/store_entitlement.dart';
import 'package:on_thi_gplx/state/progress.dart';
import 'package:on_thi_gplx/ui/app_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../exam_test.dart' show loadBank;
import 'store_entitlement_test.dart' show FakeStore, purchase;

void main() {
  final bank = loadBank();

  Future<void> pump(WidgetTester tester, EntitlementService service) async {
    final progress = (await tester.runAsync(Progress.load))!;
    // Cỡ màn điện thoại, đủ cao để thấy nút mua dưới danh sách quyền lợi.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      bank: bank,
      progress: progress,
      entitlement: service,
      child: const MaterialApp(home: PaywallScreen()),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('hiện giá từ cửa hàng, mua xong thì báo đã mở khóa', (tester) async {
    final store = FakeStore();
    final service = StoreEntitlementService(store: store, isAndroid: false);
    await tester.runAsync(service.init);
    await pump(tester, service);

    expect(find.text('Mở khóa Pro · 79.000 ₫'), findsOneWidget);
    expect(find.text('Khôi phục giao dịch'), findsOneWidget);

    await tester.tap(find.text('Mở khóa Pro · 79.000 ₫'));
    await tester.pump();
    expect(store.buyCalls, 1);

    // Dịch vụ khởi tạo ngoài fake-async nên giao dịch cũng phải chạy ở đó.
    await tester.runAsync(() async {
      store.purchases.add([purchase(PurchaseStatus.purchased)]);
      await pumpEventQueue();
    });
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã mở khóa Pro'), findsOneWidget);
  });

  testWidgets('web và desktop chỉ hiện lời giải thích, không có nút mua', (tester) async {
    await pump(tester, const FreeEntitlementService());
    expect(find.text('Bản Pro mua được trong app trên Android và iOS.'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
