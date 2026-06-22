import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../domain/models/analysis_run.dart';
import '../../../domain/models/metric_result.dart';
import 'bar_row.dart';

class MetricCard extends StatelessWidget {
  final AnalysisRun run;
  final MetricResult result;
  final String label;
  final Color accent;
  final VoidCallback? onTap;
  const MetricCard({
    super.key,
    required this.run,
    required this.result,
    required this.label,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final valA = result.isGated ? '—' : result.displayValueA;
    final valB = result.isGated ? '—' : result.displayValueB;
    final isSingleStat = valB.isEmpty;
    final (pctA, pctB) = isSingleStat ? (0.0, 0.0) : _barWidths(result);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: neoBox(bg: NeoColors.surface, offset: 4, radius: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label + accent dot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(label,
                      style: neoLabel(10).copyWith(letterSpacing: 0.4),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  width: 12,
                  height: 12,
                  color: accent,
                  foregroundDecoration:
                      BoxDecoration(border: Border.all(color: NeoColors.ink, width: 2)),
                ),
              ],
            ),
            const SizedBox(height: 9),

            if (isSingleStat) ...[
              Text(valA,
                  style: neoDisplay(22, color: NeoColors.ink).copyWith(height: 1.0)),
            ] else ...[
              BarRow(
                  name: run.personA.split(' ').first.toUpperCase(),
                  value: valA,
                  pct: pctA,
                  accent: accent),
              const SizedBox(height: 6),
              BarRow(
                  name: run.personB.split(' ').first.toUpperCase(),
                  value: valB,
                  pct: pctB,
                  accent: NeoColors.ink),
            ],
            const SizedBox(height: 9),

            Text(result.summaryLine,
                style: neoBody(10, color: NeoColors.ink.withValues(alpha: 0.55)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),

            if (onTap != null) ...[
              const SizedBox(height: 7),
              const Divider(color: NeoColors.ink, thickness: 2, height: 2),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SEE RECEIPTS', style: neoLabel(10).copyWith(letterSpacing: 0)),
                  Text('→', style: neoBody(14)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Bar widths (A, B) each in 0..1.
  // Share/rate metrics (both 0–1): bar width = displayed percentage.
  // Absolute metrics (values > 1): normalize by sum.
  // Reply latency: absolute seconds, inverted (lower = faster = keener).
  static (double, double) _barWidths(MetricResult r) {
    final a = r.valueA;
    final b = r.valueB;
    if (a == null) return (0.5, 0.5);
    if (b == null) return (a.clamp(0.0, 1.0), (1 - a).clamp(0.0, 1.0));

    if (r.metricKey == MK.replyLatency) {
      final sum = a + b;
      if (sum <= 0) return (0.5, 0.5);
      return ((b / sum).clamp(0.0, 1.0), (a / sum).clamp(0.0, 1.0));
    }

    if (a > 1 || b > 1) {
      final sum = a + b;
      if (sum <= 0) return (0.5, 0.5);
      return ((a / sum).clamp(0.0, 1.0), (b / sum).clamp(0.0, 1.0));
    }

    return (a.clamp(0.0, 1.0), b.clamp(0.0, 1.0));
  }
}
