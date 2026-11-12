import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../services/water_rule_engine.dart';
import '../services/subscription_service.dart';

// ============================================================
// AppState — পুরো app-এর কেন্দ্রীয় state (JSX-এর top-level useState-এর সমতুল্য)
// সব data local storage-এ (SharedPreferences) সেভ হয়, app বন্ধ করে
// আবার খুললেও data থেকে যায়।
// ============================================================
class AppState extends ChangeNotifier {
  // ---- Navigation ----
  String stage = "splash"; // splash -> onboarding (শুধু প্রথমবার) -> auth -> app
  String screen = "dashboard";

  // ---- পানির ফর্মের অসেভ করা draft — অন্য পেজে গিয়ে ফিরে এলেও ইনপুট যাতে
  // মুছে না যায় (WaterScreen প্রতিবার পেজ বদলালে নতুন করে তৈরি হয়,
  // তাই এই মান local state-এ না রেখে এখানে রাখা হয়েছে)। কোনো
  // notifyListeners() লাগবে না, শুধু WaterScreen initState-এ পড়া হয়।
  Map<String, double>? waterFormDraft;
  void saveWaterFormDraft(Map<String, double> form) {
    waterFormDraft = Map.of(form);
  }

  // ---- Core data ----
  Farmer farmer = Farmer();
  PondSetup pondSetup = PondSetup();
  List<WaterReading> waterHistory = [];
  FishScanResult? lastFishScan;
  List<FishScanResult> fishScanHistory = [];
  List<FeedEntry> feeds = [];
  List<GrowthEntry> growth = [];
  List<AppAlert> alerts = [];

  bool _loaded = false;
  bool get loaded => _loaded;

  // ---- Derived getters ----
  String get latestWaterRisk {
    if (waterHistory.isEmpty) return "ভালো";
    final r = waterHistory.last;
    return WaterRuleEngine.overallRiskFromReading(
      ph: r.ph,
      doLevel: r.doLevel,
      temp: r.temp,
      ammonia: r.ammonia,
      turbidity: r.turbidity,
      nitrite: r.nitrite,
      nitrate: r.nitrate,
      alkalinity: r.alkalinity,
      salinity: r.salinity,
    );
  }

  double get avgWeightG {
    if (growth.isEmpty) return 0;
    return growth.last.weightG;
  }

