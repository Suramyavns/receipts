import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';

class HowToStep extends StatelessWidget {
  final int num;
  final String text;
  final Color accent;
  const HowToStep(this.num, this.text, this.accent, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent,
              border: Border.all(color: NeoColors.ink, width: 2),
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(color: NeoColors.ink, offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            child: Text('$num', style: neoHeadline(12, color: NeoColors.ink)),
          ),
          const SizedBox(width: 14),
          Text(text, style: neoBody(14)),
        ],
      ),
    );
  }
}
