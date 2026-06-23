import '../models/metric_result.dart';
import 'metric_helpers.dart';

class CompositeMetrics {
  /// Investment Index: weighted mean of A's shares across {messages, words,
  /// initiations, questions, media}. Equal weights, propagates na.
  static MetricResult investmentIndex(
      String runId, String a, String b, Map<String, MetricResult> metrics) {
    final keys = [MK.messageShare, MK.wordShare, MK.initiationRatio, MK.questionRate];
    final values = <double>[];
    for (final k in keys) {
      final r = metrics[k];
      if (r == null || r.isGated || r.valueA == null) continue;
      values.add(r.valueA!);
    }
    if (values.length < 2) return MetricResult.gated(runId, MK.investmentIndex);

    final invA = values.reduce((s, v) => s + v) / values.length;
    final invB = 1 - invA;

    return MetricResult(
      runId: runId,
      metricKey: MK.investmentIndex,
      valueA: invA,
      valueB: invB,
      winner: winnerFromValues(invA, invB),
      displayValueA: fmtPct(invA),
      displayValueB: fmtPct(invB),
      confidence: MetricConfidence.ok,
      summaryLine: '${invA >= invB ? a : b} is investing more overall (${fmtPct(invA >= invB ? invA : invB)}).',
    );
  }

  /// Balance Score: 1 − 2·|Investment(A) − 0.5|, scaled 0–100.
  static MetricResult balanceScore(
      String runId, String a, String b, Map<String, MetricResult> metrics) {
    final inv = metrics[MK.investmentIndex];
    if (inv == null || inv.isGated || inv.valueA == null) {
      return MetricResult.gated(runId, MK.balanceScore);
    }
    final score = (1 - 2 * (inv.valueA! - 0.5).abs()) * 100;

    return MetricResult(
      runId: runId,
      metricKey: MK.balanceScore,
      scalar: score,
      displayValueA: '${score.round()}/100',
      displayValueB: '',
      confidence: MetricConfidence.ok,
      summaryLine: score >= 80
          ? 'Very balanced — you mirror each other\'s effort.'
          : score >= 60
              ? 'Slightly uneven but within normal range.'
              : 'Noticeably one-sided.',
    );
  }

  /// Pursuit Gap (Keenness): standardized mean of {reply speed, initiation,
  /// double-text, question rate, silence-breaking}. Positive = A is keener.
  static MetricResult pursuitGap(
      String runId, String a, String b, Map<String, MetricResult> metrics) {
    // Need at least 4 of the 5 component signals
    final components = <String, double>{};

    void addSignal(String key, bool higherMeansKeener) {
      final r = metrics[key];
      if (r == null || r.isGated) return;
      final vA = r.valueA, vB = r.valueB;
      if (vA == null || vB == null) return;
      final total = vA + vB;
      if (total == 0) return;
      // Normalise to A's fraction of A+B (0..1 scale)
      final fraction = higherMeansKeener ? vA / total : vB / total; // inverted if lower=keener
      components[key] = fraction;
    }

    addSignal(MK.initiationRatio, true);
    addSignal(MK.doubleTextRate, true);
    addSignal(MK.questionRate, true);
    addSignal(MK.silenceBreakerRatio, true);
    addSignal(MK.replyLatency, false); // lower latency = keener (inverted)

    if (components.length < 3) return MetricResult.gated(runId, MK.pursuitGap);

    final meanA = components.values.reduce((s, v) => s + v) / components.length;
    final meanB = 1 - meanA;
    final gap = (meanA - 0.5) * 2; // −1..+1, positive = A is keener

    final conf = components.length >= 4 ? MetricConfidence.ok : MetricConfidence.low;

    return MetricResult(
      runId: runId,
      metricKey: MK.pursuitGap,
      valueA: meanA,
      valueB: meanB,
      scalar: gap,
      winner: winnerFromValues(meanA, meanB),
      displayValueA: fmtPct(meanA),
      displayValueB: fmtPct(meanB),
      confidence: conf,
      summaryLine: gap.abs() < 0.1
          ? 'Both putting in similar effort — well matched.'
          : '${gap > 0 ? a : b} is putting in noticeably more effort.',
    );
  }

  /// Reciprocity Index: blends balanced initiation + high back-and-forth density.
  static MetricResult reciprocityIndex(
      String runId, String a, String b, Map<String, MetricResult> metrics) {
    final init = metrics[MK.initiationRatio];
    final bfd = metrics[MK.backForthDensity];
    if (init == null || init.isGated || bfd == null || bfd.isGated) {
      return MetricResult.gated(runId, MK.reciprocityIndex);
    }

    // How balanced is initiation? 1 = perfectly equal, 0 = one-sided.
    final initA = init.valueA ?? 0.5;
    final balance = 1 - 2 * (initA - 0.5).abs();
    final density = bfd.scalar ?? 0.5;
    final score = ((balance + density) / 2) * 100;

    final carrier = init.winner == MetricWinner.tie
        ? null
        : (initA > 0.5 ? a : b);

    return MetricResult(
      runId: runId,
      metricKey: MK.reciprocityIndex,
      scalar: score,
      displayValueA: '${score.round()}/100',
      displayValueB: '',
      confidence: MetricConfidence.ok,
      summaryLine: score >= 70
          ? 'High reciprocity — genuine dialogue, both engaged.'
          : score >= 50
              ? 'Moderate reciprocity.'
              : carrier != null
                  ? 'Low reciprocity — $carrier is carrying the conversation.'
                  : 'Low reciprocity — one person is carrying the conversation.',
    );
  }

  /// Relationship Health: blends Balance + Reciprocity + Momentum + pursuit gap symmetry.
  static MetricResult relationshipHealth(
      String runId, Map<String, MetricResult> metrics) {
    final parts = <double>[];

    final balance = metrics[MK.balanceScore];
    if (balance != null && !balance.isGated && balance.scalar != null) {
      parts.add(balance.scalar!);
    }

    final recip = metrics[MK.reciprocityIndex];
    if (recip != null && !recip.isGated && recip.scalar != null) {
      parts.add(recip.scalar!);
    }

    final momentum = metrics[MK.momentumTrend];
    if (momentum != null && !momentum.isGated) {
      final label = momentum.displayValueA;
      if (label.contains('Warming')) {
        parts.add(80);
      } else if (label.contains('Steady')) {
        parts.add(65);
      } else if (label.contains('Cooling')) {
        parts.add(40);
      }
    }

    if (parts.length < 2) return MetricResult.gated(runId, MK.relationshipHealth);

    final score = parts.reduce((s, v) => s + v) / parts.length;
    String label;
    if (score >= 70) {
      label = 'Thriving';
    } else if (score >= 50) {
      label = 'Steady';
    } else {
      label = 'Cooling';
    }

    return MetricResult(
      runId: runId,
      metricKey: MK.relationshipHealth,
      scalar: score,
      displayValueA: label,
      displayValueB: '${score.round()}/100',
      confidence: MetricConfidence.ok,
      summaryLine: 'Overall relationship health: $label (${score.round()}/100).',
    );
  }
}
