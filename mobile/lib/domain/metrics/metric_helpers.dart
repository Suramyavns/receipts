import '../models/metric_result.dart';

/// Median of a sorted list. Assumes list is non-empty.
double median(List<num> sorted) {
  final n = sorted.length;
  if (n == 0) return 0;
  if (n % 2 == 1) return sorted[n ~/ 2].toDouble();
  return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;
}

MetricWinner winnerFromValues(double? a, double? b, {bool lowerIsBetter = false}) {
  if (a == null || b == null) return MetricWinner.na;
  final diff = (a - b).abs();
  if (diff < 0.02) return MetricWinner.tie;
  if (lowerIsBetter) return a < b ? MetricWinner.personA : MetricWinner.personB;
  return a > b ? MetricWinner.personA : MetricWinner.personB;
}

String fmtPct(double v) => '${(v * 100).toStringAsFixed(0)}%';

String fmtDuration(double secs) {
  if (secs < 60) return '<1 min';
  if (secs < 3600) return '${(secs / 60).round()} min';
  if (secs < 86400) return '${(secs / 3600).toStringAsFixed(1)} h';
  return '${(secs / 86400).toStringAsFixed(1)} d';
}

String fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
