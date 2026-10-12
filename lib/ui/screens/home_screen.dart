import 'package:flutter/material.dart';

import '../../data/question_bank.dart';
import '../../logic/insights.dart';
import '../../models/models.dart';
import '../../monetization/paywall.dart';
import '../app_scope.dart';
import '../theme.dart';
import 'about_screen.dart';
import 'before_exam_screen.dart';
import 'exam_screen.dart';
import 'practice_screen.dart';
import 'review_screen.dart';
import 'signs_screen.dart';
import 'stats_screen.dart';

void _open(BuildContext context, Widget screen) =>
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

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
    final chapters = {for (final q in all) q.chapter}.length;
    final config = bank.examConfigs[code];
    final due = ReviewPlan.of(bank, progress, code).due.length;
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                IconBadge(
                  icon: Icons.donut_large,
                  background: c.accent,
                  foreground: c.onAccent,
                  size: 36,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ôn thi GPLX',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Giới thiệu và nguồn dữ liệu',
                  icon: Icon(Icons.info_outline, color: c.muted),
                  onPressed: () => _open(context, const AboutScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Hạng bằng',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted),
            ),
            const SizedBox(height: 8),
            _ClassPicker(selected: code, onSelect: progress.selectClass),
            const SizedBox(height: 8),
            Text(
              bank.classes[code]?.description ?? '',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: c.muted),
            ),
            const SizedBox(height: 14),
            AppCard(
              radius: 18,
              child: Row(
                children: [
                  _ProgressRing(value: all.isEmpty ? 0 : done / all.length),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiến độ hạng $code',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đã làm $done/${all.length} câu',
                          style: TextStyle(fontSize: 13, color: c.muted),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Đúng $right',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: c.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sai ${wrong.length}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: c.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              color: c.warnSoft,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => _open(context, const ReviewTodayScreen()),
              child: Row(
                children: [
                  IconBadge(
                    icon: Icons.event_repeat_outlined,
                    background: c.warnIcon,
                    foreground: c.onWarnSoft,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          due == 0
                              ? 'Ôn lại hôm nay: chưa có câu đến hạn'
                              : 'Ôn lại hôm nay: $due câu sắp quên',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: c.onWarnSoft,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lịch ôn thông minh · Bản Pro',
                          style: TextStyle(fontSize: 12.5, color: c.onWarnSoft),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: c.onWarnSoft),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              radius: 18,
              color: c.accent,
              borderColor: Colors.transparent,
              onTap: () => _open(context, const ExamIntroScreen()),
              child: Row(
                children: [
                  IconBadge(
                    icon: Icons.timer_outlined,
                    background: c.onAccent.withValues(alpha: 0.16),
                    foreground: c.onAccent,
                    size: 44,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thi thử',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: c.onAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          config == null
                              ? 'Đề theo cấu trúc thật'
                              : '${config.questionCount} câu · ${config.minutes} phút · '
                                    'đề theo cấu trúc thật',
                          style: TextStyle(fontSize: 13, color: c.onAccentMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: c.onAccent),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _GridTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Ôn theo chương',
                  subtitle: '${all.length} câu · $chapters chương',
                  onTap: () => _open(context, const ChapterListScreen()),
                ),
                _GridTile(
                  icon: Icons.warning_amber_rounded,
                  iconColor: c.danger,
                  title: 'Câu điểm liệt',
                  subtitle: '${critical.length} câu · sai là trượt',
                  onTap: () =>
                      _open(context, PracticeScreen(title: 'Câu điểm liệt', questions: critical)),
                ),
                _GridTile(
                  icon: Icons.replay,
                  title: 'Câu làm sai',
                  subtitle: wrong.isEmpty ? 'Chưa có câu sai' : '${wrong.length} câu cần ôn lại',
                  onTap: () =>
                      _open(context, PracticeScreen(title: 'Câu làm sai', questions: wrong)),
                ),
                _GridTile(
                  icon: Icons.bookmark_border,
                  title: 'Đã đánh dấu',
                  subtitle: '${bookmarked.length} câu',
                  onTap: () => _open(
                    context,
                    PracticeScreen(title: 'Câu đã đánh dấu', questions: bookmarked),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ProTile(
                    icon: Icons.insights_outlined,
                    title: 'Thống kê',
                    subtitle: 'Dự đoán đỗ',
                    onTap: () => _open(context, const StatsScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProTile(
                    icon: Icons.event_available_outlined,
                    title: 'Trước ngày thi',
                    subtitle: 'Gói ôn 4 bước',
                    onTap: () => _open(context, const BeforeExamScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => _open(context, const SignsScreen()),
              child: Row(
                children: [
                  Icon(Icons.signpost_outlined, color: c.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tra cứu biển báo',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bank.signs.length} biển theo QCVN 41:2024',
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
        ),
      ),
    );
  }
}

/// Nút chọn hạng dạng phân đoạn, như mockup.
class _ClassPicker extends StatelessWidget {
  const _ClassPicker({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (final code in enabledClasses)
            Expanded(
              child: Semantics(
                selected: code == selected,
                button: true,
                child: Material(
                  color: code == selected ? c.surface : Colors.transparent,
                  elevation: code == selected ? 1 : 0,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelect(code),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          code,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: code == selected ? FontWeight.w600 : FontWeight.w500,
                            color: code == selected ? c.accent : c.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final percent = (value * 100).round();
    return Semantics(
      label: 'Đã làm $percent%',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 68,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: c.accentSoft,
              color: c.accent,
            ),
            Center(
              child: Text(
                '$percent%',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor ?? c.accent),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: c.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lối vào tính năng Pro ở trang chủ, có nhãn PRO nhỏ.
class _ProTile extends StatelessWidget {
  const _ProTile({
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
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c.accent),
              const Spacer(),
              const ProBadge(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class ChapterListScreen extends StatelessWidget {
  const ChapterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final progress = scope.progress;
    final code = progress.classCode;
    final all = scope.bank.forClass(code);
    final done = all.where((q) => progress.lastResult.containsKey(q.id)).length;
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ôn theo chương'),
            Text(
              'Hạng $code · ${all.length} câu',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: c.muted),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          AppCard(
            color: c.accent,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () => _practice(context, 'Tất cả câu hỏi', all),
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.all_inclusive,
                  background: c.onAccent.withValues(alpha: 0.16),
                  foreground: c.onAccent,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tất cả câu hỏi',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: c.onAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Đã làm $done/${all.length} câu',
                        style: TextStyle(fontSize: 12.5, color: c.onAccentMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.onAccent),
              ],
            ),
          ),
          for (final ch in scope.bank.chapters) _chapterCard(context, ch),
        ],
      ),
    );
  }

  Widget _chapterCard(BuildContext context, Chapter ch) {
    final scope = AppScope.of(context);
    final progress = scope.progress;
    final qs = scope.bank.forChapter(progress.classCode, ch.number);
    if (qs.isEmpty) return const SizedBox.shrink();
    final done = qs.where((q) => progress.lastResult.containsKey(q.id)).length;
    final wrong = qs.where((q) => progress.isWrong(q.id)).length;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => _practice(context, 'Chương ${ch.number}', qs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${ch.number}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.accent),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ch.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ThinBar(value: done / qs.length),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Đã làm $done/${qs.length} câu',
                          style: TextStyle(fontSize: 12.5, color: c.muted),
                        ),
                      ),
                      Text(
                        wrong > 0 ? 'Sai $wrong' : (done > 0 ? 'Không sai câu nào' : ''),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: wrong > 0 ? c.danger : c.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _practice(BuildContext context, String title, List<Question> qs) =>
      _open(context, PracticeScreen(title: title, questions: qs));
}
