import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/aq_theme.dart';

// ============================================================
// ConnectivityBadge — dashboard-এ বসানোর জন্য ছোট online/offline
// ইন্ডিকেটর। কোনো নতুন প্যাকেজ লাগে না (dart:io দিয়ে বানানো)।
//
// ব্যবহার: dashboard_screen.dart-এর উপরের দিকে, AppBar-এর নিচে বা
// header-এর পাশে বসিয়ে দিন —
//   const ConnectivityBadge(),
// ============================================================
class ConnectivityBadge extends StatefulWidget {
  const ConnectivityBadge({super.key});

  @override
  State<ConnectivityBadge> createState() => _ConnectivityBadgeState();
}

class _ConnectivityBadgeState extends State<ConnectivityBadge> {
  bool _online = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    bool result;
    try {
      final lookup = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      result = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      result = false;
    }
    if (mounted && result != _online) {
      setState(() => _online = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _online ? const Color(0xFF1E9E6B) : const Color(0xFFD5473A);
    final bg = _online ? const Color(0xFFE7F8EF) : const Color(0xFFFBE3E0);
    final label = _online ? "অনলাইন" : "অফলাইন";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AqText.body(size: 11, color: color, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}