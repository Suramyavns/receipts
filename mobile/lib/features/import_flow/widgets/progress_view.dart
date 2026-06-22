import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';

class ProgressView extends StatelessWidget {
  final List<String> filePaths;
  final String status;
  final int stepIndex;
  final List<String> stepLabels;
  final VoidCallback onCancel;

  const ProgressView({
    super.key,
    required this.filePaths,
    required this.status,
    required this.stepIndex,
    required this.stepLabels,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = filePaths.isNotEmpty ? filePaths.first.split('/').last : 'chat export';
    final pct = ((stepIndex / stepLabels.length) * 100).round();
    final isDone = stepIndex >= stepLabels.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('IMPORTING', style: neoDisplay(17)),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeoColors.surface,
                    border: Border.all(color: NeoColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('CANCEL', style: neoLabel(11)),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: NeoColors.ink, thickness: 3, height: 3),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // File info card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: neoBox(bg: NeoColors.surface, offset: 5, radius: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: neoBox(bg: NeoColors.lime, offset: 0, radius: 6),
                        alignment: Alignment.center,
                        child: const Text('📄', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fileName,
                                style: neoDisplay(14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('shared from WhatsApp',
                                style: neoBody(10, color: NeoColors.ink.withValues(alpha: 0.55))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Progress card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NeoColors.ink,
                    border: Border.all(color: NeoColors.ink, width: 3),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: NeoColors.ink, offset: Offset(5, 5), blurRadius: 0),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('$pct%', style: neoDisplay(34, color: NeoColors.lime)),
                          Text(isDone ? 'DONE' : 'CRUNCHING…',
                              style: neoLabel(11, color: Colors.white).copyWith(letterSpacing: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (pct / 100).clamp(0.0, 1.0),
                            child: Container(color: NeoColors.lime),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Steps
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: neoBox(bg: NeoColors.surface, offset: 4, radius: 8),
                  child: Column(
                    children: stepLabels.asMap().entries.map((e) {
                      final i = e.key;
                      final label = e.value;
                      final done = stepIndex > i;
                      final active = stepIndex == i;
                      return Padding(
                        padding: EdgeInsets.only(bottom: i < stepLabels.length - 1 ? 10 : 0),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: done
                                    ? NeoColors.lime
                                    : active
                                        ? NeoColors.yellow
                                        : NeoColors.surface,
                                border: Border.all(color: NeoColors.ink, width: 2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              alignment: Alignment.center,
                              child: Text(done ? '✓' : '${i + 1}', style: neoHeadline(12)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              label,
                              style: neoBody(13,
                                      color: done || active
                                          ? NeoColors.ink
                                          : NeoColors.ink.withValues(alpha: 0.35))
                                  .copyWith(
                                      fontWeight: done || active
                                          ? FontWeight.w700
                                          : FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '🔒  Parsed in an on-device sandbox. No message ever uploaded.',
                  style: neoBody(10, color: NeoColors.ink.withValues(alpha: 0.45)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
