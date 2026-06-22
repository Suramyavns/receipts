import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../ingest/ingest_service.dart';
import '../../../shared/widgets/primary_button.dart';

class DuplicateView extends StatelessWidget {
  final IngestResult result;
  final VoidCallback onView, onRerun, onBack;
  const DuplicateView({
    super.key,
    required this.result,
    required this.onView,
    required this.onRerun,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isNewer = result.dedupeStatus == DedupeStatus.newerExport;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: neoBox(bg: NeoColors.yellow, offset: 5, radius: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isNewer ? 'Newer export detected' : 'Already analysed',
                    style: neoDisplay(22)),
                const SizedBox(height: 8),
                Text(
                  isNewer
                      ? 'This looks like a newer export of "${result.run.chatTitle}". Re-run to update stats?'
                      : "You've already analysed this exact export.",
                  style: neoBody(14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
              label: 'VIEW EXISTING',
              onTap: onView,
              bg: NeoColors.blue,
              textColor: Colors.white),
          if (isNewer) ...[
            const SizedBox(height: 12),
            PrimaryButton(
                label: 'RE-RUN WITH NEW DATA', onTap: onRerun, bg: NeoColors.lime),
          ],
          const SizedBox(height: 12),
          PrimaryButton(label: 'CANCEL', onTap: onBack, bg: NeoColors.surface),
        ],
      ),
    );
  }
}
