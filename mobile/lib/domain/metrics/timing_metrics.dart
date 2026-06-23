import '../models/run_message.dart';
import '../models/session.dart';
import '../models/metric_result.dart';
import 'metric_helpers.dart';

class TimingMetrics {
  static List<MetricResult> compute(
    String runId,
    String personA,
    String personB,
    List<RunMessage> messages,
    List<ChatSession> sessions,
  ) {
    final userMsgs = messages
        .where((m) => m.isUserMessage)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final results = <MetricResult>[];

    results.add(_replyLatency(runId, personA, personB, userMsgs));
    results.add(_initiationRatio(runId, personA, personB, sessions));
    results.add(_doubleTextRate(runId, personA, personB, userMsgs));
    results.add(_lastWordRatio(runId, personA, personB, sessions, messages));
    results.add(_ghostRate(runId, personA, personB, userMsgs, sessions, messages));
    results.add(_silenceBreaker(runId, personA, personB, userMsgs));
    results.add(_backForthDensity(runId, personA, personB, userMsgs));
    results.add(_momentumTrend(runId, personA, personB, userMsgs));

    return results;
  }

  // ── Reply latency ────────────────────────────────────────────────────────
  static MetricResult _replyLatency(
      String runId, String a, String b, List<RunMessage> msgs) {
    final repliesA = <int>[], repliesB = <int>[];

    for (final msg in msgs) {
      final latency = msg.replyLatencySec;
      if (latency == null || latency <= 0) continue;
      if (msg.sender == a) {
        repliesA.add(latency);
      } else if (msg.sender == b) {
        repliesB.add(latency);
      }
    }

    const minSamples = 10;
    if (repliesA.length < minSamples || repliesB.length < minSamples) {
      return MetricResult.gated(runId, MK.replyLatency);
    }

    repliesA.sort(); repliesB.sort();
    final medA = median(repliesA), medB = median(repliesB);

    // Evidence: fastest and slowest replies from both
    final withLatency = msgs.where((m) => m.replyLatencySec != null).toList()
      ..sort((x, y) => (x.replyLatencySec ?? 0).compareTo(y.replyLatencySec ?? 0));
    final ev = [
      ...withLatency.take(3),
      ...withLatency.reversed.take(3),
    ].map((m) => m.id).toSet().toList();

    return MetricResult(
      runId: runId,
      metricKey: MK.replyLatency,
      valueA: medA,
      valueB: medB,
      winner: winnerFromValues(medA, medB, lowerIsBetter: true),
      displayValueA: fmtDuration(medA),
      displayValueB: fmtDuration(medB),
      confidence: MetricConfidence.ok,
      evidenceMessageIds: ev,
      summaryLine:
          '${medA < medB ? a : b} replies faster on average (${fmtDuration(medA < medB ? medA : medB)} median).',
    );
  }

  // ── Initiation ratio ─────────────────────────────────────────────────────
  static MetricResult _initiationRatio(
      String runId, String a, String b, List<ChatSession> sessions) {
    final abSessions = sessions
        .where((s) => s.initiatorSender == a || s.initiatorSender == b)
        .toList();
    if (abSessions.length < 8) return MetricResult.gated(runId, MK.initiationRatio);

    final byA = abSessions.where((s) => s.initiatorSender == a).length;
    final ratioA = byA / abSessions.length;
    final ratioB = 1 - ratioA;

    // Evidence: opening messages of each session
    final openerIds = abSessions
        .expand((s) => s.messageIds.take(1))
        .take(10)
        .toList();

    return MetricResult(
      runId: runId,
      metricKey: MK.initiationRatio,
      valueA: ratioA,
      valueB: ratioB,
      winner: winnerFromValues(ratioA, ratioB),
      displayValueA: fmtPct(ratioA),
      displayValueB: fmtPct(ratioB),
      confidence: MetricConfidence.ok,
      evidenceMessageIds: openerIds,
      summaryLine: (ratioA - ratioB).abs() < 0.02
          ? 'Both start conversations equally.'
          : '${ratioA > ratioB ? a : b} starts ${fmtPct(ratioA > ratioB ? ratioA : ratioB)} of conversations.',
    );
  }

