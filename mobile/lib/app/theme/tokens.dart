import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ──────────────────────────────────────────────────────────────────

class NeoColors {
  static const cream = Color(0xFF0E0E0E);      // main background
  static const ink = Color(0xFFF0EDE6);         // text + borders (warm off-white)
  static const blue = Color(0xFF2D5BFF);
  static const pink = Color(0xFFFF5DA2);
  static const lime = Color(0xFFC6F000);
  static const yellow = Color(0xFFFFD23F);
  static const surface = Color(0xFF1A1A1A);     // card / elevated surface
  static const cardBg = surface;
  static const borderColor = ink;
}

// ── Shadow ────────────────────────────────────────────────────────────────────

BoxDecoration neoBox({
  Color bg = NeoColors.cardBg,
  double offset = 4,
  Color? border,
  double radius = 4,
}) =>
    BoxDecoration(
      color: bg,
      border: Border.all(color: border ?? NeoColors.ink, width: 2),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: NeoColors.ink,
          offset: Offset(offset, offset),
          blurRadius: 0,
        ),
      ],
    );

// ── Typography ────────────────────────────────────────────────────────────────

TextStyle neoDisplay(double size, {Color color = NeoColors.ink}) =>
    GoogleFonts.archivo(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -0.5);

TextStyle neoHeadline(double size, {Color color = NeoColors.ink}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: FontWeight.w700, color: color);

TextStyle neoBody(double size, {Color color = NeoColors.ink}) =>
    GoogleFonts.spaceGrotesk(fontSize: size, color: color);

TextStyle neoMono(double size, {Color color = NeoColors.ink}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        fontFeatures: [const FontFeature.tabularFigures()]);

// ── ThemeData ─────────────────────────────────────────────────────────────────

ThemeData buildNeoTheme() {
  final base = ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: NeoColors.blue,
      onPrimary: NeoColors.ink,
      secondary: NeoColors.pink,
      onSecondary: NeoColors.ink,
      tertiary: NeoColors.lime,
      onTertiary: NeoColors.ink,
      error: Colors.red,
      onError: Colors.white,
      surface: NeoColors.cream,
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

// ── Accent rotation ───────────────────────────────────────────────────────────

const _accents = [
  NeoColors.blue,
  NeoColors.pink,
  NeoColors.lime,
  NeoColors.yellow,
];

Color accentAt(int i) => _accents[i % _accents.length];
