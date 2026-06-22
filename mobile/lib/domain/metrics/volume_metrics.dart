import '../models/run_message.dart';
import '../models/metric_result.dart';
import 'metric_helpers.dart';

class VolumeMetrics {
  static List<MetricResult> compute(
    String runId,
    String personA,
    String personB,
    List<RunMessage> messages,
  ) {
    final userMsgs = messages.where((m) => m.isUserMessage).toList();
    final aMsgs = userMsgs.where((m) => m.sender == personA).toList();
    final bMsgs = userMsgs.where((m) => m.sender == personB).toList();

    final nA = aMsgs.length, nB = bMsgs.length;
    final total = nA + nB;
    if (total == 0) {
      return [MK.messageShare, MK.wordShare, MK.avgMessageLength,
              MK.emojiRate, MK.mediaShare, MK.deletedRate]
          .map((k) => MetricResult.gated(runId, k))
          .toList();
    }

    final results = <MetricResult>[];

    // ── Message share ────────────────────────────────────────────────────────
    final shareA = nA / total, shareB = nB / total;
    results.add(MetricResult(
      runId: runId,
      metricKey: MK.messageShare,
      valueA: shareA,
      valueB: shareB,
      winner: winnerFromValues(shareA, shareB),
      displayValueA: fmtPct(shareA),
      displayValueB: fmtPct(shareB),
      confidence: total >= 20 ? MetricConfidence.ok : MetricConfidence.low,
      summaryLine: _msgShareSummary(personA, personB, shareA),
    ));

    // ── Word share ───────────────────────────────────────────────────────────
    final wordsA = aMsgs.fold(0, (s, m) => s + m.wordCount);
    final wordsB = bMsgs.fold(0, (s, m) => s + m.wordCount);
    final totalWords = wordsA + wordsB;
    if (totalWords > 0) {
      final wShareA = wordsA / totalWords, wShareB = wordsB / totalWords;
      final topLong = userMsgs
          .where((m) => m.kind == MessageKind.text)
          .toList()
        ..sort((a, b) => b.wordCount.compareTo(a.wordCount));
      results.add(MetricResult(
        runId: runId,
        metricKey: MK.wordShare,
        valueA: wShareA,
        valueB: wShareB,
        winner: winnerFromValues(wShareA, wShareB),
        displayValueA: fmtPct(wShareA),
        displayValueB: fmtPct(wShareB),
        confidence: totalWords >= 50 ? MetricConfidence.ok : MetricConfidence.low,
        evidenceMessageIds: topLong.take(6).map((m) => m.id).toList(),
        summaryLine: '$personA wrote ${fmtPct(wShareA)} of all words.',
      ));
    } else {
      results.add(MetricResult.gated(runId, MK.wordShare));
    }

    // ── Avg message length ───────────────────────────────────────────────────
    final textA = aMsgs.where((m) => m.kind == MessageKind.text).toList();
    final textB = bMsgs.where((m) => m.kind == MessageKind.text).toList();
    if (textA.isNotEmpty && textB.isNotEmpty) {
      final avgA = textA.fold(0, (s, m) => s + m.wordCount) / textA.length;
      final avgB = textB.fold(0, (s, m) => s + m.wordCount) / textB.length;
      final longMsgs = [...textA, ...textB]..sort((a, b) => b.wordCount.compareTo(a.wordCount));
      results.add(MetricResult(
        runId: runId,
        metricKey: MK.avgMessageLength,
        valueA: avgA,
        valueB: avgB,
        winner: winnerFromValues(avgA, avgB),
        displayValueA: '${avgA.toStringAsFixed(1)} words',
        displayValueB: '${avgB.toStringAsFixed(1)} words',
        confidence: MetricConfidence.ok,
        evidenceMessageIds: longMsgs.take(6).map((m) => m.id).toList(),
        summaryLine:
            '${avgA > avgB ? personA : personB} writes longer messages on average.',
      ));
    } else {
      results.add(MetricResult.gated(runId, MK.avgMessageLength));
    }

    // ── Emoji rate ───────────────────────────────────────────────────────────
    // Fraction of each person's messages that contain at least one emoji.
    final withEmojiA = aMsgs.where((m) => m.emojiCount > 0).length;
    final withEmojiB = bMsgs.where((m) => m.emojiCount > 0).length;
    if (nA > 0 && nB > 0) {
      final rateA = withEmojiA / nA, rateB = withEmojiB / nB;
      final topEmoji = userMsgs.where((m) => m.emojiCount > 2).toList()
        ..sort((a, b) => b.emojiCount.compareTo(a.emojiCount));
      results.add(MetricResult(
        runId: runId,
        metricKey: MK.emojiRate,
        valueA: rateA,
        valueB: rateB,
        winner: winnerFromValues(rateA, rateB),
        displayValueA: fmtPct(rateA),
        displayValueB: fmtPct(rateB),
        confidence: (withEmojiA + withEmojiB) >= 5 ? MetricConfidence.ok : MetricConfidence.low,
        evidenceMessageIds: topEmoji.take(6).map((m) => m.id).toList(),
        summaryLine: '${rateA > rateB ? personA : personB} uses emojis in more of their messages.',
      ));
    } else {
      results.add(MetricResult.gated(runId, MK.emojiRate));
    }

    // ── Media share ──────────────────────────────────────────────────────────
    final mediaA = aMsgs.where((m) => m.kind == MessageKind.media).toList();
    final mediaB = bMsgs.where((m) => m.kind == MessageKind.media).toList();
    final totalMedia = mediaA.length + mediaB.length;
    if (totalMedia >= 4) {
      final mShareA = mediaA.length / totalMedia;
      final mShareB = mediaB.length / totalMedia;
      results.add(MetricResult(
        runId: runId,
        metricKey: MK.mediaShare,
        valueA: mShareA,
        valueB: mShareB,
        winner: winnerFromValues(mShareA, mShareB),
        displayValueA: fmtPct(mShareA),
        displayValueB: fmtPct(mShareB),
        confidence: MetricConfidence.ok,
        evidenceMessageIds: [...mediaA, ...mediaB]
            .take(6)
            .map((m) => m.id)
            .toList(),
        summaryLine: '$personA sent ${fmtPct(mShareA)} of all media.',
      ));
    } else {
      results.add(MetricResult.gated(runId, MK.mediaShare));
    }

    // ── Deleted / edited rate ────────────────────────────────────────────────
    final delA = aMsgs.where((m) => m.kind == MessageKind.deleted || m.isEdited).toList();
    final delB = bMsgs.where((m) => m.kind == MessageKind.deleted || m.isEdited).toList();
    if (nA > 0 && nB > 0) {
      final drA = delA.length / nA, drB = delB.length / nB;
      results.add(MetricResult(
        runId: runId,
        metricKey: MK.deletedRate,
        valueA: drA,
        valueB: drB,
        winner: winnerFromValues(drA, drB),
        displayValueA: fmtPct(drA),
        displayValueB: fmtPct(drB),
        confidence: (delA.length + delB.length) >= 3
            ? MetricConfidence.ok
            : MetricConfidence.low,
        evidenceMessageIds: [...delA, ...delB].take(6).map((m) => m.id).toList(),
        summaryLine:
            '$personA deleted/edited ${fmtPct(drA)} of their messages.',
      ));
    } else {
      results.add(MetricResult.gated(runId, MK.deletedRate));
    }

    return results;
  }

  static String _msgShareSummary(String a, String b, double shareA) {
    if (shareA > 0.6) return '$a sends noticeably more messages.';
    if (shareA < 0.4) return '$b sends noticeably more messages.';
    return 'Message volume is fairly balanced.';
  }
}
