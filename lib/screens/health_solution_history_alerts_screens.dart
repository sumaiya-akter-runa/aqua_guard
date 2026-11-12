import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/feed_solution_engine.dart';
import '../services/water_rule_engine.dart' as wre;
import '../theme/aq_theme.dart';
import '../widgets/shared_widgets.dart';

// ============================================================
// Health Score Screen
// ============================================================
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final score = app.healthScore;

    // সত্যিকারের ডেটা থেকে হিসাব করা ব্রেকডাউন — AppState-এর
    // healthScoreBreakdown-এর সাথে সবসময় সামঞ্জস্যপূর্ণ থাকবে।
    final breakdown = (app.healthScoreBreakdown["components"] as List)
        .cast<Map<String, dynamic>>();

    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              AppTopBar(title: "পুকুরের স্বাস্থ্য স্কোর", onBack: () => app.goTo("dashboard")),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          RippleGauge(score: score),
                          const SizedBox(height: 12),
                          Text(
                            score >= 80 ? "চমৎকার অবস্থায় আছে" : (score >= 60 ? "মোটামুটি ভালো, নজর রাখুন" : "নজরদারি প্রয়োজন"),
                            style: AqText.body(size: 14, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("স্কোর যেভাবে হিসাব হয়", style: AqText.heading(size: 14)),
                          const SizedBox(height: 12),
                          ...breakdown.map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(b["label"] as String, style: AqText.body(size: 12)),
                                    Text("${b["value"]}/100 · ওজন ${b["weight"]}%", style: AqText.body(size: 11, color: AqColors.teal700, weight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: (b["value"] as int) / 100,
                                    minHeight: 8,
                                    backgroundColor: AqColors.track,
                                    valueColor: const AlwaysStoppedAnimation(AqColors.teal700),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          Text(
                            "এই স্কোর নিয়মভিত্তিক ও স্বচ্ছ — এটি এখনো বৈজ্ঞানিকভাবে যাচাইকৃত সূচক হিসেবে উপস্থাপন করা হচ্ছে না।",
                            style: AqText.body(size: 11, color: AqColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(current: app.screen, onSelect: app.goTo),
      ),
    );
  }
}

// ============================================================
// Solution Screen — পানি + মাছ + খাবার একসাথে বিশ্লেষণ
// ============================================================
class SolutionScreen extends StatelessWidget {
  const SolutionScreen({super.key});

  /// সর্বশেষ পানির রিডিং থেকে সবচেয়ে খারাপ প্যারামিটার বের করে —
  /// "কেন এই অবস্থা" আর নিচের নির্দিষ্ট করণীয় দুই জায়গাতেই একই হিসাব
  /// ব্যবহার হয়, যাতে কারণ আর করণীয় সবসময় একে অপরের সাথে মেলে।
  Map<String, dynamic>? _worstWaterParam(AppState app) {
    if (app.waterHistory.isEmpty) return null;
    final last = app.waterHistory.last;
    const order = ["ভালো", "সতর্ক", "ঝুঁকি", "বিপদ"];
    final params = <String, double>{
      "ph": last.ph,
      "do": last.doLevel,
      "temp": last.temp,
      "ammonia": last.ammonia,
      if (last.turbidity != null) "turbidity": last.turbidity!,
      if (last.nitrite != null) "nitrite": last.nitrite!,
      if (last.nitrate != null) "nitrate": last.nitrate!,
      if (last.alkalinity != null) "alkalinity": last.alkalinity!,
      if (last.salinity != null) "salinity": last.salinity!,
    };
    String worstKey = "ph";
    String worstLevel = "ভালো";
    for (final e in params.entries) {
      final lvl = wre.WaterRuleEngine.classify(e.key, e.value);
      if (order.indexOf(lvl) > order.indexOf(worstLevel)) {
        worstLevel = lvl;
        worstKey = e.key;
      }
    }
    const labels = {
      "ph": "pH", "do": "DO (অক্সিজেন)", "temp": "তাপমাত্রা", "ammonia": "অমিশ্রিত অ্যামোনিয়া (NH₃)",
      "turbidity": "ঘোলাত্ব", "nitrite": "নাইট্রাইট", "nitrate": "নাইট্রেট", "alkalinity": "ক্ষারত্ব", "salinity": "লবণাক্ততা",
    };
    return {
      "key": worstKey,
      "label": labels[worstKey] ?? worstKey,
      "value": params[worstKey],
      "level": worstLevel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pond = app.pondSetup;
    final scan = app.lastFishScan;
    final waterRisk = app.latestWaterRisk;
    final waterAnalysis = _worstWaterParam(app);

    final diseaseDetected = scan == null ? null : (scan.uncertain ? null : scan.healthy == false);
    final fishLevel = diseaseDetected == true ? (scan!.level ?? "ঝুঁকি") : (diseaseDetected == false ? "ভালো" : "সতর্ক");

    final feedSuggestion = FeedEngine.computeFeedSuggestion(
      sizeDecimal: pond.sizeDecimal,
      quantity: pond.quantity,
      avgWeightG: app.avgWeightG,
      waterRisk: waterRisk,
      diseaseDetected: diseaseDetected,
    );

    // ---- পানির জন্য নির্দিষ্ট করণীয় — সাধারণ ধাপের বদলে ঠিক কোন
    // প্যারামিটার সমস্যা তার ভিত্তিতে (water_rule_engine-এর paramStepGuide) ----
    List<String> waterSteps = [];
    if (waterAnalysis != null) {
      final wKey = waterAnalysis["key"] as String;
      final wLevel = waterAnalysis["level"] as String;
      if (wLevel == "ভালো") {
        waterSteps = wre.WaterRuleEngine.stepGuide["ভালো"] ?? [];
      } else {
        waterSteps = wre.WaterRuleEngine.paramStepGuide[wKey]?[wLevel] ?? wre.WaterRuleEngine.stepGuide[wLevel] ?? [];
      }
    }

    // ---- মাছের জন্য করণীয় — স্ক্যান থেকে ----
    final List<String> fishSteps = [];
    if (diseaseDetected == true && scan?.pondActions != null) {
      fishSteps.addAll(scan!.pondActions);
    }

    final overallIdx = ["ভালো", "সতর্ক", "ঝুঁকি", "বিপদ"]
        .indexOf(waterAnalysis?["level"] as String? ?? "ভালো")
        .clamp(0, 3);
    final fishIdx = ["ভালো", "সতর্ক", "ঝুঁকি", "বিপদ"].indexOf(fishLevel).clamp(0, 3);
    final overall = ["ভালো", "সতর্ক", "ঝুঁকি", "বিপদ"][overallIdx > fishIdx ? overallIdx : fishIdx];

    final solution = SolutionEngine.computeSolution(
      waterRisk: waterRisk,
      fishHealthy: scan?.healthy,
      fishUncertain: scan?.uncertain,
      fishLevel: scan?.level,
      fishName: scan?.name,
      fishPondActions: scan?.pondActions,
      fishExpertNote: scan?.expertNote,
      feedSuggestion: feedSuggestion,
      species: pond.species,
    );

    final r = riskInfo(overall);

    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              AppTopBar(title: "সেরা সমাধান", onBack: () => app.goTo("dashboard")),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      color: r.bg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                child: Icon(Icons.medical_services_outlined, color: r.color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("সামগ্রিক অবস্থা — পানি + মাছ + খাবার একসাথে বিশ্লেষণ করে", style: AqText.body(size: 11)),
                                    Text("${r.emoji} ${r.label} · ${r.en}", style: AqText.heading(size: 16, color: r.color)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(14)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("পানির মান", style: AqText.body(size: 10, color: AqColors.muted)),
                                      const SizedBox(height: 4),
                                      RiskPill(level: waterRisk),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(14)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("মাছের স্বাস্থ্য", style: AqText.body(size: 10, color: AqColors.muted)),
                                      const SizedBox(height: 4),
                                      RiskPill(level: fishLevel),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (diseaseDetected == true) ...[
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: AqText.body(size: 12),
                                children: [
                                  TextSpan(text: "সনাক্তকৃত সম্ভাব্য অবস্থা: ", style: AqText.body(size: 12, weight: FontWeight.w700)),
                                  TextSpan(text: scan!.name ?? ""),
                                ],
                              ),
                            ),
                            if (scan.signs.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text("লক্ষণ: ${scan.signs.join(', ')}", style: AqText.body(size: 11, color: AqColors.muted)),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              "এটি AI স্ক্রিনিং মডেলের ভিত্তিতে একটি সম্ভাব্য অবস্থা — চূড়ান্ত রোগ নির্ণয় নয়।",
                              style: AqText.body(size: 10, color: AqColors.mutedLight),
                            ),
                          ],

                          // ---- "কেন এই অবস্থা" — সবচেয়ে খারাপ পানির প্যারামিটার + উৎস ----
                          if (waterAnalysis != null && waterAnalysis["level"] != "ভালো") ...[
                            const SizedBox(height: 10),
                            Builder(builder: (context) {
                              final wKey = waterAnalysis["key"] as String;
                              final wLevel = waterAnalysis["level"] as String;
                              final wValue = waterAnalysis["value"] as double;
                              final wLabel = waterAnalysis["label"] as String;
                              final src = wre.WaterRuleEngine.sourceNote[wKey];
                              final isConservative = src?["reliability"] == "conservative";
                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "কেন এই অবস্থা: $wLabel = ${wValue.toStringAsFixed(2)} ($wLevel)",
                                      style: AqText.body(size: 11, color: AqColors.deep, weight: FontWeight.w600),
                                    ),
                                    if (src != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        isConservative
                                            ? "নিরাপদ পরিসীমার উৎস: সাধারণ pond-culture নির্দেশিকা (নির্দিষ্ট বাংলাদেশ-উৎস যাচাই করা যায়নি)"
                                            : "নিরাপদ পরিসীমার উৎস: ${src["source"]}",
                                        style: TextStyle(fontSize: 9, color: isConservative ? const Color(0xFFB85A12) : Colors.grey.shade600),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---- পানির জন্য করণীয় — নির্দিষ্ট প্যারামিটার-ভিত্তিক ----
                    if (waterAnalysis != null && waterAnalysis["level"] != "ভালো" && waterSteps.isNotEmpty) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.water_drop_outlined, size: 17, color: AqColors.teal700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "পানির জন্য করণীয় (কারণ: ${waterAnalysis["label"]})",
                                    style: AqText.heading(size: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(waterSteps.length, (i) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(color: AqColors.teal700, shape: BoxShape.circle),
                                      child: Text("${i + 1}", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(waterSteps[i], style: AqText.body(size: 12))),
                                  ],
                                ),
                              );
                            }),
                            if (wre.WaterRuleEngine.fishImpact[waterAnalysis["key"]]?[waterAnalysis["level"]] != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(12)),
                                child: RichText(
                                  text: TextSpan(
                                    style: AqText.body(size: 11, color: AqColors.deep),
                                    children: [
                                      TextSpan(text: "🐟 মাছের ওপর প্রভাব: ", style: AqText.body(size: 11, color: AqColors.deep, weight: FontWeight.w700)),
                                      TextSpan(text: wre.WaterRuleEngine.fishImpact[waterAnalysis["key"]]![waterAnalysis["level"]]),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ---- মাছের জন্য করণীয় — স্ক্যান-ভিত্তিক ----
                    if (diseaseDetected == true && fishSteps.isNotEmpty) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.set_meal_outlined, size: 17, color: Color(0xFFF5A623)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "মাছের জন্য করণীয় (কারণ: ${scan?.name ?? 'স্ক্যান ফলাফল'})",
                                    style: AqText.heading(size: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(fishSteps.length, (i) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(color: Color(0xFFF5A623), shape: BoxShape.circle),
                                      child: Text("${i + 1}", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(fishSteps[i], style: AqText.body(size: 12))),
                                  ],
                                ),
                              );
                            }),
                            if (scan?.expertNote != null && scan!.expertNote!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(12)),
                                child: RichText(
                                  text: TextSpan(
                                    style: AqText.body(size: 11, color: AqColors.deep),
                                    children: [
                                      TextSpan(text: "বিশেষজ্ঞ নোট: ", style: AqText.body(size: 11, color: AqColors.deep, weight: FontWeight.w700)),
                                      TextSpan(text: scan.expertNote),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ---- কোনো সমস্যা না থাকলে ----
                    if ((waterAnalysis == null || waterAnalysis["level"] == "ভালো") && diseaseDetected != true) ...[
                      AppCard(
                        color: riskInfo("ভালো").bg,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20, color: riskInfo("ভালো").color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "পানি ও মাছ দুটোই স্বাভাবিক পরিসরে আছে — নিয়মিত পর্যবেক্ষণ চালিয়ে যান।",
                                style: AqText.body(size: 12, color: riskInfo("ভালো").color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF178077)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text("আজকের প্রস্তাবিত খাবার", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: "${solution.suggestedKg} ", style: AqText.heading(size: 22, color: Colors.white)),
                                TextSpan(text: "কেজি / দিন", style: AqText.body(size: 12, color: Colors.white, weight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("${pond.species}-এর জন্য প্রস্তাবিত খাবারের ধরন:", style: AqText.body(size: 11, color: AqColors.mist)),
                          const SizedBox(height: 6),
                          ...solution.feedOptions.take(2).map((f) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.name, style: AqText.body(size: 12, color: Colors.white, weight: FontWeight.w700)),
                                Text(f.note, style: AqText.body(size: 10, color: AqColors.mist)),
                              ],
                            ),
                          )),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: () => app.goTo("feed"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AqColors.gold,
                                foregroundColor: AqColors.deep,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text("খাবার পেজে যান", style: AqText.body(size: 13, color: AqColors.deep, weight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (diseaseDetected != true)
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => app.goTo("fish"),
                          icon: const Icon(Icons.camera_alt_rounded, size: 16, color: AqColors.teal700),
                          label: Text("মাছ স্ক্যান করুন আরও নির্ভুল সমাধানের জন্য", style: AqText.body(size: 13, color: AqColors.teal700, weight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AqColors.track,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      "পানির মান ও খাবারের মূল হার FAO/WorldFish-এর গাইডলাইন-ভিত্তিক। "
                          "মাছের রোগ শনাক্তকরণ একটি AI মডেলের অনুমান (~৮৭% নির্ভুল), সরকারি "
                          "অনুমোদিত রোগনির্ণয় না। এই পুরো সমাধান একটি নিয়মভিত্তিক (rule-based) "
                          "সহায়ক পরামর্শ — চূড়ান্ত বিশেষজ্ঞ পরামর্শের বিকল্প নয়।",
                      textAlign: TextAlign.center,
                      style: AqText.body(size: 10, color: AqColors.mutedLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(current: app.screen, onSelect: app.goTo),
      ),
    );
  }
}

// ============================================================
// History Screen — combined timeline
// ============================================================
class _HistoryItem {
  final String type;
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final String time;
  final String? level;
  _HistoryItem({required this.type, required this.icon, required this.color, required this.title, required this.sub, required this.time, this.level});
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = "all";

  static const _filters = [
    {"id": "all", "label": "সব"},
    {"id": "water", "label": "পানি"},
    {"id": "feed", "label": "খাবার"},
    {"id": "growth", "label": "বৃদ্ধি"},
    {"id": "scan", "label": "মাছ স্ক্যান"},
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pond = app.pondSetup;

    final waterItems = app.waterHistory.reversed
        .map((h) => _HistoryItem(
      type: "water",
      icon: Icons.water_drop_rounded,
      color: const Color(0xFF1E9E8C),
      title: "পানির রিডিং — pH ${h.ph}, DO ${h.doLevel} mg/L",
      sub: "তাপমাত্রা ${h.temp}°C · অ্যামোনিয়া ${h.ammonia}",
      time: h.day,
      level: wre.WaterRuleEngine.classify("do", h.doLevel),
    ))
        .toList();

    final feedItems = app.feeds
        .map((f) => _HistoryItem(
      type: "feed",
      icon: Icons.restaurant_rounded,
      color: const Color(0xFF7C6FE0),
      title: f.note.isNotEmpty ? f.note : "খাবার",
      sub: "${f.amountKg} কেজি খাওয়ানো হয়েছে",
      time: "${f.timestamp.day}/${f.timestamp.month}",
    ))
        .toList();

    final growthItems = app.growth.reversed
        .map((g) => _HistoryItem(
      type: "growth",
      icon: Icons.trending_up_rounded,
      color: const Color(0xFF3AA6D9),
      title: "গড় ওজন ${g.weightG} গ্রাম",
      sub: "বৃদ্ধি পরিমাপ",
      time: g.week,
    ))
        .toList();

    final scan = app.lastFishScan;
    final scanItems = scan == null
        ? <_HistoryItem>[]
        : [
      _HistoryItem(
        type: "scan",
        icon: Icons.set_meal_rounded,
        color: const Color(0xFFF5A623),
        title: scan.uncertain ? "অনিশ্চিত ফলাফল" : (scan.name ?? "—"),
        sub: scan.uncertain ? "স্পষ্ট ছবি দিয়ে আবার স্ক্যান প্রয়োজন" : "আত্মবিশ্বাস ${(scan.confidence * 100).toStringAsFixed(0)}%",
        time: "সাম্প্রতিক স্ক্যান",
      ),
    ];

    // interleave newest-first (matches JSX round-robin merge)
    final merged = <_HistoryItem>[];
    final buckets = [List.of(scanItems), List.of(feedItems), List.of(waterItems), List.of(growthItems)];
    bool more = true;
    while (more) {
      more = false;
      for (final b in buckets) {
        if (b.isNotEmpty) {
          merged.add(b.removeAt(0));
          more = true;
        }
      }
    }
    final filtered = _filter == "all" ? merged : merged.where((m) => m.type == _filter).toList();

    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              AppTopBar(title: "পুকুরের ইতিহাস", onBack: () => app.goTo("dashboard")),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF178077)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${pond.pondName} · ${pond.farmName}", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text("${pond.species} · মজুদের তারিখ: ${pond.stockingDate} · ${pond.sizeDecimal} শতক", style: AqText.body(size: 11, color: AqColors.mist)),
                          const SizedBox(height: 8),
                          Text(
                            "পানি, খাবার, বৃদ্ধি এবং মাছ স্ক্যান — সব কার্যক্রম একসাথে নিচে দেখুন।",
                            style: AqText.body(size: 11, color: AqColors.mist),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final f = _filters[i];
                          final active = _filter == f["id"];
                          return GestureDetector(
                            onTap: () => setState(() => _filter = f["id"]!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active ? AqColors.teal700 : AqColors.track,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(f["label"]!, style: AqText.body(size: 12, color: active ? Colors.white : AqColors.muted, weight: FontWeight.w700)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text("এই ক্যাটাগরিতে এখনো কোনো তথ্য নেই।", style: AqText.body(size: 13, color: AqColors.muted))),
                      )
                    else
                      ...filtered.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: item.color, width: 2),
                              ),
                              child: Icon(item.icon, size: 16, color: item.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(item.title, style: AqText.body(size: 13, weight: FontWeight.w700))),
                                        if (item.level != null) RiskPill(level: item.level!),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(item.sub, style: AqText.body(size: 11, color: AqColors.muted)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 10, color: AqColors.mutedLight),
                                        const SizedBox(width: 4),
                                        Text(item.time, style: AqText.body(size: 10, color: AqColors.mutedLight)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(current: app.screen, onSelect: app.goTo),
      ),
    );
  }
}

// ============================================================
// Alerts Screen
// ============================================================
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              AppTopBar(title: "বিজ্ঞপ্তি", onBack: () => app.goTo("dashboard")),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (app.alerts.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 30, color: Color(0xFF1E9E6B)),
                            const SizedBox(height: 8),
                            Text("কোনো নতুন বিজ্ঞপ্তি নেই", style: AqText.body(size: 13, weight: FontWeight.w600)),
                          ],
                        ),
                      )
                    else
                      ...List.generate(app.alerts.length, (i) {
                        final a = app.alerts[i];
                        final r = riskInfo(a.level);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            color: r.bg,
                            onTap: () => app.markAlertRead(i),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 18, color: r.color),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.title, style: AqText.body(size: 13, color: r.color, weight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(a.message, style: AqText.body(size: 12)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 10, color: AqColors.muted),
                                          const SizedBox(width: 4),
                                          Text("${a.timestamp.hour}:${a.timestamp.minute.toString().padLeft(2, '0')}", style: AqText.body(size: 10, color: AqColors.muted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(current: app.screen, onSelect: app.goTo),
      ),
    );
  }
}