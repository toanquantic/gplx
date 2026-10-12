import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../app_scope.dart';
import '../theme.dart';
import '../widgets/question_grid.dart';
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

  void _go(int i) => _controller.animateToPage(
    i,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

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
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: progress.bookmarks.contains(current.id) ? 'Bỏ đánh dấu câu' : 'Đánh dấu câu',
            color: c.accent,
            icon: Icon(
              progress.bookmarks.contains(current.id) ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: () => progress.toggleBookmark(current.id),
          ),
          IconButton(
            tooltip: 'Danh sách câu',
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: _showGrid,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ThinBar(value: (_index + 1) / qs.length, height: 4),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: qs.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final q = qs[i];
                final picked = _picked[q.id];
                return QuestionView(
                  question: q,
                  critical: scope.bank.isCritical(progress.classCode, q.id),
                  label: 'Câu ${q.id} · ${i + 1}/${qs.length}',
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
          ),
        ],
      ),
      bottomNavigationBar: QuestionNavBar(
        index: _index,
        total: qs.length,
        onPrev: () => _go(_index - 1),
        onNext: () => _go(_index + 1),
      ),
    );
  }

  Future<void> _showGrid() async {
    final progress = AppScope.read(context).progress;
    final picked = await QuestionGridSheet.show(
      context,
      title: widget.title,
      current: _index,
      states: [
        for (final q in widget.questions)
          switch (progress.lastResult[q.id]) {
            true => CellState.correct,
            false => CellState.wrong,
            null => CellState.untouched,
          },
      ],
    );
    if (picked != null && mounted) _controller.jumpToPage(picked);
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
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: index > 0 ? onPrev : null,
                  child: const Text('Câu trước'),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: index < total - 1 ? onNext : null,
                  child: const Text('Câu tiếp'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
