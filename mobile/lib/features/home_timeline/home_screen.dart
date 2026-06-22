import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../../data/repository.dart';
import '../../domain/models/analysis_run.dart';
import '../../ingest/ingest_service.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/neo_timeline_node.dart';
import '../analysis_detail/analysis_detail_screen.dart';
import '../import_flow/import_screen.dart';

final _runsProvider = StateProvider<List<AnalysisRun>>(
    (ref) => Repository.allRuns());

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runs = ref.watch(_runsProvider);

    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(
        title: Text('Receipts', style: neoDisplay(22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () => _pickAndImport(context, ref),
            tooltip: 'Import chat',
          ),
        ],
      ),
      body: runs.isEmpty ? _EmptyState(onImport: () => _pickAndImport(context, ref)) : _Timeline(runs: runs, ref: ref),
    );
  }

  Future<void> _pickAndImport(BuildContext context, WidgetRef ref) async {
    final paths = await IngestService.pickFile();
    if (paths == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImportScreen(
          filePaths: paths,
          onComplete: (_) => ref.read(_runsProvider.notifier).state = Repository.allRuns(),
        ),
      ),
    );
    ref.read(_runsProvider.notifier).state = Repository.allRuns();
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onImport;
  const _EmptyState({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No chats yet.', style: neoDisplay(32)),
          const SizedBox(height: 12),
          Text(
            'Share a WhatsApp export (.txt or .zip) to begin.',
            style: neoBody(16, color: NeoColors.ink.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),
          _HowToStep('1', 'Open a WhatsApp chat'),
          _HowToStep('2', 'Tap ⋮ → More → Export Chat'),
          _HowToStep('3', 'Choose "Without Media"'),
          _HowToStep('4', 'Share to ChatStat'),
          const SizedBox(height: 40),
          NeoButton(label: 'Import from Files', onPressed: onImport),
        ],
      ),
    );
  }
}

class _HowToStep extends StatelessWidget {
  final String num, text;
  const _HowToStep(this.num, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NeoColors.yellow,
              border: Border.all(color: NeoColors.ink, width: 2),
              shape: BoxShape.circle,
            ),
            child: Text(num, style: neoHeadline(13)),
          ),
          const SizedBox(width: 12),
          Text(text, style: neoBody(15)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<AnalysisRun> runs;
  final WidgetRef ref;

  const _Timeline({required this.runs, required this.ref});

  @override
  Widget build(BuildContext context) {
    // Group runs by chatTitle to show evolution
    final groups = <String, List<AnalysisRun>>{};
    for (final run in runs) {
      groups.putIfAbsent(run.chatTitle, () => []).add(run);
    }

    DateTime latestImport(String title) =>
        groups[title]!.map((r) => r.importedAt).reduce((a, b) => a.isAfter(b) ? a : b);

    final chatTitles = groups.keys.toList()
      ..sort((a, b) => latestImport(b).compareTo(latestImport(a)));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: chatTitles.length,
      itemBuilder: (ctx, gi) {
        final title = chatTitles[gi];
        final groupRuns = groups[title]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupRuns.length > 1) ...[
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 16, bottom: 4),
                child: Text(title,
                    style: neoBody(11,
                        color: NeoColors.ink.withValues(alpha: 0.5))),
              ),
            ] else
              const SizedBox(height: 12),
            ...groupRuns.asMap().entries.map((e) {
              final run = e.value;
              final i = e.key;
              return NeoTimelineNode(
                run: run,
                isFirst: i == 0,
                isLast: i == groupRuns.length - 1,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => AnalysisDetailScreen(run: run),
                  ),
                ).then((_) {
                  ref.read(_runsProvider.notifier).state =
                      Repository.allRuns();
                }),
                onDelete: () => _confirmDelete(ctx, run),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, AnalysisRun run) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: NeoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: NeoColors.ink, width: 2),
        ),
        title: Text('Delete analysis?', style: neoHeadline(18)),
        content: Text(
            'This removes all computed stats for "${run.chatTitle}". The original export is not affected.',
            style: neoBody(14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: neoBody(14))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: neoBody(14, color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await Repository.deleteRun(run.id);
      ref.read(_runsProvider.notifier).state = Repository.allRuns();
    }
  }
}
