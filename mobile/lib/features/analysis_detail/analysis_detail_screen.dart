import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../app/theme/tokens.dart';
import '../../data/repository.dart';
import '../../domain/insight/insight_generator.dart';
import '../../domain/models/analysis_run.dart';
import '../../domain/models/metric_result.dart';
import '../metric_detail/metric_detail_screen.dart';
import 'widgets/balance_card.dart';
import 'widgets/health_hero_card.dart';
import 'widgets/momentum_chart.dart';
import 'widgets/pursuit_card.dart';
import 'widgets/the_read_card.dart';
import 'widgets/two_col_grid.dart';
import '../../shared/widgets/nav_button.dart';
import '../../shared/widgets/section_label.dart';

final _yearFmt = DateFormat('MMM d, yyyy');

class AnalysisDetailScreen extends StatelessWidget {
  final AnalysisRun run;
  const AnalysisDetailScreen({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final metrics = Repository.getMetricMap(run.id);
    final insights = InsightGenerator.generate(run.personA, run.personB, metrics);
    final health = metrics[MK.relationshipHealth];
    final balance = metrics[MK.balanceScore];
    final investment = metrics[MK.investmentIndex];
    final pursuit = metrics[MK.pursuitGap];
    final momentum = metrics[MK.momentumTrend];

    final readText = insights.isNotEmpty
        ? insights.take(3).map((i) => i.text).join(' ')
        : 'Not enough data to generate a narrative yet.';

    final exportInfo = '${_compact(run.messageCount)} messages';

    return Scaffold(
      backgroundColor: NeoColors.cream,
      body: CustomPaint(
        painter: const DotGridPainter(),
        child: SafeArea(
          child: Column(
            children: [
              // ── Sticky header ──────────────────────────────────────────────
              Container(
                color: NeoColors.cream,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    NavButton(onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${run.personA.toUpperCase()} & ${run.personB.toUpperCase()}',
                            style: neoDisplay(17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(exportInfo,
                              style: neoBody(10,
                                  color: NeoColors.ink.withValues(alpha: 0.55))),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copyStats(context, run, metrics),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: neoBox(
                            bg: NeoColors.surface, offset: 3, radius: 6, borderWidth: 2),
                        child: const Icon(Icons.copy_outlined, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: NeoColors.ink, thickness: 3, height: 3),

              // ── Scrollable content ─────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                  children: [
                    HealthHeroCard(run: run, health: health, momentum: momentum),
                    const SizedBox(height: 14),

                    Row(children: [
                      Expanded(
                          child: BalanceCard(
                              run: run,
                              balance: balance,
                              investment: investment,
                              onTap: () => _openMetric(context, run, balance))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: PursuitCard(
                              run: run,
                              pursuit: pursuit,
                              onTap: () => _openMetric(context, run, pursuit))),
                    ]),
                    const SizedBox(height: 14),

                    TheReadCard(text: readText),
                    const SizedBox(height: 14),

                    const SectionLabel('VOLUME'),
                    const SizedBox(height: 11),
                    TwoColGrid(run: run, metrics: metrics, keys: const [
                      MK.messageShare,
                      MK.wordShare,
                      MK.avgMessageLength,
                      MK.emojiRate,
                      MK.mediaShare,
                      MK.deletedRate,
                    ]),
                    const SizedBox(height: 14),

                    const SectionLabel('TIMING'),
                    const SizedBox(height: 11),
                    TwoColGrid(run: run, metrics: metrics, keys: const [
                      MK.replyLatency,
                      MK.initiationRatio,
                      MK.doubleTextRate,
                      MK.silenceBreakerRatio,
                      MK.lastWordRatio,
                      MK.ghostRate,
                      MK.backForthDensity,
                    ]),
                    const SizedBox(height: 14),

                    const SectionLabel('TONE'),
                    const SizedBox(height: 11),
                    TwoColGrid(run: run, metrics: metrics, keys: const [
                      MK.laughterRate,
                      MK.questionRate,
                      MK.affectionIndex,
                    ]),
                    const SizedBox(height: 14),

                    const SectionLabel('BIG PICTURE'),
                    const SizedBox(height: 11),
                    TwoColGrid(run: run, metrics: metrics, keys: const [
                      MK.reciprocityIndex,
                      MK.investmentIndex,
                    ]),
                    const SizedBox(height: 14),

                    const SectionLabel('MOMENTUM'),
                    const SizedBox(height: 11),
                    MomentumChart(run: run, momentum: momentum),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMetric(BuildContext context, AnalysisRun run, MetricResult? metric) {
    if (metric == null || metric.isGated) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MetricDetailScreen(run: run, result: metric)));
  }

  void _copyStats(
      BuildContext context, AnalysisRun run, Map<String, MetricResult> metrics) {
    final buf = StringBuffer();
    buf.writeln('Receipts: ${run.personA} & ${run.personB}');
    final health = metrics[MK.relationshipHealth];
    if (health != null && !health.isGated) {
      buf.writeln('Health: ${health.displayValueA}');
    }
    final rl = metrics[MK.replyLatency];
    if (rl != null && !rl.isGated) {
      buf.writeln(
          'Reply: ${run.personA} ${rl.displayValueA} · ${run.personB} ${rl.displayValueB}');
    }
    buf.writeln(
        '${run.messageCount} messages · ${_yearFmt.format(run.dateRangeStart)}–${_yearFmt.format(run.dateRangeEnd)}');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Copied to clipboard', style: neoBody(13, color: NeoColors.ink)),
        backgroundColor: NeoColors.yellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: NeoColors.ink, width: 2),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
