import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../domain/models/analysis_run.dart';
import '../../../domain/models/metric_result.dart';

class BalanceCard extends StatelessWidget {
  final AnalysisRun run;
  final MetricResult? balance;
  final MetricResult? investment;
  final VoidCallback onTap;
  const BalanceCard({
    super.key,
    required this.run,
    required this.balance,
    this.investment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = balance?.displayValueA ?? '—';
    final pctA = _parseRatio(investment?.valueA);
    final pctB = 1 - pctA;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: neoBox(bg: NeoColors.surface, offset: 5, radius: 8),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 8, color: NeoColors.blue),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BALANCE',
                      style: neoLabel(10, color: NeoColors.ink.withValues(alpha: 0.55))),
                  const SizedBox(height: 4),
                  Text(score, style: neoDisplay(38).copyWith(height: 1)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        border: Border.all(color: NeoColors.ink, width: 2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            flex: (pctA * 100).round(),
                            child: Container(color: NeoColors.blue),
                          ),
                          Flexible(
                            flex: (pctB * 100).round().clamp(1, 100),
                            child: Container(color: NeoColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${(pctA * 100).round()} ${run.personA.split(' ').first} / '
                    '${(pctB * 100).round()} ${run.personB.split(' ').first}',
                    style: neoBody(10, color: NeoColors.ink.withValues(alpha: 0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _parseRatio(double? v) {
    if (v == null) return 0.5;
    return v.clamp(0.0, 1.0);
  }
}
