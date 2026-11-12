import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/app_models.dart';
import '../services/feed_solution_engine.dart';
import '../theme/aq_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/mini_chart.dart';

class FeedGrowthScreen extends StatefulWidget {
  const FeedGrowthScreen({super.key});

  @override
  State<FeedGrowthScreen> createState() => _FeedGrowthScreenState();
}

class _FeedGrowthScreenState extends State<FeedGrowthScreen> {
  String _tab = "feed"; // feed | growth
  String? _feedType;
  double _feedAmount = 2;
  bool _showGrowthInfo = false;
  final _weightCtrl = TextEditingController(text: "60");
  final _lengthCtrl = TextEditingController(text: "14");

  @override
  void dispose() {
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    super.dispose();
  }

  List<FeedOption> _optionsFor(String species) => feedBySpecies[species] ?? feedBySpecies["রুই/কাতলা"]!;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pond = app.pondSetup;
    final options = _optionsFor(pond.species);
    _feedType ??= options.first.name;
    if (!options.any((o) => o.name == _feedType)) _feedType = options.first.name;

    final avgWeightG = app.growth.isNotEmpty ? app.growth.last.weightG : 0.0;
    final scan = app.lastFishScan;
    final diseaseDetected = scan == null ? null : (scan.uncertain ? null : scan.healthy == false);

