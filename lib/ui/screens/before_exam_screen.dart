import 'package:flutter/material.dart';

import '../../logic/review.dart';
import '../../models/models.dart';
import '../../monetization/paywall.dart';
import '../../state/progress.dart';
import '../app_scope.dart';
import '../theme.dart';
import 'exam_screen.dart';
import 'practice_screen.dart';

/// Chương "Báo hiệu đường bộ" trong bộ 600 câu.
const _signChapter = 5;

/// Số câu biển báo trong bước ôn biển báo hay nhầm.
const _signCount = 15;

/// Số đề ưu tiên câu yếu ở bước cuối.
const _finalExams = 2;

/// Một bước trong gói ôn trước ngày thi.
class _Step {
  const _Step({
    required this.title,
    required this.detail,
    required this.done,
    required this.onStart,
  });

  final String title;
  final String detail;
  final bool done;
  final VoidCallback? onStart;
}

/// Ôn ngày trước khi thi (bản Pro): gói ôn gọn 4 bước dồn vào câu dễ mất điểm.
class BeforeExamScreen extends StatelessWidget {
  const BeforeExamScreen({super.key});

  @override
  Widget build(BuildContext context) => ProFeatureScreen(
    title: 'Ngày trước khi thi',
    pitch:
        'Gói ôn gọn trong một buổi trước giờ thi: câu điểm liệt, câu từng sai, biển '
        'báo hay nhầm và hai đề thi thử ưu tiên câu yếu.',
    builder: (context) => const _BeforeExamBody(),
  );
}

class _BeforeExamBody extends StatelessWidget {
  const _BeforeExamBody();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final bank = scope.bank;
    final progress = scope.progress;
    final code = progress.classCode;
    final config = bank.examConfigs[code]!;
    final c = context.colors;

