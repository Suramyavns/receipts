enum MessageKind { text, media, deleted, system, empty }

enum MediaType { photo, video, voice, sticker, gif, doc, contact }

class RunMessage {
  final String id;
  final String runId;
  final DateTime timestamp;
  final String sender;
  final String body;
  final MessageKind kind;
  final MediaType? mediaType;
  final bool isEdited;
  final int wordCount;
  final int charCount;
  final int emojiCount;
  final bool hasQuestion;
  String? sessionId;
  int? turnId;
  bool isInitiator;
  int? replyLatencySec;

  RunMessage({
    required this.id,
    required this.runId,
    required this.timestamp,
    required this.sender,
    required this.body,
    required this.kind,
    this.mediaType,
    this.isEdited = false,
    required this.wordCount,
    required this.charCount,
    required this.emojiCount,
    required this.hasQuestion,
    this.sessionId,
    this.turnId,
    this.isInitiator = false,
    this.replyLatencySec,
  });

  bool get isContent => kind == MessageKind.text || kind == MessageKind.empty;
  bool get isUserMessage => kind != MessageKind.system && sender.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'runId': runId,
        'ts': timestamp.millisecondsSinceEpoch,
        'sender': sender,
        'body': body,
        'kind': kind.index,
        'mediaType': mediaType?.index,
        'isEdited': isEdited,
        'wc': wordCount,
        'cc': charCount,
        'ec': emojiCount,
        'hq': hasQuestion,
        'sid': sessionId,
        'tid': turnId,
        'init': isInitiator,
        'rls': replyLatencySec,
      };

  factory RunMessage.fromJson(Map<String, dynamic> j) {
    final msg = RunMessage(
      id: j['id'] as String,
      runId: j['runId'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
      sender: j['sender'] as String,
      body: j['body'] as String,
      kind: MessageKind.values[j['kind'] as int],
      mediaType: j['mediaType'] != null ? MediaType.values[j['mediaType'] as int] : null,
      isEdited: j['isEdited'] as bool? ?? false,
      wordCount: j['wc'] as int,
      charCount: j['cc'] as int,
      emojiCount: j['ec'] as int,
      hasQuestion: j['hq'] as bool,
      sessionId: j['sid'] as String?,
      turnId: j['tid'] as int?,
      isInitiator: j['init'] as bool? ?? false,
      replyLatencySec: j['rls'] as int?,
    );
    return msg;
  }
}