  // ── Double-text rate ─────────────────────────────────────────────────────
  static MetricResult _doubleTextRate(
      String runId, String a, String b, List<RunMessage> msgs) {
    // Collapse bursts within 30s as one thought, then count runs
    const burstSec = 30;
    int doublesA = 0, doublesB = 0;
    final evIds = <String>[];

    for (int i = 1; i < msgs.length; i++) {
      final prev = msgs[i - 1], cur = msgs[i];
      if (cur.sender != prev.sender) continue;
      final gap = cur.timestamp.difference(prev.timestamp).inSeconds;
      if (gap <= burstSec) continue; // same burst — not a double-text
      if (cur.sender == a) { doublesA++; if (evIds.length < 6) evIds.add(cur.id); }
      else if (cur.sender == b) { doublesB++; if (evIds.length < 6) evIds.add(cur.id); }
    }

    final nA = msgs.where((m) => m.sender == a).length;
    final nB = msgs.where((m) => m.sender == b).length;
    if (nA == 0 || nB == 0) return MetricResult.gated(runId, MK.doubleTextRate);

    final rateA = doublesA / nA, rateB = doublesB / nB;
    return MetricResult(
      runId: runId,
      metricKey: MK.doubleTextRate,
      valueA: rateA,
      valueB: rateB,
      winner: winnerFromValues(rateA, rateB),
      displayValueA: fmtPct(rateA),
      displayValueB: fmtPct(rateB),
      confidence: (doublesA + doublesB) >= 5 ? MetricConfidence.ok : MetricConfidence.low,
      evidenceMessageIds: evIds,
      summaryLine: (rateA - rateB).abs() < 0.02
          ? 'Both double-text at a similar rate.'
          : '${rateA > rateB ? a : b} double-texts more often.',
    );
  }

  // ── Last-word ratio ──────────────────────────────────────────────────────
  static MetricResult _lastWordRatio(
      String runId,
      String a,
      String b,
      List<ChatSession> sessions,
      List<RunMessage> allMessages) {
    final msgById = {for (final m in allMessages) m.id: m};
    final abSessions = sessions
        .where((s) => s.messageIds.isNotEmpty)
        .where((s) {
          final last = msgById[s.messageIds.last];
          return last != null && (last.sender == a || last.sender == b);
        })
        .toList();

    if (abSessions.length < 6) return MetricResult.gated(runId, MK.lastWordRatio);

    int endsA = 0;
    final evIds = <String>[];
    for (final s in abSessions) {
      final last = msgById[s.messageIds.last];
      if (last == null) continue;
      if (last.sender == a) { endsA++; evIds.add(last.id); }
    }
    final ratioA = endsA / abSessions.length;

    return MetricResult(
      runId: runId,
      metricKey: MK.lastWordRatio,
      valueA: ratioA,
      valueB: 1 - ratioA,
      winner: winnerFromValues(ratioA, 1 - ratioA),
      displayValueA: fmtPct(ratioA),
      displayValueB: fmtPct(1 - ratioA),
      confidence: MetricConfidence.ok,
      evidenceMessageIds: evIds.take(8).toList(),
      summaryLine: '${ratioA > 1 - ratioA ? a : b} sends the last message in ${fmtPct(ratioA > 1 - ratioA ? ratioA : 1 - ratioA)} of conversations.',
    );
  }

  // ── Ghost rate ────────────────────────────────────────────────────────────
  static MetricResult _ghostRate(
      String runId,
      String a,
      String b,
      List<RunMessage> msgs,
      List<ChatSession> sessions,
      List<RunMessage> allMessages) {
    final msgById = {for (final m in allMessages) m.id: m};
    int questionsA = 0, ghostedA = 0;
    int questionsB = 0, ghostedB = 0;
    final evIds = <String>[];

    for (final session in sessions) {
      final sessionMsgs = session.messageIds
          .map((id) => msgById[id])
          .whereType<RunMessage>()
          .toList()
        ..sort((x, y) => x.timestamp.compareTo(y.timestamp));

      for (int i = 0; i < sessionMsgs.length; i++) {
        final msg = sessionMsgs[i];
        if (!msg.hasQuestion) continue;
        if (msg.sender != a && msg.sender != b) continue;

        final asker = msg.sender;
        final isA = asker == a;
        if (isA) { questionsA++; } else { questionsB++; }

        // Check if next message (within session) is from the other person
        bool answered = false;
        for (int j = i + 1; j < sessionMsgs.length; j++) {
          if (sessionMsgs[j].sender != asker) { answered = true; break; }
        }
        if (!answered) {
          if (isA) { ghostedA++; } else { ghostedB++; }
          if (evIds.length < 8) evIds.add(msg.id);
        }
      }
    }

    if (questionsA + questionsB < 5) return MetricResult.gated(runId, MK.ghostRate);

    final rateA = questionsA > 0 ? ghostedA / questionsA : 0.0;
    final rateB = questionsB > 0 ? ghostedB / questionsB : 0.0;

    return MetricResult(
      runId: runId,
      metricKey: MK.ghostRate,
      valueA: rateA,
      valueB: rateB,
      winner: winnerFromValues(rateA, rateB),
      displayValueA: fmtPct(rateA),
      displayValueB: fmtPct(rateB),
      confidence: MetricConfidence.ok,
      evidenceMessageIds: evIds,
      summaryLine: (rateA - rateB).abs() < 0.02
          ? "Questions go unanswered at a similar rate for both."
          : "${rateA > rateB ? a : b}'s questions go unanswered ${fmtPct(rateA > rateB ? rateA : rateB)} of the time.",
    );
  }

