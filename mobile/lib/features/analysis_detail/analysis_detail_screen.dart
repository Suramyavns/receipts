import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../app/theme/tokens.dart';
import '../../data/repository.dart';
import '../../domain/insight/insight_generator.dart';
import '../../domain/models/analysis_run.dart';
import '../../domain/models/metric_result.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_chart_frame.dart';
import '../../shared/widgets/neo_stat_card.dart';
import '../metric_detail/metric_detail_screen.dart';

final _dateFmt = DateFormat('MMM d, yyyy');

class AnalysisDetailScreen extends StatelessWidget {
  final AnalysisRun run;

  const AnalysisDetailScreen({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final metrics = Repository.getMetricMap(run.id);
    final insights = InsightGenerator.generate(run.personA, run.personB, metrics);

    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(
        title: Text(run.chatTitle,
            style: neoHeadline(18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _share(run, metrics),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          _HeaderCard(run: run, metrics: metrics),
          const SizedBox(height: 12),

          // ── Rational summary ───────────────────────────────────────────────
          if (insights.isNotEmpty) ...[
            _InsightPanel(insights: insights, metrics: metrics, run: run),
            const SizedBox(height: 16),
          ],

          // ── Volume ─────────────────────────────────────────────────────────
          _SectionHeader('Volume'),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.messageShare, MK.wordShare], metrics: metrics),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.avgMessageLength, MK.emojiRate], metrics: metrics),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.mediaShare, MK.deletedRate], metrics: metrics),
          const SizedBox(height: 16),

          // ── Timing ─────────────────────────────────────────────────────────
          _SectionHeader('Timing & Rhythm'),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.replyLatency, MK.initiationRatio], metrics: metrics),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.doubleTextRate, MK.lastWordRatio], metrics: metrics),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.silenceBreakerRatio, MK.ghostRate], metrics: metrics),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.backForthDensity, MK.momentumTrend], metrics: metrics),
          const SizedBox(height: 8),
          _TrendChart(run: run),
          const SizedBox(height: 16),

          // ── Tone ───────────────────────────────────────────────────────────
          _SectionHeader('Tone & Content'),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.questionRate, MK.laughterRate], metrics: metrics),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.affectionIndex], metrics: metrics),
          const SizedBox(height: 16),

          // ── Composites ─────────────────────────────────────────────────────
          _SectionHeader('The Big Picture'),
          const SizedBox(height: 8),
          _BigCompositeCard(run: run, metrics: metrics),
          const SizedBox(height: 8),
          _MetricRow(run: run, keys: [MK.reciprocityIndex, MK.balanceScore], metrics: metrics),

          // ── Date range ─────────────────────────────────────────────────────
          const SizedBox(height: 20),
          Center(
            child: Text(
              '${_dateFmt.format(run.dateRangeStart)} → ${_dateFmt.format(run.dateRangeEnd)}',
              style: neoBody(12, color: NeoColors.ink.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Everything computed on your phone.',
              style: neoBody(11, color: NeoColors.ink.withValues(alpha: 0.35)),
            ),
          ),
        ],
      ),
    );
  }

  void _share(AnalysisRun run, Map<String, MetricResult> metrics) {
    final buf = StringBuffer();
    buf.writeln('📊 ChatStat: ${run.personA} vs ${run.personB}');
    final health = metrics[MK.relationshipHealth];
    if (health != null && !health.isGated) buf.writeln('Health: ${health.displayValueA}');
    final rl = metrics[MK.replyLatency];
    if (rl != null && !rl.isGated) {
      buf.writeln('Reply time: ${run.personA} ${rl.displayValueA} · ${run.personB} ${rl.displayValueB}');
    }
    buf.writeln('${run.messageCount} messages · ${_dateFmt.format(run.dateRangeStart)}–${_dateFmt.format(run.dateRangeEnd)}');
    Clipboard.setData(ClipboardData(text: buf.toString()));
  }
}

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final AnalysisRun run;
  final Map<String, MetricResult> metrics;
  const _HeaderCard({required this.run, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final health = metrics[MK.relationshipHealth];
    final pursuit = metrics[MK.pursuitGap];

    return NeoCard(
      bg: NeoColors.yellow,
      offset: 5,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Avatar(name: run.personA, accent: NeoColors.blue),
              Text('vs', style: neoDisplay(20)),
              _Avatar(name: run.personB, accent: NeoColors.pink),
            ],
          ),
          if (health != null && !health.isGated) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: neoBox(bg: NeoColors.cream),
              child: Text(
                '${health.displayValueA} — ${health.displayValueB}',
                style: neoHeadline(16),
              ),
            ),
          ],
          if (pursuit != null && !pursuit.isGated) ...[
            const SizedBox(height: 8),
            Text(pursuit.summaryLine,
                style: neoBody(13), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color accent;
  const _Avatar({required this.name, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
          border: Border.all(color: NeoColors.ink, width: 2),
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: neoDisplay(22, color: NeoColors.ink),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(name.split(' ').first,
          style: neoHeadline(14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]);
  }
}

// ── Insight panel ─────────────────────────────────────────────────────────────

class _InsightPanel extends StatelessWidget {
  final List<InsightLine> insights;
  final Map<String, MetricResult> metrics;
  final AnalysisRun run;
  const _InsightPanel({required this.insights, required this.metrics, required this.run});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      bg: NeoColors.lime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The receipts say…', style: neoHeadline(14)),
          const SizedBox(height: 10),
          ...insights.map((ins) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    final r = metrics[ins.metricKey];
                    if (r != null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MetricDetailScreen(run: run, result: r)));
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('→ ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(ins.text, style: neoBody(14))),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 4, height: 20, color: NeoColors.ink),
      const SizedBox(width: 8),
      Text(title, style: neoHeadline(16)),
    ]);
  }
}

