import 'package:flutter/material.dart';

class AppColors {
  // === BACKGROUNDS (neutral, low-chroma) ===
  static const bgDark  = Color(0xFF05060A); // oklch(0.1 0.005 264)
  static const bg      = Color(0xFF0C0D12); // oklch(0.15 0.005 264)
  static const bgLight = Color(0xFF14151B); // oklch(0.2 0.005 264)

  static const textButton      = Color(0xFF0C0D12);
  // === TEXT ===
  static const text      = Color.fromARGB(209, 235, 235, 235); // oklch(0.96 0.01 264)
  static const textMuted = Color(0xFFB5B8C2); // oklch(0.76 0.01 264)

  // === ACCENTS ===
  static const primary   = Color(0xFF9AA8FF); // oklch(0.76 0.1 264)
  static const secondary = Color(0xFFD6C26A); // oklch(0.76 0.1 84)
  static const highlight = Color(0xFF6E717A); // oklch(0.5 0.01 264)

  // === BORDERS ===
  static const border      = Color(0xFF585B63); // oklch(0.4 0.01 264)
  static const borderMuted = Color(0xFF40434A); // oklch(0.3 0.01 264)

  // === STATUS ===
  static const danger  = Color(0xFFC98787); // oklch(0.7 0.05 30)
  static const warning = Color(0xFFC9C087); // oklch(0.7 0.05 100)
  static const success = Color(0xFF87C9A8); // oklch(0.7 0.05 160)
  static const info    = Color(0xFF87AFC9); // oklch(0.7 0.05 260)
}