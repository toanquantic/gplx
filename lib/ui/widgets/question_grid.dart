import 'package:flutter/material.dart';

import '../theme.dart';

/// Trạng thái một ô trong danh sách câu.
enum CellState { untouched, answered, correct, wrong }

/// Bảng chọn câu dạng lưới, mở từ nút "Danh sách câu".
///
/// Trả về chỉ số câu người dùng chọn qua [Navigator.pop].
class QuestionGridSheet extends StatefulWidget {
  const QuestionGridSheet({
    super.key,
    required this.title,
    required this.states,
    required this.current,
    this.showFilters = true,
  });

  final String title;
  final List<CellState> states;
  final int current;

  /// Hiện nút lọc "Chỉ câu sai", "Câu chưa làm" (tắt khi đang thi).
  final bool showFilters;

  static Future<int?> show(
    BuildContext context, {
    required String title,
    required List<CellState> states,
    required int current,
    bool showFilters = true,
  }) => showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) =>
        QuestionGridSheet(title: title, states: states, current: current, showFilters: showFilters),
  );

  @override
  State<QuestionGridSheet> createState() => _QuestionGridSheetState();
}

class _QuestionGridSheetState extends State<QuestionGridSheet> {
  CellState? _filter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final states = widget.states;
    int count(CellState s) => states.where((x) => x == s).length;
    final graded = states.any((s) => s == CellState.correct || s == CellState.wrong);
    final done = states.length - count(CellState.untouched);
    final shown = [
      for (var i = 0; i < states.length; i++)
        if (_filter == null || states[i] == _filter) i,
    ];

    Widget legend(Color color, String text, {bool outlined = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: outlined ? Border.all(color: c.borderStrong) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12.5, color: c.muted)),
      ],
    );

    Widget filterButton(CellState s, String label) {
      final on = _filter == s;
      return Expanded(
        child: on
            ? FilledButton(onPressed: () => setState(() => _filter = null), child: Text(label))
            : OutlinedButton(onPressed: () => setState(() => _filter = s), child: Text(label)),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    'Đã làm $done/${states.length}',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (graded) ...[
                      legend(c.accent, 'Đúng ${count(CellState.correct)}'),
                      legend(c.danger, 'Sai ${count(CellState.wrong)}'),
                    ] else
                      legend(c.accent, 'Đã trả lời $done'),
                    legend(c.surface, 'Chưa làm ${count(CellState.untouched)}', outlined: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: shown.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('Không có câu nào.', style: TextStyle(color: c.muted)),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 52,
                        ),
                        itemCount: shown.length,
                        itemBuilder: (context, k) => _cell(context, shown[k]),
                      ),
              ),
              if (widget.showFilters) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    filterButton(CellState.wrong, 'Chỉ câu sai'),
                    const SizedBox(width: 10),
                    filterButton(CellState.untouched, 'Câu chưa làm'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, int i) {
    final c = context.colors;
    final s = widget.states[i];
    final (bg, fg, label) = switch (s) {
      CellState.correct => (c.accent, c.onAccent, 'đúng'),
      CellState.wrong => (c.danger, c.onAccent, 'sai'),
      CellState.answered => (c.accent, c.onAccent, 'đã trả lời'),
      CellState.untouched => (c.surface, c.text, 'chưa làm'),
    };
    final current = i == widget.current;
    return Semantics(
      label: 'Câu ${i + 1}, $label${current ? ', đang xem' : ''}',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: current
              ? BorderSide(color: c.text, width: 2.5)
              : s == CellState.untouched
              ? BorderSide(color: c.borderStrong)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pop(context, i),
          child: Center(
            child: Text(
              '${i + 1}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
