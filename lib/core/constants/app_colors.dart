import 'package:flutter/material.dart';

class AppColors {
  // ── Core backgrounds ──────────────────────────────────────────
  static const Color background = Color(0xFF0E0E15);
  static const Color card = Color(0xFF16161F);
  static const Color muted = Color(0xFF27272F);
  static const Color sidebar = Color(0xFF0F0F16);

  // ── Brand green (primary) ─────────────────────────────────────
  static const Color primary = Color(0xFF86E560);
  static const Color primaryDim = Color(0xFF5EC43A);
  static const Color primaryDeep = Color(0xFF3A8A22);

  // ── Purple accent (secondary) ─────────────────────────────────
  static const Color secondary = Color(0xFF7B3FAF);
  static const Color secondaryDim = Color(0xFF5C2E85);

  // ── Text ──────────────────────────────────────────────────────
  static const Color foreground = Color(0xFFF9F9FC);
  static const Color mutedForeground = Color(0xFFA6A6A6);
  static const Color white = Colors.white;

  // ── Glassmorphism ─────────────────────────────────────────────
  static const Color glassBg = Color(0x1AFFFFFF); // white/10%

  // ── Border / input ────────────────────────────────────────────
  static const Color border = Color(0x1AFFFFFF);    // white/10%
  static const Color input = Color(0x26FFFFFF);     // white/15%
  static const Color surfaceSubtle = Color(0x0DFFFFFF); // white/5%

  // ── Status ────────────────────────────────────────────────────
  static const Color destructive = Color(0xFFE05252);
  static const Color error = Color(0xFFE05252);
  static const Color success = primary;

  // ── Gradients ─────────────────────────────────────────────────
  static LinearGradient get screenGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [background, Color(0xFF0E1510), background],
        stops: [0.0, 0.5, 1.0],
      );

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [primary, primaryDim],
      );
}
