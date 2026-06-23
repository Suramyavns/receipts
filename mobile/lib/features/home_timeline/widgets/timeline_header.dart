import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/privacy_badge.dart';

class TimelineHeader extends StatelessWidget {
  const TimelineHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Receipts',
                    style: neoDisplay(30).copyWith(height: 0.92, letterSpacing: -1)),
                const SizedBox(height: 10),
                Text(
                  'Your analyses. Nothing ever leaves this phone.',
                  style: neoBody(13, color: NeoColors.ink.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          const PrivacyBadge(),
        ],
      ),
    );
  }
}
