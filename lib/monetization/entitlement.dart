import 'dart:async';

import 'package:flutter/widgets.dart';

import '../ui/app_scope.dart';

/// Quyền dùng bản Pro (mở khóa một lần, mã sản phẩm `pro_lifetime`).
///
/// Mọi tính năng ôn tập và thi thử hiện đều miễn phí. Lớp này là điểm nối để
/// sau này gắn `in_app_purchase` (Android, iOS) mà không phải sửa giao diện.
abstract class EntitlementService {
  /// Phát giá trị hiện tại ngay khi lắng nghe, sau đó phát mỗi khi thay đổi.
  Stream<bool> get isPro;

  bool get currentIsPro;
}

/// Bản miễn phí: không bao giờ là Pro.
class FreeEntitlementService implements EntitlementService {
  const FreeEntitlementService();

  @override
  Stream<bool> get isPro => Stream.value(false);

  @override
  bool get currentIsPro => false;
}

/// Hiện [child] khi người dùng có Pro, ngược lại hiện [locked].
class ProGate extends StatelessWidget {
  const ProGate({super.key, required this.child, required this.locked});

  final Widget child;
  final Widget locked;

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).entitlement;
    return StreamBuilder<bool>(
      stream: service.isPro,
      initialData: service.currentIsPro,
      builder: (context, snap) => snap.data == true ? child : locked,
    );
  }
}