// ── Metric row ────────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  final AnalysisRun run;
  final List<String> keys;
  final Map<String, MetricResult> metrics;
  const _MetricRow({required this.run, required this.keys, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: keys.map((k) {
        final r = metrics[k];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: k != keys.last ? 8 : 0),
            child: r == null
                ? const SizedBox.shrink()
                : NeoStatCard(
                    label: _label(k),
                    valueA: r.isGated ? '—' : r.displayValueA,
                    valueB: r.isGated ? '—' : r.displayValueB,
                    nameA: run.personA,
                    nameB: run.personB,
                    confidenceLabel: r.confidence == MetricConfidence.low ? 'low data' : null,
                    onTap: r.isGated
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MetricDetailScreen(run: run, result: r)),
                            ),
                  ),
          ),
        );
      }).toList(),
    );
  }

  static String _label(String key) {
    const labels = {
      MK.messageShare: 'Message share',
      MK.wordShare: 'Word share',
      MK.avgMessageLength: 'Avg length',
      MK.emojiRate: 'Emoji rate',
      MK.mediaShare: 'Media share',
      MK.deletedRate: 'Deleted/edited',
      MK.replyLatency: 'Reply time',
      MK.initiationRatio: 'Who starts',
      MK.doubleTextRate: 'Double-texts',
      MK.lastWordRatio: 'Last word',
      MK.silenceBreakerRatio: 'Silence breaker',
      MK.ghostRate: 'Ghost rate',
      MK.backForthDensity: 'Back-and-forth',
      MK.momentumTrend: 'Momentum',
      MK.questionRate: 'Questions',
      MK.laughterRate: 'Laughter',
      MK.affectionIndex: 'Affection',
      MK.investmentIndex: 'Investment',
      MK.balanceScore: 'Balance',
      MK.pursuitGap: 'Pursuit gap',
      MK.reciprocityIndex: 'Reciprocity',
      MK.relationshipHealth: 'Health',
    };
    return labels[key] ?? key;
  }
}

// ── Big composite card ────────────────────────────────────────────────────────

class _BigCompositeCard extends StatelessWidget {
  final AnalysisRun run;
  final Map<String, MetricResult> metrics;
  const _BigCompositeCard({required this.run, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final pursuit = metrics[MK.pursuitGap];
    final investment = metrics[MK.investmentIndex];

    return NeoCard(
      bg: NeoColors.blue.withValues(alpha: 0.08),
      child: Row(
        children: [
          Expanded(
            child: _CompositeHalf(
              label: 'Investment',
              valueA: investment?.displayValueA ?? '—',
              valueB: investment?.displayValueB ?? '—',
              nameA: run.personA,
              nameB: run.personB,
              accentA: NeoColors.blue,
              accentB: NeoColors.pink,
              onTap: investment != null && !investment.isGated
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MetricDetailScreen(run: run, result: investment)))
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CompositeHalf(
              label: 'Pursuit gap',
              valueA: pursuit?.displayValueA ?? '—',
              valueB: pursuit?.displayValueB ?? '—',
              nameA: run.personA,
              nameB: run.personB,
              accentA: NeoColors.blue,
              accentB: NeoColors.pink,
              onTap: pursuit != null && !pursuit.isGated
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MetricDetailScreen(run: run, result: pursuit)))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompositeHalf extends StatelessWidget {
  final String label, valueA, valueB, nameA, nameB;
  final Color accentA, accentB;
  final VoidCallback? onTap;

  const _CompositeHalf({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.nameA,
    required this.nameB,
    required this.accentA,
    required this.accentB,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: neoBody(11, color: NeoColors.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          Row(children: [
            _Pill(name: nameA, value: valueA, accent: accentA),
            const SizedBox(width: 4),
            _Pill(name: nameB, value: valueB, accent: accentB),
          ]),
          if (onTap != null) ...[
            const SizedBox(height: 4),
            Text('See receipts →',
                style: neoBody(10, color: NeoColors.ink.withValues(alpha: 0.45))),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String name, value;
  final Color accent;
  const _Pill({required this.name, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name,
          style: neoBody(10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: accent,
        child: Text(value, style: neoHeadline(16)),
      ),
    ]);
  }
}

// ── Trend chart ───────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final AnalysisRun run;
  const _TrendChart({required this.run});

  @override
  Widget build(BuildContext context) {
    final messages = Repository.getMessages(run.id);
    if (messages.isEmpty) return const SizedBox.shrink();

    final userMsgs = messages.where((m) => m.isUserMessage).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (userMsgs.isEmpty) return const SizedBox.shrink();

    final start = userMsgs.first.timestamp;
    final weekCounts = <int, int>{};
    for (final m in userMsgs) {
      final w = m.timestamp.difference(start).inDays ~/ 7;
      weekCounts[w] = (weekCounts[w] ?? 0) + 1;
    }
    if (weekCounts.length < 3) return const SizedBox.shrink();

    final xs = weekCounts.keys.toList()..sort();
    final spots = xs
        .map((w) => FlSpot(w.toDouble(), weekCounts[w]!.toDouble()))
        .toList();

    return NeoChartFrame(
      title: 'Messages per week',
      height: 140,
      chart: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: NeoColors.blue,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: NeoColors.blue.withValues(alpha: 0.12),
              ),
            ),
          ],
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(
            border: const Border(
              bottom: BorderSide(color: NeoColors.ink, width: 2),
              left: BorderSide(color: NeoColors.ink, width: 2),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.round().toString(),
                  style: neoBody(10, color: NeoColors.ink.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
