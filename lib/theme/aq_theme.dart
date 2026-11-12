import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// AquaGuard AI — ডিজাইন টোকেন
// JSX প্রোটোটাইপের রঙ, gradient, ফন্ট এখানে হুবহু মিরর করা হয়েছে,
// যাতে সব screen-এ একই "look & feel" থাকে।
// ============================================================

class AqColors {
  // Brand teal
  static const deep = Color(0xFF0B3D39);
  static const deep2 = Color(0xFF062E2B);
  static const teal900 = Color(0xFF0B4F4A);
  static const teal700 = Color(0xFF147A72);
  static const teal400 = Color(0xFF1FB8A6);
  static const teal200 = Color(0xFF2DD4BF);
  static const mist = Color(0xFFCFEEE9);
  static const border = Color(0xFFDCEEEB);
  static const track = Color(0xFFEAF6F5);
  static const muted = Color(0xFF5B7B77);
  static const mutedLight = Color(0xFF9DB8B4);

  // Accent gold
  static const gold = Color(0xFFF5B942);
  static const gold2 = Color(0xFFF2932E);

  // Page background
  static const bgTop = Color(0xFFF2FAF9);
  static const bgBottom = Color(0xFFE7F5F3);

  static const cardShadow = Color(0x2E0B4F4A); // rgba(11,79,74,0.18) approx

  static const splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deep2, teal900, teal700, teal400],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [teal900, teal700, teal400],
    stops: [0.0, 0.6, 1.0],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, gold2],
  );
}

class RiskInfo {
  final Color color;
  final Color bg;
  final Color solid;
  final String label;
  final String en;
  final String emoji;
  const RiskInfo(this.color, this.bg, this.solid, this.label, this.en, this.emoji);
}

// RISK map — JSX-এর RISK object এর সমতুল্য
final Map<String, RiskInfo> kRisk = {
  "ভালো": RiskInfo(const Color(0xFF0F7A4E), const Color(0xFFE3FBEF), const Color(0xFF22C58C), "ভালো", "Normal", "🟢"),
  "সতর্ক": RiskInfo(const Color(0xFF9A6F06), const Color(0xFFFFF6D9), const Color(0xFFF7C948), "সতর্ক", "Monitor", "🟡"),
  "ঝুঁকি": RiskInfo(const Color(0xFFB85A12), const Color(0xFFFFEBD6), const Color(0xFFF5975A), "ঝুঁকিপূর্ণ", "Attention", "🟠"),
  "বিপদ": RiskInfo(const Color(0xFFB23327), const Color(0xFFFEE4E0), const Color(0xFFEE6455), "বিপদজনক", "Urgent", "🔴"),
};

RiskInfo riskInfo(String level) => kRisk[level] ?? kRisk["ভালো"]!;

class AqText {
  // "Baloo Da 2" এর সমতুল্য — heading font
  static TextStyle heading({double size = 20, Color color = AqColors.deep, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.baloo2(fontSize: size, color: color, fontWeight: weight);
  }

  // "Hind Siliguri" এর সমতুল্য — body font
  static TextStyle body({double size = 14, Color color = AqColors.deep, FontWeight weight = FontWeight.w400}) {
    return GoogleFonts.hindSiliguri(fontSize: size, color: color, fontWeight: weight);
  }
}

ThemeData buildAqTheme() {
  final base = ThemeData(useMaterial3: true, primaryColor: AqColors.teal700);
  return base.copyWith(
    scaffoldBackgroundColor: AqColors.bgTop,
    textTheme: GoogleFonts.hindSiliguriTextTheme(base.textTheme),
    colorScheme: base.colorScheme.copyWith(primary: AqColors.teal700, secondary: AqColors.gold),
  );
}
