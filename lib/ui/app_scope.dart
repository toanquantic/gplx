import 'package:flutter/widgets.dart';

import '../data/question_bank.dart';
import '../monetization/entitlement.dart';
import '../state/progress.dart';

/// Cung cấp bộ câu hỏi và tiến độ học cho toàn bộ cây widget.
class AppScope extends InheritedNotifier<Progress> {
  const AppScope({
    super.key,
    required this.bank,
    required Progress progress,
    this.entitlement = const FreeEntitlementService(),
    required super.child,
  }) : super(notifier: progress);

  final QuestionBank bank;
  final EntitlementService entitlement;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  /// Đọc mà không đăng ký theo dõi, dùng trong callback ngoài `build`.
  static AppScope read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;

  Progress get progress => notifier!;
}
