import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import 'how_to_step.dart';
import 'sticky_import_button.dart';
import 'timeline_header.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onImport;
  const EmptyState({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TimelineHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
