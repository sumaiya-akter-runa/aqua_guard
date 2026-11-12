import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/aq_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/mini_chart.dart';
import '../services/feed_solution_engine.dart';
import '../models/app_models.dart';
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final score = app.healthScore;
    final waterRisk = app.latestWaterRisk;
    final scan = app.lastFishScan;
    final farmerName = app.farmer.name.isNotEmpty ? app.farmer.name : "কৃষক";

    // JSX: overall = max(waterRisk, fishLevel)
    const order = ["ভালো", "সতর্ক", "ঝুঁকি", "বিপদ"];
    final diseaseDetected = scan == null ? null : (scan.uncertain ? null : scan.healthy == false);
    final fishLevel = diseaseDetected == true ? (scan!.level ?? "ঝুঁকি") : "ভালো";
    final overallIdx = [order.indexOf(waterRisk), order.indexOf(fishLevel)].reduce((a, b) => a > b ? a : b);
    final overallLevel = order[overallIdx < 0 ? 0 : overallIdx];
    final rOverall = riskInfo(overallLevel);

    // শুধু তখনই alert দেখাও যদি বর্তমান পানির অবস্থাও এখনো ঝুঁকিপূর্ণ থাকে —
// নাহলে পুরনো (এখন আর প্রাসঙ্গিক না) alert দেখানো বিভ্রান্তিকর
    final latestAlert = (app.alerts.isNotEmpty && (waterRisk == "ঝুঁকি" || waterRisk == "বিপদ"))
        ? app.alerts.first
        : null;

    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              // ---- Header (teal gradient, rounded bottom) ----
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AqColors.teal900, Color(0xFF178077)],
                  ),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("স্বাগতম", style: AqText.body(size: 12, color: const Color(0xFFBDE6DF))),
                              Text("$farmerName", style: AqText.heading(size: 24, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(
                                "${app.pondSetup.pondName} · ${app.pondSetup.species}",
                                style: AqText.body(size: 12, color: const Color(0xFFBDE6DF)),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => app.goTo("profile"),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                            child: Text(
                              farmerName.isNotEmpty ? farmerName.substring(0, 1) : "?",
                              style: AqText.heading(size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => app.goTo("alerts"),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_outlined, color: Colors.white, size: 19),
                                if (app.alerts.isNotEmpty)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(color: AqColors.gold, shape: BoxShape.circle),
                                      child: Text(
                                        "${app.alerts.length}",
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AqColors.deep),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // ---- Health score card ----
                    AppCard(
                      onTap: () => app.goTo("health"),
                      child: Row(
                        children: [
                          RippleGauge(score: score),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("পুকুরের স্বাস্থ্য স্কোর", style: AqText.body(size: 12, color: AqColors.muted, weight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text(
                                  score >= 80 ? "চমৎকার অবস্থায় আছে" : (score >= 60 ? "মোটামুটি ভালো" : "নজরদারি প্রয়োজন"),
                                  style: AqText.heading(size: 16),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => app.goTo("health"),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("বিস্তারিত দেখুন", style: AqText.body(size: 12, color: AqColors.teal700, weight: FontWeight.w600)),
                                      const Icon(Icons.chevron_right, size: 15, color: AqColors.teal700),
                                    ],
                                  ),
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

              // ---- Solution card (overall risk) ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: AppCard(
                  color: rOverall.solid,
                  onTap: () => app.goTo("solution"),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("আপনার পুকুরের আজকের সেরা সমাধান", style: AqText.body(size: 11, color: Colors.white.withOpacity(0.85))),
                            Text("${rOverall.emoji} ${rOverall.label} · ${rOverall.en}", style: AqText.heading(size: 15, color: Colors.white)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),

              // ---- Latest alert ----
              if (latestAlert != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AppCard(
                    color: riskInfo(latestAlert.level).bg,
                    onTap: () => app.goTo("water"),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 20, color: riskInfo(latestAlert.level).color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(latestAlert.title, style: AqText.body(size: 13, color: riskInfo(latestAlert.level).color, weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(latestAlert.message, style: AqText.body(size: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ---- Quick actions grid ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("দ্রুত কাজ", style: AqText.heading(size: 14)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.8,
                      children: [
                        _QuickAction(icon: Icons.water_drop_rounded, label: "পানি", color: const Color(0xFF1E9E8C), onTap: () => app.goTo("water")),
                        _QuickAction(icon: Icons.camera_alt_rounded, label: "মাছ স্ক্যান", color: const Color(0xFFF5A623), onTap: () => app.goTo("fish")),
                        _QuickAction(icon: Icons.scale_rounded, label: "খাবার", color: const Color(0xFF7C6FE0), onTap: () => app.goTo("feed")),
                        _QuickAction(icon: Icons.trending_up_rounded, label: "বৃদ্ধি", color: const Color(0xFF3AA6D9), onTap: () => app.goTo("growth")),
                        _QuickAction(icon: Icons.storefront_rounded, label: "মাছবাজার", color: const Color(0xFFE0576F), onTap: () => app.goTo("market")),
                        _QuickAction(icon: Icons.medical_services_outlined, label: "সমাধান", color: const Color(0xFF0B8F7A), onTap: () => app.goTo("solution")),
                        _QuickAction(icon: Icons.history_rounded, label: "ইতিহাস", color: const Color(0xFF3AA69C), onTap: () => app.goTo("history")),
                        _QuickAction(icon: Icons.person_rounded, label: "প্রোফাইল", color: const Color(0xFF8B6FE0), onTap: () => app.goTo("profile")),
                      ],
                    ),
                  ],
                ),
              ),

              // ---- Today's feed suggestion card (পুকুরের আকার + মাছের সংখ্যা ভিত্তিক) ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Builder(builder: (context) {
                  final pond = app.pondSetup;
                  final avgWeightG = app.avgWeightG;
                  final suggestion = FeedEngine.computeFeedSuggestion(
                    sizeDecimal: pond.sizeDecimal,
                    quantity: pond.quantity,
                    avgWeightG: avgWeightG,
                    waterRisk: waterRisk,
                    diseaseDetected: diseaseDetected,
                  );
                  final options = feedBySpecies[pond.species] ?? feedBySpecies["রুই/কাতলা"]!;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF178077)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x260B4F4A), blurRadius: 24, offset: Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text("আজকের প্রস্তাবিত খাবার", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: "${suggestion.suggestedKg} ", style: AqText.heading(size: 26, color: Colors.white)),
                              TextSpan(text: "কেজি / দিন", style: AqText.body(size: 13, color: AqColors.mist, weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${pond.species}-এর জন্য প্রস্তাবিত খাবারের ধরন:",
                          style: AqText.body(size: 11, color: AqColors.mist),
                        ),
                        const SizedBox(height: 8),
                        ...options.take(2).map((f) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.name, style: AqText.body(size: 11, color: Colors.white, weight: FontWeight.w700)),
                              Text(f.note, style: AqText.body(size: 10, color: AqColors.mist)),
                            ],
                          ),
                        )),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 44,
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
                  );
                }),
              ),

              // ---- AI assistant CTA ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: AppCard(
                  onTap: () => app.goTo("assistant"),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AqColors.teal700.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AqColors.teal700.withOpacity(0.18), width: 1),
                        ),
                        child: const Icon(Icons.chat_bubble_rounded, color: AqColors.teal700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("AI সহকারীকে জিজ্ঞাসা করুন", style: AqText.body(size: 13, color: AqColors.deep, weight: FontWeight.w700)),
                            Text("আপনার পুকুরের তথ্য দিয়ে বাংলায় উত্তর দেবে", style: AqText.body(size: 11, color: AqColors.muted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AqColors.teal700),
                    ],
                  ),
                ),
              ),

              // ---- Recent trend chart ----
              if (app.waterHistory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("সাম্প্রতিক প্রবণতা", style: AqText.heading(size: 14)),
                          InkWell(
                            onTap: () => app.goTo("water"),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("বিস্তারিত", style: AqText.body(size: 12, color: AqColors.teal700, weight: FontWeight.w600)),
                                const Icon(Icons.chevron_right, size: 14, color: AqColors.teal700),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _TrendChartCard(waterHistory: app.waterHistory, onSeeMore: () => app.goTo("water")),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.18), width: 1),
              boxShadow: [BoxShadow(color: color.withOpacity(0.16), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: AqText.body(size: 10, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ============================================================
// পানির প্রবণতা কার্ড — DO / pH / তাপমাত্রা এই তিনটার মধ্যে ট্যাব
// দিয়ে বদলানো যায়, যাতে দ্রুত সব গুরুত্বপূর্ণ প্যারামিটার এক নজরে
// দেখা যায় (আগে শুধু DO দেখাত)।
// ============================================================
enum _TrendMetric { doLevel, ph, temp }

class _TrendChartCard extends StatefulWidget {
  final List<WaterReading> waterHistory;
  final VoidCallback onSeeMore;
  const _TrendChartCard({required this.waterHistory, required this.onSeeMore});

  @override
  State<_TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<_TrendChartCard> {
  _TrendMetric _metric = _TrendMetric.doLevel;

  ({String label, String unit, Color color, String idealNote, double Function(WaterReading) getValue}) _metricInfo(_TrendMetric m) {
    switch (m) {
      case _TrendMetric.doLevel:
        return (
        label: "দ্রবীভূত অক্সিজেন (DO)",
        unit: "mg/L",
        color: const Color(0xFF1E9E8C),
        idealNote: "মাছের শ্বাস-প্রশ্বাসের জন্য জরুরি (আদর্শ মাত্রা: ৫+ mg/L)।",
        getValue: (r) => r.doLevel,
        );
      case _TrendMetric.ph:
        return (
        label: "পানির pH",
        unit: "",
        color: const Color(0xFF3AA6D9),
        idealNote: "স্বাদু পানির পুকুরের জন্য আদর্শ মাত্রা প্রায় ৭.০–৮.৫।",
        getValue: (r) => r.ph,
        );
      case _TrendMetric.temp:
        return (
        label: "পানির তাপমাত্রা",
        unit: "°C",
        color: const Color(0xFFF5A623),
        idealNote: "বেশিরভাগ চাষযোগ্য মাছের জন্য আদর্শ মাত্রা প্রায় ২৫–৩০°C।",
        getValue: (r) => r.temp,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = widget.waterHistory.length > 10
        ? widget.waterHistory.sublist(widget.waterHistory.length - 10)
        : widget.waterHistory;
    final info = _metricInfo(_metric);
    final latest = recent.isNotEmpty ? info.getValue(recent.last) : null;

    return AppCard(
      onTap: widget.onSeeMore,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- মেট্রিক বাছাইয়ের ট্যাব ----
          Row(
            children: _TrendMetric.values.map((m) {
              final selected = m == _metric;
              final mInfo = _metricInfo(m);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _metric = m),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? mInfo.color.withOpacity(0.12) : AqColors.track,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: selected ? mInfo.color.withOpacity(0.35) : Colors.transparent, width: 1),
                    ),
                    child: Text(
                      mInfo.unit.isEmpty ? mInfo.label.split(" ").last : mInfo.unit,
                      style: AqText.body(size: 11, color: selected ? mInfo.color : AqColors.muted, weight: FontWeight.w700),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "${info.label} — গত ${recent.length}টি রিডিং",
                  style: AqText.body(size: 12, weight: FontWeight.w700, color: AqColors.deep),
                ),
              ),
              if (latest != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    "সর্বশেষ: ${latest.toStringAsFixed(1)}${info.unit.isEmpty ? '' : ' ${info.unit}'}",
                    style: AqText.body(size: 11, color: info.color, weight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          MiniLineChart(
            xLabels: recent.map((r) => r.day).toList(),
            series: [ChartSeries(label: info.label, color: info.color, values: recent.map(info.getValue).toList())],
            height: 110,
          ),
          const SizedBox(height: 6),
          Text(info.idealNote, style: AqText.body(size: 11, color: AqColors.muted)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 12, color: AqColors.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "আপনি \"পানি\" পেজ থেকে যে মান জমা দেন, প্রতিবার নতুন রিডিং জমা দিলে এই গ্রাফ সেটা দিয়েই আপডেট হয় — এটা স্বয়ংক্রিয়/সেন্সর ডেটা নয়।",
                  style: AqText.body(size: 10, color: AqColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}