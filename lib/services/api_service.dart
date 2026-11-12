// ============================================================
// API Service — Backend Integration
// ============================================================
// AI চ্যাট সহকারী এখন aquaguard_backend (Flask + Gemini)-এর সাথে
// সংযুক্ত। backend deploy করার পর নিচের `assistantBaseUrl` বদলে
// দিলেই কাজ শুরু হয়ে যাবে — অ্যাপের বাকি কোডে হাত দিতে হবে না।
//
// backend অফলাইন থাকলে বা এরর দিলে ChatEngine.reply() (local
// rule-based ফলব্যাক) স্বয়ংক্রিয়ভাবে ব্যবহার হয় — কখনো ফাঁকা
// উত্তর দেখাবে না। দেখুন: lib/screens/profile_assistant_market_screens.dart
//
// নোট: "ফিশপান্ডা" (মাছের খাবার মার্কেটপ্লেস)-এর জন্য backend
// ইন্টিগ্রেশন আলাদাভাবে ইতিমধ্যে করা আছে —
// দেখুন lib/services/fish_food_market_service.dart, ওটার নিজের
// real API call + local fallback ব্যবস্থা আছে। এই ফাইলে সেটার
// জন্য আলাদা কিছু বসানোর দরকার নেই।
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';
// ...
// line 29: hard-coded key er jaygay apiKey use koro
class ApiService {
  // deploy করার পর তোমার aquaguard_backend-এর URL এখানে বসাও।
  // লোকাল টেস্টের জন্য (Android emulator): "http://10.0.2.2:5000"
  // রিয়েল ডিভাইসে টেস্টের জন্য: তোমার কম্পিউটারের লোকাল IP, যেমন "http://192.168.0.105:5000"
  // প্রোডাকশনে (Render-এ deploy করার পর): "https://your-app-name.onrender.com"
  static const String assistantBaseUrl = "https://aquaguard-ai-chat.onrender.com";

  static bool get isConfigured => assistantBaseUrl.isNotEmpty;
  // ------------------------------------------------------------
  // AI চ্যাট সহকারী — aquaguard_backend-এর /api/assistant endpoint কল করে
  // ------------------------------------------------------------
  static Future<String> getAssistantResponse(
      String message,
      Map<String, dynamic> pondData,
      ) async {
    final uri = Uri.parse("$assistantBaseUrl/api/assistant");
    final res = await http
        .post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message, "pondData": pondData}),
    )
        .timeout(const Duration(seconds: 45));

    if (res.statusCode != 200) {
      throw Exception("Backend error: ${res.statusCode}");
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body["error"] != null) {
      throw Exception(body["error"]);
    }
    final reply = body["reply"];
    if (reply == null || (reply is String && reply.trim().isEmpty)) {
      throw Exception("Empty reply from backend");
    }
    return reply as String;
  }

  // ------------------------------------------------------------
  // ১. Auth (login/register) — একাধিক ব্যবহারকারীর জন্য (এখনো ব্যবহৃত হয় না)
  // ------------------------------------------------------------
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    throw UnimplementedError(
      "Auth backend এখনো কানেক্ট করা হয়নি।",
    );
  }

  // ------------------------------------------------------------
  // ২. Multi-device sync — একই farmer, ভিন্ন ফোনে data মেলানো (এখনো ব্যবহৃত হয় না)
  // ------------------------------------------------------------
  static Future<void> syncPondData(Map<String, dynamic> localData) async {
    throw UnimplementedError(
      "Sync backend এখনো কানেক্ট করা হয়নি।",
    );
  }

  static Future<Map<String, dynamic>> fetchPondData(String farmerId) async {
    throw UnimplementedError(
      "Sync backend এখনো কানেক্ট করা হয়নি।",
    );
  }
}