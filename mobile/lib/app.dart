import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/tokens.dart';
import 'data/repository.dart';
import 'features/home_timeline/home_screen.dart';
import 'features/import_flow/import_screen.dart';
import 'ingest/ingest_service.dart';

class ChatStatApp extends ConsumerStatefulWidget {
  const ChatStatApp({super.key});

  @override
  ConsumerState<ChatStatApp> createState() => _ChatStatAppState();
}

class _ChatStatAppState extends ConsumerState<ChatStatApp> {
  final _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initSharing();
  }

  Future<void> _initSharing() async {
    final initial = await IngestService.init(_onFilesReceived);
    if (initial.isNotEmpty) _onFilesReceived(initial);
  }

  void _onFilesReceived(List<String> paths) {
    _navKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ImportScreen(
          filePaths: paths,
          onComplete: (_) =>
              ref.read(runsProvider.notifier).state = Repository.allRuns(),
        ),
      ),
    ).then((_) {
      ref.read(runsProvider.notifier).state = Repository.allRuns();
    });
  }

  @override
  void dispose() {
    IngestService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Receipts',
      debugShowCheckedModeBanner: false,
      theme: buildNeoTheme(),
      home: const HomeScreen(),
    );
  }
}
