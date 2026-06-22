import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../domain/models/analysis_run.dart';
import '../../../domain/models/metric_result.dart';

class HealthHeroCard extends StatelessWidget {
  final AnalysisRun run;
  final MetricResult? health;
  final MetricResult? momentum;
  const HealthHeroCard({super.key, required this.run, required this.health, required this.momentum});

  @override
  Widget build(BuildContext context) {
    final score = health?.displayValueA ?? '—';
    final healthB = health?.displayValueB ?? '';
    final trendLabel = _trendLabel(momentum);
    final heroBg = _heroBg(healthB);
    final heroInk = heroBg == NeoColors.blue ? Colors.white : NeoColors.ink;

    return Transform.rotate(
      angle: -0.017453,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: heroBg,
          border: Border.all(color: NeoColors.ink, width: 3),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: NeoColors.ink, offset: Offset(6, 6), blurRadius: 0),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RELATIONSHIP HEALTH',
                    style: neoLabel(11, color: heroInk).copyWith(letterSpacing: 1)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NeoColors.ink,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(trendLabel,
                      style: neoLabel(11, color: Colors.white).copyWith(letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: score,
                      style: neoDisplay(58).copyWith(height: 0.95, color: heroInk)),
                  TextSpan(
                      text: '/100',
                      style: neoDisplay(20).copyWith(color: heroInk)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              healthB.isNotEmpty ? healthB : 'Relationship overview',
              style: neoBody(13, color: heroInk).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  static String _trendLabel(MetricResult? m) {
    if (m == null || m.isGated) return 'STEADY';
    final v = double.tryParse(m.displayValueA.replaceAll('%', '')) ?? 0;
    if (v > 5) return 'WARMING 🔥';
    if (v < -5) return 'COOLING ❄️';
    return 'STEADY 〰';
  }

  static Color _heroBg(String healthLabel) {
    final l = healthLabel.toLowerCase();
    if (l.contains('thriv')) return NeoColors.lime;
    if (l.contains('warm')) return NeoColors.yellow;
    if (l.contains('cool')) return NeoColors.blue;
    return NeoColors.lime;
  }
}
