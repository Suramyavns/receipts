import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/primary_button.dart';

class ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onBack;
  const ErrorView({super.key, required this.error, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: neoBox(
                bg: NeoColors.pink.withValues(alpha: 0.15), offset: 5, radius: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Parse error', style: neoDisplay(22)),
                const SizedBox(height: 8),
                Text(error, style: neoBody(13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'GO BACK', onTap: onBack, bg: NeoColors.surface),
        ],
      ),
    );
  }
}
