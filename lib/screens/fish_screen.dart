import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../models/app_models.dart';
import '../services/fish_classifier_service.dart';
import '../services/fish_gatekeeper_service.dart';
import '../theme/aq_theme.dart';
import '../widgets/shared_widgets.dart';

class FishScreen extends StatefulWidget {
  const FishScreen({super.key});

  @override
  State<FishScreen> createState() => _FishScreenState();
}

class _FishScreenState extends State<FishScreen> with SingleTickerProviderStateMixin {
  final AquaGuardClassifier _classifier = AquaGuardClassifier();
  final FishGatekeeperService _gatekeeper = FishGatekeeperService();
  final ImagePicker _picker = ImagePicker();
  late final AnimationController _spinCtrl;

  File? _selectedImage;
  FishClassificationResult? _result;
  String _stage = "idle"; // idle -> scanning -> result
  bool _modelReady = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _classifier.loadModel();
      // gatekeeper লোড ব্যর্থ হলেও মূল ডিজিজ স্ক্যান যেন বন্ধ না হয়ে
      // যায় — তাই এটা আলাদা try-catch-এ, শুধু নীরবে বন্ধ থাকবে।
      try {
        await _gatekeeper.loadModel();
      } catch (_) {
        // gatekeeper optional — ব্যর্থ হলে সরাসরি ডিজিজ স্ক্যানে যাবে
      }
      if (mounted) setState(() => _modelReady = true);
    } catch (e) {
      if (mounted) setState(() => _loadError = "মডেল লোড করা যায়নি: $e");
    }
  }

  Future<void> _showNotFishDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFE07A22).withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.image_search_rounded, size: 20, color: Color(0xFFE07A22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text("মাছের ছবি প্রয়োজন", style: AqText.body(size: 15, weight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "এই ছবিতে স্পষ্টভাবে মাছ শনাক্ত করা যায়নি, তাই রোগ বিশ্লেষণ করা হয়নি।",
              style: AqText.body(size: 13, color: AqColors.deep, weight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ভালো ফলাফলের জন্য:", style: AqText.body(size: 12, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _tipRow(Icons.center_focus_strong_rounded, "শুধু মাছের ছবি তুলুন, অন্য কিছু না"),
                  _tipRow(Icons.wb_sunny_outlined, "দিনের আলোয় বা উজ্জ্বল আলোতে তুলুন"),
                  _tipRow(Icons.crop_free_rounded, "মাছের পুরো শরীর ফ্রেমে রাখুন"),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "এই প্রাথমিক যাচাই সীমিত (মূলত কিছু নির্দিষ্ট প্রজাতির জন্য প্রশিক্ষিত), তাই মাঝেমধ্যে সঠিক মাছের ছবিতেও এই বার্তা আসতে পারে। এমন হলে ভিন্ন angle থেকে আবার চেষ্টা করুন।",
              style: AqText.body(size: 11, color: AqColors.mutedLight),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AqColors.teal700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("বুঝেছি, আবার ছবি তুলব", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
      _stage = "scanning";
    });

    try {
      // ---- প্রথমে gatekeeper দিয়ে যাচাই: ছবিতে মাছ/জলজ প্রাণীর মতো
      // কিছু আছে কিনা (soft check — hard block না, শুধু সতর্ক করে) ----
      if (_gatekeeper.isLoaded) {
        final gate = await _gatekeeper.check(_selectedImage!);
        if (!gate.looksLikeFish) {
          if (!mounted) return;
          await _showNotFishDialog();
          setState(() => _stage = "idle"); // hard block — override করার সুযোগ নেই
          return;
        }
      }

      final result = await _classifier.classifyImage(_selectedImage!);
      if (!mounted) return;
      setState(() {
        _result = result;
        _stage = "result";
      });

      final app = context.read<AppState>();
      await app.addFishScan(FishScanResult(
        timestamp: DateTime.now(),
        uncertain: result.uncertain,
        confidence: result.confidence,
        diseaseId: result.info?.id,
        name: result.info?.name,
        level: result.info?.level,
        signs: result.info?.signs ?? [],
        causes: result.info?.causes ?? [],
        pondActions: result.info?.pondActions ?? [],
        expertNote: result.info?.expertNote,
        healthy: result.uncertain ? null : result.isHealthy,
        imagePath: _selectedImage!.path,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = "idle");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("স্ক্যান ব্যর্থ হয়েছে: $e")));
    }
  }

  void _reset() {
    setState(() {
      _stage = "idle";
      _selectedImage = null;
      _result = null;
    });
  }

  @override
  void dispose() {
    _classifier.dispose();
    _gatekeeper.dispose();
    _spinCtrl.dispose();
    super.dispose();
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
              AppTopBar(title: "মাছ স্ক্যান", onBack: () => app.goTo("dashboard")),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Disclaimer banner ----
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF1E9E8C)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        "এটি একটি স্ক্রিনিং টুল — চূড়ান্ত রোগ নির্ণয় নয়। সন্দেহ হলে বিশেষজ্ঞের পরামর্শ নিন।",
                        style: AqText.body(size: 12, color: AqColors.mist),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(_loadError!, style: AqText.body(size: 12, color: const Color(0xFFD5473A))),
                      ),

                    // ---- idle ----
                    if (_stage == "idle")
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: const Color(0xFFF5A623).withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                              child: const Icon(Icons.set_meal_rounded, size: 34, color: Color(0xFFF5A623)),
                            ),
                            const SizedBox(height: 16),
                            Text("মাছের ছবি তুলুন", style: AqText.body(size: 14, weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                "স্পষ্ট আলোয়, একটি মাছের কাছ থেকে ছবি তুলুন",
                                textAlign: TextAlign.center,
                                style: AqText.body(size: 12, color: AqColors.muted),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _modelReady ? () => _pickImage(ImageSource.camera) : null,
                                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                  label: Text("ছবি তুলুন", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AqColors.teal700,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: _modelReady ? () => _pickImage(ImageSource.gallery) : null,
                                  icon: const Icon(Icons.photo_library_outlined, size: 18, color: AqColors.teal700),
                                  label: Text("আপলোড", style: AqText.body(size: 13, color: AqColors.teal700, weight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AqColors.border),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                ),
                              ],
                            ),
                            if (!_modelReady && _loadError == null) ...[
                              const SizedBox(height: 12),
                              Text("মডেল লোড হচ্ছে...", style: AqText.body(size: 11, color: AqColors.mutedLight)),
                            ],
                          ],
                        ),
                      ),

                    // ---- scanning ----
                    if (_stage == "scanning")
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            if (_selectedImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(_selectedImage!, width: 128, height: 128, fit: BoxFit.cover),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RotationTransition(
                                  turns: _spinCtrl,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AqColors.teal700, width: 2),
                                    ),
                                    child: const Align(alignment: Alignment.topCenter, child: SizedBox()),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text("বিশ্লেষণ করা হচ্ছে…", style: AqText.body(size: 13, weight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // ---- result ----
                    if (_stage == "result" && _result != null)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_selectedImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(_selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover),
                              ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 12, color: AqColors.mutedLight),
                                  const SizedBox(width: 4),
                                  Text(_formatDateTime(DateTime.now()), style: AqText.body(size: 10, color: AqColors.mutedLight)),
                                ],
                              ),
                            ),

                            if (_result!.uncertain) ...[
                              // ---- অনিশ্চিত ফলাফল — বিস্তারিত গাইডেন্স সহ ----
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: const Color(0xFFE07A22).withOpacity(0.12), shape: BoxShape.circle),
                                    child: const Icon(Icons.help_outline_rounded, size: 20, color: Color(0xFFE07A22)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("নিশ্চিতভাবে মূল্যায়ন করা যাচ্ছে না", style: AqText.body(size: 14, color: const Color(0xFFE07A22), weight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(
                                          _result!.message ?? "ছবিটি স্পষ্ট না হওয়ায় নির্দিষ্ট ফলাফল দেওয়া যায়নি।",
                                          style: AqText.body(size: 12, color: AqColors.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("স্পষ্ট ছবি পেতে যা করবেন:", style: AqText.body(size: 12, weight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    _tipRow(Icons.wb_sunny_outlined, "দিনের আলোয় বা উজ্জ্বল আলোতে ছবি তুলুন"),
                                    _tipRow(Icons.center_focus_strong_rounded, "একটামাত্র মাছের কাছ থেকে, স্পষ্ট ফোকাসে তুলুন"),
                                    _tipRow(Icons.crop_free_rounded, "মাছের পুরো শরীর ফ্রেমে রাখুন, বেশি দূর থেকে না"),
                                    _tipRow(Icons.water_drop_outlined, "পানি/কাদা লেগে থাকলে যতটা সম্ভব পরিষ্কার অংশ দেখান"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "বারবার অস্পষ্ট ফলাফল এলে বা মাছের আচরণ অস্বাভাবিক মনে হলে স্থানীয় মৎস্য বিশেষজ্ঞের সরাসরি পরামর্শ নিন।",
                                style: AqText.body(size: 11, color: AqColors.muted),
                              ),
                            ] else ...[
                              // ---- নির্দিষ্ট ফলাফল — বিস্তারিত তথ্যসহ ----
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: riskInfo(_result!.info!.level).bg, shape: BoxShape.circle),
                                    child: Icon(
                                      _result!.isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                                      size: 20,
                                      color: riskInfo(_result!.info!.level).color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_result!.info!.name, style: AqText.body(size: 15, weight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        RiskPill(level: _result!.info!.level),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              if (_result!.isHealthy) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: riskInfo(_result!.info!.level).bg, borderRadius: BorderRadius.circular(14)),
                                  child: Text(
                                    "সুখবর — এই ছবিতে অসুস্থতার কোনো সুস্পষ্ট লক্ষণ পাওয়া যায়নি। নিয়মিত পর্যবেক্ষণ চালিয়ে গেলে পুকুরের স্বাস্থ্য ভালো থাকবে।",
                                    style: AqText.body(size: 12, color: riskInfo(_result!.info!.level).color),
                                  ),
                                ),
                              ],

                              if (_result!.info!.signs.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _sectionHeader(Icons.visibility_outlined, "পর্যবেক্ষিত লক্ষণ"),
                                const SizedBox(height: 6),
                                ..._result!.info!.signs.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 5, height: 5,
                                        margin: const EdgeInsets.only(top: 6, right: 8),
                                        decoration: const BoxDecoration(color: AqColors.mutedLight, shape: BoxShape.circle),
                                      ),
                                      Expanded(child: Text(s, style: AqText.body(size: 12))),
                                    ],
                                  ),
                                )),
                              ],

                              if (_result!.info!.causes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _sectionHeader(Icons.search_rounded, "সম্ভাব্য কারণ"),
                                const SizedBox(height: 6),
                                ..._result!.info!.causes.map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 5, height: 5,
                                        margin: const EdgeInsets.only(top: 6, right: 8),
                                        decoration: const BoxDecoration(color: AqColors.mutedLight, shape: BoxShape.circle),
                                      ),
                                      Expanded(child: Text(c, style: AqText.body(size: 12))),
                                    ],
                                  ),
                                )),
                              ],

                              const SizedBox(height: 14),
                              _sectionHeader(Icons.checklist_rounded, "পুকুরে করণীয় (কী দিতে/করতে হবে)"),
                              const SizedBox(height: 8),
                              ...List.generate(_result!.info!.pondActions.length, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        margin: const EdgeInsets.only(top: 1),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: riskInfo(_result!.info!.level).color, shape: BoxShape.circle),
                                        child: Text("${i + 1}", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_result!.info!.pondActions[i], style: AqText.body(size: 12))),
                                    ],
                                  ),
                                );
                              }),

                              if ((_result!.info!.expertNote ?? "").isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: riskInfo(_result!.info!.level).bg, borderRadius: BorderRadius.circular(14)),
                                  child: RichText(
                                    text: TextSpan(
                                      style: AqText.body(size: 11, color: riskInfo(_result!.info!.level).color),
                                      children: [
                                        TextSpan(text: "বিশেষজ্ঞ নোট: ", style: AqText.body(size: 11, color: riskInfo(_result!.info!.level).color, weight: FontWeight.w700)),
                                        TextSpan(text: _result!.info!.expertNote),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AqColors.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.event_repeat_rounded, size: 15, color: AqColors.teal700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _result!.isHealthy
                                            ? "পরবর্তী স্ক্যান: সপ্তাহে ১ বার নিয়মিত পর্যবেক্ষণের জন্য যথেষ্ট।"
                                            : "পরবর্তী স্ক্যান: ২৪-৪৮ ঘণ্টার মধ্যে আবার স্ক্যান করে উন্নতি হচ্ছে কিনা দেখুন।",
                                        style: AqText.body(size: 11, color: AqColors.muted),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("ℹ️ ", style: TextStyle(fontSize: 11)),
                                    Expanded(
                                      child: Text(
                                        _result!.disclaimer,
                                        style: AqText.body(size: 10, color: AqColors.mutedLight),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _reset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AqColors.track,
                                  foregroundColor: AqColors.teal700,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: Text("আবার স্ক্যান করুন", style: AqText.body(size: 13, color: AqColors.teal700, weight: FontWeight.w700)),
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
        bottomNavigationBar: AppBottomNav(current: "fish", onSelect: app.goTo),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AqColors.teal700),
        const SizedBox(width: 6),
        Text(title, style: AqText.body(size: 12, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _tipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AqColors.teal700),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AqText.body(size: 12))),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = ["জানু", "ফেব্রু", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্ট", "অক্টো", "নভে", "ডিসে"];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    final minute = dt.minute.toString().padLeft(2, '0');
    return "স্ক্যান করা হয়েছে: ${dt.day} ${months[dt.month - 1]}, $hour12:$minute $ampm";
  }
}