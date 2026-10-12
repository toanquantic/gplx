import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/question_bank.dart';
import 'monetization/entitlement.dart';
import 'monetization/store_entitlement.dart';
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
  const OnThiApp({super.key, this.loader = loadAppData, this.entitlement});

  final Future<AppData> Function() loader;

  /// Mặc định chọn theo nền tảng; test truyền bản giả vào đây.
  final EntitlementService? entitlement;

  @override
  State<OnThiApp> createState() => _OnThiAppState();
}

class _OnThiAppState extends State<OnThiApp> {
  late final Future<AppData> _loading = widget.loader();
  late final EntitlementService _entitlement = widget.entitlement ?? createEntitlementService();

  @override
  Widget build(BuildContext context) {
    Widget app(Widget home) => MaterialApp(
      title: 'Ôn thi GPLX',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
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
          child: app(const HomeScreen()),
        );
      },
    );
  }
}