  // ── Silence-breaker ratio ────────────────────────────────────────────────
  static MetricResult _silenceBreaker(
      String runId, String a, String b, List<RunMessage> msgs) {
    const gapDays = 2;
    int breaksA = 0, breaksB = 0;
    final evIds = <String>[];

    for (int i = 1; i < msgs.length; i++) {
      final prev = msgs[i - 1], cur = msgs[i];
      if (cur.sender != a && cur.sender != b) continue;
      final gapD = cur.timestamp.difference(prev.timestamp).inHours / 24;
      if (gapD < gapDays) continue;
      if (cur.sender == a) {
        breaksA++;
        if (evIds.length < 8) evIds.add(cur.id);
      } else {
        breaksB++;
        if (evIds.length < 8) evIds.add(cur.id);
      }
    }

    if (breaksA + breaksB < 3) return MetricResult.gated(runId, MK.silenceBreakerRatio);

    final total = breaksA + breaksB;
    final ratioA = breaksA / total, ratioB = breaksB / total;

    return MetricResult(
      runId: runId,
      metricKey: MK.silenceBreakerRatio,
      valueA: ratioA,
      valueB: ratioB,
      winner: winnerFromValues(ratioA, ratioB),
      displayValueA: fmtPct(ratioA),
      displayValueB: fmtPct(ratioB),
      confidence: MetricConfidence.ok,
      evidenceMessageIds: evIds,
      summaryLine: (ratioA - ratioB).abs() < 0.02
          ? 'Both break the silence equally often.'
          : '${ratioA > ratioB ? a : b} breaks the silence more often (${fmtPct(ratioA > ratioB ? ratioA : ratioB)} of the time).',
    );
  }

  // ── Back-and-forth density ───────────────────────────────────────────────
  static MetricResult _backForthDensity(
      String runId, String a, String b, List<RunMessage> msgs) {
    if (msgs.length < 10) return MetricResult.gated(runId, MK.backForthDensity);

    int switches = 0;
    for (int i = 1; i < msgs.length; i++) {
      if (msgs[i].sender != msgs[i - 1].sender) switches++;
    }
    final density = switches / msgs.length;

    return MetricResult(
      runId: runId,
      metricKey: MK.backForthDensity,
      scalar: density,
      displayValueA: fmtPct(density),
      displayValueB: '',
      confidence: MetricConfidence.ok,
      summaryLine: density > 0.7
          ? 'This chat is a fast volley — lots of back and forth.'
          : density < 0.4
              ? 'One person tends to monologue.'
              : 'Conversation rhythm is balanced.',
    );
  }

  // ── Momentum / trend ─────────────────────────────────────────────────────
  static MetricResult _momentumTrend(
      String runId, String a, String b, List<RunMessage> msgs) {
    if (msgs.isEmpty) return MetricResult.gated(runId, MK.momentumTrend);

    final start = msgs.first.timestamp;
    final end = msgs.last.timestamp;
    final totalWeeks = end.difference(start).inDays / 7;
    if (totalWeeks < 6) return MetricResult.gated(runId, MK.momentumTrend);

    // Count messages per calendar week
    final weekCounts = <int, int>{};
    for (final m in msgs) {
      final week = m.timestamp.difference(start).inDays ~/ 7;
      weekCounts[week] = (weekCounts[week] ?? 0) + 1;
    }

    final xs = weekCounts.keys.map((k) => k.toDouble()).toList()..sort();
    final ys = xs.map((x) => weekCounts[x.toInt()]!.toDouble()).toList();

    // Simple linear regression slope
    final n = xs.length;
    final xMean = xs.reduce((a, b) => a + b) / n;
    final yMean = ys.reduce((a, b) => a + b) / n;
    double num = 0, den = 0;
    for (int i = 0; i < n; i++) {
      num += (xs[i] - xMean) * (ys[i] - yMean);
      den += (xs[i] - xMean) * (xs[i] - xMean);
    }
    final slope = den == 0 ? 0.0 : num / den;

    // Recent 30d vs all-time average
    final allAvg = ys.reduce((a, b) => a + b) / ys.length;
    final recent = msgs.where((m) =>
        m.timestamp.isAfter(end.subtract(const Duration(days: 30)))).length;
    final recentAvg = recent / 4.3;
    final ratio = allAvg > 0 ? recentAvg / allAvg : 1.0;

    String label;
    if (slope > 1 || ratio > 1.2) {
      label = 'Warming 🔥';
    } else if (slope < -1 || ratio < 0.8) {
      label = 'Cooling ❄️';
    } else {
      label = 'Steady';
    }

    return MetricResult(
      runId: runId,
      metricKey: MK.momentumTrend,
      scalar: slope,
      displayValueA: label,
      displayValueB: '${ratio.toStringAsFixed(1)}× recent avg',
      confidence: MetricConfidence.ok,
      summaryLine: 'Chat activity is $label over recent weeks.',
    );
  }
}
