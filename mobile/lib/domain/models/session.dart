class ChatSession {
  final String id;
  final String runId;
  final DateTime startTs;
  final DateTime endTs;
  final String initiatorSender;
  final List<String> messageIds;

  const ChatSession({
    required this.id,
    required this.runId,
    required this.startTs,
    required this.endTs,
    required this.initiatorSender,
    required this.messageIds,
  });

  int get durationSec => endTs.difference(startTs).inSeconds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'runId': runId,
        'startTs': startTs.millisecondsSinceEpoch,
        'endTs': endTs.millisecondsSinceEpoch,
        'initiator': initiatorSender,
        'msgIds': messageIds,
      };

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        id: j['id'] as String,
        runId: j['runId'] as String,
        startTs: DateTime.fromMillisecondsSinceEpoch(j['startTs'] as int),
        endTs: DateTime.fromMillisecondsSinceEpoch(j['endTs'] as int),
        initiatorSender: j['initiator'] as String,
        messageIds: List<String>.from(j['msgIds'] as List),
      );
}
