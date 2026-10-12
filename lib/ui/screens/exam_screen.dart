import 'dart:async';

import 'package:flutter/material.dart';

import '../../logic/exam.dart';
import '../../models/models.dart';
import '../../state/progress.dart';
import '../app_scope.dart';
import '../theme.dart';
import '../widgets/question_grid.dart';
import '../widgets/question_view.dart';
import '../../monetization/entitlement.dart';
import '../../monetization/paywall.dart';
import 'practice_screen.dart';
import 'signs_screen.dart';

String _formatTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}

String _formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return m == 0 ? '$s giây' : '$m phút $s giây';
}

/// Dòng tóm tắt kết quả, dùng trong lịch sử thi.
String _verdict(ExamRecord e) => e.passed
    ? 'Đạt'
    : e.failedCritical
    ? 'Trượt câu điểm liệt'
    : 'Không đạt';

/// Số đề gần nhất bản miễn phí xem được trong lịch sử thi.
const freeHistoryLimit = 5;

/// Mở đề thi thử mới của hạng đang chọn; [smart] là đề ưu tiên câu yếu (Pro).
void startExam(BuildContext context, {bool smart = false, bool replace = false}) {
  final scope = AppScope.read(context);
  final code = scope.progress.classCode;
  final exam = smart
      ? generateSmartExam(scope.bank, scope.progress, code)
      : generateExam(scope.bank, code);
  final route = MaterialPageRoute<void>(builder: (_) => ExamScreen(exam: exam));
  replace ? Navigator.pushReplacement(context, route) : Navigator.push(context, route);
}

/// Màn giới thiệu đề thi thử và lịch sử thi của hạng đang chọn.
class ExamIntroScreen extends StatelessWidget {
  const ExamIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final code = scope.progress.classCode;
    final config = scope.bank.examConfigs[code]!;
    final history = scope.progress.exams.where((e) => e.classCode == code).toList();
    final c = context.colors;

