import 'dart:math' as math;
import '../models/run_message.dart';
import '../models/metric_result.dart';
import 'metric_helpers.dart';

class ToneMetrics {
  static final _laughRe = RegExp(
    r'\b(he{2,}|heh|hehe|haha|lol|lmao|lmfao|jaja|kkk+|555)\b',
    caseSensitive: false,
  );
  static final _affectionRe = RegExp(
    r'\b(love|miss you|miss u|adore|darling|babe|baby|honey|sweetheart|dear|❤|🧡|💛|💚|💙|💜|🖤|🤍|🤎|💕|💞|💓|💗|💖|💝|😍|🥰)\b',
    caseSensitive: false,
  );

  static final _emojiRe = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE00}-\u{FE0F}]',
    unicode: true,
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
      _emojiDiversity(runId, personA, personB, aMsgs, bMsgs),
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

  static MetricResult _emojiDiversity(
      String runId, String a, String b,
      List<RunMessage> aMsgs, List<RunMessage> bMsgs) {
    List<String> extractEmojis(RunMessage m) =>
        _emojiRe.allMatches(m.body).map((x) => x.group(0)!).toList();

    final aEmojis = aMsgs.expand(extractEmojis).toList();
    final bEmojis = bMsgs.expand(extractEmojis).toList();

    if (aEmojis.length < 10 || bEmojis.length < 10) {
      return MetricResult.gated(runId, MK.emojiDiversity);
    }

    double shannonEntropy(List<String> emojis) {
      final freq = <String, int>{};
      for (final e in emojis) { freq[e] = (freq[e] ?? 0) + 1; }
      final n = emojis.length;
      double entropy = 0;
      for (final count in freq.values) {
        final p = count / n;
        entropy -= p * math.log(p) / math.ln2;
      }
      return entropy;
    }

    final entropyA = shannonEntropy(aEmojis);
    final entropyB = shannonEntropy(bEmojis);

    final ev = [...aMsgs, ...bMsgs]
        .where((m) => m.emojiCount >= 2)
        .toList()
      ..sort((x, y) => y.emojiCount.compareTo(x.emojiCount));

    return MetricResult(
      runId: runId,
      metricKey: MK.emojiDiversity,
      valueA: entropyA,
      valueB: entropyB,
      winner: winnerFromValues(entropyA, entropyB),
      displayValueA: entropyA.toStringAsFixed(2),
      displayValueB: entropyB.toStringAsFixed(2),
      confidence: MetricConfidence.ok,
      evidenceMessageIds: ev.take(6).map((m) => m.id).toList(),
      summaryLine: (entropyA - entropyB).abs() < 0.2
          ? 'Both use a similar range of emojis.'
          : '${entropyA > entropyB ? a : b} uses a wider variety of emojis.',
    );
  }
}
