import 'package:flutter/material.dart';

import '../../models/models.dart';

const _letters = ['A', 'B', 'C', 'D', 'E'];

/// Hiển thị một câu hỏi và các phương án.
///
/// Khi [reveal] bật, tô màu đáp án đúng/sai và hiện lời giải thích.
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.critical,
    this.selected,
    this.reveal = false,
    this.onSelect,
    this.label,
  });

  final Question question;
  final bool critical;
  final int? selected;
  final bool reveal;
  final ValueChanged<int>? onSelect;

  /// Nhãn đầu câu, mặc định là "Câu {id}".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(children: [
          Text(label ?? 'Câu ${question.id}',
              style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
          if (critical) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Điểm liệt',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.onErrorContainer)),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        Text(question.text, style: theme.textTheme.titleMedium),
        if (question.image != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: Colors.white,
              child: Image.asset(question.image!, fit: BoxFit.contain),
            ),
          ),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < question.options.length; i++)
          _OptionTile(
            letter: _letters[i],
            text: question.options[i],
            state: _stateFor(i),
            onTap: onSelect == null ? null : () => onSelect!(i),
          ),
        if (reveal) ...[
          const SizedBox(height: 8),
          _Explanation(question: question),
        ],
      ],
    );
  }

  _OptionState _stateFor(int i) {
    if (!reveal) return i == selected ? _OptionState.selected : _OptionState.normal;
    if (i == question.correctIndex) return _OptionState.correct;
    if (i == selected) return _OptionState.wrong;
    return _OptionState.normal;
  }
}

enum _OptionState { normal, selected, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color border, IconData? icon) = switch (state) {
      _OptionState.normal => (scheme.surfaceContainerLow, scheme.outlineVariant, null),
      _OptionState.selected => (scheme.primaryContainer, scheme.primary, null),
      _OptionState.correct => (
          Colors.green.withValues(alpha: 0.15),
          Colors.green,
          Icons.check_circle
        ),
      _OptionState.wrong => (scheme.errorContainer, scheme.error, Icons.cancel),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: border,
                foregroundColor: scheme.surface,
                child: Text(letter, style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: border),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Đáp án: ${_letters[question.correctIndex]}',
              style: theme.textTheme.titleSmall),
          if (question.explanation != null) ...[
            const SizedBox(height: 6),
            Text(question.explanation!),
            const SizedBox(height: 6),
            Text('Giải thích do cộng đồng biên soạn, chỉ mang tính tham khảo.',
                style: theme.textTheme.bodySmall),
          ],
        ]),
      ),
    );
  }
}
