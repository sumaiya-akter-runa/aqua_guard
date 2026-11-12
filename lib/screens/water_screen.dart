import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/app_models.dart';
import '../services/water_rule_engine.dart';
import '../theme/aq_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/mini_chart.dart';

// ---- Slider field definition ----
class _SliderField {
  final String key;
  final String label;
  final double min, max, step;
  final String unit;
  const _SliderField(this.key, this.label, this.min, this.max, this.step, this.unit);
}

const _basicFields = [
  _SliderField("ph", "pH", 5, 10, 0.1, ""),
  _SliderField("do", "দ্রবীভূত অক্সিজেন (DO)", 0, 10, 0.1, "mg/L"),
];

const _advancedFields = [
  _SliderField("temp", "তাপমাত্রা", 15, 40, 0.5, "°C"),
  _SliderField("ammonia", "অমিশ্রিত অ্যামোনিয়া (NH₃)", 0, 2.5, 0.01, "mg/L"),
  _SliderField("turbidity", "ঘোলাত্ব (Turbidity)", 0, 120, 1, "NTU"),
  _SliderField("nitrite", "নাইট্রাইট", 0, 1, 0.01, "mg/L"),
  _SliderField("nitrate", "নাইট্রেট", 0, 100, 1, "mg/L"),
  _SliderField("alkalinity", "ক্ষারত্ব (Alkalinity)", 0, 300, 5, "mg/L"),
  _SliderField("salinity", "লবণাক্ততা", 0, 15, 0.1, "ppt"),
];

const Map<String, String> _paramLabel = {
  "ph": "pH",
  "do": "দ্রবীভূত অক্সিজেন",
  "temp": "তাপমাত্রা",
  "ammonia": "অমিশ্রিত অ্যামোনিয়া (NH₃)",
  "turbidity": "ঘোলাত্ব (Turbidity)",
  "nitrite": "নাইট্রাইট",
  "nitrate": "নাইট্রেট",
  "alkalinity": "ক্ষারত্ব (Alkalinity)",
  "salinity": "লবণাক্ততা",
};

// ---- Test-kit colour swatches (JSX WATER_KIT) ----
class _Swatch {
  final String label;
  final double value;
  final Color color;
  const _Swatch(this.label, this.value, this.color);
}

