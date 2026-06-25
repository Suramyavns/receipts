import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../app/theme/tokens.dart';
import '../../data/repository.dart';
import '../../domain/insight/insight_generator.dart';
import '../../domain/metrics/metrics_runner.dart';
import '../../domain/models/analysis_run.dart';
import '../../domain/models/metric_result.dart';
import '../../domain/models/run_message.dart';
import '../metric_detail/metric_detail_screen.dart';
import 'widgets/balance_card.dart';
import 'widgets/group_stats_section.dart';
import 'widgets/health_hero_card.dart';
import 'widgets/momentum_chart.dart';
import 'widgets/participant_filter_sheet.dart';
import 'widgets/pursuit_card.dart';
import 'widgets/the_read_card.dart';
import 'widgets/two_col_grid.dart';
import '../../shared/widgets/nav_button.dart';
import '../../shared/widgets/section_label.dart';

final _yearFmt = DateFormat('MMM d, yyyy');

class AnalysisDetailScreen extends StatefulWidget {
  final AnalysisRun run;
  final bool startGroupMode;

  const AnalysisDetailScreen({
    super.key,
    required this.run,
    this.startGroupMode = false,
  });

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  late Map<String, MetricResult> _metrics;
  late String _personA;
  late String _personB;
  late Set<String> _filteredParticipants;
  List<RunMessage>? _messages;
  bool _recomputing = false;

  @override
  void initState() {
    super.initState();
    _metrics = Repository.getMetricMap(widget.run.id);
    _personA = widget.run.personA;
    _personB = widget.run.personB;

    if (widget.run.isGroup &&
        (widget.startGroupMode || widget.run.participants.length > 2)) {
      _filteredParticipants = Set.from(widget.run.participants);
      _loadMessages();
    } else {
      _filteredParticipants = {widget.run.personA, widget.run.personB};
    }
  }

  void _loadMessages() {
    _messages ??= Repository.getMessages(widget.run.id);
  }

  bool get _isGroupMode => _filteredParticipants.length != 2;

  bool get _usingStoredMetrics =>
      _personA == widget.run.personA && _personB == widget.run.personB;

  String get _headerTitle {
    if (_isGroupMode) {
      if (_filteredParticipants.length == widget.run.participants.length) {
        return widget.run.chatTitle.toUpperCase();
      }
      return '${_filteredParticipants.length} PEOPLE';
    }
    return '${_personA.toUpperCase()} & ${_personB.toUpperCase()}';
  }

  String get _headerSubtitle {
    if (_isGroupMode) {
      return '${_filteredParticipants.length} of ${widget.run.participants.length} people';
    }
    return '${_compact(widget.run.messageCount)} messages';
  }

  AnalysisRun get _displayRun => _usingStoredMetrics
      ? widget.run
      : widget.run.copyWith(personA: _personA, personB: _personB);

  void _applyFilter(Set<String> selected) {
    _loadMessages();
    if (selected.length == 2) {
      final pair = selected.toList();
      final newA = pair[0];
      final newB = pair[1];
      final sameAsStored =
          (newA == widget.run.personA && newB == widget.run.personB) ||
          (newA == widget.run.personB && newB == widget.run.personA);
      setState(() {
        _filteredParticipants = selected;
        _personA = newA;
        _personB = newB;
        if (sameAsStored) {
          _metrics = Repository.getMetricMap(widget.run.id);
        }
      });
      if (!sameAsStored) _recompute();
    } else {
      setState(() => _filteredParticipants = selected);
    }
  }

