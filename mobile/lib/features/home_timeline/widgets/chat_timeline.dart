import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/repository.dart';
import '../../../domain/models/analysis_run.dart';
import '../../../shared/widgets/neo_timeline_node.dart';
import '../../../shared/widgets/privacy_badge.dart';
import '../../analysis_detail/analysis_detail_screen.dart';
import 'sticky_import_button.dart';

class ChatTimeline extends StatelessWidget {
  final List<AnalysisRun> runs;
  final WidgetRef ref;
  final VoidCallback onImport;
  final StateProvider<List<AnalysisRun>> runsProvider;

  const ChatTimeline({
    super.key,
    required this.runs,
    required this.ref,
    required this.onImport,
    required this.runsProvider,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<AnalysisRun>>{};
    for (final run in runs) {
      groups.putIfAbsent(run.chatTitle, () => []).add(run);
    }

    DateTime latestImport(String title) => groups[title]!
        .map((r) => r.importedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final chatTitles = groups.keys.toList()
      ..sort((a, b) => latestImport(b).compareTo(latestImport(a)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipts',
                        style: neoDisplay(30).copyWith(height: 0.92, letterSpacing: -1)),
                    const SizedBox(height: 10),
                    Text(
                      'Your analyses. Nothing ever leaves this phone.',
                      style: neoBody(13, color: NeoColors.ink.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              const PrivacyBadge(),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            itemCount: chatTitles.length,
            itemBuilder: (ctx, gi) {
              final title = chatTitles[gi];
              final groupRuns = groups[title]!;
              final accent = accentAt(gi);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groupRuns.asMap().entries.map((e) {
                  final run = e.value;
                  final i = e.key;
                  return NeoTimelineNode(
                    run: run,
                    isFirst: gi == 0 && i == 0,
                    isLast: gi == chatTitles.length - 1 && i == groupRuns.length - 1,
                    accentColor: accent,
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => AnalysisDetailScreen(run: run)),
                    ).then((_) {
                      ref.read(runsProvider.notifier).state = Repository.allRuns();
                    }),
                    onDelete: () => _confirmDelete(ctx, run, ref),
                  );
                }).toList(),
              );
            },
          ),
        ),
        StickyImportButton(onImport: onImport),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, AnalysisRun run, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: NeoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: NeoColors.ink, width: 3),
        ),
        title: Text('Delete analysis?', style: neoHeadline(18)),
        content: Text(
            'This removes all computed stats for "${run.chatTitle}".',
            style: neoBody(14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: neoBody(14))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: neoBody(14, color: NeoColors.pink))),
        ],
      ),
    );
    if (ok == true) {
      await Repository.deleteRun(run.id);
      ref.read(runsProvider.notifier).state = Repository.allRuns();
    }
  }
}
