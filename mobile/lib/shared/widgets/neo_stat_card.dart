import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import 'neo_card.dart';

/// Large number + label card. Optionally shows a winner chip.
class NeoStatCard extends StatelessWidget {
  final String label;
  final String valueA;
  final String valueB;
  final String nameA;
  final String nameB;
  final Color accentA;
  final Color accentB;
  final String? confidenceLabel;
  final VoidCallback? onTap;

  const NeoStatCard({
    super.key,
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.nameA,
    required this.nameB,
    this.accentA = NeoColors.blue,
    this.accentB = NeoColors.pink,
    this.confidenceLabel,
    this.onTap,
  });

  /// Single scalar value (no A/B split).
  const NeoStatCard.scalar({
    super.key,
    required this.label,
    required this.valueA,
    this.valueB = '',
    this.nameA = '',
    this.nameB = '',
    this.accentA = NeoColors.blue,
    this.accentB = NeoColors.pink,
    this.confidenceLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isScalar = nameA.isEmpty;
    return NeoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: neoBody(12,
                        color: NeoColors.ink.withValues(alpha: 0.6))),
              ),
              if (confidenceLabel != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: NeoColors.yellow,
                    border: Border.all(color: NeoColors.ink, width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(confidenceLabel!,
                      style: neoBody(9,
                          color: NeoColors.ink.withValues(alpha: 0.7))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (isScalar)
            Text(valueA, style: neoDisplay(32))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _Half(name: nameA, value: valueA, accent: accentA)),
                const SizedBox(width: 8),
                Expanded(child: _Half(name: nameB, value: valueB, accent: accentB)),
              ],
            ),
          if (onTap != null) ...[
            const SizedBox(height: 8),
            Text('See the receipts →',
                style: neoBody(11,
                    color: NeoColors.ink.withValues(alpha: 0.5))),
          ],
        ],
      ),
    );
  }
}

class _Half extends StatelessWidget {
  final String name, value;
  final Color accent;
  const _Half({required this.name, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: accent,
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: neoBody(10, color: NeoColors.ink)),
        ),
        const SizedBox(height: 4),
        Text(value, style: neoDisplay(24)),
      ],
    );
  }
}
