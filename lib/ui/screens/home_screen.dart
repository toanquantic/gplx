import 'package:flutter/material.dart';

import '../../data/question_bank.dart';
import '../../models/models.dart';
import '../app_scope.dart';
import 'about_screen.dart';
import 'exam_screen.dart';
import 'practice_screen.dart';
import 'signs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final bank = scope.bank;
    final progress = scope.progress;
    final code = progress.classCode;
    final all = bank.forClass(code);
    final done = all.where((q) => progress.lastResult.containsKey(q.id)).length;
    final right = all.where((q) => progress.lastResult[q.id] == true).length;
    final wrong = all.where((q) => progress.isWrong(q.id)).toList();
    final bookmarked = all.where((q) => progress.bookmarks.contains(q.id)).toList();
    final critical = bank.criticalFor(code);
    final theme = Theme.of(context);

    void open(Widget screen) =>
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ôn thi GPLX'),
        actions: [
          IconButton(
            tooltip: 'Giới thiệu và nguồn dữ liệu',
            icon: const Icon(Icons.info_outline),
            onPressed: () => open(const AboutScreen()),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Hạng bằng', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            for (final c in enabledClasses) ButtonSegment(value: c, label: Text(c)),
          ],
          selected: {code},
          onSelectionChanged: (s) => progress.selectClass(s.first),
        ),
        const SizedBox(height: 8),
        Text(bank.classes[code]?.description ?? '', style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tiến độ hạng $code', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: all.isEmpty ? 0 : done / all.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text('Đã làm $done/${all.length} câu · Đúng $right · Sai ${wrong.length}'),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        _MenuTile(
          icon: Icons.timer_outlined,
          title: 'Thi thử',
          subtitle: 'Đề ngẫu nhiên theo cấu trúc đề thật, có tính giờ',
          onTap: () => open(const ExamIntroScreen()),
        ),
        _MenuTile(
          icon: Icons.menu_book_outlined,
          title: 'Ôn theo chương',
          subtitle: '${all.length} câu, chia theo 6 chương',
          onTap: () => open(const ChapterListScreen()),
        ),
        _MenuTile(
          icon: Icons.warning_amber_outlined,
          title: 'Câu điểm liệt',
          subtitle: '${critical.length} câu, sai một câu là trượt',
          onTap: () => open(PracticeScreen(title: 'Câu điểm liệt', questions: critical)),
        ),
        _MenuTile(
          icon: Icons.replay,
          title: 'Câu làm sai',
          subtitle: wrong.isEmpty ? 'Chưa có câu sai' : '${wrong.length} câu cần ôn lại',
          onTap: () => open(PracticeScreen(title: 'Câu làm sai', questions: wrong)),
        ),
        _MenuTile(
          icon: Icons.bookmark_border,
          title: 'Câu đã đánh dấu',
          subtitle: '${bookmarked.length} câu',
          onTap: () => open(PracticeScreen(title: 'Câu đã đánh dấu', questions: bookmarked)),
        ),
        _MenuTile(
          icon: Icons.signpost_outlined,
          title: 'Biển báo',
          subtitle: '${bank.signs.length} biển theo QCVN 41:2024',
          onTap: () => open(const SignsScreen()),
        ),
      ]),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class ChapterListScreen extends StatelessWidget {
  const ChapterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final code = scope.progress.classCode;
    return Scaffold(
      appBar: AppBar(title: Text('Ôn theo chương · Hạng $code')),
      body: ListView(children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.all_inclusive, size: 20)),
          title: const Text('Tất cả câu hỏi'),
          subtitle: Text('${scope.bank.forClass(code).length} câu'),
          onTap: () => _open(context, 'Tất cả câu hỏi', scope.bank.forClass(code)),
        ),
        for (final ch in scope.bank.chapters) _chapterTile(context, ch),
      ]),
    );
  }

  Widget _chapterTile(BuildContext context, Chapter ch) {
    final scope = AppScope.of(context);
    final qs = scope.bank.forChapter(scope.progress.classCode, ch.number);
    if (qs.isEmpty) return const SizedBox.shrink();
    final done = qs.where((q) => scope.progress.lastResult.containsKey(q.id)).length;
    return ListTile(
      leading: CircleAvatar(child: Text('${ch.number}')),
      title: Text(ch.name),
      subtitle: Text('Đã làm $done/${qs.length} câu'),
      onTap: () => _open(context, 'Chương ${ch.number}', qs),
    );
  }

  void _open(BuildContext context, String title, List<Question> qs) => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => PracticeScreen(title: title, questions: qs)));
}
