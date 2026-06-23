import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';

class StickyImportButton extends StatelessWidget {
  final VoidCallback onImport;
  const StickyImportButton({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [NeoColors.cream.withValues(alpha: 0), NeoColors.cream],
          stops: const [0, 0.35],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onImport,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: neoBox(bg: NeoColors.blue, offset: 5, shadowColor: NeoColors.ink, radius: 8),
              alignment: Alignment.center,
              child: Text(
                '＋  SHARE A CHAT EXPORT',
                style: neoDisplay(16, color: Colors.white).copyWith(letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '🔒  Computed on your phone · never uploaded · delete anytime',
            style: neoBody(10, color: NeoColors.ink.withValues(alpha: 0.45)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
