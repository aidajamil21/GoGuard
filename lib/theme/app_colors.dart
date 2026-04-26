import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const jade        = Color(0xFF00A878);
  static const jadeDark    = Color(0xFF007A58);
  static const jadeDeeper  = Color(0xFF005C42);
  static const jadeLight   = Color(0xFFE6F7F2);
  static const jadeMid     = Color(0xFFB3E8D8);
  static const jadeGlow    = Color(0x2E00A878);

  static const gold        = Color(0xFFF5C842);
  static const danger      = Color(0xFFE8333A);
  static const dangerLight = Color(0xFFFFF0F0);
  static const warn        = Color(0xFFF59E0B);
  static const warnLight   = Color(0xFFFFFBEB);
  static const safe        = Color(0xFF10B981);
  static const success     = Color(0xFF00A878); // Add success color

  static const text        = Color(0xFF0D1F1A);
  static const text2       = Color(0xFF4A6B60);
  static const text3       = Color(0xFF8AADA3);
  static const surface     = Color(0xFFF4FBF8);
  static const card        = Color(0xFFFFFFFF);
  static const border      = Color(0x26007A58);

  static LinearGradient get jadeGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [jadeDark, jade],
    stops: [0.0, 1.0],
  );

  static LinearGradient get dangerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB91C1C), danger],
  );
}
