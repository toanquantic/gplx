import 'package:flutter/material.dart';

import '../ui/app_scope.dart';
import '../ui/theme.dart';
import 'entitlement.dart';
import 'store_entitlement.dart';

/// Những gì gói Pro mang lại, hiện trên màn mời mua: (tiêu đề, mô tả).
const proBenefits = [
  ('Lịch ôn lại câu sai', 'Mỗi ngày nhắc đúng những câu sắp quên.'),
  ('Đề ưu tiên câu yếu', 'Thi thử dồn vào câu yếu và câu điểm liệt từng sai.'),
  ('Thống kê và dự đoán đỗ', 'Biết chương nào còn yếu, khả năng đỗ bao nhiêu.'),
  ('Chế độ ngày trước khi thi', 'Gói ôn gọn trong một buổi trước giờ thi.'),
  ('Mẹo nhớ nhanh', 'Nhớ gọn tốc độ, khoảng cách, xe ưu tiên, thứ tự qua giao lộ.'),
  ('Không quảng cáo', 'Học liền mạch, không bị gián đoạn.'),
];

/// Mở màn mời mua Pro.
Future<void> openPaywall(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const PaywallScreen()),
);

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
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.proBackground,
      appBar: AppBar(
        backgroundColor: c.proBackground,
        leading: IconButton(
          tooltip: 'Đóng',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: StreamBuilder<bool>(
        stream: service.isPro,
        initialData: service.currentIsPro,
        builder: (context, snap) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.onWarnSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ÔN THI GPLX PRO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: c.proBackground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Học đúng câu mình yếu, biết khi nào đã sẵn sàng đi thi.',
              style: TextStyle(fontSize: 26, height: 1.25, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Toàn bộ câu hỏi, giải thích và thi thử vẫn miễn phí.',
              style: TextStyle(fontSize: 14, height: 1.5, color: c.muted),
            ),
            const SizedBox(height: 14),
            for (final (title, body) in proBenefits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconBadge(
                      icon: Icons.check_rounded,
                      background: c.warnIcon,
                      foreground: c.onWarnSoft,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(body, style: TextStyle(fontSize: 13, height: 1.45, color: c.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (snap.data == true)
              const _Unlocked()
            else if (service is PurchasableEntitlement)
              _BuyPanel(service: service, offer: _offer!)
            else
              Text(
                'Bản Pro mua được trong app trên Android và iOS.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: c.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _Unlocked extends StatelessWidget {
  const _Unlocked();

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Icon(Icons.verified, color: context.colors.accent),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bạn đã mở khóa Pro', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Cảm ơn bạn đã ủng hộ app.'),
            ],
          ),
        ),
      ],
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
                final c = context.colors;
                return FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: c.text,
                    foregroundColor: c.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: busy || snap.connectionState != ConnectionState.done
                      ? null
                      : service.buy,
                  child: Text(label),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Trả một lần, dùng mãi mãi cho mọi hạng bằng.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.colors.muted),
            ),
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
              style: TextButton.styleFrom(foregroundColor: context.colors.onWarnSoft),
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
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      color: c.warnSoft,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => openPaywall(context),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: c.onWarnSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature,
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.onWarnSoft),
                ),
                Text('Có trong bản Pro', style: TextStyle(fontSize: 12.5, color: c.onWarnSoft)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: c.onWarnSoft),
        ],
      ),
    );
  }
}

/// Nhãn "PRO" nhỏ cạnh tiêu đề.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.warnSoft, borderRadius: BorderRadius.circular(6)),
      child: Text(
        'PRO',
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.onWarnSoft),
      ),
    );
  }
}

/// Khung chung cho màn tính năng Pro: thanh tiêu đề có nhãn PRO, nội dung thật
/// khi đã mở khóa, ngược lại là phần giới thiệu và nút mở màn mời mua.
class ProFeatureScreen extends StatelessWidget {
  const ProFeatureScreen({
    super.key,
    required this.title,
    required this.pitch,
    required this.builder,
    this.teaser,
  });

  final String title;

  /// Một câu nói tính năng giúp gì, hiện khi chưa mở khóa.
  final String pitch;

  /// Dòng số liệu thật của người dùng để họ thấy tính năng đáng giá thế nào.
  final String? teaser;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            const ProBadge(),
          ],
        ),
      ),
      body: ProGate(
        locked: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            AppCard(
              radius: 20,
              color: c.warnSoft,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconBadge(
                      icon: Icons.lock_outline,
                      background: c.warnIcon,
                      foreground: c.onWarnSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (teaser != null) ...[
                    Text(
                      teaser!,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.onWarnSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(pitch, style: TextStyle(fontSize: 14, height: 1.5, color: c.onWarnSoft)),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.text,
                      foregroundColor: c.surface,
                    ),
                    onPressed: () => openPaywall(context),
                    child: const Text('Xem bản Pro'),
                  ),
                ],
              ),
            ),
          ],
        ),
        child: Builder(builder: builder),
      ),
    );
  }
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