    Widget stat(String value, String unit) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: c.tile, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text(unit, style: TextStyle(fontSize: 12, color: c.muted)),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: Text('Thi thử hạng $code')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          AppCard(
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Đề theo cấu trúc chính thức',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    stat('${config.questionCount}', 'câu hỏi'),
                    const SizedBox(width: 8),
                    stat('${config.minutes}', 'phút'),
                    const SizedBox(width: 8),
                    stat(config.passScore == null ? '?' : '${config.passScore}', 'câu để đạt'),
                  ],
                ),
                const SizedBox(height: 14),
                for (final MapEntry(key: group, value: n) in config.structure.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            groupLabels[group] ?? group,
                            style: TextStyle(
                              fontSize: 13,
                              color: group == 'diem_liet' ? c.danger : c.muted,
                            ),
                          ),
                        ),
                        Text(
                          '$n câu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: group == 'diem_liet' ? c.danger : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (config.passScore == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Chưa xác minh điểm đạt của hạng này.',
                    style: TextStyle(fontSize: 12.5, color: c.muted),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.dangerSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Trả lời sai câu điểm liệt là trượt dù đủ điểm.',
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: c.onDangerSoft),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(
                fontFamily: appFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Bắt đầu thi'),
            onPressed: () => startExam(context),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => scope.entitlement.currentIsPro
                ? startExam(context, smart: true)
                : openPaywall(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_outlined, size: 20),
                SizedBox(width: 8),
                Flexible(child: Text('Đề ưu tiên câu yếu')),
                SizedBox(width: 8),
                ProBadge(),
              ],
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Lịch sử thi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ProGate(
              locked: Column(
                children: [
                  for (final e in history.take(freeHistoryLimit)) _historyTile(context, e),
                  if (history.length > freeHistoryLimit)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: ProLockedCard(feature: 'Xem toàn bộ lịch sử thi'),
                    ),
                ],
              ),
              child: Column(
                children: [for (final e in history.take(100)) _historyTile(context, e)],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historyTile(BuildContext context, ExamRecord e) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: e.questionIds == null ? null : () => _openRecord(context, e),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: e.passed ? c.accent : c.danger,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.correct}/${e.total} đúng · ${_verdict(e)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(_formatTime(e.time), style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            if (e.questionIds != null) Icon(Icons.chevron_right, color: c.muted),
          ],
        ),
      ),
    );
  }

  void _openRecord(BuildContext context, ExamRecord record) {
    final exam = restoreExam(AppScope.read(context).bank, record);
    if (exam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bộ đề đã được cập nhật nên không xem lại được bài thi này.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ExamResultScreen(
          exam: exam,
          result: exam.grade(),
          duration: record.duration,
          fromHistory: true,
        ),
      ),
    );
  }
}

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.exam});

  final Exam exam;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final _controller = PageController();
  late final DateTime _started;
  late final DateTime _deadline;
  late Duration _left;
  Timer? _timer;
  int _index = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    _deadline = _started.add(Duration(minutes: widget.exam.config.minutes));
    _left = _deadline.difference(_started);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _deadline.difference(DateTime.now());
      if (left <= Duration.zero) {
        _submit();
      } else {
        setState(() => _left = left);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    _submitted = true;
    _timer?.cancel();
    final exam = widget.exam;
    final result = exam.grade();
    final now = DateTime.now();
    final took = now.isAfter(_deadline) ? _deadline.difference(_started) : now.difference(_started);
    final progress = AppScope.read(context).progress;
    progress.recordAnswers({
      for (var i = 0; i < exam.questions.length; i++)
        if (exam.answers[i] != null) exam.questions[i].id: exam.isCorrect(i),
    });
    progress.recordExam(
      ExamRecord(
        exam.classCode,
        now,
        result.correct,
        result.total,
        result.passed,
        failedCritical: result.failedCritical,
        duration: took,
        questionIds: [for (final q in exam.questions) q.id],
        answers: List.of(exam.answers),
        correctAnswers: [for (final q in exam.questions) q.correctIndex],
        smart: exam.smart,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ExamResultScreen(exam: exam, result: result, duration: took),
      ),
    );
  }

  Future<void> _confirmSubmit() async {
    final missing = widget.exam.questions.length - widget.exam.answeredCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nộp bài?'),
        content: Text(
          missing > 0 ? 'Bạn còn $missing câu chưa trả lời.' : 'Bạn đã trả lời tất cả các câu.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Làm tiếp')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Nộp bài')),
        ],
      ),
    );
    if (ok == true && mounted) _submit();
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát bài thi?'),
        content: const Text('Bài làm sẽ không được lưu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ở lại')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Thoát')),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final total = exam.questions.length;
    final mm = _left.inMinutes.toString().padLeft(2, '0');
    final ss = (_left.inSeconds % 60).toString().padLeft(2, '0');
    final lowTime = _left.inMinutes < 2;
    final c = context.colors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Thoát bài thi',
            icon: const Icon(Icons.close),
            onPressed: _confirmLeave,
          ),
          titleSpacing: 0,
          title: Semantics(
            label: 'Còn ${_left.inMinutes} phút ${_left.inSeconds % 60} giây',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: lowTime ? c.dangerSoft : c.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: lowTime ? c.danger : c.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: lowTime ? c.danger : c.muted),
                  const SizedBox(width: 6),
                  Text(
                    '$mm:$ss',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: lowTime ? c.danger : c.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Danh sách câu',
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: _showGrid,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _confirmSubmit,
                child: const Text('Nộp bài'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Semantics(
              label: 'Tiến độ bài thi: đã trả lời ${exam.answeredCount}/$total',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (var i = 0; i < total; i++)
                      Expanded(
                        child: Container(
                          height: 6,
                          margin: EdgeInsets.only(right: i == total - 1 ? 0 : 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == _index
                                ? c.text
                                : exam.answers[i] != null
                                ? c.accent
                                : c.track,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: total,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => QuestionView(
                  question: exam.questions[i],
                  // Như đề thật: không báo trước câu nào là điểm liệt.
                  critical: false,
                  label: _examLabel(exam, i),
                  selected: exam.answers[i],
                  onSelect: (choice) => setState(() => exam.answers[i] = choice),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: QuestionNavBar(
          index: _index,
          total: total,
          onPrev: () => _controller.previousPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
          onNext: () => _controller.nextPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
  }

  Future<void> _showGrid() async {
    final picked = await QuestionGridSheet.show(
      context,
      title: 'Bài thi',
      current: _index,
      showFilters: false,
      states: [
        for (final a in widget.exam.answers) a == null ? CellState.untouched : CellState.answered,
      ],
    );
    if (picked != null && mounted) _controller.jumpToPage(picked);
  }
}

/// Nhãn đầu câu khi thi, kèm tên nhóm. Câu điểm liệt không ghi nhóm để không
/// lộ trước, như đề thật.
String _examLabel(Exam exam, int i) {
  final head = 'Câu ${i + 1}/${exam.questions.length}';
  final g = exam.groupOf(i);
  final name = g == 'diem_liet' ? null : groupLabels[g];
  return name == null ? head : '$head · $name';
}

class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({
    super.key,
    required this.exam,
    required this.result,
    this.duration,
    this.fromHistory = false,
  });

  final Exam exam;
  final ExamResult result;
  final Duration? duration;

  /// Mở từ lịch sử thi: không hiện nút thi đề mới.
  final bool fromHistory;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = result.passed ? c.accent : c.danger;
    final wrong = [
      for (var i = 0; i < exam.questions.length; i++)
        if (!exam.isCorrect(i)) i,
    ];
    final criticalIndex = exam.questions.indexWhere((q) => exam.config.criticalIds.contains(q.id));
    final details = [
      if (result.passScore != null) 'Cần ${result.passScore} câu',
      if (duration != null) 'Làm trong ${_formatDuration(duration!)}',
    ].join(' · ');

    void home() => Navigator.popUntil(context, (r) => r.isFirst);

    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('Kết quả')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          AppCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                Icon(
                  result.passed ? Icons.verified_rounded : Icons.cancel_rounded,
                  size: 56,
                  color: color,
                ),
                const SizedBox(height: 6),
                Text(
                  result.passed ? 'Đạt' : 'Không đạt',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${result.correct}',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: '/${result.total}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.muted),
                      ),
                    ],
                  ),
                  semanticsLabel: '${result.correct}/${result.total} câu đúng',
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(details, style: TextStyle(fontSize: 13, color: c.muted)),
                ],
                if (result.passScore == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Chưa xác minh điểm đạt của hạng này.',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                ],
              ],
            ),
          ),
          if (criticalIndex >= 0) ...[
            const SizedBox(height: 10),
            AppCard(
              radius: 14,
              color: result.failedCritical ? c.dangerSoft : c.accentSoft,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    result.failedCritical ? Icons.warning_amber_rounded : Icons.check_circle,
                    color: result.failedCritical ? c.danger : c.accent,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Câu điểm liệt',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    exam.answers[criticalIndex] == null
                        ? 'Bỏ trống'
                        : result.failedCritical
                        ? 'Trả lời sai'
                        : 'Trả lời đúng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: result.failedCritical ? c.danger : c.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Theo nhóm câu',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                for (final s in exam.scoreByGroup())
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                groupLabels[s.group] ?? s.group,
                                style: TextStyle(fontSize: 13, color: c.muted),
                              ),
                            ),
                            Text(
                              '${s.correct}/${s.total}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: s.correct < s.total ? c.danger : c.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ThinBar(
                          value: s.correct / s.total,
                          color: s.correct < s.total ? c.partial : c.accent,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ExamReviewScreen(exam: exam, onlyWrong: wrong.isNotEmpty),
              ),
            ),
            child: Text(wrong.isEmpty ? 'Xem lại bài thi' : 'Xem lại ${wrong.length} câu sai'),
          ),
          const SizedBox(height: 10),
          if (fromHistory)
            OutlinedButton(onPressed: home, child: const Text('Về trang chủ'))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => startExam(
                      context,
                      // Hỏi lại quyền Pro: có thể đã bị thu hồi (hoàn tiền) trong lúc thi.
                      smart: exam.smart && AppScope.read(context).entitlement.currentIsPro,
                      replace: true,
                    ),
                    child: const Text('Thi đề mới'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(onPressed: home, child: const Text('Về trang chủ')),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Xem lại từng câu của bài thi, lọc theo câu sai hoặc đúng.
class ExamReviewScreen extends StatefulWidget {
  const ExamReviewScreen({super.key, required this.exam, this.onlyWrong = false});

  final Exam exam;
  final bool onlyWrong;

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

enum _Filter { all, wrong, right }

class _ExamReviewScreenState extends State<ExamReviewScreen> {
  late _Filter _filter = widget.onlyWrong ? _Filter.wrong : _Filter.all;
  // Mở sẵn câu sai đầu tiên, các câu khác bấm vào để xem.
  late final Set<int> _expanded = {
    for (var i = 0; i < widget.exam.questions.length; i++)
      if (!widget.exam.isCorrect(i)) i,
  }.take(1).toSet();

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final total = exam.questions.length;
    final wrong = [
      for (var i = 0; i < total; i++)
        if (!exam.isCorrect(i)) i,
    ];
    final right = [
      for (var i = 0; i < total; i++)
        if (exam.isCorrect(i)) i,
    ];
    final shown = switch (_filter) {
      _Filter.all => [for (var i = 0; i < total; i++) i],
      _Filter.wrong => wrong,
      _Filter.right => right,
    };
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('Xem lại bài thi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_Filter>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: _Filter.all, label: Text('Tất cả $total')),
                  ButtonSegment(value: _Filter.wrong, label: Text('Sai ${wrong.length}')),
                  ButtonSegment(value: _Filter.right, label: Text('Đúng ${right.length}')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text('Không có câu nào.', style: TextStyle(color: context.colors.muted)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, k) => _reviewCard(context, shown[k]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(BuildContext context, int i) {
    final exam = widget.exam;
    final q = exam.questions[i];
    final answer = exam.answers[i];
    final ok = exam.isCorrect(i);
    final c = context.colors;
    final progress = AppScope.of(context).progress;
    final open = _expanded.contains(i);
    final critical = exam.config.criticalIds.contains(q.id);
    final header = 'Câu ${i + 1}/${exam.questions.length} · ${groupLabels[exam.groupOf(i)] ?? ''}';
    final status = answer == null
        ? 'Bỏ trống · Đáp án ${optionLetter(q.correctIndex)}'
        : ok
        ? 'Bạn chọn ${optionLetter(answer)} · Đúng'
        : 'Bạn chọn ${optionLetter(answer)} · Đáp án ${optionLetter(q.correctIndex)}';

    Widget option(int idx, String tag, Color color, Color soft) => Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            optionLetter(idx),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(q.options[idx], style: const TextStyle(fontSize: 14, height: 1.45))),
          const SizedBox(width: 8),
          Text(
            tag,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => open ? _expanded.remove(i) : _expanded.add(i)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    answer == null
                        ? Icons.remove_circle_outline
                        : ok
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: answer == null ? c.muted : (ok ? c.accent : c.danger),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                header,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.accent,
                                ),
                              ),
                            ),
                            if (critical) ...[const SizedBox(width: 6), const CriticalChip()],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q.text,
                          maxLines: open ? null : 2,
                          overflow: open ? null : TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                        if (!open) ...[
                          const SizedBox(height: 4),
                          Text(status, style: TextStyle(fontSize: 12.5, color: c.muted)),
                        ],
                      ],
                    ),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more, color: c.muted),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (q.image != null) QuestionImage(path: q.image!),
                  option(q.correctIndex, 'Đáp án đúng', c.accent, c.accentSoft),
                  if (answer != null && !ok) option(answer, 'Bạn chọn', c.danger, c.dangerSoft),
                  if (answer == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Bạn bỏ trống câu này.',
                        style: TextStyle(fontSize: 13, color: c.danger),
                      ),
                    ),
                  if (q.explanation != null) ...[
                    const SizedBox(height: 10),
                    Text(q.explanation!, style: const TextStyle(fontSize: 13.5, height: 1.55)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            progress.bookmarks.contains(q.id)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          label: Text(
                            progress.bookmarks.contains(q.id) ? 'Đã đánh dấu' : 'Đánh dấu câu',
                          ),
                          onPressed: () => progress.toggleBookmark(q.id),
                        ),
                      ),
                      if (exam.groupOf(i) == 'bao_hieu') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.signpost_outlined),
                            label: const Text('Tra biển báo'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (_) => const SignsScreen()),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
