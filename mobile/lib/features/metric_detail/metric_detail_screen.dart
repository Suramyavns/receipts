import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../data/repository.dart';
import '../../domain/models/analysis_run.dart';
import '../../domain/models/metric_result.dart';
import '../../shared/widgets/neo_bubble.dart';
import '../../shared/widgets/neo_card.dart';

const _metricDescriptions = <String, String>{
  MK.messageShare: 'Fraction of all messages sent by each person (system messages excluded).',
  MK.wordShare: 'Fraction of all words written by each person.',
  MK.avgMessageLength: 'Mean words per text message (media and empty messages excluded).',
  MK.emojiRate: 'Emojis sent per message. Grapheme-correct — ZWJ sequences and skin tones count as one.',
  MK.mediaShare: 'Fraction of all media items (photos, videos, voice notes, stickers…) sent.',
  MK.deletedRate: 'Fraction of messages that were deleted or edited.',
  MK.replyLatency: 'Median time from the other person\'s last message to this person\'s first reply. Within-session only — overnight gaps excluded.',
  MK.initiationRatio: 'Fraction of conversation sessions started by each person. A session begins after a gap longer than the adaptive threshold.',
  MK.doubleTextRate: 'Fraction of messages sent when the previous message was also theirs (burst-filtered: messages within 30 s of each other count as one thought).',
  MK.lastWordRatio: 'Fraction of sessions where each person sent the final message.',
  MK.silenceBreakerRatio: 'Who breaks the silence after gaps of 2+ days.',
  MK.ghostRate: 'Fraction of questions (messages containing "?") that went unanswered within the same session.',
  MK.backForthDensity: 'Speaker switches divided by total messages. High = rapid volley; low = one person monologuing.',
  MK.momentumTrend: 'Slope of a linear regression on weekly message volume, plus recent-30d average vs all-time average.',
  MK.questionRate: 'Fraction of messages that contain a question mark (URLs excluded).',
  MK.laughterRate: 'Fraction of messages containing laughter markers (haha, lol, lmao, 😂, etc.).',
  MK.affectionIndex: 'Fraction of messages containing affection tokens (love, miss you, ❤️, pet names, etc.).',
  MK.investmentIndex: 'Equal-weighted mean of each person\'s share across message count, word count, initiation, and question rate.',
  MK.balanceScore: '100 = perfectly even; 0 = entirely one-sided. Formula: (1 − 2·|Investment(A) − 0.5|) × 100.',
  MK.pursuitGap: 'Standardised mean of five "keenness" signals: reply speed, initiation, double-texts, question rate, silence-breaking. Positive = A is keener.',
  MK.reciprocityIndex: 'Blend of balanced initiation and high back-and-forth density. 100 = real dialogue.',
  MK.relationshipHealth: 'Composite of Balance, Reciprocity, and Momentum. Thriving / Steady / Cooling.',
};

class MetricDetailScreen extends StatelessWidget {
  final AnalysisRun run;
  final MetricResult result;

  const MetricDetailScreen({super.key, required this.run, required this.result});

