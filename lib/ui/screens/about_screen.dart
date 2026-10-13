import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;

import '../../monetization/paywall.dart';
import '../app_scope.dart';
import '../theme.dart';

/// Nguồn dữ liệu, ghi công và lưu ý: app không phải sản phẩm chính thức.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = context.colors;

    Widget section(String title, List<Widget> body) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        ...body,
      ],
    );
    Text para(String text) => Text(text, style: const TextStyle(fontSize: 13.5, height: 1.55));
    Widget divider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: c.track),
    );

    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('Giới thiệu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const ProStatusTile(),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                section('Nguồn câu hỏi', [
                  para(scope.bank.sourceNote),
                  const SizedBox(height: 6),
                  para('Áp dụng cho kỳ sát hạch từ 01/6/2025 đến hết 28/02/2027.'),
                ]),
                divider(),
                section('Lưu ý', [
                  para(
                    'Đây là ứng dụng ôn tập độc lập, không phải sản phẩm của Cục Cảnh sát '
                    'giao thông hay cơ quan nhà nước nào.',
                  ),
                ]),
                divider(),
                section('Lời giải thích', [
                  para(
                    'Lời giải thích do cộng đồng biên soạn (dự án mở On_THI_GPLX_B của '
                    'Thi Thanh Chuong, giấy phép MIT). App đã đọc lại cả 600 lời giải thích, '
                    'đối chiếu với đáp án và QCVN 41:2024, và viết lại những câu sai hoặc khó '
                    'hiểu. Phần này chưa được cơ quan chức năng kiểm duyệt, bạn chỉ nên dùng để '
                    'tham khảo.',
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () =>
                        showLicensePage(context: context, applicationName: 'Ôn thi GPLX'),
                    child: const Text('Xem giấy phép'),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: c.danger,
              side: BorderSide(color: c.danger.withValues(alpha: 0.4)),
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa toàn bộ tiến độ học'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa tiến độ?'),
                  content: const Text('Kết quả ôn tập, câu đánh dấu và lịch sử thi sẽ bị xóa.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (ok == true) await scope.progress.reset();
            },
          ),
        ],
      ),
    );
  }
}

/// Đăng ký giấy phép MIT của phần giải thích vào trang giấy phép của Flutter.
void registerDataLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/data/LICENSE-MIT-thichuong.txt');
    yield LicenseEntryWithLineBreaks(['On_THI_GPLX_B (lời giải thích)'], text);
    final font = await rootBundle.loadString('assets/fonts/OFL-BeVietnamPro.txt');
    yield LicenseEntryWithLineBreaks(['Be Vietnam Pro (phông chữ)'], font);
  });
}
