import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:on_thi_gplx/monetization/store_entitlement.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cửa hàng giả: giữ luồng giao dịch và ghi lại các lệnh app gọi.
class FakeStore implements InAppPurchase {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];
  bool available = true;
  int buyCalls = 0;
  int restoreCalls = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async =>
      ProductDetailsResponse(productDetails: [
        ProductDetails(
            id: proProductId,
            title: 'Pro',
            description: '',
            price: '79.000 ₫',
            rawPrice: 79000,
            currencyCode: 'VND'),
      ], notFoundIDs: []);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCalls++;
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async => restoreCalls++;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.purchaseID ?? '');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PurchaseDetails purchase(PurchaseStatus status, {String id = 'gd1', bool pending = true}) =>
    PurchaseDetails(
      purchaseID: id,
      productID: proProductId,
      verificationData: PurchaseVerificationData(
          localVerificationData: '', serverVerificationData: '', source: 'test'),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = pending;

void main() {
  late FakeStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = FakeStore();
  });

  Future<StoreEntitlementService> make({
    bool android = false,
    Future<Set<String>?> Function()? owned,
  }) async {
    final s = StoreEntitlementService(store: store, isAndroid: android, queryOwned: owned);
    await s.init();
    return s;
  }

  test('mặc định là bản miễn phí', () async {
    final s = await make();
    expect(s.currentIsPro, isFalse);
    expect(await s.isPro.first, isFalse);
  });

  test('mua thành công thì mở khóa, lưu lại và xác nhận giao dịch', () async {
    final s = await make();
    await s.buy();
    expect(store.buyCalls, 1);
    expect(s.state.value, PurchaseState.pending);

    store.purchases.add([purchase(PurchaseStatus.purchased)]);
    await pumpEventQueue();

    expect(s.currentIsPro, isTrue);
    expect(s.state.value, PurchaseState.success);
    expect(store.completed, ['gd1']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('pro_v1'), isTrue);
  });

  test('isPro phát giá trị hiện tại rồi các thay đổi', () async {
    final s = await make();
    final seen = <bool>[];
    final sub = s.isPro.listen(seen.add);
    await pumpEventQueue();
    store.purchases.add([purchase(PurchaseStatus.purchased)]);
    await pumpEventQueue();
    expect(seen, [false, true]);
    await sub.cancel();
  });

  test('hủy hoặc lỗi thì không mở khóa', () async {
    final s = await make();
    store.purchases.add([purchase(PurchaseStatus.canceled, pending: false)]);
    await pumpEventQueue();
    expect(s.state.value, PurchaseState.canceled);

    store.purchases.add([purchase(PurchaseStatus.error)]);
    await pumpEventQueue();
    expect(s.state.value, PurchaseState.error);
    expect(s.lastError, isNotNull);
    expect(s.currentIsPro, isFalse);
    expect(store.completed, ['gd1']);
  });

  test('quyền đã lưu vẫn còn khi mở lại app không có mạng', () async {
    SharedPreferences.setMockInitialValues({'pro_v1': true});
    final s = await make(android: true, owned: () async => null);
    expect(s.currentIsPro, isTrue);
  });

  test('Android thu hồi quyền khi giao dịch đã hoàn tiền', () async {
    SharedPreferences.setMockInitialValues({'pro_v1': true});
    final s = await make(android: true, owned: () async => <String>{});
    expect(s.currentIsPro, isFalse);
  });

  test('Android khôi phục từ giao dịch cũ', () async {
    final s = await make(android: true, owned: () async => {proProductId});
    expect(s.currentIsPro, isTrue);
  });

  test('iOS khôi phục qua cửa hàng', () async {
    final s = await make();
    await s.restore();
    expect(store.restoreCalls, 1);
    store.purchases.add([purchase(PurchaseStatus.restored)]);
    await pumpEventQueue();
    expect(s.currentIsPro, isTrue);
  });

  test('không kết nối được cửa hàng thì báo lỗi', () async {
    store.available = false;
    final s = await make();
    await s.buy();
    expect(store.buyCalls, 0);
    expect(s.state.value, PurchaseState.error);
  });
}
