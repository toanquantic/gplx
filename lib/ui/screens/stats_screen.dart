import 'dart:math';

import 'package:flutter/material.dart';

import '../../logic/insights.dart';
import '../../models/models.dart';
import '../../monetization/paywall.dart';
import '../../state/progress.dart';
import '../app_scope.dart';
import '../theme.dart';
import 'practice_screen.dart';

void _practice(BuildContext context, String title, List<Question> qs) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => PracticeScreen(title: title, questions: qs),
  ),
);

String _percent(double v) => '${(v * 100).round()}%';

/// Thống kê (bản Pro): tỉ lệ đúng, câu điểm liệt, đề đạt và tỉ lệ đúng theo chương.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final code = scope.progress.classCode;
    final stats = chapterStats(scope.bank, scope.progress, code);
    final weak = stats.where((s) => s.accuracy != null).toList();
    return ProFeatureScreen(
      title: 'Thống kê',
      teaser: weak.isEmpty
          ? null
          : 'Chương yếu nhất của bạn đang đúng '
                '${_percent(weak.map((s) => s.accuracy!).reduce(min))}',
      pitch:
          'Xem tỉ lệ đúng từng chương so với mức cần để đạt, câu điểm liệt đã chắc '
          'chưa và dự đoán khả năng đỗ.',
      builder: (context) => _StatsBody(stats: stats),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final List<ChapterStat> stats;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final bank = scope.bank;
    final progress = scope.progress;
    final code = progress.classCode;
    final config = bank.examConfigs[code]!;
    final c = context.colors;

    final answered = stats.fold(0, (a, s) => a + s.answered);
    final correct = stats.fold(0, (a, s) => a + s.correct);
    final critical = bank.criticalFor(code);
    final criticalRight = critical.where((q) => progress.lastResult[q.id] == true).length;
    final exams = progress.exams.where((e) => e.classCode == code).toList();
    final target = config.passScore == null ? null : config.passScore! / config.questionCount;

    final sorted = List.of(stats)..sort((a, b) => (a.accuracy ?? 2).compareTo(b.accuracy ?? 2));
    final weakest = sorted.firstOrNull;
    final weakestQs = weakest == null
        ? const <Question>[]
        : bank
              .forChapter(code, weakest.chapter.number)
              .where((q) => progress.lastResult[q.id] != true)
              .toList();
    final prediction = predictPass(bank, progress, code);

    Widget tile(String value, String label) => Expanded(
      child: AppCard(
        radius: 14,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
          ],
        ),
      ),
    );

    Color colorFor(double v) => target != null && v >= target
        ? c.accent
        : v < 0.7
        ? c.danger
        : c.partial;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Row(
          children: [
            tile(answered == 0 ? '–' : _percent(correct / answered), 'trả lời đúng'),
            const SizedBox(width: 8),
            tile('$criticalRight/${critical.length}', 'câu điểm liệt'),
            const SizedBox(width: 8),
            tile('${exams.where((e) => e.passed == true).length}/${exams.length}', 'đề thi đạt'),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Expanded(
                    child: Text(
                      'Tỉ lệ đúng theo chương',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('yếu nhất trước', style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
              for (final s in sorted)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.chapter.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.accuracy == null ? 'Chưa làm' : _percent(s.accuracy!),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: s.accuracy == null ? c.muted : colorFor(s.accuracy!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _TargetBar(
                        value: s.accuracy ?? 0,
                        target: target,
                        color: s.accuracy == null ? c.track : colorFor(s.accuracy!),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Đã làm ${s.answered}/${s.total} câu',
                        style: TextStyle(fontSize: 11.5, color: c.muted),
                      ),
                    ],
                  ),
                ),
              if (target != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(width: 2, height: 10, color: c.text),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Vạch đen: mức ${_percent(target)} '
                        '(${config.passScore}/${config.questionCount} câu) cần để đạt',
                        style: TextStyle(fontSize: 11.5, color: c.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (weakest != null && weakest.accuracy != null && weakestQs.isNotEmpty) ...[
          const SizedBox(height: 14),
          AppCard(
            color: c.dangerSoft,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.all(14),
            onTap: () => _practice(context, 'Chương ${weakest.chapter.number}', weakestQs),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ôn ngay: chương ${weakest.chapter.number}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: c.onDangerSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${weakestQs.length} câu sai hoặc chưa làm trong chương yếu nhất',
                        style: TextStyle(fontSize: 12.5, color: c.onDangerSoft),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.onDangerSoft),
              ],
            ),
          ),
        ],
        if (prediction != null) ...[
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const PredictionScreen()),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded, color: c.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dự đoán khả năng đỗ',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hiện tại: ${predictionLabel(prediction).toLowerCase()}',
                        style: TextStyle(fontSize: 12.5, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.muted),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Thanh tỉ lệ với vạch đánh dấu mức cần để đạt.
class _TargetBar extends StatelessWidget {
  const _TargetBar({required this.value, required this.target, required this.color});

  final double value;
  final double? target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            ThinBar(value: value, color: color, height: 8),
            if (target != null)
              Positioned(
                left: box.maxWidth * target! - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: c.text),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dự đoán khả năng đỗ (bản Pro), kèm điểm các đề gần nhất và việc nên làm tiếp.
class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) => ProFeatureScreen(
    title: 'Dự đoán khả năng đỗ',
    pitch:
        'Ước tính khả năng đỗ từ các câu đã làm và đề thi thử, kèm những việc cụ thể '
        'để chắc đỗ hơn.',
    builder: (context) => const _PredictionBody(),
  );
}

class _PredictionBody extends StatelessWidget {
  const _PredictionBody();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final bank = scope.bank;
    final progress = scope.progress;
    final code = progress.classCode;
    final config = bank.examConfigs[code]!;
    final prediction = predictPass(bank, progress, code);
    final c = context.colors;
    if (prediction == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Chưa xác minh điểm đạt của hạng $code nên chưa dự đoán được.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted),
          ),
        ),
      );
    }
    final label = predictionLabel(prediction);
    final p = prediction.probability;
    final color = !prediction.enoughData
        ? c.muted
        : p >= 0.75
        ? c.accent
        : p >= 0.5
        ? c.partial
        : c.danger;
    final recent = progress.exams.where((e) => e.classCode == code).take(6).toList().reversed;

    final all = bank.forClass(code);
    final criticalWrong = bank.criticalFor(code).where((q) => progress.isWrong(q.id)).toList();
    final stats = chapterStats(bank, progress, code).where((s) => s.accuracy != null).toList()
      ..sort((a, b) => a.accuracy!.compareTo(b.accuracy!));
    final target = config.passScore! / config.questionCount;
    final weak = stats.where((s) => s.accuracy! < target).firstOrNull;
    final unseen = all.where((q) => !progress.lastResult.containsKey(q.id)).toList();

    Widget action(IconData icon, String text, VoidCallback onTap, {bool danger = false}) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppCard(
        radius: 14,
        color: danger ? c.dangerSoft : null,
        borderColor: danger ? Colors.transparent : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? c.onDangerSoft : c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: danger ? c.onDangerSoft : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        AppCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              Semantics(
                label: 'Khả năng đỗ ước tính ${_percent(p)}',
                excludeSemantics: true,
                child: SizedBox(
                  width: 220,
                  height: 122,
                  child: CustomPaint(
                    painter: _GaugePainter(value: p, track: c.track, color: color),
                    child: Align(
                      alignment: const Alignment(0, 0.55),
                      child: Text(
                        _percent(p),
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                'Ước tính từ ${prediction.examCount} đề thi thử và ${prediction.answered} câu '
                'đã làm. Chỉ để tham khảo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, height: 1.5, color: c.muted),
              ),
            ],
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        'Điểm ${recent.length} đề gần nhất',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      'đạt từ ${config.passScore}',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: 'Điểm các đề: ${recent.map((e) => e.correct).join(', ')}',
                  excludeSemantics: true,
                  child: SizedBox(
                    height: 92,
                    child: CustomPaint(
                      painter: _ScoresPainter(
                        exams: recent.toList(),
                        passScore: config.passScore!,
                        total: config.questionCount,
                        line: c.accent,
                        pass: c.accent,
                        fail: c.danger,
                        guide: c.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        const Text('Để chắc đỗ hơn', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
        if (criticalWrong.isNotEmpty)
          action(
            Icons.warning_amber_rounded,
            'Làm lại ${criticalWrong.length} câu điểm liệt từng sai',
            () => _practice(context, 'Câu điểm liệt từng sai', criticalWrong),
            danger: true,
          ),
        if (weak != null)
          action(
            Icons.schedule,
            'Ôn chương ${weak.chapter.number}, đang đúng ${_percent(weak.accuracy!)}',
            () => _practice(
              context,
              'Chương ${weak.chapter.number}',
              bank.forChapter(code, weak.chapter.number),
            ),
          ),
        if (unseen.isNotEmpty)
          action(
            Icons.menu_book_outlined,
            'Làm nốt ${unseen.length} câu chưa gặp',
            () => _practice(context, 'Câu chưa làm', unseen),
          ),
        if (criticalWrong.isEmpty && weak == null && unseen.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Bạn đã làm hết bộ câu và mọi chương đều đạt. Hãy làm thêm vài đề thi thử.',
              style: TextStyle(fontSize: 13, height: 1.5, color: c.muted),
            ),
          ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.track, required this.color});

  final double value;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final r = size.width / 2 - stroke / 2 - 1;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height - 12), radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, paint..color = track);
    if (value > 0) canvas.drawArc(rect, pi, pi * value, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color || old.track != track;
}

class _ScoresPainter extends CustomPainter {
  _ScoresPainter({
    required this.exams,
    required this.passScore,
    required this.total,
    required this.line,
    required this.pass,
    required this.fail,
    required this.guide,
  });

  final List<ExamRecord> exams;
  final int passScore;
  final int total;
  final Color line;
  final Color pass;
  final Color fail;
  final Color guide;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final lo = max(0, min(passScore - 6, exams.map((e) => e.correct).reduce(min) - 1));
    final hi = total;
    double y(int score) => pad + (size.height - 2 * pad) * (1 - (score - lo) / (hi - lo));
    double x(int i) =>
        exams.length == 1 ? size.width / 2 : 16 + (size.width - 32) * i / (exams.length - 1);

    final passY = y(passScore);
    final dash = Paint()
      ..color = guide
      ..strokeWidth = 1;
    for (var dx = 0.0; dx < size.width; dx += 8) {
      canvas.drawLine(Offset(dx, passY), Offset(min(dx + 4, size.width), passY), dash);
    }
    final path = Path();
    for (var i = 0; i < exams.length; i++) {
      final p = Offset(x(i), y(exams[i].correct));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );
    for (var i = 0; i < exams.length; i++) {
      canvas.drawCircle(
        Offset(x(i), y(exams[i].correct)),
        4.5,
        Paint()..color = exams[i].passed == true ? pass : fail,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoresPainter old) => true;
}
