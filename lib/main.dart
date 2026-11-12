import 'package:aqua_guard/screens/water_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/aq_theme.dart';
import 'providers/app_state.dart';
import 'screens/splash_auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/water_screen.dart';
import 'screens/fish_screen.dart';
import 'screens/feed_growth_screen.dart';
import 'screens/health_solution_history_alerts_screens.dart';
import 'screens/profile_assistant_market_screens.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const AquaGuardApp(),
    ),
  );
}

class AquaGuardApp extends StatelessWidget {
  const AquaGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaGuard AI',
      debugShowCheckedModeBanner: false,
      theme: buildAqTheme(),
      home: const AppRoot(),
    );
  }
}

// ============================================================
// AppRoot — stage (splash/auth/app) আর screen (dashboard/water/...)
// অনুযায়ী সঠিক widget দেখায়। JSX-এর top-level {screen === "x" && <X/>}
// প্যাটার্নের Dart সমতুল্য।
// ============================================================
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (!app.loaded) {
      return const SplashScreen();
    }

    if (app.stage == "auth") {
      return const AuthScreen();
    }

    // stage == "app" — মূল অ্যাপ, screen অনুযায়ী পেজ পাল্টায়
    Widget page;
    switch (app.screen) {
      case "dashboard":
        page = const DashboardScreen();
        break;
      case "water":
        page = const WaterScreen();
        break;
      case "fish":
        page = const FishScreen();
        break;
      case "feed":
      case "growth":
        page = const FeedGrowthScreen();
        break;
      case "health":
        page = const HealthScreen();
        break;
      case "solution":
        page = const SolutionScreen();
        break;
      case "history":
        page = const HistoryScreen();
        break;
      case "alerts":
        page = const AlertsScreen();
        break;
      case "profile":
        page = const ProfileScreen();
        break;
      case "assistant":
        page = const AssistantScreen();
        break;
      case "market":
        page = const MarketScreen();
        break;
      default:
        page = const DashboardScreen();
    }

    // Assistant পেজে নিজেই থাকলে ভাসমান বাটন দেখানো হয় না (একই স্ক্রিন)
    if (app.screen == "assistant") return page;

    return Stack(
      children: [
        page,
        Positioned(
          right: 16,
          bottom: 88,
          child: _ChatFab(onTap: () => app.goTo("assistant")),
        ),
      ],
    );
  }
}

// ============================================================
// ভাসমান AI সহকারী বাটন — Dashboard সহ সব main screen-এ দেখা যায়
// ============================================================
class _ChatFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF1E9E8C)]),
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Color(0x400B4F4A), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