    void practice(int step, String title, List<Question> qs) => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          title: title,
          questions: qs,
          onAllAnswered: () => progress.markPlanStep(step),
        ),
      ),
    );

    final critical = bank.criticalFor(code);
    final all = bank.forClass(code);
    final wrong = all.where((q) => progress.isWrong(q.id)).toList();
    final signs = _confusingSigns(bank.forChapter(code, _signChapter), progress);
    // Chưa chọn ngày thi thì tính các đề làm từ hôm qua.
    final start = progress.planStart ?? addDays(progress.today, -1);
    final smartDone = progress.exams
        .where((e) => e.classCode == code && e.smart && !e.time.isBefore(start))
        .length;

    String minutes(int n) => 'Khoảng ${(n / 2).ceil()} phút';
    final steps = [
      _Step(
        title: '${critical.length} câu điểm liệt',
        detail: progress.isPlanStepDone(1) ? 'Xong' : minutes(critical.length),
        done: progress.isPlanStepDone(1),
        onStart: () => practice(1, 'Câu điểm liệt', critical),
      ),
      _Step(
        title: wrong.isEmpty ? 'Câu từng làm sai' : '${wrong.length} câu từng làm sai',
        detail: progress.isPlanStepDone(2)
            ? 'Xong'
            : wrong.isEmpty
            ? 'Không còn câu sai'
            : minutes(wrong.length),
        done: progress.isPlanStepDone(2) || wrong.isEmpty,
        onStart: wrong.isEmpty ? null : () => practice(2, 'Câu từng làm sai', wrong),
      ),
      _Step(
        title: '${signs.length} câu biển báo hay nhầm',
        detail: progress.isPlanStepDone(3) ? 'Xong' : minutes(signs.length),
        done: progress.isPlanStepDone(3),
        onStart: () => practice(3, 'Biển báo hay nhầm', signs),
      ),
      _Step(
        title: '$_finalExams đề thi thử cuối',
        detail: smartDone >= _finalExams
            ? 'Xong'
            : '$_finalExams × ${config.minutes} phút, ưu tiên câu yếu'
                  '${smartDone > 0 ? ' · đã làm $smartDone' : ''}',
        done: smartDone >= _finalExams,
        onStart: () => startExam(context, smart: true),
      ),
    ];
    final doneCount = steps.where((s) => s.done).length;
    final current = steps.indexWhere((s) => !s.done);
    final totalMinutes =
        ((critical.length + wrong.length + signs.length) / 2).ceil() + _finalExams * config.minutes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _DateCard(progress: progress, totalMinutes: totalMinutes),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: ThinBar(value: doneCount / steps.length, height: 8)),
            const SizedBox(width: 10),
            Text(
              '$doneCount/${steps.length} bước',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.muted),
            ),
          ],
        ),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _StepCard(number: i + 1, step: steps[i], current: i == current),
          ),
        if (doneCount == steps.length) ...[
          const SizedBox(height: 14),
          AppCard(
            color: c.accentSoft,
            borderColor: Colors.transparent,
            child: Text(
              'Bạn đã xong gói ôn. Nghỉ ngơi sớm và mang đủ giấy tờ khi đi thi nhé.',
              style: TextStyle(fontSize: 13.5, height: 1.5, color: c.text),
            ),
          ),
        ],
      ],
    );
  }

  /// Câu biển báo dễ nhầm nhất: sai nhiều lần trước, rồi câu đang sai, câu chưa làm.
  static List<Question> _confusingSigns(List<Question> pool, Progress progress) {
    int rank(Question q) {
      final lapses = progress.reviews[q.id]?.lapses ?? 0;
      final last = progress.lastResult[q.id];
      return lapses * 10 +
          (last == false
              ? 5
              : last == null
              ? 1
              : 0);
    }

    final sorted = List.of(pool)..sort((a, b) => rank(b).compareTo(rank(a)));
    return sorted.take(_signCount).toList()..sort((a, b) => a.id.compareTo(b.id));
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.progress, required this.totalMinutes});

  final Progress progress;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final date = progress.examDate;
    final days = date?.difference(progress.today).inHours;
    final left = days == null ? null : (days / 24).round();
    final title = switch (left) {
      null => 'Bạn thi ngày nào?',
      < 0 => 'Ngày thi đã qua',
      0 => 'Thi hôm nay',
      1 => 'Thi vào ngày mai',
      _ => 'Còn $left ngày nữa thi',
    };
    return AppCard(
      radius: 20,
      color: c.warnSoft,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
            child: date == null
                ? Icon(Icons.event_outlined, size: 32, color: c.onWarnSoft)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'THÁNG ${date.month}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.danger,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: const TextStyle(
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.onWarnSoft),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gói ôn gọn khoảng $totalMinutes phút, tập trung vào câu dễ mất điểm nhất.',
                  style: TextStyle(fontSize: 13, height: 1.45, color: c.onWarnSoft),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    foregroundColor: c.onWarnSoft,
                    textStyle: const TextStyle(
                      fontFamily: appFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onPressed: () => _pickDate(context),
                  child: Text(date == null ? 'Chọn ngày thi' : 'Đổi ngày thi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final today = progress.today;
    final picked = await showDatePicker(
      context: context,
      helpText: 'Chọn ngày thi',
      initialDate: progress.examDate != null && !progress.examDate!.isBefore(today)
          ? progress.examDate!
          : addDays(today, 1),
      firstDate: today,
      lastDate: addDays(today, 365),
    );
    if (picked != null) progress.setExamDate(picked);
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.step, required this.current});

  final int number;
  final _Step step;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      borderColor: current ? c.text : null,
      onTap: step.onStart,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.done
                  ? c.accent
                  : current
                  ? c.text
                  : c.track,
            ),
            child: step.done
                ? Icon(Icons.check_rounded, size: 18, color: c.onAccent)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: current ? c.surface : c.text,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: step.done ? c.muted : null,
                    decoration: step.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(step.detail, style: TextStyle(fontSize: 12.5, color: c.muted)),
              ],
            ),
          ),
          if (current && step.onStart != null)
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                  fontFamily: appFont,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: step.onStart,
              child: const Text('Làm tiếp'),
            ),
        ],
      ),
    );
  }
}
