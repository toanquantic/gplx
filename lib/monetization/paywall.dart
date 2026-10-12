import 'package:flutter/material.dart';

import '../ui/app_scope.dart';
import '../ui/theme.dart';
import 'store_entitlement.dart';

/// Những gì gói Pro mang lại, hiện trên màn mời mua.
const proBenefits = [
  'Lịch ôn lại câu sai, mỗi ngày nhắc đúng những câu sắp quên',
  'Đề thi thử ưu tiên câu yếu và câu điểm liệt từng sai',
  'Thống kê theo chương và dự đoán khả năng đỗ',
  'Chế độ ôn "ngày trước khi thi"',
  'Không quảng cáo',
];

/// Mở màn mời mua Pro.
Future<void> openPaywall(BuildContext context) =>
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PaywallScreen()));

/// Màn mời mua Pro: lợi ích, giá từ cửa hàng, nút mua và khôi phục giao dịch.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Future<ProOffer?>? _offer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = AppScope.of(context).entitlement;
    if (_offer == null && service is PurchasableEntitlement) _offer = service.loadOffer();
  }

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).entitlement;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bản Pro')),
      body: StreamBuilder<bool>(
        stream: service.isPro,
        initialData: service.currentIsPro,
        builder: (context, snap) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Học đúng câu mình yếu, biết khi nào đã sẵn sàng đi thi.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('Toàn bộ câu hỏi, giải thích và thi thử vẫn miễn phí.'),
            const SizedBox(height: 16),
            for (final b in proBenefits)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(b),
              ),
            const SizedBox(height: 16),
            if (snap.data == true)
              const _Unlocked()
            else if (service is PurchasableEntitlement)
              _BuyPanel(service: service, offer: _offer!)
            else
              const Text('Bản Pro mua được trong app trên Android và iOS.'),
          ],
        ),
      ),
    );
  }
}

class _Unlocked extends StatelessWidget {
  const _Unlocked();

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(Icons.verified, color: Theme.of(context).colorScheme.primary),
      title: const Text('Bạn đã mở khóa Pro'),
      subtitle: const Text('Cảm ơn bạn đã ủng hộ app.'),
    ),
  );
}

class _BuyPanel extends StatelessWidget {
  const _BuyPanel({required this.service, required this.offer});

  final PurchasableEntitlement service;
  final Future<ProOffer?> offer;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PurchaseState>(
      valueListenable: service.state,
      builder: (context, state, _) {
        final busy = state == PurchaseState.pending;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<ProOffer?>(
              future: offer,
              builder: (context, snap) {
                final o = snap.data;
                final label = switch (snap.connectionState) {
                  ConnectionState.done when o != null => 'Mở khóa Pro · ${o.price}',
                  ConnectionState.done => 'Mở khóa Pro',
                  _ => 'Đang tải giá…',
                };
                return FilledButton(
                  onPressed: busy || snap.connectionState != ConnectionState.done
                      ? null
                      : service.buy,
                  child: Text(label),
                );
              },
            ),
            const SizedBox(height: 4),
            const Text('Trả một lần, dùng mãi mãi cho mọi hạng bằng.', textAlign: TextAlign.center),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (state == PurchaseState.error && service.lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  service.lastError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: busy ? null : service.restore,
              child: const Text('Khôi phục giao dịch'),
            ),
          ],
        );
      },
    );
  }
}

/// Thẻ thay thế cho tính năng Pro khi chưa mở khóa, dùng làm `locked` của [ProGate].
class ProLockedCard extends StatelessWidget {
  const ProLockedCard({super.key, required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.lock_outline),
      title: Text(feature),
      subtitle: const Text('Có trong bản Pro'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openPaywall(context),
    ),
  );
}

/// Dòng "Bản Pro" trong màn Giới thiệu: trạng thái hiện tại và lối vào màn mời mua.
class ProStatusTile extends StatelessWidget {
  const ProStatusTile({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).entitlement;
    return StreamBuilder<bool>(
      stream: service.isPro,
      initialData: service.currentIsPro,
      builder: (context, snap) {
        final c = context.colors;
        final pro = snap.data == true;
        return AppCard(
          color: c.warnSoft,
          borderColor: Colors.transparent,
          padding: const EdgeInsets.all(14),
          onTap: () => openPaywall(context),
          child: Row(
            children: [
              IconBadge(
                icon: pro ? Icons.verified : Icons.star_outline_rounded,
                background: c.warnIcon,
                foreground: c.onWarnSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pro ? 'Đã mở khóa Pro' : 'Bản Pro',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.onWarnSoft,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pro
                          ? 'Xem quyền lợi hoặc khôi phục trên máy khác'
                          : 'Xem quyền lợi, mua hoặc khôi phục giao dịch',
                      style: TextStyle(fontSize: 12.5, color: c.onWarnSoft),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.onWarnSoft),
            ],
          ),
        );
      },
    );
  }
}
