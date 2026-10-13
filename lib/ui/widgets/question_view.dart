import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../monetization/entitlement.dart';
import '../../monetization/paywall.dart';
import '../app_scope.dart';
import '../theme.dart';

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
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label ?? 'Câu ${question.id}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.accent),
              ),
            ),
            if (critical) ...[const SizedBox(width: 8), const CriticalChip()],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          question.text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
        ),
        if (question.image != null) ...[
          const SizedBox(height: 14),
          QuestionImage(path: question.image!),
        ],
        const SizedBox(height: 14),
        for (var i = 0; i < question.options.length; i++)
          _OptionTile(
            letter: _letters[i],
            text: question.options[i],
            state: _stateFor(i),
            onTap: onSelect == null ? null : () => onSelect!(i),
          ),
        if (reveal) ...[
          const SizedBox(height: 4),
          ExplanationCard(question: question),
          TipHint(questionId: question.id),
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
  const _OptionTile({required this.letter, required this.text, required this.state, this.onTap});

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (
      Color bg,
      Color border,
      double width,
      Color badge,
      Color onBadge,
      IconData? icon,
      String? hint,
    ) = switch (state) {
      _OptionState.normal => (c.surface, c.border, 1, c.track, c.text, null, null),
      _OptionState.selected => (c.accentSoft, c.accent, 1.5, c.accent, c.onAccent, null, 'Đã chọn'),
      _OptionState.correct => (
        c.accentSoft,
        c.accent,
        1.5,
        c.accent,
        c.onAccent,
        Icons.check_circle,
        'Đáp án đúng',
      ),
      _OptionState.wrong => (
        c.dangerSoft,
        c.danger,
        1.5,
        c.danger,
        c.onAccent,
        Icons.cancel,
        'Bạn chọn, sai',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        hint: hint,
        selected: state != _OptionState.normal,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: border, width: width),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: badge, shape: BoxShape.circle),
                    child: Text(
                      letter,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: onBadge),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(text, style: const TextStyle(fontSize: 15, height: 1.45)),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, color: border, size: 22),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Đáp án đúng và lời giải thích của câu.
class ExplanationCard extends StatelessWidget {
  const ExplanationCard({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Text(
                'Đáp án: ${_letters[question.correctIndex]}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.accent),
              ),
            ],
          ),
          if (question.explanation != null) ...[
            const SizedBox(height: 8),
            Text(question.explanation!, style: const TextStyle(fontSize: 14, height: 1.55)),
            const SizedBox(height: 8),
            Text(
              question.explanationReviewed
                  ? 'Giải thích đã được rà soát theo đáp án, chỉ mang tính tham khảo.'
                  : 'Giải thích do cộng đồng biên soạn, chỉ mang tính tham khảo.',
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mẹo nhớ nhanh của câu (bản Pro). Bản miễn phí chỉ thấy một dòng mời mở khóa.
class TipHint extends StatelessWidget {
  const TipHint({super.key, required this.questionId});

  final int questionId;

  @override
  Widget build(BuildContext context) {
    final group = AppScope.of(context).bank.tipFor(questionId);
    if (group == null) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ProGate(
        locked: AppCard(
          color: c.warnSoft,
          borderColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () => openPaywall(context),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 18, color: c.onWarnSoft),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Có mẹo nhớ nhanh cho câu này',
                  style: TextStyle(fontSize: 13.5, color: c.onWarnSoft),
                ),
              ),
              const ProBadge(),
            ],
          ),
        ),
        child: AppCard(
          color: c.warnSoft,
          borderColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 18, color: c.onWarnSoft),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mẹo nhớ: ${group.title}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.onWarnSoft,
                      ),
                    ),
                  ),
                ],
              ),
              for (final tip in group.tips) ...[
                const SizedBox(height: 6),
                Text(tip, style: TextStyle(fontSize: 13.5, height: 1.5, color: c.onWarnSoft)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Nhãn đỏ "Điểm liệt".
class CriticalChip extends StatelessWidget {
  const CriticalChip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: c.dangerSoft, borderRadius: BorderRadius.circular(999)),
      child: Text(
        'Điểm liệt',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.danger),
      ),
    );
  }
}

/// Hình của câu hỏi, nền trắng để hình sa hình dễ nhìn cả khi dùng giao diện tối.
class QuestionImage extends StatelessWidget {
  const QuestionImage({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: ColoredBox(
      color: Colors.white,
      child: Image.asset(path, fit: BoxFit.contain, width: double.infinity),
    ),
  );
}

/// Chữ cái của phương án thứ [i].
String optionLetter(int i) => _letters[i];