    final suggestion = FeedEngine.computeFeedSuggestion(
      sizeDecimal: pond.sizeDecimal,
      quantity: pond.quantity,
      avgWeightG: avgWeightG,
      waterRisk: app.latestWaterRisk,
      diseaseDetected: diseaseDetected,
    );

    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              AppTopBar(title: "খাবার ও বৃদ্ধি", onBack: () => app.goTo("dashboard")),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- tab switch ----
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          Expanded(child: _tabBtn("খাবার", "feed")),
                          Expanded(child: _tabBtn("বৃদ্ধি", "growth")),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_tab == "feed") ..._buildFeedTab(app, pond, options, suggestion, avgWeightG),
                    if (_tab == "growth") ..._buildGrowthTab(app),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(current: "feed", onSelect: app.goTo),
      ),
    );
  }

  Widget _tabBtn(String label, String id) {
    final active = _tab == id;
    return GestureDetector(
      onTap: () => setState(() => _tab = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: active ? AqColors.teal700 : Colors.transparent, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Text(label, style: AqText.body(size: 13, color: active ? Colors.white : AqColors.muted, weight: FontWeight.w700)),
      ),
    );
  }

  List<Widget> _buildFeedTab(AppState app, PondSetup pond, List<FeedOption> options, FeedSuggestion suggestion, double avgWeightG) {
    return [
      // ---- Smart suggestion card ----
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF178077)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.eco_rounded, size: 16, color: AqColors.gold),
                ),
                const SizedBox(width: 8),
                Text("স্মার্ট খাবার সুপারিশ", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: "পুকুরের আকার (শতক)",
                    value: pond.sizeDecimal.toStringAsFixed(pond.sizeDecimal == pond.sizeDecimal.roundToDouble() ? 0 : 1),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) app.updatePondSetup(PondSetup(farmName: pond.farmName, pondName: pond.pondName, sizeDecimal: parsed, quantity: pond.quantity, species: pond.species));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _numberField(
                    label: "মাছের সংখ্যা",
                    value: "${pond.quantity}",
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) app.updatePondSetup(PondSetup(farmName: pond.farmName, pondName: pond.pondName, sizeDecimal: pond.sizeDecimal, quantity: parsed, species: pond.species));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: AqText.body(size: 11, color: AqColors.mist),
                children: [
                  const TextSpan(text: "গড় ওজন (সর্বশেষ বৃদ্ধি এন্ট্রি থেকে): "),
                  TextSpan(text: "${avgWeightG > 0 ? avgWeightG.toStringAsFixed(0) : '—'} গ্রাম", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const TextSpan(text: " · মোট আনুমানিক বায়োমাস: "),
                  TextSpan(text: "${suggestion.biomassKg} কেজি", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("আজকের প্রস্তাবিত খাবার", style: AqText.body(size: 11, color: AqColors.muted, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: "${suggestion.suggestedKg} ", style: AqText.heading(size: 24)),
                        TextSpan(text: "কেজি / দিন", style: AqText.body(size: 13, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...suggestion.notes.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(color: riskInfo(n.level).color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(n.text, style: AqText.body(size: 11))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: () => setState(() => _feedAmount = suggestion.suggestedKg),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AqColors.gold,
                  foregroundColor: AqColors.deep,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("এই পরিমাণ ব্যবহার করুন", style: AqText.body(size: 13, color: AqColors.deep, weight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "এটি একটি সাধারণ নিয়মভিত্তিক অনুমান — চূড়ান্ত বৈজ্ঞানিক ফিডিং চার্ট নয়। নিশ্চিত হতে বিশেষজ্ঞের পরামর্শ নিন।",
              style: AqText.body(size: 10, color: AqColors.mist),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // ---- Feed entry form ----
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "খাবারের তথ্য যোগ করুন",
                    style: AqText.heading(size: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: GestureDetector(
                    onTap: () => _pickSpecies(app, pond),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              pond.species,
                              style: AqText.body(size: 10, color: AqColors.teal700, weight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.unfold_more_rounded, size: 12, color: AqColors.teal700),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "আপনার মাছের প্রজাতি অনুযায়ী প্রস্তাবিত খাবার — বদলাতে উপরে ব্যাজে ট্যাপ করুন।",
              style: AqText.body(size: 11, color: AqColors.muted),
            ),
            const SizedBox(height: 12),

            // ---- প্রধান খাবার ----
            Builder(builder: (context) {
              final mainOptions = options.where((f) => f.category == "main").toList();
              final supplementOptions = options.where((f) => f.category != "main").toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mainOptions.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.restaurant_rounded, size: 14, color: AqColors.teal700),
                        const SizedBox(width: 6),
                        Text("প্রধান খাবার", style: AqText.body(size: 12, weight: FontWeight.w700, color: AqColors.teal700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...mainOptions.map((f) => _feedOptionTile(f)),
                    const SizedBox(height: 12),
                  ],
                  if (supplementOptions.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.eco_outlined, size: 14, color: Color(0xFFB98600)),
                        const SizedBox(width: 6),
                        Text("সম্পূরক / সাশ্রয়ী বিকল্প", style: AqText.body(size: 12, weight: FontWeight.w700, color: const Color(0xFFB98600))),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "— প্রধান খাবারের পাশাপাশি বা তার অভাবে",
                            style: AqText.body(size: 10, color: AqColors.mutedLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...supplementOptions.map((f) => _feedOptionTile(f)),
                  ],
                ],
              );
            }),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "পরিমাণ (কেজি)",
                    style: AqText.body(size: 12, color: AqColors.muted),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _stepBtn("−", () => setState(() => _feedAmount = (_feedAmount - 0.5).clamp(0.5, 999))),
                    SizedBox(width: 34, child: Text("$_feedAmount", textAlign: TextAlign.center, style: AqText.body(size: 13, weight: FontWeight.w700))),
                    _stepBtn("+", () => setState(() => _feedAmount += 0.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  app.addFeed(FeedEntry(timestamp: DateTime.now(), amountKg: _feedAmount, note: _feedType ?? ""));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("সংরক্ষণ হয়েছে")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AqColors.teal700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text("সংরক্ষণ করুন", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history_rounded, size: 13, color: AqColors.mutedLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "সংরক্ষণ করলে এই এন্ট্রি আপনার পুকুরের \"খাবারের ইতিহাসে\" যোগ হবে।",
                    style: AqText.body(size: 10, color: AqColors.mutedLight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // ---- Recent entries ----
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("সাম্প্রতিক এন্ট্রি", style: AqText.heading(size: 14)),
            const SizedBox(height: 10),
            if (app.feeds.isEmpty)
              Text("এখনো কোনো এন্ট্রি নেই।", style: AqText.body(size: 12, color: AqColors.muted))
            else
              ...app.feeds.reversed.take(10).map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_rounded, size: 15, color: Color(0xFF7C6FE0)),
                          const SizedBox(width: 8),
                          Flexible(child: Text(f.note.isNotEmpty ? f.note : "খাবার", style: AqText.body(size: 12, weight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("${f.amountKg} কেজি · ${f.timestamp.day}/${f.timestamp.month}", style: AqText.body(size: 11, color: AqColors.muted)),
                  ],
                ),
              )),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildGrowthTab(AppState app) {
    final entries = app.growth;
    final hasData = entries.isNotEmpty;

    // ---- সারাংশ পরিসংখ্যান — সবই আসল এন্ট্রি থেকে হিসাব করা, কোনো fixed/fake সংখ্যা নয় ----
    final currentWeight = hasData ? entries.last.weightG : 0.0;
    final firstWeight = hasData ? entries.first.weightG : 0.0;
    final totalGain = currentWeight - firstWeight;
    final currentLength = hasData ? entries.last.lengthCm : null;

    double? avgGainPerEntry;
    if (entries.length >= 2) {
      avgGainPerEntry = totalGain / (entries.length - 1);
    }

    String? trendNote;
    if (entries.length >= 2) {
      final last = entries[entries.length - 1].weightG;
      final prev = entries[entries.length - 2].weightG;
      final diff = last - prev;
      if (diff > 0) {
        trendNote = "সর্বশেষ পরিমাপে +${diff.toStringAsFixed(1)} গ্রাম বৃদ্ধি হয়েছে — ভালো অগ্রগতি।";
      } else if (diff < 0) {
        trendNote = "সর্বশেষ পরিমাপে ${diff.toStringAsFixed(1)} গ্রাম কমেছে — পানির মান ও খাবার আবার পরীক্ষা করুন।";
      } else {
        trendNote = "সর্বশেষ দুই পরিমাপে ওজন অপরিবর্তিত আছে।";
      }
    }

    return [
      // ---- পেজের কাজ কী — সংক্ষিপ্ত পরিচিতি ----
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF178077)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.trending_up_rounded, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "নিয়মিত মাছের ওজন/দৈর্ঘ্য মেপে এখানে লিখুন — এই তথ্য দিয়ে app বৃদ্ধির প্রবণতা দেখায় এবং \"খাবার\" ট্যাবের খাবারের পরিমাণ হিসাব করে।",
                style: AqText.body(size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("নতুন পরিমাপ", style: AqText.heading(size: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _numberField(label: "গড় ওজন (গ্রাম)", value: _weightCtrl.text, onChanged: (v) => _weightCtrl.text = v, light: false)),
                const SizedBox(width: 10),
                Expanded(child: _numberField(label: "গড় দৈর্ঘ্য (সেমি)", value: _lengthCtrl.text, onChanged: (v) => _lengthCtrl.text = v, light: false)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  final w = double.tryParse(_weightCtrl.text) ?? 0;
                  final l = double.tryParse(_lengthCtrl.text);
                  app.addGrowth(GrowthEntry(timestamp: DateTime.now(), week: "সপ্তাহ ${app.growth.length + 1}", weightG: w, lengthCm: l));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("যোগ হয়েছে")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AqColors.teal700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text("যোগ করুন", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // ---- সারাংশ কার্ড ----
      if (hasData)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("বৃদ্ধির সারাংশ", style: AqText.heading(size: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      icon: Icons.monitor_weight_outlined,
                      label: "বর্তমান গড় ওজন",
                      value: "${currentWeight.toStringAsFixed(1)} গ্রাম",
                      color: const Color(0xFF3AA6D9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statTile(
                      icon: Icons.straighten_rounded,
                      label: "বর্তমান গড় দৈর্ঘ্য",
                      value: currentLength != null ? "${currentLength.toStringAsFixed(1)} সেমি" : "তথ্য নেই",
                      color: const Color(0xFF7C6FE0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      icon: Icons.trending_up_rounded,
                      label: "মোট বৃদ্ধি (শুরু থেকে)",
                      value: "${totalGain >= 0 ? '+' : ''}${totalGain.toStringAsFixed(1)} গ্রাম",
                      color: totalGain >= 0 ? const Color(0xFF1E9E6B) : const Color(0xFFD5473A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statTile(
                      icon: Icons.timeline_rounded,
                      label: "গড় বৃদ্ধি/এন্ট্রি",
                      value: avgGainPerEntry != null ? "${avgGainPerEntry >= 0 ? '+' : ''}${avgGainPerEntry.toStringAsFixed(1)} গ্রাম" : "আরও এন্ট্রি দরকার",
                      color: const Color(0xFFF5A623),
                    ),
                  ),
                ],
              ),
              if (trendNote != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 15, color: AqColors.teal700),
                      const SizedBox(width: 8),
                      Expanded(child: Text(trendNote, style: AqText.body(size: 12, color: AqColors.deep))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              InkWell(
                onTap: () => setState(() => _showGrowthInfo = !_showGrowthInfo),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calculate_outlined, size: 14, color: AqColors.teal700),
                      const SizedBox(width: 6),
                      Text(
                        _showGrowthInfo ? "হিসাবের ব্যাখ্যা লুকান" : "এই হিসাবগুলো কীভাবে বের হয়?",
                        style: AqText.body(size: 12, color: AqColors.teal700, weight: FontWeight.w600),
                      ),
                      AnimatedRotation(
                        turns: _showGrowthInfo ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right, size: 15, color: AqColors.teal700),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showGrowthInfo) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _calcRow(
                        "বর্তমান গড় ওজন",
                        "আপনার সর্বশেষ লেখা এন্ট্রি — নতুন এন্ট্রি দিলেই এটা আপডেট হয়।",
                      ),
                      _calcRow(
                        "মোট বৃদ্ধি (শুরু থেকে)",
                        "সর্বশেষ এন্ট্রি − প্রথম এন্ট্রি। যেমন প্রথমে ৪০ গ্রাম ছিল, এখন ৬০ গ্রাম হলে মোট বৃদ্ধি = ৬০ − ৪০ = +২০ গ্রাম।",
                      ),
                      _calcRow(
                        "গড় বৃদ্ধি/এন্ট্রি",
                        "মোট বৃদ্ধি ÷ (মোট এন্ট্রি সংখ্যা − ১)। এটা বোঝায় গড়ে প্রতিবার পরিমাপে কতটা বেড়েছে। কমপক্ষে ২টা এন্ট্রি না দিলে এটা দেখা যাবে না।",
                      ),
                      _calcRow(
                        "সর্বশেষ পরিমাপে বৃদ্ধি/কমা",
                        "শুধু সবচেয়ে সাম্প্রতিক দুইটা এন্ট্রির তুলনা — এটা বলে দেয় সবশেষ পরিবর্তনটা ভালো নাকি চিন্তার বিষয়।",
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: RichText(
                          text: TextSpan(
                            style: AqText.body(size: 11, color: AqColors.deep),
                            children: [
                              TextSpan(text: "নোট: ", style: AqText.body(size: 11, color: AqColors.deep, weight: FontWeight.w700)),
                              const TextSpan(
                                text:
                                "নিচের গ্রাফে \"সপ্তাহ ১, সপ্তাহ ২...\" লেখাটা আসলে ক্যালেন্ডারের সপ্তাহ না — এটা আপনার কততম পরিমাপ (measurement) সেটা বোঝায়। একই দিনে দুইবার এন্ট্রি দিলে সেটাও \"সপ্তাহ ১\", \"সপ্তাহ ২\" দেখাবে।",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        )
      else
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AqColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "এখনো কোনো পরিমাপ যোগ করা হয়নি — উপরে প্রথম পরিমাপ যোগ করলে এখানে সারাংশ ও লেখচিত্র দেখা যাবে।",
                  style: AqText.body(size: 12, color: AqColors.muted),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 14),

      // ---- ওজনের লেখচিত্র ----
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ওজনের লেখচিত্র (গ্রাম)", style: AqText.heading(size: 14)),
            const SizedBox(height: 12),
            MiniLineChart(
              xLabels: entries.map((g) => g.week).toList(),
              series: [ChartSeries(label: "গড় ওজন (গ্রাম)", color: const Color(0xFF3AA6D9), values: entries.map((g) => g.weightG).toList())],
              height: 150,
            ),
          ],
        ),
      ),

      // ---- দৈর্ঘ্যের লেখচিত্র (শুধু দৈর্ঘ্য ডেটা থাকলে দেখাবে) ----
      if (entries.any((g) => g.lengthCm != null)) ...[
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("দৈর্ঘ্যের লেখচিত্র (সেমি)", style: AqText.heading(size: 14)),
              const SizedBox(height: 12),
              MiniLineChart(
                xLabels: entries.where((g) => g.lengthCm != null).map((g) => g.week).toList(),
                series: [
                  ChartSeries(
                    label: "গড় দৈর্ঘ্য (সেমি)",
                    color: const Color(0xFF7C6FE0),
                    values: entries.where((g) => g.lengthCm != null).map((g) => g.lengthCm!).toList(),
                  ),
                ],
                height: 150,
              ),
            ],
          ),
        ),
      ],

      // ---- পরিমাপের ইতিহাস ----
      if (hasData) ...[
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("পরিমাপের ইতিহাস", style: AqText.heading(size: 14)),
              const SizedBox(height: 10),
              ...entries.reversed.map((g) {
                final dateStr = "${g.timestamp.day.toString().padLeft(2, '0')}/${g.timestamp.month.toString().padLeft(2, '0')}/${g.timestamp.year}";
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.scale_rounded, size: 16, color: AqColors.teal700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.week, style: AqText.body(size: 12, weight: FontWeight.w700)),
                            Text(dateStr, style: AqText.body(size: 10, color: AqColors.muted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${g.weightG.toStringAsFixed(1)} গ্রাম", style: AqText.body(size: 12, weight: FontWeight.w700)),
                          if (g.lengthCm != null) Text("${g.lengthCm!.toStringAsFixed(1)} সেমি", style: AqText.body(size: 10, color: AqColors.muted)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _feedOptionTile(FeedOption f) {
    final selected = _feedType == f.name;
    final isMain = f.category == "main";
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _feedType = f.name),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AqColors.teal700 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AqColors.teal700 : AqColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name, style: AqText.body(size: 12, color: selected ? Colors.white : AqColors.deep, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(f.note, style: AqText.body(size: 10, color: selected ? AqColors.mist : AqColors.mutedLight)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.2)
                      : (isMain ? AqColors.track : const Color(0xFFFFF3D9)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isMain ? "প্রধান" : "সম্পূরক",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : (isMain ? AqColors.teal700 : const Color(0xFFB98600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calcRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chevron_right_rounded, size: 14, color: AqColors.teal700),
              Text(title, style: AqText.body(size: 12, weight: FontWeight.w700)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(desc, style: AqText.body(size: 11, color: AqColors.muted)),
          ),
        ],
      ),
    );
  }

  Widget _statTile({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(label, style: AqText.body(size: 10, color: AqColors.muted)),
          const SizedBox(height: 2),
          Text(value, style: AqText.heading(size: 14, color: color)),
        ],
      ),
    );
  }

  void _pickSpecies(AppState app, PondSetup pond) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("মাছের প্রজাতি বেছে নিন", style: AqText.heading(size: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: speciesList.map((s) {
                    final selected = pond.species == s;
                    return GestureDetector(
                      onTap: () {
                        app.updatePondSetup(PondSetup(
                          farmName: pond.farmName,
                          pondName: pond.pondName,
                          sizeDecimal: pond.sizeDecimal,
                          quantity: pond.quantity,
                          species: s,
                          stockingDate: pond.stockingDate,
                        ));
                        setState(() {
                          _feedType = null; // নতুন প্রজাতির প্রথম অপশন অটো-সিলেক্ট হবে
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AqColors.teal700 : AqColors.track,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? AqColors.teal700 : AqColors.border),
                        ),
                        child: Text(s, style: AqText.body(size: 12, color: selected ? Colors.white : AqColors.deep, weight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _numberField({required String label, required String value, required void Function(String) onChanged, bool light = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AqText.body(size: 10, color: light ? AqColors.mist : AqColors.muted)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: AqText.body(size: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: light ? Colors.white.withOpacity(0.92) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: light ? BorderSide.none : const BorderSide(color: AqColors.border)),
          ),
        ),
      ],
    );
  }

  Widget _stepBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AqColors.track, shape: BoxShape.circle),
        child: Text(label, style: AqText.body(size: 16, color: AqColors.teal700, weight: FontWeight.w800)),
      ),
    );
  }
}