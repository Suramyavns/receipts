import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../domain/models/analysis_run.dart';
import '../../../domain/models/metric_result.dart';

class PursuitCard extends StatelessWidget {
  final AnalysisRun run;
  final MetricResult? pursuit;
  final VoidCallback onTap;
  const PursuitCard({super.key, required this.run, required this.pursuit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final valA = pursuit?.displayValueA ?? '—';
    final winner = pursuit?.winner;
    final name = winner == MetricWinner.personA
        ? run.personA.split(' ').first.toUpperCase()
        : winner == MetricWinner.personB
            ? run.personB.split(' ').first.toUpperCase()
            : '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: neoBox(bg: NeoColors.surface, offset: 5, radius: 8),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 8, color: NeoColors.pink),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PURSUIT GAP',
                      style: neoLabel(10, color: NeoColors.ink.withValues(alpha: 0.55))),
                  const SizedBox(height: 6),
                  Text(name, style: neoDisplay(30).copyWith(height: 1)),
                  Text(valA, style: neoDisplay(20).copyWith(height: 1.1)),
                  const SizedBox(height: 8),
                  Text('is a touch more into it',
                      style: neoBody(10, color: NeoColors.ink.withValues(alpha: 0.6)),
                      maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
