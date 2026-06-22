import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';

class BarRow extends StatelessWidget {
  final String name, value;
  final double pct;
  final Color accent;
  const BarRow({
    super.key,
    required this.name,
    required this.value,
    required this.pct,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(name, style: neoLabel(9), maxLines: 1, overflow: TextOverflow.clip),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 13,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: NeoColors.ink, width: 2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(color: accent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 46,
          child: Text(value,
              style: neoDisplay(12),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