  /// পুকুরের স্বাস্থ্য স্কোরের বিস্তারিত ব্রেকডাউন (৪টা উপাদান + ওজন)।
  /// Dashboard-এর ছোট স্কোর আর "স্বাস্থ্য স্কোর" পেজের বিস্তারিত ব্রেকডাউন —
  /// দুটোই এই একই হিসাব থেকে আসে, যাতে দুই জায়গায় সংখ্যায় গরমিল না হয়
  /// (আগে এই দুটো আলাদা/ভুল সমন্বয়হীন হিসাব ব্যবহার করত)।
  Map<String, dynamic> get healthScoreBreakdown {
    // ---- ১. পানির মান (ওজন ৪০%) — সর্বশেষ রিডিং-এর সার্বিক ঝুঁকি লেভেল থেকে ----
    const waterLevelScore = {"ভালো": 100, "সতর্ক": 78, "ঝুঁকি": 48, "বিপদ": 15};
    final waterScore = waterHistory.isEmpty ? 100 : (waterLevelScore[latestWaterRisk] ?? 100);

    // ---- ২. মাছের স্বাস্থ্য/স্ক্যান (ওজন ২৫%) ----
    int fishScore;
    if (lastFishScan == null) {
      fishScore = 100; // এখনো স্ক্যান করা হয়নি — সমস্যা আছে ধরে নেওয়ার কারণ নেই
    } else if (lastFishScan!.uncertain) {
      fishScore = 70; // অনিশ্চিত ফলাফল — সতর্কতাবশত কিছুটা কম
    } else if (lastFishScan!.healthy == true) {
      fishScore = 100;
    } else {
      const diseaseLevelScore = {"ভালো": 90, "সতর্ক": 70, "ঝুঁকি": 45, "বিপদ": 15};
      fishScore = diseaseLevelScore[lastFishScan!.level] ?? 45;
    }

    // ---- ৩. খাবার নিয়মিততা (ওজন ২০%) — গত ৭ দিনে কয়দিন এন্ট্রি দেওয়া হয়েছে ----
    int feedScore;
    if (feeds.isEmpty) {
      feedScore = 0;
    } else {
      final now = DateTime.now();
      final daysWithEntry = <String>{};
      for (final f in feeds) {
        final diff = now.difference(f.timestamp).inDays;
        if (diff >= 0 && diff <= 6) {
          daysWithEntry.add("${f.timestamp.year}-${f.timestamp.month}-${f.timestamp.day}");
        }
      }
      feedScore = ((daysWithEntry.length / 7) * 100).round().clamp(0, 100);
    }

    // ---- ৪. বৃদ্ধির হার (ওজন ১৫%) — সর্বশেষ দুইটা মাপের তুলনা ----
    int growthScore;
    if (growth.length < 2) {
      growthScore = 75; // পর্যাপ্ত ডেটা নেই — নিরপেক্ষ ধরে নেওয়া হচ্ছে
    } else {
      final last = growth[growth.length - 1].weightG;
      final prev = growth[growth.length - 2].weightG;
      if (prev <= 0) {
        growthScore = 75;
      } else {
        final changePct = ((last - prev) / prev) * 100;
        if (changePct >= 5) {
          growthScore = 100;
        } else if (changePct >= 0) {
          growthScore = 80;
        } else if (changePct >= -5) {
          growthScore = 50;
        } else {
          growthScore = 25;
        }
      }
    }

    final overall = (waterScore * 0.40 + fishScore * 0.25 + feedScore * 0.20 + growthScore * 0.15)
        .round()
        .clamp(0, 100);

    return {
      "overall": overall,
      "components": [
        {"label": "পানির মান", "value": waterScore, "weight": 40},
        {"label": "মাছের স্বাস্থ্য (স্ক্যান)", "value": fishScore, "weight": 25},
        {"label": "খাবার নিয়মিততা", "value": feedScore, "weight": 20},
        {"label": "বৃদ্ধির হার", "value": growthScore, "weight": 15},
      ],
    };
  }

  /// Dashboard-এর ছোট স্কোর — উপরের বিস্তারিত ব্রেকডাউনের weighted overall
  int get healthScore => healthScoreBreakdown["overall"] as int;

  // ============================================================
  // Init — app শুরুতে সব local storage থেকে লোড করে
  // ============================================================
  Future<void> init() async {
    farmer = await StorageService.loadFarmer();
    pondSetup = await StorageService.loadPondSetup();
    waterHistory = await StorageService.loadWaterHistory();
    lastFishScan = await StorageService.loadLastFishScan();
    fishScanHistory = await StorageService.loadFishScanHistory();
    feeds = await StorageService.loadFeeds();
    growth = await StorageService.loadGrowth();
    alerts = await StorageService.loadAlerts();

    final loggedIn = await StorageService.isLoggedIn();
    if (loggedIn) {
      stage = "app";
    } else {
      final seenOnboarding = await StorageService.hasSeenOnboarding();
      stage = seenOnboarding ? "auth" : "onboarding";
    }

    _loaded = true;
    notifyListeners();
  }

  // ============================================================
  // Navigation
  // ============================================================
  void goTo(String newScreen) {
    screen = newScreen;
    notifyListeners();
  }

  void setStage(String newStage) {
    stage = newStage;
    notifyListeners();
  }

  // ============================================================
  // Onboarding — শুধু প্রথমবার দেখানো হয়, "শুরু করুন" চাপলে flag সেভ হয়
  // ============================================================
  Future<void> completeOnboarding() async {
    await StorageService.setHasSeenOnboarding(true);
    stage = "auth";
    notifyListeners();
  }

  // ============================================================
  // Auth
  // ============================================================
  // এই মেথডটা এখন OTP ভেরিফাই সফল হওয়ার পরেই কল করা হয় (দেখো
  // AuthScreen._verifyOtp), তাই subscribed সরাসরি true বসানো হচ্ছে।
  Future<void> login(String name, String phone) async {
    farmer = Farmer(name: name, phone: phone, subscribed: true, subscribedSince: DateTime.now());
    await StorageService.saveFarmer(farmer);
    await StorageService.setLoggedIn(true);
    stage = "app";
    screen = "dashboard";
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.setLoggedIn(false);
    farmer = Farmer();
    stage = "auth";
    notifyListeners();
  }

