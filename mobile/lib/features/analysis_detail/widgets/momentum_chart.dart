import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/repository.dart';
import '../../../domain/models/analysis_run.dart';
import '../../../domain/models/metric_result.dart';

class MomentumChart extends StatelessWidget {
  final AnalysisRun run;
  final MetricResult? momentum;
  const MomentumChart({super.key, required this.run, required this.momentum});

  @override
  Widget build(BuildContext context) {
    final messages = Repository.getMessages(run.id);
    if (messages.isEmpty) return const SizedBox.shrink();

    final userMsgs = messages.where((m) => m.isUserMessage).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (userMsgs.length < 10) return const SizedBox.shrink();

    final start = userMsgs.first.timestamp;
    final weekCounts = <int, int>{};
    for (final m in userMsgs) {
      final w = m.timestamp.difference(start).inDays ~/ 7;
      weekCounts[w] = (weekCounts[w] ?? 0) + 1;
    }
    if (weekCounts.length < 3) return const SizedBox.shrink();

    final xs = weekCounts.keys.toList()..sort();
    final maxCount = weekCounts.values.reduce((a, b) => a > b ? a : b);
    final barColors = [NeoColors.blue, NeoColors.pink, NeoColors.yellow, NeoColors.lime];

    final trendLabel = momentum != null && !momentum!.isGated
        ? '↑ ${momentum!.displayValueA}'
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: neoBox(bg: NeoColors.surface, offset: 4, radius: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEEKLY MESSAGES',
                  style: neoLabel(10).copyWith(letterSpacing: 0.4)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: NeoColors.lime,
                  border: Border.all(color: NeoColors.ink, width: 2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(trendLabel, style: neoLabel(11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: xs.asMap().entries.map((e) {
                final w = e.value;
                final count = weekCounts[w] ?? 0;
                final h = maxCount > 0 ? count / maxCount : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: (h * 80).clamp(4, 80),
                      decoration: BoxDecoration(
                        color: barColors[e.key % barColors.length],
                        border: Border.all(color: NeoColors.ink, width: 2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('wk 1', style: neoBody(9, color: NeoColors.ink.withValues(alpha: 0.5))),
              Text('now', style: neoBody(9, color: NeoColors.ink.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }
}
