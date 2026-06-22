class HeadlineStat {
  final String key;
  final String text;
  const HeadlineStat({required this.key, required this.text});

  Map<String, dynamic> toJson() => {'key': key, 'text': text};
  factory HeadlineStat.fromJson(Map<String, dynamic> j) =>
      HeadlineStat(key: j['key'] as String, text: j['text'] as String);
}

class AnalysisRun {
  final String id;
  final DateTime importedAt;
  final String chatTitle;
  final bool isGroup;
  final List<String> participants;
  final String personA;
  final String personB;
  final int messageCount;
  final int mediaCount;
  final int systemCount;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final String sourceHash;
  final String exportFormat;
  final HeadlineStat? headline;
  final bool notEnoughData;

  const AnalysisRun({
    required this.id,
    required this.importedAt,
    required this.chatTitle,
    required this.isGroup,
    required this.participants,
    required this.personA,
    required this.personB,
    required this.messageCount,
    required this.mediaCount,
    required this.systemCount,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.sourceHash,
    required this.exportFormat,
    this.headline,
    this.notEnoughData = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'importedAt': importedAt.millisecondsSinceEpoch,
        'chatTitle': chatTitle,
        'isGroup': isGroup,
        'participants': participants,
        'personA': personA,
        'personB': personB,
        'messageCount': messageCount,
        'mediaCount': mediaCount,
        'systemCount': systemCount,
        'dateRangeStart': dateRangeStart.millisecondsSinceEpoch,
        'dateRangeEnd': dateRangeEnd.millisecondsSinceEpoch,
        'sourceHash': sourceHash,
        'exportFormat': exportFormat,
        'headline': headline?.toJson(),
        'notEnoughData': notEnoughData,
      };

  factory AnalysisRun.fromJson(Map<String, dynamic> j) => AnalysisRun(
        id: j['id'] as String,
        importedAt: DateTime.fromMillisecondsSinceEpoch(j['importedAt'] as int),
        chatTitle: j['chatTitle'] as String,
        isGroup: j['isGroup'] as bool,
        participants: List<String>.from(j['participants'] as List),
        personA: j['personA'] as String,
        personB: j['personB'] as String,
        messageCount: j['messageCount'] as int,
        mediaCount: j['mediaCount'] as int,
        systemCount: j['systemCount'] as int,
        dateRangeStart: DateTime.fromMillisecondsSinceEpoch(j['dateRangeStart'] as int),
        dateRangeEnd: DateTime.fromMillisecondsSinceEpoch(j['dateRangeEnd'] as int),
        sourceHash: j['sourceHash'] as String,
        exportFormat: j['exportFormat'] as String,
        headline: j['headline'] != null
            ? HeadlineStat.fromJson(j['headline'] as Map<String, dynamic>)
            : null,
        notEnoughData: j['notEnoughData'] as bool? ?? false,
      );

  AnalysisRun copyWith({
    HeadlineStat? headline,
    bool? notEnoughData,
    String? personA,
    String? personB,
  }) =>
      AnalysisRun(
        id: id,
        importedAt: importedAt,
        chatTitle: chatTitle,
        isGroup: isGroup,
        participants: participants,
        personA: personA ?? this.personA,
        personB: personB ?? this.personB,
        messageCount: messageCount,
        mediaCount: mediaCount,
        systemCount: systemCount,
        dateRangeStart: dateRangeStart,
        dateRangeEnd: dateRangeEnd,
        sourceHash: sourceHash,
        exportFormat: exportFormat,
        headline: headline ?? this.headline,
        notEnoughData: notEnoughData ?? this.notEnoughData,
      );
}
