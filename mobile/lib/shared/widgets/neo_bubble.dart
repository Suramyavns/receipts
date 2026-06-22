import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/tokens.dart';
import '../../domain/models/run_message.dart';

final _timeFmt = DateFormat('h:mm a');

class NeoBubble extends StatelessWidget {
  final RunMessage message;
  final bool isPersonA;
  final Color accentA;
  final Color accentB;

  const NeoBubble({
    super.key,
    required this.message,
    required this.isPersonA,
    this.accentA = NeoColors.blue,
    this.accentB = NeoColors.pink,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = !isPersonA; // "mine" = right side = person B perspective
    final bubbleBg = isMine ? NeoColors.blue : NeoColors.surface;
    final textColor = isMine ? Colors.white : NeoColors.ink;
    final timeColor = isMine
        ? Colors.white.withValues(alpha: 0.7)
        : NeoColors.ink.withValues(alpha: 0.5);
    final borderRadius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(2),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(2),
            bottomRight: Radius.circular(12),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bubbleBg,
              border: Border.all(color: NeoColors.ink, width: 2),
              borderRadius: borderRadius,
              boxShadow: const [
                BoxShadow(
                    color: NeoColors.ink,
                    offset: Offset(3, 3),
                    blurRadius: 0),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(_bodyText(), style: neoBody(13, color: textColor)
                    .copyWith(height: 1.35)),
                const SizedBox(height: 4),
                Text(
                  '${message.sender} · ${_timeFmt.format(message.timestamp)}',
                  style: neoBody(9, color: timeColor),
                  textAlign: isMine ? TextAlign.right : TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _bodyText() {
    switch (message.kind) {
      case MessageKind.media:
        return '📷 ${message.mediaType?.name ?? 'Media'}';
      case MessageKind.deleted:
        return '🗑 This message was deleted';
      case MessageKind.system:
        return '⚙️ ${message.body}';
      case MessageKind.empty:
        return '(empty)';
      case MessageKind.text:
        return message.body;
    }
  }
}

/// Gap marker shown between message clusters (e.g. "4 hours of silence")
class NeoBubbleGap extends StatelessWidget {
  final String label;
  const NeoBubbleGap({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          label.toUpperCase(),
          style: neoLabel(10,
              color: NeoColors.ink.withValues(alpha: 0.5))
              .copyWith(letterSpacing: 1),
        ),
      ),
    );
  }
}