  // bdApps-এর মাধ্যমে real আনসাবস্ক্রাইব — Profile স্ক্রিন থেকে কল হয়।
  // সফল হলে লোকাল সেশনও লগ-আউট করে দেয়।
  Future<SubscriptionResult> unsubscribeSubscription() async {
    final result = await SubscriptionService.unsubscribe(farmer.phone);
    if (result.success) {
      await logout();
    }
    return result;
  }

  Future<void> updateFarmer(Farmer newFarmer) async {
    farmer = newFarmer;
    await StorageService.saveFarmer(farmer);
    notifyListeners();
  }

  // ============================================================
  // Pond setup
  // ============================================================
  Future<void> updatePondSetup(PondSetup newSetup) async {
    pondSetup = newSetup;
    await StorageService.savePondSetup(pondSetup);
    notifyListeners();
  }

  // ============================================================
  // Water readings
  // ============================================================
  Future<void> addWaterReading(WaterReading reading) async {
    waterHistory.add(reading);
    if (waterHistory.length > 60) {
      waterHistory = waterHistory.sublist(waterHistory.length - 60);
    }
    await StorageService.saveWaterHistory(waterHistory);

    // ঝুঁকিপূর্ণ/বিপদজনক হলে অ্যালার্ট তৈরি করো
    final risk = WaterRuleEngine.overallRiskFromReading(
      ph: reading.ph,
      doLevel: reading.doLevel,
      temp: reading.temp,
      ammonia: reading.ammonia,
    );
    if (risk == "ঝুঁকি" || risk == "বিপদ") {
      await addAlert(AppAlert(
        timestamp: DateTime.now(),
        title: "পানির মান সতর্কতা",
        message: "সাম্প্রতিক রিডিং অনুযায়ী পানির মান \"$risk\" পর্যায়ে আছে।",
        level: risk,
      ));
    }

    notifyListeners();
  }

  // ============================================================
  // Fish scan
  // ============================================================
  Future<void> addFishScan(FishScanResult scan) async {
    lastFishScan = scan;
    await StorageService.saveLastFishScan(scan);

    fishScanHistory.insert(0, scan);
    if (fishScanHistory.length > 30) {
      fishScanHistory = fishScanHistory.sublist(0, 30);
    }
    await StorageService.saveFishScanHistory(fishScanHistory);

    if (!scan.uncertain && scan.healthy == false) {
      await addAlert(AppAlert(
        timestamp: DateTime.now(),
        title: "মাছে রোগের লক্ষণ শনাক্ত",
        message: "${scan.name ?? 'অজানা রোগ'} শনাক্ত হয়েছে — বিস্তারিত দেখুন।",
        level: scan.level ?? "ঝুঁকি",
      ));
    }

    notifyListeners();
  }

  // ============================================================
  // Feed entries
  // ============================================================
  Future<void> addFeed(FeedEntry feed) async {
    feeds.add(feed);
    await StorageService.saveFeeds(feeds);
    notifyListeners();
  }

  // ============================================================
  // Growth entries
  // ============================================================
  Future<void> addGrowth(GrowthEntry g) async {
    growth.add(g);
    await StorageService.saveGrowth(growth);
    notifyListeners();
  }

  // ============================================================
  // Alerts
  // ============================================================
  Future<void> addAlert(AppAlert alert) async {
    alerts.insert(0, alert);
    if (alerts.length > 50) {
      alerts = alerts.sublist(0, 50);
    }
    await StorageService.saveAlerts(alerts);
    notifyListeners();
  }

  Future<void> markAlertRead(int index) async {
    if (index < 0 || index >= alerts.length) return;
    alerts[index].read = true;
    await StorageService.saveAlerts(alerts);
    notifyListeners();
  }

  int get unreadAlertCount => alerts.where((a) => !a.read).length;
}