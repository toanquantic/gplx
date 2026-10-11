import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_thi_gplx/monetization/entitlement.dart';
import 'package:on_thi_gplx/state/progress.dart';
import 'package:on_thi_gplx/ui/app_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exam_test.dart' show loadBank;

class _ProService implements EntitlementService {
  @override
  Stream<bool> get isPro => Stream.value(true);

  @override
  bool get currentIsPro => true;
}

void main() {
  final bank = loadBank();

  Future<void> pump(WidgetTester tester, EntitlementService service) async {
    SharedPreferences.setMockInitialValues({});
    final progress = (await tester.runAsync(Progress.load))!;
    await tester.pumpWidget(AppScope(
      bank: bank,
      progress: progress,
      entitlement: service,
      child: const MaterialApp(
        home: ProGate(locked: Text('khoa'), child: Text('pro')),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('bản miễn phí hiện phần khóa', (tester) async {
    await pump(tester, const FreeEntitlementService());
    expect(find.text('khoa'), findsOneWidget);
    expect(find.text('pro'), findsNothing);
  });

  testWidgets('có Pro thì hiện nội dung', (tester) async {
    await pump(tester, _ProService());
    expect(find.text('pro'), findsOneWidget);
  });
}
