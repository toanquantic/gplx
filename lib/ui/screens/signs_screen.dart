import 'package:flutter/material.dart';

import '../app_scope.dart';

const _signGroups = {
  'bien_cam': 'Biển báo cấm',
  'bien_hieu_lenh': 'Biển hiệu lệnh',
  'bien_nguy_hiem': 'Biển báo nguy hiểm và cảnh báo',
  'bien_chi_dan': 'Biển chỉ dẫn',
  'bien_phu': 'Biển phụ',
  'vach_ke': 'Vạch kẻ đường',
};

/// Danh mục biển báo theo QCVN 41:2024 (mã và tên; chưa có hình riêng).
class SignsScreen extends StatefulWidget {
  const SignsScreen({super.key});

  @override
  State<SignsScreen> createState() => _SignsScreenState();
}

class _SignsScreenState extends State<SignsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final signs = AppScope.of(context).bank.signs;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? signs
        : signs
            .where((s) =>
                s.code.toLowerCase().contains(q) || s.name.toLowerCase().contains(q))
            .toList();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Biển báo')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm theo mã hoặc tên, ví dụ P.102',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final s = filtered[i];
              final header = i == 0 || filtered[i - 1].group != s.group;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (header)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(_signGroups[s.group] ?? s.group,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ),
                ListTile(
                  dense: true,
                  leading: SizedBox(
                    width: 64,
                    child: Text(s.code, style: theme.textTheme.labelLarge),
                  ),
                  title: Text(s.name),
                  subtitle: s.meaning == null ? null : Text(s.meaning!),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
