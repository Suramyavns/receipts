import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/tokens.dart';
import '../../domain/models/run_message.dart';

final _timeFmt = DateFormat('HH:mm · MMM d');

/// Renders a single message as a faux chat bubble for the evidence screen.
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
    final accent = isPersonA ? accentA : accentB;
    final align = isPersonA ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final bodyText = _bodyText();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment:
                isPersonA ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(message.sender,
                  style: neoBody(11,
                      color: NeoColors.ink.withValues(alpha: 0.55))),
              const SizedBox(width: 8),
              Text(_timeFmt.format(message.timestamp),
                  style: neoBody(10,
                      color: NeoColors.ink.withValues(alpha: 0.4))),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              border: Border.all(color: NeoColors.ink, width: 1.5),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                    color: NeoColors.ink,
                    offset: const Offset(2, 2),
                    blurRadius: 0),
              ],
            ),
            child: Text(bodyText, style: neoBody(14)),
          ),
        ],
      ),
    );
  }

  String _bodyText() {
    switch (message.kind) {
      case MessageKind.media:
        return '📎 ${message.mediaType?.name ?? 'media'}';
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
