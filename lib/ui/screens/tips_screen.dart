import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../monetization/paywall.dart';
import '../app_scope.dart';
import '../theme.dart';
import 'practice_screen.dart';

/// Mẹo nhớ nhanh (bản Pro): các quy tắc hay ra thi gom theo nhóm, kèm nút ôn
/// đúng những câu mà mẹo đó giúp trả lời.
class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key, this.initialCode});

  /// Mã nhóm mẹo cần mở sẵn, ví dụ khi đi từ một câu hỏi.
  final String? initialCode;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final groups = scope.bank.tipsForClass(scope.progress.classCode);
    final count = groups.fold(0, (a, g) => a + g.$2.length);
    return ProFeatureScreen(
      title: 'Mẹo nhớ nhanh',
      teaser: '${groups.length} nhóm mẹo cho $count câu của hạng ${scope.progress.classCode}',
      pitch:
          'Nhớ gọn các con số và thứ tự hay bị hỏi: tốc độ, khoảng cách, độ tuổi, '
          'xe ưu tiên, thứ tự qua giao lộ. Mỗi nhóm có nút ôn đúng các câu liên quan.',
      builder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          for (final (group, questions) in groups) ...[
            _TipCard(
              group: group,
              questions: questions,
              initiallyExpanded: group.code == initialCode,
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'Mẹo do app tự biên soạn từ đáp án bộ 600 câu, giúp nhớ nhanh, '
            'không thay cho văn bản luật.',
            style: TextStyle(fontSize: 12, color: context.colors.muted),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.group, required this.questions, required this.initiallyExpanded});

  final TipGroup group;
  final List<Question> questions;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Icon(Icons.tips_and_updates_outlined, color: c.accent),
          title: Text(
            group.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${questions.length} câu liên quan',
            style: TextStyle(fontSize: 12.5, color: c.muted),
          ),
          children: [
            for (final tip in group.tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 10),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                      ),
                    ),
                    Expanded(
                      child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.5)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Ôn ${questions.length} câu'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PracticeScreen(title: group.title, questions: questions),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
