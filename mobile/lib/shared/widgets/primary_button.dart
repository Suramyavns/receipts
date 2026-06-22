import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.bg,
    this.textColor = NeoColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: neoBox(bg: onTap != null ? bg : NeoColors.surface, offset: 5, radius: 8),
        alignment: Alignment.center,
        child: Text(
          label,
          style: neoDisplay(16,
                  color: onTap != null
                      ? textColor
                      : NeoColors.ink.withValues(alpha: 0.35))
              .copyWith(letterSpacing: 0.5),
        ),
      ),
    );
  }
}
