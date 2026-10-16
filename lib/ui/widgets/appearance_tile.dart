import 'package:flutter/material.dart';

import '../../state/progress.dart';
import '../app_scope.dart';
import '../theme.dart';

/// Chọn giao diện sáng, tối hay theo cài đặt của máy.
class AppearanceTile extends StatelessWidget {
  const AppearanceTile({super.key});

  static const _labels = {
    Appearance.light: 'Sáng',
    Appearance.dark: 'Tối',
    Appearance.system: 'Theo máy',
  };

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.contrast, color: c.accent),
              const SizedBox(width: 12),
              const Text(
                'Giao diện',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<Appearance>(
            showSelectedIcon: false,
            segments: [
              for (final a in Appearance.values)
                ButtonSegment(value: a, label: Text(_labels[a]!)),
            ],
            selected: {progress.appearance},
            onSelectionChanged: (s) => progress.setAppearance(s.first),
          ),
        ],
      ),
    );
  }
}
