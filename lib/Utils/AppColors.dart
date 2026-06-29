import 'package:flutter/material.dart';

class AppColors {
  // Official SIDAR Luxury Palette from Web Client (public/css/styles.css)
  static const Color primary = Color(0xFF0F5F4D); // --dark-green
  static const Color primaryDark = Color(0xFF124C3F); // --deep-green
  static const Color secondary = Color(0xFF178568); // --primary-olive-sage / teal
  static const Color accent = Color(0xFFC8A66A); // --gold
  static const Color gold = Color(0xFFC8A66A); // --gold
  static const Color lightGold = Color(0xFFD9BF8A); // --light-gold / gold2

  // Backgrounds & Surfaces (Luxury Soft Cream Palette)
  static const Color background = Color(0xFFFAF8F1); // --soft-cream / --bg
  static const Color surface = Color(0xFFFFFFFF); // --bg4 / Cards
  static const Color surfaceMuted = Color(0xFFF5F2E9); // --cream-bg / --bg2
  static const Color sageTint = Color(0xFFE6EFEA); // --light-sage-tint / --bg3
  static const Color sidebar = Color(0xFFF5F2E9);

  // Typography
  static const Color textPrimary = Color(0xFF0F5F4D); // --text (Deep Emerald)
  static const Color textSecondary = Color(0xFF53756C); // --muted (Sage)
  static const Color textDark = Color(0xFF0A3026);

  // Borders & Accents
  static const Color border = Color(0x47C8A66A); // rgba(200, 166, 106, 0.28)
  static const Color borderSoft = Color(0x240F5F4D); // rgba(15, 95, 77, 0.14)

  // Status
  static const Color success = Color(0xFF178568);
  static const Color warning = Color(0xFFC8A66A);
  static const Color error = Color(0xFFC0392B); // --red
  static const Color info = Color(0xFF0F5F4D);

  static const Color bg3 = Color(0xFFE6EFEA);
  static const Color bg4 = Color(0xFFFFFFFF);
  static const Color teal2 = Color(0xFF124C3F);
  static const Color gold2 = Color(0xFFD9BF8A);
  static const Color tealAccent = Color(0xFF178568);

  // Olive Green Palette from user reference (#718568, #E4EAE0)
  static const Color oliveGreen = Color(0xFF718568);
  static const Color oliveLight = Color(0xFFE4EAE0);

  static Color glass = const Color(0xFFFFFFFF).withValues(alpha: 0.90);
  static Color goldSoft = const Color(0xFFC8A66A).withValues(alpha: 0.16);
  static Color goldSofter = const Color(0xFFC8A66A).withValues(alpha: 0.08);
}
