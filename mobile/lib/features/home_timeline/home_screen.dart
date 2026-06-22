import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../../data/repository.dart';
import '../../domain/models/analysis_run.dart';
import '../../ingest/ingest_service.dart';
import '../import_flow/import_screen.dart';
import 'widgets/chat_timeline.dart';
import 'widgets/empty_state.dart';

final _runsProvider = StateProvider<List<AnalysisRun>>((ref) => Repository.allRuns());

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runs = ref.watch(_runsProvider);

    return Scaffold(
      backgroundColor: NeoColors.cream,
      body: CustomPaint(
        painter: const DotGridPainter(),
        child: SafeArea(
          child: runs.isEmpty
              ? EmptyState(onImport: () => _pickAndImport(context, ref))
              : ChatTimeline(
                  runs: runs,
                  ref: ref,
                  onImport: () => _pickAndImport(context, ref),
                  runsProvider: _runsProvider,
                ),
        ),
      ),
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
          onComplete: (_) =>
              ref.read(_runsProvider.notifier).state = Repository.allRuns(),
        ),
      ),
    );
    ref.read(_runsProvider.notifier).state = Repository.allRuns();
  }
}
