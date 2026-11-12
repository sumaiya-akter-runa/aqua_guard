import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

// ============================================================
// Local Storage Service — সব ডেটা ফোনেই সেভ থাকবে (SharedPreferences)
// ============================================================
// পরে backend যোগ করার সময়, এই ক্লাসের প্রতিটা save method-এর ভেতরে
// একটা API call (ApiService.sync...) যোগ করলেই sync চালু হয়ে যাবে —
// UI/logic-এর বাকি অংশ একই থাকবে।
// ============================================================

class StorageService {
  static const _kFarmer = "aq_farmer";
  static const _kPondSetup = "aq_pond_setup";
  static const _kWaterHistory = "aq_water_history";
  static const _kLastFishScan = "aq_last_fish_scan";
  static const _kFishScanHistory = "aq_fish_scan_history";
  static const _kFeeds = "aq_feeds";
  static const _kGrowth = "aq_growth";
  static const _kAlerts = "aq_alerts";
  static const _kIsLoggedIn = "aq_is_logged_in";
  static const _kNotificationsOn = "aq_notifications_on";
  static const _kHasSeenOnboarding = "aq_has_seen_onboarding";

  // ---------------- দৈনিক রিমাইন্ডার সেটিংস ----------------
  static const _kWaterReminderOn = "aq_water_reminder_on";
  static const _kWaterReminderHour = "aq_water_reminder_hour";
  static const _kWaterReminderMinute = "aq_water_reminder_minute";
  static const _kFeedReminderOn = "aq_feed_reminder_on";
  static const _kFeedReminderHour = "aq_feed_reminder_hour";
  static const _kFeedReminderMinute = "aq_feed_reminder_minute";

  static Future<void> setWaterReminder(bool on, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWaterReminderOn, on);
    await prefs.setInt(_kWaterReminderHour, hour);
    await prefs.setInt(_kWaterReminderMinute, minute);
  }

  static Future<(bool, int, int)> getWaterReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getBool(_kWaterReminderOn) ?? false,
      prefs.getInt(_kWaterReminderHour) ?? 8,
      prefs.getInt(_kWaterReminderMinute) ?? 0,
    );
  }

  static Future<void> setFeedReminder(bool on, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFeedReminderOn, on);
    await prefs.setInt(_kFeedReminderHour, hour);
    await prefs.setInt(_kFeedReminderMinute, minute);
  }

  static Future<(bool, int, int)> getFeedReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getBool(_kFeedReminderOn) ?? false,
      prefs.getInt(_kFeedReminderHour) ?? 7,
      prefs.getInt(_kFeedReminderMinute) ?? 0,
    );
  }

  // ---------------- Onboarding (শুধু প্রথমবার দেখানোর জন্য) ----------------
  static Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboarding, value);
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasSeenOnboarding) ?? false;
  }

  // ---------------- Settings ----------------
  static Future<void> setNotificationsOn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsOn, value);
  }

  static Future<bool> getNotificationsOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotificationsOn) ?? true;
  }

  // ---------------- Farmer / Auth ----------------
  static Future<void> saveFarmer(Farmer farmer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFarmer, jsonEncode(farmer.toJson()));
  }

  static Future<Farmer> loadFarmer() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFarmer);
    if (raw == null) return Farmer();
    return Farmer.fromJson(jsonDecode(raw));
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsLoggedIn) ?? false;
  }

  // ---------------- Pond Setup ----------------
  static Future<void> savePondSetup(PondSetup setup) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPondSetup, jsonEncode(setup.toJson()));
  }

  static Future<PondSetup> loadPondSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPondSetup);
    if (raw == null) return PondSetup();
    return PondSetup.fromJson(jsonDecode(raw));
  }

  // ---------------- Water History ----------------
  static Future<void> saveWaterHistory(List<WaterReading> history) async {
    final prefs = await SharedPreferences.getInstance();
    final list = history.map((r) => r.toJson()).toList();
    await prefs.setString(_kWaterHistory, jsonEncode(list));
  }

  static Future<List<WaterReading>> loadWaterHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kWaterHistory);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => WaterReading.fromJson(e)).toList();
  }

  // ---------------- Fish Scan ----------------
  static Future<void> saveLastFishScan(FishScanResult scan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastFishScan, jsonEncode(scan.toJson()));
  }

  static Future<FishScanResult?> loadLastFishScan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastFishScan);
    if (raw == null) return null;
    return FishScanResult.fromJson(jsonDecode(raw));
  }

  static Future<void> saveFishScanHistory(List<FishScanResult> history) async {
    final prefs = await SharedPreferences.getInstance();
    final list = history.map((r) => r.toJson()).toList();
    await prefs.setString(_kFishScanHistory, jsonEncode(list));
  }

  static Future<List<FishScanResult>> loadFishScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFishScanHistory);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => FishScanResult.fromJson(e)).toList();
  }

  // ---------------- Feeds ----------------
  static Future<void> saveFeeds(List<FeedEntry> feeds) async {
    final prefs = await SharedPreferences.getInstance();
    final list = feeds.map((f) => f.toJson()).toList();
    await prefs.setString(_kFeeds, jsonEncode(list));
  }

  static Future<List<FeedEntry>> loadFeeds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFeeds);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => FeedEntry.fromJson(e)).toList();
  }

  // ---------------- Growth ----------------
  static Future<void> saveGrowth(List<GrowthEntry> growth) async {
    final prefs = await SharedPreferences.getInstance();
    final list = growth.map((g) => g.toJson()).toList();
    await prefs.setString(_kGrowth, jsonEncode(list));
  }

  static Future<List<GrowthEntry>> loadGrowth() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGrowth);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => GrowthEntry.fromJson(e)).toList();
  }

  // ---------------- Alerts ----------------
  static Future<void> saveAlerts(List<AppAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final list = alerts.map((a) => a.toJson()).toList();
    await prefs.setString(_kAlerts, jsonEncode(list));
  }

  static Future<List<AppAlert>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlerts);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => AppAlert.fromJson(e)).toList();
  }

  // ---------------- Clear all (logout) ----------------
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
