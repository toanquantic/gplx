import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/question_bank.dart';
import 'monetization/entitlement.dart';
import 'monetization/store_entitlement.dart';
import 'notifications/reminder_sync.dart';
import 'notifications/reminders.dart';
import 'state/progress.dart';
import 'ui/app_scope.dart';
import 'ui/screens/about_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerDataLicenses();
  runApp(const OnThiApp());
}

typedef AppData = (QuestionBank, Progress);

Future<AppData> loadAppData() =>
    Future.wait([QuestionBank.load(), Progress.load()])
        .then((r) => (r[0] as QuestionBank, r[1] as Progress));

class OnThiApp extends StatefulWidget {
  const OnThiApp({super.key, this.loader = loadAppData, this.entitlement, this.reminders});

  final Future<AppData> Function() loader;

  /// Mặc định chọn theo nền tảng; test truyền bản giả vào đây.
  final EntitlementService? entitlement;

  /// Mặc định chọn theo nền tảng (chỉ Android, iOS có thông báo).
  final ReminderScheduler? reminders;

  @override
  State<OnThiApp> createState() => _OnThiAppState();
}

class _OnThiAppState extends State<OnThiApp> {
  late final Future<AppData> _loading = widget.loader();
  late final EntitlementService _entitlement = widget.entitlement ?? createEntitlementService();
  late final ReminderScheduler _reminders = widget.reminders ?? createReminderScheduler();
  ReminderSync? _sync;

  @override
  void initState() {
    super.initState();
    _loading.then((data) {
      if (mounted) _sync = ReminderSync(data.$1, data.$2, _entitlement, _reminders);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sync?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget app(Widget home, [Appearance appearance = Appearance.light]) => MaterialApp(
      title: 'Ôn thi GPLX',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      // Mặc định luôn sáng (kể cả khi máy bật chế độ tối), người dùng đổi được trong app.
      themeMode: switch (appearance) {
        Appearance.light => ThemeMode.light,
        Appearance.dark => ThemeMode.dark,
        Appearance.system => ThemeMode.system,
      },
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );
    return FutureBuilder(
      future: _loading,
      builder: (context, snap) {
        if (snap.hasError) {
          return app(Scaffold(body: Center(child: Text('Không nạp được dữ liệu: ${snap.error}'))));
        }
        if (!snap.hasData) {
          return app(const Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        final (bank, progress) = snap.data!;
        // AppScope bọc ngoài MaterialApp để mọi route đều đọc được dữ liệu.
        return AppScope(
          bank: bank,
          progress: progress,
          entitlement: _entitlement,
          reminders: _reminders,
          child: ListenableBuilder(
            listenable: progress,
            builder: (_, _) => app(const HomeScreen(), progress.appearance),
          ),
        );
      },
    );
  }
}