  @override
  Widget build(BuildContext context) {
    final evidenceMsgs = Repository.getMessagesByIds(run.id, result.evidenceMessageIds);
    final description = _metricDescriptions[result.metricKey] ?? '';

    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(
        title: Text(_label(result.metricKey),
            style: neoHeadline(18)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Number ────────────────────────────────────────────────
                  _NumberRow(run: run, result: result),
                  const SizedBox(height: 12),

                  // ── Summary ───────────────────────────────────────────────
                  if (result.summaryLine.isNotEmpty) ...[
                    NeoCard(
                      bg: NeoColors.lime,
                      child: Text(result.summaryLine, style: neoBody(14)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Confidence ────────────────────────────────────────────
                  _ConfidenceChip(confidence: result.confidence),
                  const SizedBox(height: 16),

                  // ── How computed ──────────────────────────────────────────
                  if (description.isNotEmpty) ...[
                    _Expander(
                      label: 'How this is computed',
                      child: Text(description, style: neoBody(13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Evidence header ───────────────────────────────────────
                  if (evidenceMsgs.isNotEmpty) ...[
                    Row(children: [
                      Container(width: 4, height: 20, color: NeoColors.ink),
                      const SizedBox(width: 8),
                      Text('Key message indicators', style: neoHeadline(16)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      '${evidenceMsgs.length} messages that drove this metric.',
                      style: neoBody(12, color: NeoColors.ink.withValues(alpha: 0.5)),
                    ),
                  ] else if (!result.isGated) ...[
                    Text('No specific messages to show for this metric.',
                        style: neoBody(13,
                            color: NeoColors.ink.withValues(alpha: 0.5))),
                  ],
                ],
              ),
            ),
          ),

          // ── Evidence bubbles ───────────────────────────────────────────────
          if (evidenceMsgs.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final msg = evidenceMsgs[i];
                  final isA = msg.sender == run.personA;
                  return NeoBubble(
                    message: msg,
                    isPersonA: isA,
                    accentA: NeoColors.blue,
                    accentB: NeoColors.pink,
                  );
                },
                childCount: evidenceMsgs.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  static String _label(String key) {
    const labels = {
      MK.messageShare: 'Message Share',
      MK.wordShare: 'Word Share',
      MK.avgMessageLength: 'Avg Message Length',
      MK.emojiRate: 'Emoji Rate',
      MK.mediaShare: 'Media Share',
      MK.deletedRate: 'Deleted / Edited Rate',
      MK.replyLatency: 'Reply Latency',
      MK.initiationRatio: 'Initiation Ratio',
      MK.doubleTextRate: 'Double-Text Rate',
      MK.lastWordRatio: 'Last-Word Ratio',
      MK.silenceBreakerRatio: 'Silence Breaker',
      MK.ghostRate: 'Ghost Rate',
      MK.backForthDensity: 'Back-and-Forth Density',
      MK.momentumTrend: 'Momentum / Trend',
      MK.questionRate: 'Question Rate',
      MK.laughterRate: 'Laughter Rate',
      MK.affectionIndex: 'Affection Index',
      MK.investmentIndex: 'Investment Index',
      MK.balanceScore: 'Balance Score',
      MK.pursuitGap: 'Pursuit Gap',
      MK.reciprocityIndex: 'Reciprocity Index',
      MK.relationshipHealth: 'Relationship Health',
    };
    return labels[key] ?? key;
  }
}

class _NumberRow extends StatelessWidget {
  final AnalysisRun run;
  final MetricResult result;
  const _NumberRow({required this.run, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.isGated) {
      return NeoCard(
        bg: NeoColors.surface,
        child: Text('Not enough data to compute this metric.',
            style: neoBody(14)),
      );
    }
    if (result.displayValueB.isEmpty) {
      return NeoCard(
        bg: NeoColors.yellow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.displayValueA, style: neoDisplay(36)),
            Text(result.summaryLine, style: neoBody(13)),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _NumCard(
            name: run.personA,
            value: result.displayValueA,
            accent: NeoColors.blue,
            isWinner: result.winner == MetricWinner.personA,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NumCard(
            name: run.personB,
            value: result.displayValueB,
            accent: NeoColors.pink,
            isWinner: result.winner == MetricWinner.personB,
          ),
        ),
      ],
    );
  }
}

class _NumCard extends StatelessWidget {
  final String name, value;
  final Color accent;
  final bool isWinner;
  const _NumCard(
      {required this.name,
      required this.value,
      required this.accent,
      required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      bg: isWinner ? accent.withValues(alpha: 0.2) : NeoColors.cardBg,
      offset: isWinner ? 5 : 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: accent,
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: neoBody(11)),
          ),
          const SizedBox(height: 6),
          Text(value, style: neoDisplay(28)),
          if (isWinner)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: NeoColors.lime,
                child: Text('winner', style: neoBody(10)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  final MetricConfidence confidence;
  const _ConfidenceChip({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (confidence) {
      MetricConfidence.ok => ('High confidence', NeoColors.lime),
      MetricConfidence.low => ('Low data — treat as indicative', NeoColors.yellow),
      MetricConfidence.na => ('Insufficient data', NeoColors.surface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: NeoColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(label, style: neoBody(12)),
    );
  }
}

class _Expander extends StatefulWidget {
  final String label;
  final Widget child;
  const _Expander({required this.label, required this.child});

  @override
  State<_Expander> createState() => _ExpanderState();
}

class _ExpanderState extends State<_Expander> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Expanded(
                    child: Text(widget.label, style: neoHeadline(13))),
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                    size: 18),
              ],
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 8),
            widget.child,
          ],
        ],
      ),
    );
  }
}
