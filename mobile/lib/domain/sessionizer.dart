import 'models/run_message.dart';
import 'models/session.dart';

class Sessionizer {
  /// Splits messages into sessions and mutates them with sessionId, turnId,
  /// isInitiator, and replyLatencySec.
  static List<ChatSession> sessionize(List<RunMessage> messages, String runId) {
    final userMsgs = messages.where((m) => m.isUserMessage).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (userMsgs.isEmpty) return [];

    final tGap = _adaptiveGap(userMsgs);

    final sessions = <ChatSession>[];
    var sessionMsgIds = <String>[];
    var sessionStart = userMsgs.first.timestamp;
    var sessionEnd = userMsgs.first.timestamp;
    String? sessionInitiator;
    var turn = 0;
    String? lastSender;

    int sessionIdx = 0;

    void closeSession() {
      if (sessionMsgIds.isEmpty) return;
      final sid = '${runId}_s$sessionIdx';
      sessions.add(ChatSession(
        id: sid,
        runId: runId,
        startTs: sessionStart,
        endTs: sessionEnd,
        initiatorSender: sessionInitiator!,
        messageIds: List.unmodifiable(sessionMsgIds),
      ));
      sessionIdx++;
      sessionMsgIds = [];
      sessionInitiator = null;
      lastSender = null;
      turn = 0;
    }

    for (int i = 0; i < userMsgs.length; i++) {
      final msg = userMsgs[i];
      final gapSec = i == 0
          ? 0
          : msg.timestamp.difference(userMsgs[i - 1].timestamp).inSeconds;

      if (i > 0 && gapSec >= tGap) {
        closeSession();
      }

      if (sessionMsgIds.isEmpty) {
        sessionStart = msg.timestamp;
        sessionInitiator = msg.sender;
        msg.isInitiator = true;
        turn = 0;
      }

      sessionEnd = msg.timestamp;
      final sid = '${runId}_s$sessionIdx';
      msg.sessionId = sid;

      if (msg.sender != lastSender) {
        turn++;
        lastSender = msg.sender;
      }
      msg.turnId = turn;

      if (i > 0 && !msg.isInitiator) {
        final prev = userMsgs[i - 1];
        if (prev.sender != msg.sender) {
          final gapS = msg.timestamp.difference(prev.timestamp).inSeconds;
          if (gapS < tGap) {
            msg.replyLatencySec = gapS;
          }
        }
      }

      sessionMsgIds.add(msg.id);
    }

    closeSession();
    return sessions;
  }

  /// Adaptive gap: 90th percentile of inter-message gaps, clamped to [1h, 12h].
  static int _adaptiveGap(List<RunMessage> msgs) {
    if (msgs.length < 2) return 6 * 3600;
    final gaps = <int>[];
    for (int i = 1; i < msgs.length; i++) {
      gaps.add(msgs[i].timestamp.difference(msgs[i - 1].timestamp).inSeconds);
    }
    gaps.sort();
    final p90idx = ((gaps.length - 1) * 0.9).round();
    final p90 = gaps[p90idx];
    return p90.clamp(3600, 12 * 3600);
  }

  static double adaptiveGapHours(List<RunMessage> messages) {
    final userMsgs = messages.where((m) => m.isUserMessage).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return _adaptiveGap(userMsgs) / 3600.0;
  }
}
