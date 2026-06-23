enum MetricConfidence { ok, low, na }

enum MetricWinner { personA, personB, tie, na }

class MetricResult {
  final String runId;
  final String metricKey;
  final double? valueA;
  final double? valueB;
  final double? scalar;
  final MetricWinner winner;
  final String displayValueA;
  final String displayValueB;
  final MetricConfidence confidence;
  final List<String> evidenceMessageIds;
  final String summaryLine;

  const MetricResult({
    required this.runId,
    required this.metricKey,
    this.valueA,
    this.valueB,
    this.scalar,
    this.winner = MetricWinner.na,
    this.displayValueA = '—',
    this.displayValueB = '—',
    this.confidence = MetricConfidence.na,
    this.evidenceMessageIds = const [],
    this.summaryLine = '',
  });

  bool get isGated => confidence == MetricConfidence.na;

  static MetricResult gated(String runId, String key) => MetricResult(
        runId: runId,
        metricKey: key,
        confidence: MetricConfidence.na,
        summaryLine: 'Not enough data',
      );

  Map<String, dynamic> toJson() => {
        'runId': runId,
        'key': metricKey,
        'vA': valueA,
        'vB': valueB,
        'sc': scalar,
        'win': winner.index,
        'dvA': displayValueA,
        'dvB': displayValueB,
        'conf': confidence.index,
        'ev': evidenceMessageIds,
        'sum': summaryLine,
      };

  factory MetricResult.fromJson(Map<String, dynamic> j) => MetricResult(
        runId: j['runId'] as String,
        metricKey: j['key'] as String,
        valueA: (j['vA'] as num?)?.toDouble(),
        valueB: (j['vB'] as num?)?.toDouble(),
        scalar: (j['sc'] as num?)?.toDouble(),
        winner: MetricWinner.values[j['win'] as int? ?? 3],
        displayValueA: j['dvA'] as String? ?? '—',
        displayValueB: j['dvB'] as String? ?? '—',
        confidence: MetricConfidence.values[j['conf'] as int? ?? 2],
        evidenceMessageIds: List<String>.from(j['ev'] as List? ?? []),
        summaryLine: j['sum'] as String? ?? '',
      );
}

// Metric key constants
class MK {
  static const messageShare = 'message_share';
  static const wordShare = 'word_share';
  static const avgMessageLength = 'avg_message_length';
  static const emojiRate = 'emoji_rate';
  static const mediaShare = 'media_share';
  static const deletedRate = 'deleted_rate';
  static const replyLatency = 'reply_latency';
  static const initiationRatio = 'initiation_ratio';
  static const doubleTextRate = 'double_text_rate';
  static const lastWordRatio = 'last_word_ratio';
  static const ghostRate = 'ghost_rate';
  static const silenceBreakerRatio = 'silence_breaker_ratio';
  static const backForthDensity = 'back_forth_density';
  static const momentumTrend = 'momentum_trend';
  static const questionRate = 'question_rate';
  static const laughterRate = 'laughter_rate';
  static const affectionIndex = 'affection_index';
  static const investmentIndex = 'investment_index';
  static const balanceScore = 'balance_score';
  static const pursuitGap = 'pursuit_gap';
  static const reciprocityIndex = 'reciprocity_index';
  static const relationshipHealth = 'relationship_health';
  static const emojiDiversity = 'emoji_diversity';
  static const activeHoursOverlap = 'active_hours_overlap';
  static const dryTexterScore = 'dry_texter_score';
}
