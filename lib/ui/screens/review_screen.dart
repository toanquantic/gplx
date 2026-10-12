import 'package:flutter/material.dart';

import '../../logic/insights.dart';
import '../../logic/review.dart';
import '../../monetization/paywall.dart';
import '../app_scope.dart';
import '../theme.dart';
import 'practice_screen.dart';

const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// "Ôn lại hôm nay" (bản Pro): các câu từng sai đến hạn ôn theo lịch lặp lại
/// ngắt quãng, lịch 7 ngày tới và những câu hay quên nhất.
class ReviewTodayScreen extends StatelessWidget {
  const ReviewTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final plan = ReviewPlan.of(scope.bank, scope.progress, scope.progress.classCode);
    return ProFeatureScreen(
      title: 'Ôn lại hôm nay',
      teaser: plan.due.isEmpty ? null : '${plan.due.length} câu đến hạn ôn hôm nay',
      pitch:
          'Câu làm sai được xếp lịch ôn lại: ngày mai, rồi 3, 7, 14, 30 ngày sau. '
          'Mỗi ngày bạn chỉ ôn đúng những câu sắp quên.',
      builder: (context) => _ReviewBody(plan: plan),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.plan});

  final ReviewPlan plan;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = AppScope.of(context).progress.today;
    final n = plan.due.length;
    final top = plan.forecast.reduce((a, b) => a > b ? a : b);
    const onDark = Color(0xFFDDE6DF);
    const highlight = Color(0xFFF5B860);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        AppCard(
          radius: 20,
          color: const Color(0xFF142019),
          borderColor: Colors.transparent,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đến hạn hôm nay',
                          style: TextStyle(fontSize: 13, color: Color(0xFFB9C7BD)),
                        ),
                        Text.rich(
                          TextSpan(
                            text: '$n ',
                            style: const TextStyle(
                              fontSize: 38,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            children: const [
                              TextSpan(
                                text: 'câu',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFB9C7BD),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plan.streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: highlight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Chuỗi ${plan.streak} ngày',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (n - plan.wrongYesterday > 0)
                    Text(
                      '${n - plan.wrongYesterday} câu sắp quên',
                      style: const TextStyle(fontSize: 13, color: onDark),
                    ),
                  if (plan.wrongYesterday > 0)
                    Text(
                      '${plan.wrongYesterday} câu sai hôm qua',
                      style: const TextStyle(fontSize: 13, color: onDark),
                    ),
                  if (n > 0)
                    Text(
                      '~ ${plan.minutes} phút',
                      style: const TextStyle(fontSize: 13, color: onDark),
                    ),
                  if (n == 0)
                    const Text(
                      'Không còn câu nào cần ôn hôm nay.',
                      style: TextStyle(fontSize: 13, color: onDark),
                    ),
                ],
              ),
              if (n > 0) ...[
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: highlight,
                    foregroundColor: const Color(0xFF142019),
                    textStyle: const TextStyle(
                      fontFamily: appFont,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PracticeScreen(title: 'Ôn lại hôm nay', questions: plan.due),
                    ),
                  ),
                  child: Text('Bắt đầu ôn $n câu'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lịch ôn 7 ngày tới',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: [
                  for (var i = 0; i < 7; i++)
                    '${i == 0 ? 'hôm nay' : _weekdays[addDays(today, i).weekday - 1]} '
                        '${plan.forecast[i]} câu',
                ].join(', '),
                excludeSemantics: true,
                child: SizedBox(
                  height: 96,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${plan.forecast[i]}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: top == 0 ? 2 : 2 + 54 * plan.forecast[i] / top,
                                  decoration: BoxDecoration(
                                    color: i == 0 ? c.partial : c.accentSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  i == 0 ? 'Nay' : _weekdays[addDays(today, i).weekday - 1],
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                                    color: i == 0 ? c.onWarnSoft : c.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (plan.hardest.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Hay quên nhất',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          for (final (q, card) in plan.hardest)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppCard(
                radius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      q.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Độ nhớ', style: TextStyle(fontSize: 12, color: c.muted)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ThinBar(
                            value: card.strength,
                            color: card.strength < 0.4 ? c.danger : c.partial,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sai ${card.lapses} lần',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (plan.hardest.isEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Chưa có câu nào trong lịch. Câu bạn làm sai khi ôn tập hoặc thi thử sẽ '
            'tự vào lịch ôn lại.',
            style: TextStyle(fontSize: 13, height: 1.5, color: c.muted),
          ),
        ],
      ],
    );
  }
}
