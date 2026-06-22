import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/tokens.dart';
import '../../domain/models/analysis_run.dart';

final _dateFmt = DateFormat('MMM d, yyyy');

class NeoTimelineNode extends StatelessWidget {
  final AnalysisRun run;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NeoTimelineNode({
    super.key,
    required this.run,
    this.isFirst = false,
    this.isLast = false,
    this.isSelected = false,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Connector ─────────────────────────────────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                      child: Center(
                          child: Container(width: 2, color: NeoColors.ink))),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isSelected ? NeoColors.blue : NeoColors.yellow,
                    border: Border.all(color: NeoColors.ink, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                      child: Center(
                          child: Container(width: 2, color: NeoColors.ink))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Card ──────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  decoration: neoBox(
                    bg: run.notEnoughData ? NeoColors.surface : NeoColors.cardBg,
                    offset: 3,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(run.chatTitle,
                                style: neoHeadline(16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          _TypeChip(isGroup: run.isGroup),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(Icons.delete_outline,
                                size: 18,
                                color: NeoColors.ink.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${run.personA} & ${run.personB}',
                        style: neoBody(12,
                            color: NeoColors.ink.withValues(alpha: 0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (run.headline != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          color: NeoColors.lime,
                          child: Text(run.headline!.text,
                              style: neoBody(12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _dateFmt.format(run.importedAt),
                            style: neoBody(11,
                                color: NeoColors.ink.withValues(alpha: 0.45)),
                          ),
                          const SizedBox(width: 8),
                          Text('·', style: neoBody(11)),
                          const SizedBox(width: 8),
                          Text(
                            '${_compact(run.messageCount)} msgs',
                            style: neoBody(11,
                                color: NeoColors.ink.withValues(alpha: 0.45)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _TypeChip extends StatelessWidget {
  final bool isGroup;
  const _TypeChip({required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isGroup ? NeoColors.pink : NeoColors.blue,
        border: Border.all(color: NeoColors.ink, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        isGroup ? 'group' : '1:1',
        style: neoBody(10, color: NeoColors.ink),
      ),
    );
  }
}
