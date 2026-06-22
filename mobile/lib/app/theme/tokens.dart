import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ──────────────────────────────────────────────────────────────────

class NeoColors {
  static const cream   = Color(0xFFFAF4E6);   // warm cream scaffold bg
  static const surface = Color(0xFFFFFEF7);   // card / elevated surface
  static const cardBg  = surface;

  static const ink     = Color(0xFF111111);   // near-black text & borders

  static const blue    = Color(0xFF2D5BFF);
  static const pink    = Color(0xFFFF5DA2);
  static const lime    = Color(0xFFC6F000);
  static const yellow  = Color(0xFFFFD23F);

  static const borderColor = ink;
}

// ── Decorations ───────────────────────────────────────────────────────────────

BoxDecoration neoBox({
  Color bg = NeoColors.cardBg,
  double offset = 5,
  Color? border,
  Color? shadowColor,
  double radius = 8,
  double borderWidth = 3,
}) =>
    BoxDecoration(
      color: bg,
      border: Border.all(
          color: border ?? NeoColors.ink, width: borderWidth),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: offset > 0
          ? [
              BoxShadow(
                color: shadowColor ?? NeoColors.ink,
                offset: Offset(offset, offset),
                blurRadius: 0,
              ),
            ]
          : [],
    );

// ── Typography ────────────────────────────────────────────────────────────────

TextStyle neoDisplay(double size, {Color color = NeoColors.ink}) =>
    GoogleFonts.archivoBlack(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -0.5);

TextStyle neoHeadline(double size, {Color color = NeoColors.ink}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: FontWeight.w700, color: color);

TextStyle neoBody(double size, {Color color = NeoColors.ink}) =>
    GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w500, color: color);

TextStyle neoMono(double size, {Color color = NeoColors.ink}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        fontFeatures: [const FontFeature.tabularFigures()]);

TextStyle neoLabel(double size, {Color color = NeoColors.ink}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5);

// ── ThemeData ─────────────────────────────────────────────────────────────────

ThemeData buildNeoTheme() {
  final base = ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: NeoColors.blue,
      onPrimary: Colors.white,
      secondary: NeoColors.pink,
      onSecondary: NeoColors.ink,
      tertiary: NeoColors.lime,
      onTertiary: NeoColors.ink,
      error: Color(0xFFFF3B3B),
      onError: Colors.white,
      surface: NeoColors.surface,
      onSurface: NeoColors.ink,
    ),
    scaffoldBackgroundColor: NeoColors.cream,
    appBarTheme: AppBarTheme(
      backgroundColor: NeoColors.cream,
      foregroundColor: NeoColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: neoHeadline(20),
      iconTheme: const IconThemeData(color: NeoColors.ink),
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: NeoColors.ink,
      displayColor: NeoColors.ink,
    ),
  );
}

// ── Accent rotation (4 colours matching design) ───────────────────────────────

const _accents = [
  NeoColors.blue,
  NeoColors.pink,
  NeoColors.lime,
  NeoColors.yellow,
];

Color accentAt(int i) => _accents[i % _accents.length];

// ── Dot-grid background painter ───────────────────────────────────────────────

class DotGridPainter extends CustomPainter {
  const DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeoColors.ink.withValues(alpha: 0.13)
      ..strokeCap = StrokeCap.round;
    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
