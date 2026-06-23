import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../home_timeline/home_screen.dart';
import '../../app/theme/tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _progress;

  int _textIndex = 0;
  bool _textVisible = true;

  static const _fadeDuration = Duration(milliseconds: 500);
  static const _splashDuration = Duration(milliseconds: 4800);
  static const _textFadeDuration = Duration(milliseconds: 300);

  static const _texts = [
    'Dusting off the conversation archives...',
    'Who texts first? The receipts will tell...',
    'Spotting the 3 am confessions...',
    'Finding out who really carries the conversation',
    'The receipts don\'t lie — almost there!',
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this, duration: _fadeDuration);
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _progressCtrl = AnimationController(vsync: this, duration: _splashDuration);
    _progress = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut);

    // Remove the native splash and fade Flutter content in simultaneously.
    FlutterNativeSplash.remove();
    _fadeCtrl.forward();

    _progressCtrl.forward().then((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const HomeScreen(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });

    _rotateTexts();
  }

  Future<void> _rotateTexts() async {
    final interval = _splashDuration.inMilliseconds ~/ _texts.length;
    for (int i = 0; i < _texts.length; i++) {
      if (!mounted) return;
      setState(() {
        _textIndex = i;
        _textVisible = true;
      });
      await Future.delayed(Duration(milliseconds: interval - _textFadeDuration.inMilliseconds));
      if (!mounted) return;
      setState(() => _textVisible = false);
      await Future.delayed(_textFadeDuration);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Scaffold(
        backgroundColor: NeoColors.cream,
        body: CustomPaint(
          painter: const DotGridPainter(),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _Icon(),
                const SizedBox(height: 28),
                Text('Receipts', style: neoDisplay(42)),
                const SizedBox(height: 6),
                Text(
                  'the receipts don\'t lie.',
                  style: neoBody(14, color: NeoColors.ink.withValues(alpha: 0.5)),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(36, 0, 36, 52),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 36,
                        child: AnimatedOpacity(
                          opacity: _textVisible ? 1.0 : 0.0,
                          duration: _textFadeDuration,
                          child: AnimatedSwitcher(
                            duration: _textFadeDuration,
                            child: Text(
                              _texts[_textIndex],
                              key: ValueKey(_textIndex),
                              textAlign: TextAlign.center,
                              style: neoBody(13, color: NeoColors.ink.withValues(alpha: 0.6)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProgressBar(progress: _progress),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: NeoColors.ink, width: 4),
        boxShadow: const [BoxShadow(color: NeoColors.ink, offset: Offset(7, 7))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/icon/receipts_icon.png', fit: BoxFit.cover),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Animation<double> progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: NeoColors.surface,
        border: Border.all(color: NeoColors.ink, width: 3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: NeoColors.ink, offset: Offset(4, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: progress,
        builder: (_, _) => LinearProgressIndicator(
          value: progress.value,
          backgroundColor: Colors.transparent,
          valueColor: const AlwaysStoppedAnimation(NeoColors.lime),
          minHeight: 16,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
