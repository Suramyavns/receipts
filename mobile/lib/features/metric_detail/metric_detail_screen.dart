import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../data/repository.dart';
import '../../domain/models/analysis_run.dart';
import '../../domain/models/metric_result.dart';
import '../../shared/widgets/nav_button.dart';
import '../../shared/widgets/neo_bubble.dart';
import 'widgets/metric_hero_card.dart';

class MetricDetailScreen extends StatelessWidget {
  final AnalysisRun run;
  final MetricResult result;

  const MetricDetailScreen({super.key, required this.run, required this.result});

  @override
  Widget build(BuildContext context) {
    final evidenceMsgs = Repository.getMessagesByIds(run.id, result.evidenceMessageIds);
    final label = _label(result.metricKey);
    final conf = _confLabel(result.confidence);

    return Scaffold(
      backgroundColor: NeoColors.cream,
      body: CustomPaint(
        painter: const DotGridPainter(),
        child: SafeArea(
          child: Column(
            children: [
              // ── Sticky header ────────────────────────────────────────────
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
                          Text(label,
                              style: neoDisplay(17),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text('key metric indicators',
                              style: neoBody(10,
                                  color: NeoColors.ink.withValues(alpha: 0.55))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: NeoColors.ink, thickness: 3, height: 3),

              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MetricHeroCard(run: run, result: result, conf: conf),
                          const SizedBox(height: 14),

                          // Verdict / conclusion
                          if (!result.isGated && result.summaryLine.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration:
                                  neoBox(bg: NeoColors.yellow, offset: 4, radius: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('THE VERDICT',
                                      style: neoLabel(11).copyWith(letterSpacing: 1)),
                                  const SizedBox(height: 8),
                                  Text(result.summaryLine,
                                      style: neoBody(15).copyWith(
                                          height: 1.5, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Receipts header
                          if (evidenceMsgs.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: NeoColors.ink,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('THE RECEIPTS',
                                  style: neoLabel(13, color: Colors.white)
                                      .copyWith(letterSpacing: 1)),
                            ),
                            const SizedBox(height: 8),
                          ] else if (!result.isGated) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration:
                                  neoBox(bg: NeoColors.surface, offset: 4, radius: 6),
                              child: Text(
                                'No specific messages to show for this metric.',
                                style: neoBody(13,
                                    color: NeoColors.ink.withValues(alpha: 0.55)),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),

                    // Bubble list
                    ...evidenceMsgs.map((msg) {
                      final isA = msg.sender == run.personA;
                      return NeoBubble(
                        message: msg,
                        isPersonA: isA,
                        accentA: NeoColors.blue,
                        accentB: NeoColors.pink,
                      );
                    }),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(String key) {
    const labels = {
      MK.messageShare:       'Message Share',
      MK.wordShare:          'Word Share',
      MK.avgMessageLength:   'Avg Message Length',
      MK.emojiRate:          'Emoji Rate',
      MK.mediaShare:         'Media Share',
      MK.deletedRate:        'Deleted / Edited',
      MK.replyLatency:       'Reply Speed',
      MK.initiationRatio:    'Who Texts First',
      MK.doubleTextRate:     'Double-Texts',
      MK.lastWordRatio:      'Last Word',
      MK.silenceBreakerRatio:'Breaks the Silence',
      MK.ghostRate:          'Ghost Rate',
      MK.backForthDensity:   'Back-and-Forth',
      MK.momentumTrend:      'Momentum',
      MK.questionRate:       'Question Rate',
      MK.laughterRate:       'Laughter',
      MK.affectionIndex:     'Affection',
      MK.investmentIndex:    'Investment Index',
      MK.balanceScore:       'Balance Score',
      MK.pursuitGap:         'Pursuit Gap',
      MK.reciprocityIndex:   'Reciprocity',
      MK.relationshipHealth: 'Relationship Health',
    };
    return labels[key] ?? key;
  }

  static String _confLabel(MetricConfidence c) {
    return switch (c) {
      MetricConfidence.ok => 'HIGH CONFIDENCE',
      MetricConfidence.low => 'LOW SAMPLE',
      MetricConfidence.na => 'INSUFFICIENT DATA',
    };
  }
}
