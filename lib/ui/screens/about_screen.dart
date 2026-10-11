import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;

import '../../monetization/paywall.dart';
import '../app_scope.dart';

/// Nguồn dữ liệu, ghi công và lưu ý: app không phải sản phẩm chính thức.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const ProStatusTile(),
        const SizedBox(height: 16),
        Text('Nguồn câu hỏi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(scope.bank.sourceNote),
        const SizedBox(height: 4),
        const Text('Áp dụng cho kỳ sát hạch từ 01/6/2025 đến hết 28/02/2027.'),
        const SizedBox(height: 16),
        Text('Lưu ý', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
            'Đây là ứng dụng ôn tập độc lập, không phải sản phẩm của Cục Cảnh sát giao thông '
            'hay cơ quan nhà nước nào.'),
        const SizedBox(height: 16),
        Text('Lời giải thích', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
            'Lời giải thích lấy từ dự án On_THI_GPLX_B của Thi Thanh Chuong, '
            'phát hành theo giấy phép MIT, chưa được kiểm duyệt.'),
        TextButton(
          onPressed: () => showLicensePage(context: context, applicationName: 'Ôn thi GPLX'),
          child: const Text('Xem giấy phép'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Xóa toàn bộ tiến độ học'),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Xóa tiến độ?'),
                content: const Text('Kết quả ôn tập, câu đánh dấu và lịch sử thi sẽ bị xóa.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
                ],
              ),
            );
            if (ok == true) await scope.progress.reset();
          },
        ),
      ]),
    );
  }
}

/// Đăng ký giấy phép MIT của phần giải thích vào trang giấy phép của Flutter.
void registerDataLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/data/LICENSE-MIT-thichuong.txt');
    yield LicenseEntryWithLineBreaks(['On_THI_GPLX_B (lời giải thích)'], text);
  });
}
