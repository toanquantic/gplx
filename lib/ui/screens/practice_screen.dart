import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../app_scope.dart';
import '../widgets/question_view.dart';

/// Ôn tập: chọn đáp án là biết ngay đúng sai và xem giải thích.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.title, required this.questions});

  final String title;
  final List<Question> questions;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _controller = PageController();
  final Map<int, int> _picked = {};
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int i) => _controller.animateToPage(i,
      duration: const Duration(milliseconds: 250), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final progress = scope.progress;
    final qs = widget.questions;
    if (qs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Chưa có câu nào ở mục này.')),
      );
    }
    final current = qs[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu câu',
            icon: Icon(progress.bookmarks.contains(current.id)
                ? Icons.bookmark
                : Icons.bookmark_border),
            onPressed: () => progress.toggleBookmark(current.id),
          ),
          IconButton(
            tooltip: 'Danh sách câu',
            icon: const Icon(Icons.grid_view),
            onPressed: () => _showGrid(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: qs.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final q = qs[i];
          final picked = _picked[q.id];
          return QuestionView(
            question: q,
            critical: scope.bank.isCritical(progress.classCode, q.id),
            label: 'Câu ${q.id}  ·  ${i + 1}/${qs.length}',
            selected: picked,
            reveal: picked != null,
            onSelect: picked != null
                ? null
                : (choice) {
                    setState(() => _picked[q.id] = choice);
                    progress.recordAnswer(q.id, choice == q.correctIndex);
                  },
          );
        },
      ),
      bottomNavigationBar: QuestionNavBar(
        index: _index,
        total: qs.length,
        onPrev: () => _go(_index - 1),
        onNext: () => _go(_index + 1),
      ),
    );
  }

  void _showGrid(BuildContext context) {
    final progress = AppScope.read(context).progress;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 56, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemCount: widget.questions.length,
        itemBuilder: (context, i) {
          final id = widget.questions[i].id;
          final r = progress.lastResult[id];
          return ActionChip(
            padding: EdgeInsets.zero,
            label: Text('${i + 1}'),
            backgroundColor: r == null
                ? null
                : r
                    ? Colors.green.withValues(alpha: 0.25)
                    : Theme.of(context).colorScheme.errorContainer,
            onPressed: () {
              Navigator.pop(context);
              _controller.jumpToPage(i);
            },
          );
        },
      ),
    );
  }
}

/// Thanh chuyển câu trước/sau, dùng chung cho ôn tập và thi thử.
class QuestionNavBar extends StatelessWidget {
  const QuestionNavBar({
    super.key,
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNext,
    this.trailing,
  });

  final int index;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            TextButton.icon(
              onPressed: index > 0 ? onPrev : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Trước'),
            ),
            Expanded(
              child: Align(
                heightFactor: 1,
                child: trailing ?? Text('${index + 1} / $total'),
              ),
            ),
            TextButton.icon(
              onPressed: index < total - 1 ? onNext : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Sau'),
              iconAlignment: IconAlignment.end,
            ),
          ]),
        ),
      );
}
