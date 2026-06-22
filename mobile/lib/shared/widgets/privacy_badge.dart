import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

class PrivacyBadge extends StatelessWidget {
  const PrivacyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeoColors.ink,
        border: Border.all(color: NeoColors.ink, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: NeoColors.lime,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text('ON-DEVICE',
              style:
                  neoLabel(10, color: NeoColors.lime).copyWith(letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
