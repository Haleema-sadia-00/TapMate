import 'package:flutter/material.dart';

class AppColors {
  // --- PROFESSIONAL PALETTE ---
  static const Color deepTeal = Color(0xFF0C3B2E);     // Primary
  static const Color mutedGreen = Color(0xFF6D9773);   // Secondary
  static const Color burntOrange = Color(0xFFB46617);  // Accent
  static const Color softBeige = Color(0xFFF7F3E9);    // Light Background
  static const Color charcoalInk = Color(0xFF1B263B);  // Dark Background
  static const Color lightGray = Color(0xFFEAEAEA);    // Neutral surface

  // --- BRANDING ---
  static const Color primary = deepTeal;
  static const Color secondary = mutedGreen;
  static const Color accent = burntOrange;

  // --- LIGHT MODE ---
  static const Color lightBg = softBeige;              // Solid beige background
  static const Color lightSurface = Colors.white;
  static const Color textMain = deepTeal;

  // --- DARK MODE ---
  static const Color darkBg = charcoalInk;
  static const Color darkSurface = Color(0xFF243447);
  static const Color textOnDark = softBeige;

  // --- GRADIENTS (not used anymore, but kept for optional use) ---
  static const Gradient sunsetGradient = LinearGradient(
    colors: [burntOrange, mutedGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient oceanGradient = LinearGradient(
    colors: [deepTeal, mutedGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
