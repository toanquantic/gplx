import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'entitlement.dart';

/// Mã sản phẩm mua một lần, khai báo giống nhau trên Google Play và App Store.
const proProductId = 'pro_lifetime';

/// Thông tin gói Pro lấy từ cửa hàng (giá đã định dạng theo tiền tệ của máy).
class ProOffer {
  const ProOffer({required this.title, required this.price, required this.details});

  final String title;
  final String price;
  final ProductDetails details;
}

/// Trạng thái giao dịch để màn mời mua hiển thị.
enum PurchaseState { idle, pending, success, canceled, error }

/// Quyền Pro có thể mua được: thêm thao tác mua, khôi phục và trạng thái giao dịch.
abstract class PurchasableEntitlement implements EntitlementService {
  ValueListenable<PurchaseState> get state;

  /// Lỗi gần nhất, đã viết sẵn bằng tiếng Việt.
  String? get lastError;

  Future<ProOffer?> loadOffer();

  Future<void> buy();

  Future<void> restore();
}

/// Mua gói Pro qua Google Play và App Store bằng `in_app_purchase`.
///
/// Quyền Pro lưu trong SharedPreferences nên app vẫn mở khóa khi không có mạng.
/// Trên Android, mỗi lần mở app có mạng sẽ hỏi lại cửa hàng để thu hồi quyền nếu
/// giao dịch đã được hoàn tiền. Trên iOS chỉ khôi phục khi người dùng bấm nút.
class StoreEntitlementService implements PurchasableEntitlement {
  StoreEntitlementService({
    InAppPurchase? store,
    Future<Set<String>?> Function()? queryOwned,
    bool? isAndroid,
  })  : _store = store ?? InAppPurchase.instance,
        _queryOwnedOverride = queryOwned,
        _isAndroid = isAndroid ?? defaultTargetPlatform == TargetPlatform.android;

  static const _key = 'pro_v1';

  final InAppPurchase _store;
  final Future<Set<String>?> Function()? _queryOwnedOverride;
  final bool _isAndroid;

  final _controller = StreamController<bool>.broadcast();
  final _state = ValueNotifier(PurchaseState.idle);
  StreamSubscription<List<PurchaseDetails>>? _sub;
  SharedPreferences? _prefs;
  bool _isPro = false;
  String? _lastError;
  ProOffer? _offer;

  @override
  ValueListenable<PurchaseState> get state => _state;

  @override
  String? get lastError => _lastError;

  @override
  bool get currentIsPro => _isPro;

  @override
  Stream<bool> get isPro async* {
    yield _isPro;
    yield* _controller.stream;
  }

  /// Đọc quyền đã lưu, rồi lắng nghe giao dịch. Gọi một lần lúc mở app.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _set(_prefs!.getBool(_key) ?? false, save: false);
    _sub = _store.purchaseStream.listen(_onPurchases, onError: (Object e) {
      _fail('Không kết nối được với cửa hàng ứng dụng.');
    });
    if (_isAndroid) await _refreshOwned();
  }

  Future<void> _refreshOwned() async {
    try {
      final owned = await (_queryOwnedOverride ?? _queryAndroidOwned)();
      // null nghĩa là không hỏi được (mất mạng): giữ nguyên quyền đã lưu.
      if (owned != null) _set(owned.contains(proProductId));
    } catch (_) {
      // Không có mạng hoặc cửa hàng lỗi: giữ nguyên quyền đã lưu.
    }
  }

  Future<Set<String>?> _queryAndroidOwned() async {
    if (!await _store.isAvailable()) return null;
    final android = _store.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await android.queryPastPurchases();
    if (response.error != null) return null;
    for (final p in response.pastPurchases) {
      if (p.pendingCompletePurchase) await _store.completePurchase(p);
    }
    return {
      for (final p in response.pastPurchases)
        if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored)
          p.productID,
    };
  }

  @override
  Future<ProOffer?> loadOffer() async {
    if (_offer != null) return _offer;
    if (!await _store.isAvailable()) return null;
    final response = await _store.queryProductDetails({proProductId});
    if (response.productDetails.isEmpty) return null;
    final d = response.productDetails.first;
    return _offer = ProOffer(title: d.title, price: d.price, details: d);
  }

  @override
  Future<void> buy() async {
    _lastError = null;
    final offer = await loadOffer();
    if (offer == null) {
      _fail('Chưa kết nối được cửa hàng. Kiểm tra mạng rồi thử lại.');
      return;
    }
    _state.value = PurchaseState.pending;
    try {
      await _store.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: offer.details));
    } catch (_) {
      _fail('Không mở được giao dịch. Thử lại sau.');
    }
  }

  @override
  Future<void> restore() async {
    _lastError = null;
    _state.value = PurchaseState.pending;
    if (_isAndroid) {
      await _refreshOwned();
      _state.value = _isPro ? PurchaseState.success : PurchaseState.idle;
      if (!_isPro) _lastError = 'Không tìm thấy giao dịch Pro nào của tài khoản này.';
      return;
    }
    try {
      await _store.restorePurchases();
      // Kết quả đến qua purchaseStream. Nếu không có giao dịch nào thì không có
      // sự kiện, nên trả trạng thái về idle sau khi lệnh chạy xong.
      if (!_isPro) _state.value = PurchaseState.idle;
    } catch (_) {
      _fail('Không khôi phục được giao dịch. Thử lại sau.');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != proProductId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _state.value = PurchaseState.pending;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _set(true);
          _state.value = PurchaseState.success;
        case PurchaseStatus.canceled:
          _state.value = PurchaseState.canceled;
        case PurchaseStatus.error:
          _fail('Giao dịch không thành công. Bạn chưa bị trừ tiền.');
      }
      // Google Play tự hoàn tiền nếu giao dịch không được xác nhận trong 3 ngày.
      if (p.pendingCompletePurchase) await _store.completePurchase(p);
    }
  }

  void _fail(String message) {
    _lastError = message;
    _state.value = PurchaseState.error;
  }

  void _set(bool value, {bool save = true}) {
    if (save) _prefs?.setBool(_key, value);
    if (value == _isPro) return;
    _isPro = value;
    _controller.add(value);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
    _state.dispose();
  }
}

/// Bật Pro khi phát triển: `flutter run --dart-define=FORCE_PRO=true`.
class ForcedProEntitlementService implements EntitlementService {
  const ForcedProEntitlementService();

  @override
  Stream<bool> get isPro => Stream.value(true);

  @override
  bool get currentIsPro => true;
}

/// Chọn cách mở khóa theo nền tảng: chỉ Android và iOS bán qua cửa hàng.
EntitlementService createEntitlementService() {
  if (const bool.fromEnvironment('FORCE_PRO')) return const ForcedProEntitlementService();
  if (kIsWeb) return const FreeEntitlementService();
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => _startStore(),
    _ => const FreeEntitlementService(),
  };
}

StoreEntitlementService _startStore() {
  final service = StoreEntitlementService();
  // Lỗi lúc khởi động (ví dụ cửa hàng chưa sẵn sàng) chỉ để lại bản miễn phí.
  unawaited(service.init().catchError((Object _) {}));
  return service;
}
