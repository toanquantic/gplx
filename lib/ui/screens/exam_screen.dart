import 'dart:async';

import 'package:flutter/material.dart';

import '../../logic/exam.dart';
import '../../models/models.dart';
import '../../state/progress.dart';
import '../app_scope.dart';
import '../widgets/question_view.dart';
import 'practice_screen.dart';

/// Màn giới thiệu đề thi thử và lịch sử thi của hạng đang chọn.
class ExamIntroScreen extends StatelessWidget {
  const ExamIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final code = scope.progress.classCode;
    final config = scope.bank.examConfigs[code]!;
    final history =
        scope.progress.exams.where((e) => e.classCode == code).toList();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Thi thử hạng $code')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Đề thi theo cấu trúc chính thức', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _row('Số câu', '${config.questionCount} câu'),
              _row('Thời gian', '${config.minutes} phút'),
              _row('Điểm đạt',
                  config.passScore == null ? 'Chưa xác minh' : '${config.passScore}/${config.questionCount}'),
              const SizedBox(height: 8),
              Text('Mỗi đề có 1 câu điểm liệt. Trả lời sai câu này là trượt dù đủ điểm.',
                  style: theme.textTheme.bodySmall),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Bắt đầu thi'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ExamScreen(exam: generateExam(scope.bank, code)),
            ),
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Lịch sử thi', style: theme.textTheme.titleMedium),
          for (final e in history.take(20))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(e.passed ? Icons.verified : Icons.highlight_off,
                  color: e.passed ? Colors.green : theme.colorScheme.error),
              title: Text('${e.correct}/${e.total} câu đúng · ${e.passed ? 'Đạt' : 'Không đạt'}'),
              subtitle: Text(_formatTime(e.time)),
            ),
        ],
      ]),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [Expanded(child: Text(k)), Text(v)]),
      );
}

String _formatTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.exam});

  final Exam exam;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final _controller = PageController();
  late final DateTime _deadline;
  late Duration _left;
  Timer? _timer;
  int _index = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.now().add(Duration(minutes: widget.exam.config.minutes));
    _left = _deadline.difference(DateTime.now());
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
    final progress = AppScope.read(context).progress;
    for (var i = 0; i < exam.questions.length; i++) {
      if (exam.answers[i] != null) {
        progress.recordAnswer(
            exam.questions[i].id, exam.answers[i] == exam.questions[i].correctIndex);
      }
    }
    progress.recordExam(ExamRecord(
        exam.classCode, DateTime.now(), result.correct, result.total, result.passed));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
          builder: (_) => ExamResultScreen(exam: exam, result: result)),
    );
  }

  Future<void> _confirmSubmit() async {
    final missing = widget.exam.questions.length - widget.exam.answeredCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nộp bài?'),
        content: Text(missing > 0
            ? 'Bạn còn $missing câu chưa trả lời.'
            : 'Bạn đã trả lời tất cả các câu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Làm tiếp')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Nộp bài')),
        ],
      ),
    );
    if (ok == true && mounted) _submit();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final mm = _left.inMinutes.toString().padLeft(2, '0');
    final ss = (_left.inSeconds % 60).toString().padLeft(2, '0');
    final lowTime = _left.inMinutes < 2;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
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
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('$mm:$ss',
              style: TextStyle(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: lowTime ? Theme.of(context).colorScheme.error : null)),
          actions: [
            IconButton(
              tooltip: 'Danh sách câu',
              icon: const Icon(Icons.grid_view),
              onPressed: _showGrid,
            ),
            TextButton(onPressed: _confirmSubmit, child: const Text('Nộp bài')),
          ],
        ),
        body: PageView.builder(
          controller: _controller,
          itemCount: exam.questions.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => QuestionView(
            question: exam.questions[i],
            // Như đề thật: không báo trước câu nào là điểm liệt.
            critical: false,
            label: 'Câu ${i + 1}/${exam.questions.length}',
            selected: exam.answers[i],
            onSelect: (choice) => setState(() => exam.answers[i] = choice),
          ),
        ),
        bottomNavigationBar: QuestionNavBar(
          index: _index,
          total: exam.questions.length,
          onPrev: () => _controller.previousPage(
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
          onNext: () => _controller.nextPage(
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
          trailing: Text('Đã làm ${exam.answeredCount}/${exam.questions.length}'),
        ),
      ),
    );
  }

  void _showGrid() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 56, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemCount: widget.exam.questions.length,
        itemBuilder: (context, i) => ActionChip(
          padding: EdgeInsets.zero,
          label: Text('${i + 1}'),
          backgroundColor: widget.exam.answers[i] != null
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          onPressed: () {
            Navigator.pop(context);
            _controller.jumpToPage(i);
          },
        ),
      ),
    );
  }
}

class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({super.key, required this.exam, required this.result});

  final Exam exam;
  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = result.passed ? Colors.green : theme.colorScheme.error;
    final critical = exam.config.criticalIds.toSet();
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Icon(result.passed ? Icons.verified : Icons.highlight_off, size: 72, color: color),
        const SizedBox(height: 8),
        Text(result.passed ? 'ĐẠT' : 'KHÔNG ĐẠT',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(color: color)),
        Text(
          '${result.correct}/${result.total} câu đúng'
          '${result.passScore != null ? ' (cần ${result.passScore})' : ''}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (result.failedCritical)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Bạn trả lời sai câu điểm liệt.',
                textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
          ),
        if (result.passScore == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Chưa xác minh điểm đạt của hạng này.', textAlign: TextAlign.center),
          ),
        const SizedBox(height: 16),
        const Divider(),
        for (var i = 0; i < exam.questions.length; i++)
          _ReviewTile(
            number: i + 1,
            question: exam.questions[i],
            answer: exam.answers[i],
            critical: critical.contains(exam.questions[i].id),
          ),
      ]),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.number,
    required this.question,
    required this.answer,
    required this.critical,
  });

  final int number;
  final Question question;
  final int? answer;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final ok = answer == question.correctIndex;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        answer == null ? Icons.remove_circle_outline : (ok ? Icons.check_circle : Icons.cancel),
        color: answer == null ? scheme.outline : (ok ? Colors.green : scheme.error),
      ),
      title: Text('Câu $number${critical ? ' · Điểm liệt' : ''}'),
      subtitle: Text(question.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('Câu $number')),
            body: QuestionView(
              question: question,
              critical: critical,
              selected: answer,
              reveal: true,
              label: 'Câu ${question.id} trong bộ đề',
            ),
          ),
        ),
      ),
    );
  }
}
