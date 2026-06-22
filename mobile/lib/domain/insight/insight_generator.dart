import '../models/metric_result.dart';

class InsightLine {
  final String metricKey;
  final String text;
  const InsightLine({required this.metricKey, required this.text});
}

class InsightGenerator {
  /// Returns up to 5 highest-confidence, highest-magnitude summary sentences.
  static List<InsightLine> generate(
    String personA,
    String personB,
    Map<String, MetricResult> metrics,
  ) {
    final candidates = <_Candidate>[];

    void add(String key, double magnitude, String text) {
      final r = metrics[key];
      if (r == null || r.isGated) return;
      candidates.add(_Candidate(key: key, magnitude: magnitude, text: text));
    }

    // ── Pursuit gap (spiciest — gate hard) ──────────────────────────────────
    final pg = metrics[MK.pursuitGap];
    if (pg != null && !pg.isGated && pg.confidence == MetricConfidence.ok) {
      final gap = pg.scalar ?? 0;
      if (gap.abs() > 0.25) {
        final keener = gap > 0 ? personA : personB;
        add(MK.pursuitGap, gap.abs(),
            '$keener is putting in noticeably more — faster replies, more first-moves, longer texts.');
      } else if (gap.abs() <= 0.1) {
        add(MK.pursuitGap, 0.5,
            'Pretty balanced. $personA and $personB mirror each other\'s effort.');
      }
    }

    // ── Reply latency ────────────────────────────────────────────────────────
    final rl = metrics[MK.replyLatency];
    if (rl != null && !rl.isGated && rl.valueA != null && rl.valueB != null) {
      final faster = rl.valueA! < rl.valueB! ? personA : personB;
      final diff = (rl.valueA! - rl.valueB!).abs();
      final mag = diff / (rl.valueA! + rl.valueB! + 1);
      if (mag > 0.2) {
        add(MK.replyLatency, mag,
            '$faster replies faster on average (${rl.displayValueA} vs ${rl.displayValueB}).');
      }
    }

    // ── Initiation ───────────────────────────────────────────────────────────
    final init = metrics[MK.initiationRatio];
    if (init != null && !init.isGated && init.valueA != null) {
      final vA = init.valueA!;
      if (vA > 0.65) {
        add(MK.initiationRatio, vA - 0.5,
            '$personA starts ${init.displayValueA} of conversations.');
      } else if (vA < 0.35) {
        add(MK.initiationRatio, 0.5 - vA,
            '$personB starts ${init.displayValueB} of conversations.');
      }
    }

    // ── Balance score ────────────────────────────────────────────────────────
    final bs = metrics[MK.balanceScore];
    if (bs != null && !bs.isGated && bs.scalar != null) {
      final s = bs.scalar!;
      if (s >= 80) {
        add(MK.balanceScore, s / 100,
            'Very balanced dynamic — both contribute about equally.');
      } else if (s < 50) {
        add(MK.balanceScore, (100 - s) / 100,
            'Noticeably one-sided — balance score is ${s.round()}/100.');
      }
    }

    // ── Momentum ─────────────────────────────────────────────────────────────
    final mt = metrics[MK.momentumTrend];
    if (mt != null && !mt.isGated) {
      final label = mt.displayValueA;
      if (label.contains('Warming')) {
        add(MK.momentumTrend, 0.8, 'Activity is picking up recently — things are warming up.');
      } else if (label.contains('Cooling')) {
        add(MK.momentumTrend, 0.7, 'Message volume has been declining — things are cooling off.');
      }
    }

    // ── Ghost rate ───────────────────────────────────────────────────────────
    final gr = metrics[MK.ghostRate];
    if (gr != null && !gr.isGated && gr.valueA != null && gr.valueB != null) {
      final higher = gr.valueA! >= gr.valueB! ? personA : personB;
      final rate = gr.valueA! >= gr.valueB! ? gr.valueA! : gr.valueB!;
      if (rate > 0.3) {
        add(MK.ghostRate, rate,
            '$higher leaves ${(rate * 100).round()}% of questions unanswered.');
      }
    }

    // ── Reciprocity ──────────────────────────────────────────────────────────
    final ri = metrics[MK.reciprocityIndex];
    if (ri != null && !ri.isGated && ri.scalar != null) {
      final s = ri.scalar!;
      if (s >= 75) {
        add(MK.reciprocityIndex, s / 100, 'High reciprocity — real dialogue, both actively engaged.');
      } else if (s < 45) {
        add(MK.reciprocityIndex, (100 - s) / 100,
            'Low reciprocity — the conversation feels one-directional.');
      }
    }

    // Sort by magnitude, take top 5
    candidates.sort((a, b) => b.magnitude.compareTo(a.magnitude));
    return candidates
        .take(5)
        .map((c) => InsightLine(metricKey: c.key, text: c.text))
        .toList();
  }
}

class _Candidate {
  final String key;
  final double magnitude;
  final String text;
  const _Candidate({required this.key, required this.magnitude, required this.text});
}
