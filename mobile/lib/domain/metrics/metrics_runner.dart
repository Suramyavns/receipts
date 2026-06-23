import 'dart:isolate';
import '../models/run_message.dart';
import '../models/session.dart';
import '../models/metric_result.dart';
import 'volume_metrics.dart';
import 'timing_metrics.dart';
import 'tone_metrics.dart';
import 'composite_metrics.dart';

class MetricsRunner {
  /// Run all metrics in an isolate; returns a flat list of MetricResults.
  static Future<List<MetricResult>> run({
    required String runId,
    required String personA,
    required String personB,
    required List<RunMessage> messages,
    required List<ChatSession> sessions,
  }) {
    return Isolate.run(() => _compute(
          runId: runId,
          personA: personA,
          personB: personB,
          messages: messages,
          sessions: sessions,
        ));
  }

  static List<MetricResult> _compute({
    required String runId,
    required String personA,
    required String personB,
    required List<RunMessage> messages,
    required List<ChatSession> sessions,
  }) {
    final results = <MetricResult>[];

    results.addAll(VolumeMetrics.compute(runId, personA, personB, messages));
    results.addAll(
        TimingMetrics.compute(runId, personA, personB, messages, sessions));
    results.addAll(ToneMetrics.compute(runId, personA, personB, messages));

    // Build a lookup map for composites
    final byKey = {for (final r in results) r.metricKey: r};

    results.add(CompositeMetrics.investmentIndex(runId, personA, personB, byKey));
    byKey[MK.investmentIndex] = results.last;

    results.add(CompositeMetrics.balanceScore(runId, personA, personB, byKey));
    byKey[MK.balanceScore] = results.last;

    results.add(CompositeMetrics.pursuitGap(runId, personA, personB, byKey));
    byKey[MK.pursuitGap] = results.last;

    results.add(CompositeMetrics.reciprocityIndex(runId, personA, personB, byKey));
    byKey[MK.reciprocityIndex] = results.last;

    results.add(CompositeMetrics.dryTexterScore(runId, personA, personB, byKey));

    results.add(CompositeMetrics.relationshipHealth(runId, byKey));

    return results;
  }

  /// Synchronous version for small chats or testing.
  static List<MetricResult> runSync({
    required String runId,
    required String personA,
    required String personB,
    required List<RunMessage> messages,
    required List<ChatSession> sessions,
  }) =>
      _compute(
        runId: runId,
        personA: personA,
        personB: personB,
        messages: messages,
        sessions: sessions,
      );
}