const Map<String, List<_Swatch>> _waterKit = {
  "ph": [
    _Swatch("হলুদ (অম্লীয়)", 6.0, Color(0xFFE7D24D)),
    _Swatch("হালকা সবুজ", 6.8, Color(0xFFB7D96A)),
    _Swatch("সবুজ (স্বাভাবিক)", 7.2, Color(0xFF5FB86A)),
    _Swatch("নীল-সবুজ", 7.9, Color(0xFF3FA79C)),
    _Swatch("নীল (ক্ষারীয়)", 8.6, Color(0xFF3A7FC1)),
  ],
  "do": [
    _Swatch("খুব কম", 1.5, Color(0xFFD5473A)),
    _Swatch("কম", 3.0, Color(0xFFE07A22)),
    _Swatch("মাঝারি", 4.2, Color(0xFFDCB53A)),
    _Swatch("ভালো", 6.0, Color(0xFF5FB86A)),
    _Swatch("খুব ভালো", 8.5, Color(0xFF1E9E6B)),
  ],
  "ammonia": [
    _Swatch("হালকা হলুদ (নিরাপদ)", 0.01, Color(0xFFF1E9B8)),
    _Swatch("হালকা সবুজ (সতর্ক)", 0.03, Color(0xFFBFDA8E)),
    _Swatch("সবুজ (ঝুঁকি)", 0.10, Color(0xFF6FAE55)),
    _Swatch("গাঢ় সবুজ (বিপদ)", 0.5, Color(0xFF2F7A3C)),
  ],
};

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  bool _advanced = false;
  bool _advancedTrends = false;
  String _mode = "slider"; // "slider" | "kit"

  final Map<String, double> _form = {
    "ph": 7.3,
    "do": 5.5,
    "temp": 29,
    "ammonia": 0.01,
    "turbidity": 25,
    "nitrite": 0.05,
    "nitrate": 15,
    "alkalinity": 110,
    "salinity": 0.5,
  };

  Map<String, dynamic>? _result;
  int? _expandedHistoryIndex;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();

    // অন্য পেজ থেকে ফিরে এলে (একই session-এ) আগের ইনপুট করা মানগুলো
    // ফিরিয়ে আনো — এটা শুধু temporary/in-memory draft, app সম্পূর্ণ বন্ধ
    // হলে হারিয়ে যায়।
    final draft = app.waterFormDraft;
    if (draft != null) {
      for (final k in _form.keys) {
        if (draft.containsKey(k)) _form[k] = draft[k]!;
      }
      return;
    }

    // draft না থাকলে (যেমন app সম্পূর্ণ বন্ধ করে আবার খোলার পর) —
    // সর্বশেষ সত্যিকারের সেভ করা reading (SharedPreferences-এ স্থায়ীভাবে
    // সংরক্ষিত, তাই app বন্ধ/চালু করলেও থেকে যায়) থেকে ফর্ম পূরণ করো।
    if (app.waterHistory.isNotEmpty) {
      final last = app.waterHistory.last;
      _form["ph"] = last.ph;
      _form["do"] = last.doLevel;
      _form["temp"] = last.temp;
      _form["ammonia"] = last.ammonia;
      if (last.turbidity != null) _form["turbidity"] = last.turbidity!;
      if (last.nitrite != null) _form["nitrite"] = last.nitrite!;
      if (last.nitrate != null) _form["nitrate"] = last.nitrate!;
      if (last.alkalinity != null) _form["alkalinity"] = last.alkalinity!;
      if (last.salinity != null) _form["salinity"] = last.salinity!;
    }
  }

  void _setParam(String key, double value) {
    setState(() => _form[key] = value);
    context.read<AppState>().saveWaterFormDraft(_form);
  }

  void _submit(AppState app) {
    const order = ["ভালো", "সতর্ক", "ঝুঁকি", "বিপদ"];

    // ---- প্রতিটা প্যারামিটারের জন্য আলাদা ফলাফল বের করো ----
    final Map<String, Map<String, dynamic>> perParam = {};
    String overallWorst = "ভালো";

    for (final k in _form.keys) {
      final level = WaterRuleEngine.classify(k, _form[k]!);
      perParam[k] = {
        "paramKey": k,
        "param": _paramLabel[k] ?? k,
        "value": _form[k],
        "level": level,
        "why": WaterRuleEngine.feedback[k]?[level] ?? "",
      };
      if (order.indexOf(level) > order.indexOf(overallWorst)) {
        overallWorst = level;
      }
    }

    // সবচেয়ে খারাপ থেকে ভালো — এই ক্রমে সাজাও, জরুরি জিনিস আগে দেখানোর জন্য
    final sortedKeys = perParam.keys.toList()
      ..sort((a, b) => order
          .indexOf(perParam[b]!["level"])
          .compareTo(order.indexOf(perParam[a]!["level"])));

    final res = {
      "level": overallWorst, // সার্বিক (সবচেয়ে খারাপ) অবস্থা — headline-এ দেখানোর জন্য
      "perParam": perParam,
      "sortedKeys": sortedKeys,
    };
    setState(() => _result = res);

    final reading = WaterReading(
      timestamp: DateTime.now(),
      day: "${DateTime.now().day}/${DateTime.now().month}",
      ph: _form["ph"]!,
      doLevel: _form["do"]!,
      temp: _form["temp"]!,
      ammonia: _form["ammonia"]!,
      turbidity: _form["turbidity"],
      nitrite: _form["nitrite"],
      nitrate: _form["nitrate"],
      alkalinity: _form["alkalinity"],
      salinity: _form["salinity"],
    );
    app.addWaterReading(reading);
  }

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
              AppTopBar(title: "পানির মান", onBack: () => app.goTo("dashboard")),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Input card ----
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("আজকের রিডিং লিখুন", style: AqText.heading(size: 14)),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(999)),
                                child: Row(
                                  children: [
                                    _modeButton("সংখ্যা", "slider"),
                                    _modeButton("টেস্ট কিট", "kit"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_mode == "kit")
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: const Color(0xFFFBF3D9), borderRadius: BorderRadius.circular(14)),
                              child: Text(
                                "পানির নমুনায় টেস্ট কিট ব্যবহার করে যে রঙ পেয়েছেন, তার কাছাকাছি রঙটি বেছে নিন। এটি আনুমানিক মান দেখাবে।",
                                style: AqText.body(size: 11, color: const Color(0xFF7A5E0B)),
                              ),
                            ),

                          if (_mode == "slider")
                            ..._basicFields.map(_sliderRow)
                          else ...[
                            _kitRow("ph", "pH", ""),
                            _kitRow("do", "দ্রবীভূত অক্সিজেন (DO)", "mg/L"),
                          ],

                          InkWell(
                            onTap: () => setState(() => _advanced = !_advanced),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _advanced ? "সাধারণ প্যারামিটার দেখুন" : "উন্নত প্যারামিটার দেখুন",
                                    style: AqText.body(size: 12, color: AqColors.teal700, weight: FontWeight.w600),
                                  ),
                                  AnimatedRotation(
                                    turns: _advanced ? 0.25 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: const Icon(Icons.chevron_right, size: 15, color: AqColors.teal700),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_advanced) ...[
                            if (_mode == "slider")
                              ..._advancedFields.map(_sliderRow)
                            else ...[
                              _sliderRow(const _SliderField("temp", "তাপমাত্রা", 15, 40, 0.5, "°C")),
                              Text(
                                "তাপমাত্রা থার্মোমিটার দিয়ে সরাসরি মাপুন — কিট প্রযোজ্য নয়",
                                style: AqText.body(size: 10, color: AqColors.mutedLight),
                              ),
                              const SizedBox(height: 8),
                              _kitRow("ammonia", "অমিশ্রিত অ্যামোনিয়া (NH₃)", "mg/L"),
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(14)),
                                child: Text(
                                  "নিচের প্যারামিটারগুলো সরাসরি সংখ্যায় দিন — এগুলোর জন্য সাধারণ রঙ-মিলানো কিট নির্ভরযোগ্য নয়।",
                                  style: AqText.body(size: 11, color: AqColors.muted),
                                ),
                              ),
                              ..._advancedFields.where((f) => f.key != "temp").map(_sliderRow),
                            ],
                          ],

                          const SizedBox(height: 4),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AqColors.teal700,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: () => _submit(app),
                              child: Text("বিশ্লেষণ করুন", style: AqText.body(size: 14, color: Colors.white, weight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ---- Result: overall headline + প্রতিটা প্যারামিটারের আলাদা কার্ড ----
                    if (_result != null) ...[
                      const SizedBox(height: 14),

                      // সার্বিক (সবচেয়ে খারাপ) অবস্থা — এক নজরে headline
                      AppCard(
                        color: riskInfo(_result!["level"]).bg,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "সার্বিক অবস্থা: ${riskInfo(_result!["level"]).label}",
                                style: AqText.body(size: 14, color: riskInfo(_result!["level"]).color, weight: FontWeight.w700),
                              ),
                            ),
                            RiskPill(level: _result!["level"]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text("প্রতিটি প্যারামিটার অনুযায়ী বিস্তারিত", style: AqText.heading(size: 13)),
                      const SizedBox(height: 8),

                      // ---- প্রতিটা প্যারামিটারের জন্য আলাদা কার্ড (সবচেয়ে খারাপ থেকে ভালো ক্রমে) ----
                      ...List<String>.from(_result!["sortedKeys"]).map((paramKey) {
                        final Map<String, dynamic> p = _result!["perParam"][paramKey];
                        final level = p["level"] as String;
                        final info = riskInfo(level);
                        final steps = _stepsFor(paramKey, level);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            color: info.bg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${p["param"]} — ${_fmt((p["value"] as num).toDouble())}",
                                        style: AqText.body(size: 13, color: info.color, weight: FontWeight.w700),
                                      ),
                                    ),
                                    RiskPill(level: level),
                                  ],
                                ),
                                if ((p["why"] as String).isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(p["why"], style: AqText.body(size: 12)),
                                ],
                                if (level != "ভালো" && steps.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text("করণীয়:", style: AqText.body(size: 12, weight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  ...steps.map(
                                        (step) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("•  ", style: AqText.body(size: 12, color: info.color, weight: FontWeight.w700)),
                                          Expanded(child: Text(step, style: AqText.body(size: 12))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (level != "ভালো") ...[
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: TextSpan(
                                      style: AqText.body(size: 11, color: AqColors.deep),
                                      children: [
                                        TextSpan(text: "🐟 মাছের ওপর প্রভাব: ", style: AqText.body(size: 11, color: AqColors.deep, weight: FontWeight.w700)),
                                        TextSpan(
                                          text: WaterRuleEngine.fishImpact[paramKey]?[level] ??
                                              "এই মাত্রায় মাছের ওপর বাড়তি চাপ পড়তে পারে।",
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 14),
                    // ---- প্রধান দুটো প্যারামিটার (pH, DO) — সবসময় দেখাবে ----
                    _paramTrendCard(app, "ph", "pH", ""),
                    _paramTrendCard(app, "do", "DO (দ্রবীভূত অক্সিজেন)", "mg/L"),

                    // ---- বাকি প্যারামিটারের প্রবণতা — প্রয়োজনে দেখুন ----
                    InkWell(
                      onTap: () => setState(() => _advancedTrends = !_advancedTrends),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _advancedTrends ? "বাকি প্যারামিটারের প্রবণতা লুকান" : "বাকি প্যারামিটারের প্রবণতা দেখুন",
                              style: AqText.body(size: 12, color: AqColors.teal700, weight: FontWeight.w600),
                            ),
                            AnimatedRotation(
                              turns: _advancedTrends ? 0.25 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.chevron_right, size: 15, color: AqColors.teal700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_advancedTrends) ...[
                      _paramTrendCard(app, "temp", "তাপমাত্রা", "°C"),
                      _paramTrendCard(app, "ammonia", "অমিশ্রিত অ্যামোনিয়া (NH₃)", "mg/L"),
                      _paramTrendCard(app, "turbidity", "ঘোলাত্ব (Turbidity)", "NTU"),
                      _paramTrendCard(app, "nitrite", "নাইট্রাইট", "mg/L"),
                      _paramTrendCard(app, "nitrate", "নাইট্রেট", "mg/L"),
                      _paramTrendCard(app, "alkalinity", "ক্ষারত্ব (Alkalinity)", "mg/L"),
                      _paramTrendCard(app, "salinity", "লবণাক্ততা", "ppt"),
                    ],

                    // ---- History ----
                    if (app.waterHistory.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text("ইতিহাস", style: AqText.heading(size: 14)),
                      const SizedBox(height: 4),
                      Text(
                        "যেকোনো এন্ট্রিতে ট্যাপ করে সেই দিনের করণীয় দেখুন",
                        style: AqText.body(size: 10, color: AqColors.mutedLight),
                      ),
                      const SizedBox(height: 10),
                      ...app.waterHistory.reversed.take(10).toList().asMap().entries.map((entry) {
                        final i = entry.key;
                        final r = entry.value;
                        final expanded = _expandedHistoryIndex == i;
                        final analysis = _analyzeReading(r);
                        final level = analysis["level"] as String;
                        final worstParamKey = analysis["paramKey"] as String;
                        final worstParamLabel = analysis["param"] as String;
                        final steps = _stepsFor(worstParamKey, level);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            onTap: () => setState(() => _expandedHistoryIndex = expanded ? null : i),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r.day, style: AqText.body(size: 13, weight: FontWeight.w600)),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          "pH ${_fmt(r.ph)}  ·  DO ${_fmt(r.doLevel)}  ·  ${_fmt(r.temp)}°C",
                                          style: AqText.body(size: 11, color: AqColors.muted),
                                        ),
                                      ),
                                    ),
                                    RiskPill(level: level),
                                    const SizedBox(width: 4),
                                    AnimatedRotation(
                                      turns: expanded ? 0.25 : 0,
                                      duration: const Duration(milliseconds: 200),
                                      child: const Icon(Icons.chevron_right, size: 16, color: AqColors.mutedLight),
                                    ),
                                  ],
                                ),
                                if (expanded) ...[
                                  const SizedBox(height: 10),
                                  Container(height: 1, color: AqColors.border),
                                  const SizedBox(height: 10),
                                  if (level == "ভালো")
                                    Text(
                                      "এই দিনের রিডিং স্বাভাবিক পরিসরে ছিল — কোনো বিশেষ ব্যবস্থার দরকার ছিল না।",
                                      style: AqText.body(size: 12, color: AqColors.muted),
                                    )
                                  else ...[
                                    Text(
                                      "সবচেয়ে বড় সমস্যা ছিল: $worstParamLabel (${riskInfo(level).label})",
                                      style: AqText.body(size: 12, weight: FontWeight.w700, color: riskInfo(level).color),
                                    ),
                                    if (steps.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text("করণীয় ছিল:", style: AqText.body(size: 12, weight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      ...List.generate(steps.length, (si) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 16,
                                                height: 16,
                                                margin: const EdgeInsets.only(top: 1),
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(color: riskInfo(level).color, shape: BoxShape.circle),
                                                child: Text("${si + 1}", style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(steps[si], style: AqText.body(size: 12))),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(current: "water", onSelect: app.goTo),
      ),
    );
  }

  /// একটা WaterReading থেকে নির্দিষ্ট প্যারামিটারের মান বের করে (null হতে পারে,
  /// কারণ কিছু advanced প্যারামিটার প্রতিটা reading-এ নাও থাকতে পারে)
  double? _valueFor(String key, WaterReading r) {
    switch (key) {
      case "ph":
        return r.ph;
      case "do":
        return r.doLevel;
      case "temp":
        return r.temp;
      case "ammonia":
        return r.ammonia;
      case "turbidity":
        return r.turbidity;
      case "nitrite":
        return r.nitrite;
      case "nitrate":
        return r.nitrate;
      case "alkalinity":
        return r.alkalinity;
      case "salinity":
        return r.salinity;
    }
    return null;
  }

  /// একটা প্যারামিটারের জন্য: চার্ট (নিরাপদ পরিসীমা + উৎসসহ) + প্রবণতা
  /// বিশ্লেষণ + বর্তমান অবস্থার ভিত্তিতে প্রকৃত করণীয় লিস্ট — সব একসাথে
  Widget _paramTrendCard(AppState app, String key, String label, String unit) {
    final entries = <MapEntry<String, double>>[];
    for (final r in app.waterHistory) {
      final v = _valueFor(key, r);
      if (v != null) entries.add(MapEntry(r.day, v));
    }
    final recent = entries.length > 15 ? entries.sublist(entries.length - 15) : entries;

    final goodRange = WaterRuleEngine.goodRangeFor(key);
    final src = WaterRuleEngine.sourceNote[key];
    final isConservative = src?["reliability"] == "conservative";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$label — সাপ্তাহিক প্রবণতা", style: AqText.heading(size: 14)),
            const SizedBox(height: 2),
            if (goodRange != null && src != null)
              Text(
                isConservative
                    ? "আনুমানিক নিরাপদ পরিসীমা: ${_fmt(goodRange[0])}–${_fmt(goodRange[1])} $unit — সাধারণ pond-culture নির্দেশিকা, নির্দিষ্ট বাংলাদেশ-উৎস যাচাই করা যায়নি"
                    : "নিরাপদ পরিসীমা: ${_fmt(goodRange[0])}–${_fmt(goodRange[1])} $unit  (Source: ${src["source"]})",
                style: TextStyle(
                  fontSize: 10,
                  color: isConservative ? const Color(0xFFB85A12) : Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "এই প্যারামিটারের জন্য এখনো কোনো রিডিং নেই।",
                  style: AqText.body(size: 11, color: AqColors.muted),
                ),
              )
            else ...[
              MiniLineChart(
                xLabels: recent.map((e) => e.key).toList(),
                series: [ChartSeries(label: label, color: AqColors.teal700, values: recent.map((e) => e.value).toList())],
                height: 120,
                safeMin: goodRange?[0],
                safeMax: goodRange?[1],
              ),
              if (entries.length >= 2) ...[
                const SizedBox(height: 10),
                Builder(builder: (context) {
                  final trendValues = entries.length > 7
                      ? entries.sublist(entries.length - 7).map((e) => e.value).toList()
                      : entries.map((e) => e.value).toList();
                  final trend = WaterRuleEngine.trendAdvice(key, trendValues);
                  final currentLevel = WaterRuleEngine.classify(key, entries.last.value);
                  final steps = _stepsFor(key, currentLevel);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _trendBox(label, AqColors.teal700, trend),
                      // ---- এখানেই প্রকৃত করণীয় দেখানো হচ্ছে — আগে ট্রেন্ড
                      // বক্স "নিচের করণীয় দেখুন" বললেও কোনো লিস্ট ছিল না ----
                      if (currentLevel != "ভালো" && steps.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AqColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("করণীয়:", style: AqText.body(size: 12, weight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              ...List.generate(steps.length, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        margin: const EdgeInsets.only(top: 1),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: riskInfo(currentLevel).color, shape: BoxShape.circle),
                                        child: Text("${i + 1}", style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(steps[i], style: AqText.body(size: 12))),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// একটা historical WaterReading থেকে সবচেয়ে খারাপ প্যারামিটার ও লেভেল বের করে
  /// — ইতিহাসের এন্ট্রি ট্যাপ করলে সেই দিনের করণীয় দেখানোর জন্য ব্যবহার হয়।
  Map<String, dynamic> _analyzeReading(WaterReading r) {
    const order = ["ভালো", "সতর্ক", "ঝুঁকি", "বিপদ"];
    final values = <String, double>{
      "ph": r.ph,
      "do": r.doLevel,
      "temp": r.temp,
      "ammonia": r.ammonia,
      if (r.turbidity != null) "turbidity": r.turbidity!,
      if (r.nitrite != null) "nitrite": r.nitrite!,
      if (r.nitrate != null) "nitrate": r.nitrate!,
      if (r.alkalinity != null) "alkalinity": r.alkalinity!,
      if (r.salinity != null) "salinity": r.salinity!,
    };

    String worstKey = "ph";
    String worstLevel = "ভালো";
    for (final e in values.entries) {
      final level = WaterRuleEngine.classify(e.key, e.value);
      if (order.indexOf(level) > order.indexOf(worstLevel)) {
        worstLevel = level;
        worstKey = e.key;
      }
    }

    return {"level": worstLevel, "paramKey": worstKey, "param": _paramLabel[worstKey] ?? worstKey};
  }

  List<String> _stepsFor(String paramKey, String level) {
    final specific = WaterRuleEngine.paramStepGuide[paramKey]?[level];
    if (specific != null && specific.isNotEmpty) return specific;
    return WaterRuleEngine.stepGuide[level] ?? [];
  }

  Widget _trendBox(String label, Color color, Map<String, String> trend) {
    IconData icon;
    switch (trend["trend"]) {
      case "বাড়ছে":
        icon = Icons.trending_up_rounded;
        break;
      case "কমছে":
        icon = Icons.trending_down_rounded;
        break;
      default:
        icon = Icons.trending_flat_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AqText.body(size: 11, color: AqColors.deep),
                children: [
                  TextSpan(text: "$label — ${trend["trend"]}: ", style: AqText.body(size: 11, color: AqColors.deep, weight: FontWeight.w700)),
                  TextSpan(text: trend["advice"]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String label, String mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AqColors.teal700 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: AqText.body(size: 11, color: active ? Colors.white : AqColors.muted, weight: FontWeight.w600)),
      ),
    );
  }

  Widget _sliderRow(_SliderField f) {
    final value = _roundToStep(_form[f.key]!.clamp(f.min, f.max), f.step);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(f.label, style: AqText.body(size: 12, color: AqColors.muted)),
              Text("${_fmt(value)} ${f.unit}", style: AqText.body(size: 12, weight: FontWeight.w700)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AqColors.teal700,
              inactiveTrackColor: AqColors.border,
              thumbColor: AqColors.teal700,
              overlayColor: AqColors.teal700.withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              min: f.min,
              max: f.max,
              value: value,
              // ---- divisions দিয়ে স্লাইডার নির্দিষ্ট ধাপে "স্ন্যাপ" করে ----
              // এটা ছাড়া টেনে ছাড়ার সময় যেকোনো লম্বা দশমিক মান
              // (যেমন 2.0227604166666664) তৈরি হয়ে সরাসরি সেভ হয়ে যেত।
              divisions: (((f.max - f.min) / f.step).round()).clamp(1, 100000),
              onChanged: (v) => _setParam(f.key, _roundToStep(v, f.step)),
            ),
          ),
        ],
      ),
    );
  }

  /// একটা মানকে নির্দিষ্ট step-এর কাছাকাছি পরিষ্কার সংখ্যায় রাউন্ড করে —
  /// floating-point ত্রুটির কারণে "2.0227604..." এর মতো লম্বা মান
  /// যেন কখনো _form/history-তে সেভ না হয়, তার জন্য দ্বিতীয় নিরাপত্তা স্তর।
  double _roundToStep(double v, double step) {
    if (step <= 0) return double.parse(v.toStringAsFixed(3));
    final snapped = (v / step).round() * step;
    return double.parse(snapped.toStringAsFixed(4));
  }

  Widget _kitRow(String key, String label, String unit) {
    final swatches = _waterKit[key]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AqText.body(size: 12, color: AqColors.muted)),
              Text("${_fmt(_form[key]!)} $unit", style: AqText.body(size: 12, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: swatches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final sw = swatches[i];
                final selected = _form[key] == sw.value;
                return GestureDetector(
                  onTap: () => _setParam(key, sw.value),
                  child: SizedBox(
                    width: 58,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: sw.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: selected ? AqColors.teal700 : Colors.transparent, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 28,
                          child: Text(
                            sw.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9, color: AqColors.muted, height: 1.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(v < 1 ? 3 : 1);
  }
}