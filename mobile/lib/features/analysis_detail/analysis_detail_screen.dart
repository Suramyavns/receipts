import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../app/theme/tokens.dart';
import '../../data/repository.dart';
import '../../domain/insight/insight_generator.dart';
import '../../domain/metrics/metrics_runner.dart';
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

class AnalysisDetailScreen extends StatefulWidget {
  final AnalysisRun run;
  const AnalysisDetailScreen({super.key, required this.run});

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  late Map<String, MetricResult> _metrics;
  bool _recomputing = false;

  @override
  void initState() {
    super.initState();
    _metrics = Repository.getMetricMap(widget.run.id);
  }

  Future<void> _recompute() async {
    if (_recomputing) return;
    setState(() => _recomputing = true);
    final messages = Repository.getMessages(widget.run.id);
    final sessions = Repository.getSessions(widget.run.id);
    final fresh = await MetricsRunner.run(
      runId: widget.run.id,
      personA: widget.run.personA,
      personB: widget.run.personB,
      messages: messages,
      sessions: sessions,
    );
    await Repository.saveMetrics(widget.run.id, fresh);
    if (mounted) {
      setState(() {
        _metrics = {for (final m in fresh) m.metricKey: m};
        _recomputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final insights = InsightGenerator.generate(widget.run.personA, widget.run.personB, _metrics);
    final health = _metrics[MK.relationshipHealth];
    final balance = _metrics[MK.balanceScore];
    final investment = _metrics[MK.investmentIndex];
    final pursuit = _metrics[MK.pursuitGap];
    final momentum = _metrics[MK.momentumTrend];

    final readText = insights.isNotEmpty
        ? insights.take(3).map((i) => i.text).join(' ')
        : 'Not enough data to generate a narrative yet.';

    final exportInfo = '${_compact(widget.run.messageCount)} messages';

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
                            '${widget.run.personA.toUpperCase()} & ${widget.run.personB.toUpperCase()}',
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
                      onTap: _recomputing ? null : _recompute,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: neoBox(
                            bg: NeoColors.surface, offset: 3, radius: 6, borderWidth: 2),
                        child: _recomputing
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: NeoColors.ink,
                                ),
                              )
                            : const Icon(Icons.refresh_outlined, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _copyStats(context, widget.run, _metrics),
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
                    HealthHeroCard(run: widget.run, health: health, momentum: momentum),
                    const SizedBox(height: 14),

                    Row(children: [
                      Expanded(
                          child: BalanceCard(
                              run: widget.run,
                              balance: balance,
                              investment: investment,
                              onTap: () => _openMetric(context, widget.run, balance))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: PursuitCard(
                              run: widget.run,
                              pursuit: pursuit,
                              onTap: () => _openMetric(context, widget.run, pursuit))),
                    ]),
                    const SizedBox(height: 14),

                    TheReadCard(text: readText),
                    const SizedBox(height: 14),

                    const SectionLabel('VOLUME'),
                    const SizedBox(height: 11),
                    TwoColGrid(run: widget.run, metrics: _metrics, keys: const [
                      MK.messageShare,
                      MK.wordShare,
                      MK.avgMessageLength,
                      MK.emojiRate,
                    ]),
                    const SizedBox(height: 14),

                    const SectionLabel('TIMING'),
                    const SizedBox(height: 11),
                    TwoColGrid(run: widget.run, metrics: _metrics, keys: const [
                      MK.replyLatency,
                      MK.initiationRatio,
                      MK.doubleTextRate,
                      MK.silenceBreakerRatio,
                      MK.lastWordRatio,
                      MK.ghostRate,
                      MK.backForthDensity,
                      MK.activeHoursOverlap,
                    ]),
                    const SizedBox(height: 14),

                    const SectionLabel('TONE'),
                    const SizedBox(height: 11),
                    TwoColGrid(run: widget.run, metrics: _metrics, keys: const [
                      MK.laughterRate,
                      MK.questionRate,
                      MK.affectionIndex,
                      MK.emojiDiversity,
                    ]),
                    const SizedBox(height: 14),

                    const SectionLabel('BIG PICTURE'),
                    const SizedBox(height: 11),
                    TwoColGrid(run: widget.run, metrics: _metrics, keys: const [
                      MK.reciprocityIndex,
                      MK.investmentIndex,
                      MK.dryTexterScore,
                    ]),
                    const SizedBox(height: 14),

                    const SectionLabel('MOMENTUM'),
                    const SizedBox(height: 11),
                    MomentumChart(run: widget.run, momentum: momentum),
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
