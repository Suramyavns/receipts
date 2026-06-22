import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/privacy_badge.dart';
import 'how_to_step.dart';
import 'sticky_import_button.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onImport;
  const EmptyState({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('Receipts',
                          style: neoDisplay(30).copyWith(height: 0.92, letterSpacing: -1)),
                    ),
                    const PrivacyBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your analyses. Nothing ever leaves this phone.',
                  style: neoBody(13, color: NeoColors.ink.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 28),
                Text('HOW TO EXPORT',
                    style: neoLabel(10, color: NeoColors.ink.withValues(alpha: 0.4))
                        .copyWith(letterSpacing: 1.5)),
                const SizedBox(height: 16),
                const HowToStep(1, 'Open a WhatsApp chat', NeoColors.blue),
                const HowToStep(2, 'Tap ⋮ → More → Export Chat', NeoColors.pink),
                const HowToStep(3, 'Choose "Without Media"', NeoColors.lime),
                const HowToStep(4, 'Share to Receipts', NeoColors.yellow),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        StickyImportButton(onImport: onImport),
      ],
    );
  }
}
