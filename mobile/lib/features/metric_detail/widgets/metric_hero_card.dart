import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../domain/models/analysis_run.dart';
import '../../../domain/models/metric_result.dart';

class MetricHeroCard extends StatelessWidget {
  final AnalysisRun run;
  final MetricResult result;
  final String conf;
  const MetricHeroCard({super.key, required this.run, required this.result, required this.conf});

  @override
  Widget build(BuildContext context) {
    if (result.isGated) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: neoBox(bg: NeoColors.surface, offset: 5, radius: 8),
        child: Text('Not enough data to compute this metric.', style: neoBody(14)),
      );
    }

    final hasB = result.displayValueB.isNotEmpty && result.displayValueB != '—';
    final bigVal = result.displayValueA;
    final sub = hasB
        ? '${run.personA}: ${result.displayValueA} · ${run.personB}: ${result.displayValueB}'
        : result.summaryLine;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: neoBox(bg: NeoColors.blue, offset: 6, radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bigVal,
              style: neoDisplay(52).copyWith(color: Colors.white, height: 0.95)),
          const SizedBox(height: 4),
          Text(sub,
              style: neoBody(13, color: Colors.white).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: NeoColors.ink, width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('✓  $conf', style: neoLabel(10).copyWith(letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}
