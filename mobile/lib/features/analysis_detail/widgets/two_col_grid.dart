import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../domain/models/analysis_run.dart';
import '../../../domain/models/metric_result.dart';
import '../../metric_detail/metric_detail_screen.dart';
import 'metric_card.dart';

class TwoColGrid extends StatelessWidget {
  final AnalysisRun run;
  final Map<String, MetricResult> metrics;
  final List<String> keys;
  const TwoColGrid({
    super.key,
    required this.run,
    required this.metrics,
    required this.keys,
  });

  @override
  Widget build(BuildContext context) {
    final pairs = <List<String>>[];
    for (var i = 0; i < keys.length; i += 2) {
      pairs.add(keys.sublist(i, (i + 2).clamp(0, keys.length)));
    }
    return Column(
      children: pairs
          .map((pair) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: pair.map((k) {
                    final r = metrics[k];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: k != pair.last ? 12 : 0),
                        child: r == null
                            ? const SizedBox.shrink()
                            : MetricCard(
                                run: run,
                                result: r,
                                label: _label(k),
                                accent: _accent(k),
                                onTap: r.isGated
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => MetricDetailScreen(
                                                  run: run, result: r)),
                                        ),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ))
          .toList(),
    );
  }

  static const _labels = {
    MK.messageShare:       'MESSAGES',
    MK.wordShare:          'WORD SHARE',
    MK.avgMessageLength:   'AVG LENGTH',
    MK.emojiRate:          'EMOJI RATE',
    MK.mediaShare:         'MEDIA SHARE',
    MK.deletedRate:        'DELETED',
    MK.replyLatency:       'REPLY SPEED',
    MK.initiationRatio:    'TEXTS FIRST',
    MK.doubleTextRate:     'DOUBLE-TEXTS',
    MK.lastWordRatio:      'LAST WORD',
    MK.silenceBreakerRatio:'BREAKS SILENCE',
    MK.ghostRate:          'GHOST RATE',
    MK.backForthDensity:   'BACK-AND-FORTH',
    MK.momentumTrend:      'MOMENTUM',
    MK.questionRate:       'QUESTION RATE',
    MK.laughterRate:       'LAUGHTER',
    MK.affectionIndex:     'AFFECTION',
    MK.investmentIndex:    'INVESTMENT',
    MK.balanceScore:       'BALANCE',
    MK.pursuitGap:         'PURSUIT GAP',
    MK.reciprocityIndex:   'RECIPROCITY',
    MK.relationshipHealth: 'HEALTH',
  };
  static String _label(String k) => _labels[k] ?? k.toUpperCase();

  static const _accentCycle = [
    NeoColors.blue,
    NeoColors.pink,
    NeoColors.yellow,
    NeoColors.lime,
  ];
  static final _displayOrder = [
    MK.messageShare,    MK.wordShare,
    MK.avgMessageLength,MK.emojiRate,
    MK.mediaShare,      MK.deletedRate,
    MK.replyLatency,    MK.initiationRatio,
    MK.doubleTextRate,  MK.silenceBreakerRatio,
    MK.lastWordRatio,   MK.ghostRate,
    MK.backForthDensity,
    MK.laughterRate,    MK.questionRate,
    MK.affectionIndex,
    MK.reciprocityIndex,MK.investmentIndex,
  ];
  static Color _accent(String k) {
    final i = _displayOrder.indexOf(k);
    return _accentCycle[(i < 0 ? 0 : i) % _accentCycle.length];
  }
}
