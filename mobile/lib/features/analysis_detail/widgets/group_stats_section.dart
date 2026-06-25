import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../domain/models/run_message.dart';
import '../../../shared/widgets/section_label.dart';
import 'bar_row.dart';

// ── Data model ───────────────────────────────────────────────────────────────

class _Entry {
  final String name;
  final double barPct;
  final String display;
  _Entry(this.name, this.barPct, this.display);
}

class _GroupMetric {
  final String label;
  final Color accent;
  final List<_Entry> entries;
  _GroupMetric({required this.label, required this.accent, required this.entries});
}

// ── Main widget ───────────────────────────────────────────────────────────────

class GroupStatsSection extends StatelessWidget {
  final List<RunMessage> messages;
  final List<String> participants;

  const GroupStatsSection({
    super.key,
    required this.messages,
    required this.participants,
  });

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

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    if (sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: neoBox(bg: NeoColors.surface, offset: 3),
        child: Text(
          'No messages from selected participants.',
          style: neoBody(14, color: NeoColors.ink.withValues(alpha: 0.6)),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
  }

  List<Widget> _buildSections() {
    final userMsgs = messages
        .where((m) => m.isUserMessage && participants.contains(m.sender))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (userMsgs.isEmpty) return [];

    final byPerson = <String, List<RunMessage>>{
      for (final p in participants)
        p: userMsgs.where((m) => m.sender == p).toList(),
    };
    final textByPerson = <String, List<RunMessage>>{
      for (final p in participants)
        p: byPerson[p]!.where((m) => m.kind == MessageKind.text).toList(),
    };

    final total = userMsgs.length;
    final totalWords = userMsgs.fold(0, (s, m) => s + m.wordCount);

    // ── VOLUME ──────────────────────────────────────────────────────────────
    final volume = <_GroupMetric>[
      _rateMetric('MESSAGES', NeoColors.blue, {
        for (final p in participants) p: byPerson[p]!.length / total,
      }, _pct),
      if (totalWords > 0)
        _rateMetric('WORD SHARE', NeoColors.pink, {
          for (final p in participants)
            p: byPerson[p]!.fold(0, (s, m) => s + m.wordCount) / totalWords,
        }, _pct),
      if (participants.any((p) => textByPerson[p]!.isNotEmpty))
        _absoluteMetric('AVG LENGTH', NeoColors.yellow, {
          for (final p in participants)
            p: textByPerson[p]!.isEmpty
                ? 0.0
                : textByPerson[p]!.fold(0, (s, m) => s + m.wordCount) /
                    textByPerson[p]!.length,
        }, (v) => '${v.toStringAsFixed(1)}w'),
      _rateMetric('EMOJI RATE', NeoColors.lime, {
        for (final p in participants)
          p: byPerson[p]!.isEmpty
              ? 0.0
              : byPerson[p]!.where((m) => m.emojiCount > 0).length /
                  byPerson[p]!.length,
      }, _pct),
    ];

    // ── TIMING ──────────────────────────────────────────────────────────────
    final timing = <_GroupMetric>[];

    final latMap = <String, List<int>>{
      for (final p in participants)
        p: byPerson[p]!
            .where((m) => (m.replyLatencySec ?? 0) > 0)
            .map((m) => m.replyLatencySec!)
            .toList()
          ..sort(),
    };
    if (latMap.values.any((l) => l.length >= 5)) {
      timing.add(_absoluteMetric(
        'REPLY SPEED',
        NeoColors.yellow,
        {
          for (final p in participants)
            p: latMap[p]!.isEmpty
                ? double.infinity
                : _median(latMap[p]!),
        },
        (v) => v.isInfinite ? '—' : _fmtDuration(v.round()),
        lowerIsBetter: true,
      ));
    }

    final doubles = <String, int>{for (final p in participants) p: 0};
    for (int i = 1; i < userMsgs.length; i++) {
      final prev = userMsgs[i - 1], cur = userMsgs[i];
      if (cur.sender != prev.sender) continue;
      if (!doubles.containsKey(cur.sender)) continue;
      final gap = cur.timestamp.difference(prev.timestamp).inSeconds;
      if (gap <= 30) continue;
      doubles[cur.sender] = doubles[cur.sender]! + 1;
    }
    if (doubles.values.any((d) => d > 0)) {
      timing.add(_rateMetric('DOUBLE-TEXTS', NeoColors.blue, {
        for (final p in participants)
          p: byPerson[p]!.isEmpty ? 0.0 : doubles[p]! / byPerson[p]!.length,
      }, _pct));
    }

    // ── TONE ────────────────────────────────────────────────────────────────
    final tone = <_GroupMetric>[
      _rateMetric('LAUGHTER', NeoColors.yellow, {
        for (final p in participants)
          p: textByPerson[p]!.isEmpty
              ? 0.0
              : textByPerson[p]!.where((m) => _laughRe.hasMatch(m.body)).length /
                  textByPerson[p]!.length,
      }, _pct),
      _rateMetric('QUESTION RATE', NeoColors.lime, {
        for (final p in participants)
          p: byPerson[p]!.isEmpty
              ? 0.0
              : byPerson[p]!.where((m) => m.hasQuestion).length /
                  byPerson[p]!.length,
      }, _pct),
      _rateMetric('AFFECTION', NeoColors.blue, {
        for (final p in participants)
          p: textByPerson[p]!.isEmpty
              ? 0.0
              : textByPerson[p]!
                      .where((m) => _affectionRe.hasMatch(m.body))
                      .length /
                  textByPerson[p]!.length,
      }, _pct),
    ];

    final divVals = <String, double>{};
    for (final p in participants) {
      final emojis = textByPerson[p]!
          .expand((m) => _emojiRe.allMatches(m.body).map((x) => x.group(0)!))
          .toList();
      divVals[p] = emojis.length >= 10 ? _shannonEntropy(emojis) : 0.0;
    }
    if (divVals.values.any((v) => v > 0)) {
      tone.add(_absoluteMetric(
        'EMOJI VARIETY',
        NeoColors.pink,
        divVals,
        (v) => v.toStringAsFixed(2),
      ));
    }

    final built = [
      _section('VOLUME', volume),
      _section('TIMING', timing),
      _section('TONE', tone),
    ].whereType<Widget>().toList();

    final result = <Widget>[];
    for (int i = 0; i < built.length; i++) {
      if (i > 0) result.add(const SizedBox(height: 14));
      result.add(built[i]);
    }
    return result;
  }

  Widget? _section(String label, List<_GroupMetric> metrics) {
    if (metrics.isEmpty) return null;
    final rows = <Widget>[SectionLabel(label), const SizedBox(height: 11)];
    for (int i = 0; i < metrics.length; i += 2) {
      final pair = metrics.sublist(i, math.min(i + 2, metrics.length));
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int j = 0; j < pair.length; j++) ...[
              if (j > 0) const SizedBox(width: 12),
              Expanded(child: _GroupMetricCard(metric: pair[j])),
            ],
          ],
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  // ── Metric builders ──────────────────────────────────────────────────────

  static _GroupMetric _rateMetric(
    String label,
    Color accent,
    Map<String, double> values,
    String Function(double) fmt,
  ) {
    final entries = values.entries
        .map((e) => _Entry(e.key, e.value.clamp(0.0, 1.0), fmt(e.value)))
        .toList()
      ..sort((a, b) => b.barPct.compareTo(a.barPct));
    return _GroupMetric(label: label, accent: accent, entries: entries);
  }

  static _GroupMetric _absoluteMetric(
    String label,
    Color accent,
    Map<String, double> values,
    String Function(double) fmt, {
    bool lowerIsBetter = false,
  }) {
    final finite = values.values.where((v) => v.isFinite).toList();
    if (finite.isEmpty) {
      return _GroupMetric(
        label: label,
        accent: accent,
        entries: values.keys.map((p) => _Entry(p, 0.0, '—')).toList(),
      );
    }
    final maxV = finite.reduce(math.max);
    final minV = finite.reduce(math.min);
    final range = maxV - minV;

    double barFor(double v) {
      if (!v.isFinite) return 0.0;
      if (range == 0) return 1.0;
      final norm = (v - minV) / range;
      return lowerIsBetter ? 1.0 - norm : norm;
    }

    final entries = values.entries
        .map((e) => _Entry(
              e.key,
              barFor(e.value),
              e.value.isInfinite ? '—' : fmt(e.value),
            ))
        .toList()
      ..sort((a, b) {
        final va = values[a.name]!;
        final vb = values[b.name]!;
        if (!va.isFinite) return 1;
        if (!vb.isFinite) return -1;
        return lowerIsBetter ? va.compareTo(vb) : vb.compareTo(va);
      });
    return _GroupMetric(label: label, accent: accent, entries: entries);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _pct(double v) => '${(v * 100).toStringAsFixed(0)}%';

  static double _median(List<int> sorted) {
    final n = sorted.length;
    if (n % 2 == 1) return sorted[n ~/ 2].toDouble();
    return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;
  }

  static String _fmtDuration(int secs) {
    if (secs < 60) return '<1 min';
    if (secs < 3600) return '${(secs / 60).round()} min';
    if (secs < 86400) return '${(secs / 3600).toStringAsFixed(1)} h';
    return '${(secs / 86400).toStringAsFixed(1)} d';
  }

  static double _shannonEntropy(List<String> items) {
    final freq = <String, int>{};
    for (final e in items) {
      freq[e] = (freq[e] ?? 0) + 1;
    }
    final n = items.length;
    double entropy = 0;
    for (final count in freq.values) {
      final p = count / n;
      entropy -= p * math.log(p) / math.ln2;
    }
    return entropy;
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────

class _GroupMetricCard extends StatelessWidget {
  final _GroupMetric metric;
  const _GroupMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: neoBox(bg: NeoColors.surface, offset: 4, radius: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  metric.label,
                  style: neoLabel(10).copyWith(letterSpacing: 0.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                color: metric.accent,
                foregroundDecoration: BoxDecoration(
                  border: Border.all(color: NeoColors.ink, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...metric.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: BarRow(
                  name: e.name.split(' ').first.toUpperCase(),
                  value: e.display,
                  pct: e.barPct,
                  accent: metric.accent,
                ),
              )),
        ],
      ),
    );
  }
}
