import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import 'neo_card.dart';

class NeoChartFrame extends StatelessWidget {
  final String title;
  final Widget chart;
  final double height;

  const NeoChartFrame({
    super.key,
    required this.title,
    required this.chart,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: neoBody(12, color: NeoColors.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 10),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }
}
