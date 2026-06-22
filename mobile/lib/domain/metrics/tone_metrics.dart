import '../models/run_message.dart';
import '../models/metric_result.dart';
import 'metric_helpers.dart';

class ToneMetrics {
  static final _laughRe = RegExp(
    r'\b(ha{2,}|he{2,}|heh|hehe|haha|lol|lmao|lmfao|jaja|kkk+|555)\b',
    caseSensitive: false,
  );
  static final _affectionRe = RegExp(
    r'\b(love|miss you|miss u|adore|darling|babe|baby|honey|sweetheart|dear|❤|🧡|💛|💚|💙|💜|🖤|🤍|🤎|💕|💞|💓|💗|💖|💝|😍|🥰)\b',
    caseSensitive: false,
  );

  static List<MetricResult> compute(
    String runId,
    String personA,
    String personB,
    List<RunMessage> messages,
  ) {
    final textMsgs = messages
        .where((m) => m.kind == MessageKind.text && m.isUserMessage)
        .toList();
    final aMsgs = textMsgs.where((m) => m.sender == personA).toList();
    final bMsgs = textMsgs.where((m) => m.sender == personB).toList();

    return [
      _questionRate(runId, personA, personB, aMsgs, bMsgs),
      _laughterRate(runId, personA, personB, aMsgs, bMsgs),
      _affectionIndex(runId, personA, personB, aMsgs, bMsgs),
    ];
  }

  static MetricResult _questionRate(
      String runId, String a, String b,
      List<RunMessage> aMsgs, List<RunMessage> bMsgs) {
    if (aMsgs.isEmpty || bMsgs.isEmpty) return MetricResult.gated(runId, MK.questionRate);

    final qA = aMsgs.where((m) => m.hasQuestion).toList();
    final qB = bMsgs.where((m) => m.hasQuestion).toList();
    final rateA = qA.length / aMsgs.length;
    final rateB = qB.length / bMsgs.length;

    final ev = [...qA.take(4), ...qB.take(4)].map((m) => m.id).toList();

    return MetricResult(
      runId: runId,
      metricKey: MK.questionRate,
      valueA: rateA,
      valueB: rateB,
      winner: winnerFromValues(rateA, rateB),
      displayValueA: fmtPct(rateA),
      displayValueB: fmtPct(rateB),
      confidence: (qA.length + qB.length) >= 5 ? MetricConfidence.ok : MetricConfidence.low,
      evidenceMessageIds: ev,
      summaryLine: '${rateA >= rateB ? a : b} asks more questions.',
    );
  }

  static MetricResult _laughterRate(
      String runId, String a, String b,
      List<RunMessage> aMsgs, List<RunMessage> bMsgs) {
    if (aMsgs.isEmpty || bMsgs.isEmpty) return MetricResult.gated(runId, MK.laughterRate);

    final laughA = aMsgs.where((m) => _laughRe.hasMatch(m.body)).toList();
    final laughB = bMsgs.where((m) => _laughRe.hasMatch(m.body)).toList();
    final rateA = laughA.length / aMsgs.length;
    final rateB = laughB.length / bMsgs.length;

    final ev = [...laughA.take(4), ...laughB.take(4)].map((m) => m.id).toList();

    return MetricResult(
      runId: runId,
      metricKey: MK.laughterRate,
      valueA: rateA,
      valueB: rateB,
      winner: winnerFromValues(rateA, rateB),
      displayValueA: fmtPct(rateA),
      displayValueB: fmtPct(rateB),
      confidence: (laughA.length + laughB.length) >= 5 ? MetricConfidence.ok : MetricConfidence.low,
      evidenceMessageIds: ev,
      summaryLine: '${rateA >= rateB ? a : b} laughs more in messages.',
    );
  }

  static MetricResult _affectionIndex(
      String runId, String a, String b,
      List<RunMessage> aMsgs, List<RunMessage> bMsgs) {
    if (aMsgs.isEmpty || bMsgs.isEmpty) return MetricResult.gated(runId, MK.affectionIndex);

    final affA = aMsgs.where((m) => _affectionRe.hasMatch(m.body)).toList();
    final affB = bMsgs.where((m) => _affectionRe.hasMatch(m.body)).toList();
    final rateA = affA.length / aMsgs.length;
    final rateB = affB.length / bMsgs.length;

    final ev = [...affA.take(4), ...affB.take(4)].map((m) => m.id).toList();

    return MetricResult(
      runId: runId,
      metricKey: MK.affectionIndex,
      valueA: rateA,
      valueB: rateB,
      winner: winnerFromValues(rateA, rateB),
      displayValueA: fmtPct(rateA),
      displayValueB: fmtPct(rateB),
      confidence: (affA.length + affB.length) >= 3 ? MetricConfidence.ok : MetricConfidence.low,
      evidenceMessageIds: ev,
      summaryLine: '${rateA >= rateB ? a : b} expresses more affection.',
    );
  }
}