  void _openPeopleFilter(BuildContext context) {
    _loadMessages();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ParticipantFilterSheet(
          allParticipants: widget.run.participants,
          selected: _filteredParticipants,
          onApply: _applyFilter,
        ),
      ),
    );
  }

  Future<void> _recompute() async {
    if (_recomputing) return;
    setState(() => _recomputing = true);
    _loadMessages();
    final sessions = Repository.getSessions(widget.run.id);
    final fresh = await MetricsRunner.run(
      runId: widget.run.id,
      personA: _personA,
      personB: _personB,
      messages: _messages!,
      sessions: sessions,
    );
    if (_usingStoredMetrics) {
      await Repository.saveMetrics(widget.run.id, fresh);
    }
    if (mounted) {
      setState(() {
        _metrics = {for (final m in fresh) m.metricKey: m};
        _recomputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.cream,
      body: CustomPaint(
        painter: const DotGridPainter(),
        child: SafeArea(
          child: Column(
            children: [
              // ── Sticky header ───────────────────────────────────────────────
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
                            _headerTitle,
                            style: neoDisplay(17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(_headerSubtitle,
                              style: neoBody(10,
                                  color: NeoColors.ink.withValues(alpha: 0.55))),
                        ],
                      ),
                    ),
                    if (widget.run.isGroup) ...[
                      _PeopleButton(
                        totalCount: widget.run.participants.length,
                        selectedCount: _filteredParticipants.length,
                        onTap: () => _openPeopleFilter(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (!_isGroupMode) ...[
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
                        onTap: () => _copyStats(context, _displayRun, _metrics),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: neoBox(
                              bg: NeoColors.surface, offset: 3, radius: 6, borderWidth: 2),
                          child: const Icon(Icons.copy_outlined, size: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(color: NeoColors.ink, thickness: 3, height: 3),

              // ── Scrollable content ──────────────────────────────────────────
              Expanded(
                child: _isGroupMode ? _buildGroupView() : _buildPairView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupView() {
    final msgs = _messages ?? [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        GroupStatsSection(
          messages: msgs,
          participants: _filteredParticipants.toList(),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildPairView() {
    final insights = InsightGenerator.generate(_personA, _personB, _metrics);
    final health = _metrics[MK.relationshipHealth];
    final balance = _metrics[MK.balanceScore];
    final investment = _metrics[MK.investmentIndex];
    final pursuit = _metrics[MK.pursuitGap];
    final momentum = _metrics[MK.momentumTrend];

    final readText = insights.isNotEmpty
        ? insights.take(3).map((i) => i.text).join(' ')
        : 'Not enough data to generate a narrative yet.';

    return _recomputing
        ? const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: NeoColors.ink),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
            children: [
              HealthHeroCard(run: _displayRun, health: health, momentum: momentum),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(
                    child: BalanceCard(
                        run: _displayRun,
                        balance: balance,
                        investment: investment,
                        onTap: () => _openMetric(context, _displayRun, balance))),
                const SizedBox(width: 14),
                Expanded(
                    child: PursuitCard(
                        run: _displayRun,
                        pursuit: pursuit,
                        onTap: () => _openMetric(context, _displayRun, pursuit))),
              ]),
              const SizedBox(height: 14),

              TheReadCard(text: readText),
              const SizedBox(height: 14),

              const SectionLabel('VOLUME'),
              const SizedBox(height: 11),
              TwoColGrid(run: _displayRun, metrics: _metrics, keys: const [
                MK.messageShare,
                MK.wordShare,
                MK.avgMessageLength,
                MK.emojiRate,
              ]),
              const SizedBox(height: 14),

              const SectionLabel('TIMING'),
              const SizedBox(height: 11),
              TwoColGrid(run: _displayRun, metrics: _metrics, keys: const [
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
              TwoColGrid(run: _displayRun, metrics: _metrics, keys: const [
                MK.laughterRate,
                MK.questionRate,
                MK.affectionIndex,
                MK.emojiDiversity,
              ]),
              const SizedBox(height: 14),

              const SectionLabel('BIG PICTURE'),
              const SizedBox(height: 11),
              TwoColGrid(run: _displayRun, metrics: _metrics, keys: const [
                MK.reciprocityIndex,
                MK.investmentIndex,
                MK.dryTexterScore,
              ]),
              const SizedBox(height: 14),

              const SectionLabel('MOMENTUM'),
              const SizedBox(height: 11),
              MomentumChart(run: _displayRun, momentum: momentum),
              const SizedBox(height: 6),
            ],
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

// ── People filter button ───────────────────────────────────────────────────────

class _PeopleButton extends StatelessWidget {
  final int totalCount;
  final int selectedCount;
  final VoidCallback onTap;

  const _PeopleButton({
    required this.totalCount,
    required this.selectedCount,
    required this.onTap,
  });

  bool get _isFiltered => selectedCount != totalCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: neoBox(
          bg: _isFiltered ? NeoColors.yellow : NeoColors.surface,
          offset: 3,
          radius: 6,
          borderWidth: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_outlined, size: 15),
            const SizedBox(width: 5),
            Text(
              _isFiltered ? '$selectedCount/$totalCount' : 'ALL',
              style: neoLabel(11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
