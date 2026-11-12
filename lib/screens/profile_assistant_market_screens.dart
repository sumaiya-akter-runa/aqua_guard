import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/app_models.dart';
import '../services/feed_solution_engine.dart';
import '../services/chat_engine.dart';
import '../services/fish_food_market_service.dart';
import '../services/api_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme/aq_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/connectivity_badge.dart';

// ============================================================
// Profile Screen
// ============================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _districtCtrl;

  late TextEditingController _farmNameCtrl;
  late TextEditingController _pondNameCtrl;
  late TextEditingController _sizeCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _stockingDateCtrl;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _nameCtrl = TextEditingController(text: app.farmer.name);
    _phoneCtrl = TextEditingController(text: app.farmer.phone);
    _districtCtrl = TextEditingController(text: app.farmer.district);

    _farmNameCtrl = TextEditingController(text: app.pondSetup.farmName);
    _pondNameCtrl = TextEditingController(text: app.pondSetup.pondName);
    _sizeCtrl = TextEditingController(text: app.pondSetup.sizeDecimal.toString());
    _quantityCtrl = TextEditingController(text: app.pondSetup.quantity.toString());
    _stockingDateCtrl = TextEditingController(text: app.pondSetup.stockingDate);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _districtCtrl.dispose();
    _farmNameCtrl.dispose();
    _pondNameCtrl.dispose();
    _sizeCtrl.dispose();
    _quantityCtrl.dispose();
    _stockingDateCtrl.dispose();
    super.dispose();
  }

  void _saveProfile(AppState app) {
    app.updateFarmer(Farmer(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      subscribed: app.farmer.subscribed,
      subscribedSince: app.farmer.subscribedSince,
    ));
    setState(() => _editing = false);
  }

  void _savePondField() {
    final app = context.read<AppState>();
    app.updatePondSetup(PondSetup(
      farmName: _farmNameCtrl.text.trim(),
      pondName: _pondNameCtrl.text.trim(),
      sizeDecimal: double.tryParse(_sizeCtrl.text) ?? app.pondSetup.sizeDecimal,
      quantity: int.tryParse(_quantityCtrl.text) ?? app.pondSetup.quantity,
      species: app.pondSetup.species,
      stockingDate: _stockingDateCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final farmer = app.farmer;
    final pond = app.pondSetup;

    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              AppTopBar(title: "প্রোফাইল", onBack: () => app.goTo("dashboard")),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Header card ----
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF178077)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(18)),
                            child: Text(
                              farmer.name.isNotEmpty ? farmer.name.substring(0, 1) : "?",
                              style: AqText.heading(size: 22, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(farmer.name.isNotEmpty ? farmer.name : "নাম নেই", style: AqText.heading(size: 16, color: Colors.white)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  const Icon(Icons.person_outline, size: 12, color: AqColors.mist),
                                  const SizedBox(width: 4),
                                  Text(farmer.phone.isNotEmpty ? farmer.phone : "নম্বর নেই", style: AqText.body(size: 11, color: AqColors.mist)),
                                ]),
                                const SizedBox(height: 2),
                                Row(children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: AqColors.mist),
                                  const SizedBox(width: 4),
                                  Text(farmer.district, style: AqText.body(size: 11, color: AqColors.mist)),
                                ]),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _editing = !_editing),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                              child: const Icon(Icons.edit_outlined, size: 15, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_editing) ...[
                      const SizedBox(height: 14),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label("নাম"),
                            _input(_nameCtrl),
                            const SizedBox(height: 10),
                            _label("মোবাইল নম্বর"),
                            _input(_phoneCtrl, keyboardType: TextInputType.phone),
                            const SizedBox(height: 10),
                            _label("জেলা"),
                            _input(_districtCtrl),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () => _saveProfile(app),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AqColors.teal700,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text("সংরক্ষণ করুন", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    // ---- Subscription card ----
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFF6D9), Color(0xFFFCE29B)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.emoji_events_outlined, size: 18, color: Color(0xFF9A6F06)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  farmer.subscribed ? "সাবস্ক্রিপশন সক্রিয়" : "সাবস্ক্রিপশন নিষ্ক্রিয়",
                                  style: AqText.body(size: 13, color: const Color(0xFF7A5E0B), weight: FontWeight.w700),
                                ),
                                Text(
                                  farmer.subscribed ? "প্রতিদিন নির্ধারিত হারে চার্জ কাটা হচ্ছে (Robi/Cirkle)" : "সম্পূর্ণ ফিচার ব্যবহার করতে সাবস্ক্রাইব করুন",
                                  style: AqText.body(size: 11, color: const Color(0xFF8A6A0E)),
                                ),
                              ],
                            ),
                          ),
                          if (farmer.subscribed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF9A6F06), borderRadius: BorderRadius.circular(999)),
                              child: const Text("✓ সক্রিয়", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    // ---- Farm/pond info ----
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.set_meal_rounded, size: 16, color: AqColors.teal700),
                              const SizedBox(width: 8),
                              Text("আমার ফার্ম ও পুকুরের তথ্য", style: AqText.heading(size: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _label("ফার্মের নাম"),
                          _input(_farmNameCtrl, onSubmit: _savePondField),
                          const SizedBox(height: 10),
                          _label("পুকুরের নাম"),
                          _input(_pondNameCtrl, onSubmit: _savePondField),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label("পুকুরের আকার (শতক)"),
                                    _input(_sizeCtrl, keyboardType: TextInputType.number, onSubmit: _savePondField),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label("মাছের সংখ্যা"),
                                    _input(_quantityCtrl, keyboardType: TextInputType.number, onSubmit: _savePondField),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _label("মজুদের তারিখ (Stocking Date)"),
                          _input(_stockingDateCtrl, onSubmit: _savePondField, hint: "YYYY-MM-DD"),
                          const SizedBox(height: 12),
                          Text("মাছের প্রজাতি", style: AqText.body(size: 11, color: AqColors.muted)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: speciesList.map((s) {
                              final selected = pond.species == s;
                              return GestureDetector(
                                onTap: () => app.updatePondSetup(PondSetup(
                                  farmName: pond.farmName,
                                  pondName: pond.pondName,
                                  sizeDecimal: pond.sizeDecimal,
                                  quantity: pond.quantity,
                                  species: s,
                                  stockingDate: pond.stockingDate,
                                )),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected ? AqColors.teal700 : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: selected ? AqColors.teal700 : AqColors.border),
                                  ),
                                  child: Text(s, style: AqText.body(size: 11, color: selected ? Colors.white : AqColors.deep, weight: FontWeight.w600)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 6),
                          Text("প্রজাতি বদলালে \"খাবার\" পেজের প্রস্তাবিত খাবারের তালিকাও বদলে যাবে।", style: AqText.body(size: 10, color: AqColors.mutedLight)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => app.goTo("history"),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF178077)]),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.history_rounded, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("পুকুরের সম্পূর্ণ কার্যক্রম দেখুন", style: AqText.body(size: 13, color: Colors.white, weight: FontWeight.w600)),
                                  Text("পানি, খাবার, বৃদ্ধি ও মাছ স্ক্যান — সব একসাথে", style: AqText.body(size: 10, color: AqColors.mist)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    // ---- Settings list ----
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text("সেটিংস", style: AqText.heading(size: 14)),
                          ),
                          _settingsRow(
                            icon: Icons.notifications_outlined,
                            label: "নোটিফিকেশন",
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                          ),
                          _settingsRow(
                            icon: Icons.settings_outlined,
                            label: "অ্যাপ সেটিংস",
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppSettingsScreen())),
                          ),
                          _settingsRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: "সাহায্য ও সাপোর্ট",
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmLogout(context, app),
                        icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFD5473A)),
                        label: Text("লগ-আউট", style: AqText.body(size: 13, color: const Color(0xFFD5473A), weight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBE3E0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmUnsubscribe(context, app),
                        icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFF7A5E0B)),
                        label: Text("সাবস্ক্রিপশন বন্ধ করুন", style: AqText.body(size: 13, color: const Color(0xFF7A5E0B), weight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF1DFB2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(current: "profile", onSelect: app.goTo),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("লগ-আউট নিশ্চিত করুন", style: AqText.heading(size: 15)),
        content: Text("আপনি কি নিশ্চিতভাবে লগ-আউট করতে চান?", style: AqText.body(size: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("বাতিল", style: AqText.body(size: 13, color: AqColors.muted))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              app.logout();
            },
            child: Text("লগ-আউট", style: AqText.body(size: 13, color: const Color(0xFFD5473A), weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // bdApps-এর subscription/send (action=0) কল করে আসল আনসাবস্ক্রিপশন করে —
  // logout()-এর মতো শুধু লোকাল সেশন ক্লিয়ার করে না।
  void _confirmUnsubscribe(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("সাবস্ক্রিপশন বন্ধ করুন", style: AqText.heading(size: 15)),
        content: Text(
          "আনসাবস্ক্রাইব করলে প্রতিদিনের চার্জ কাটা বন্ধ হয়ে যাবে এবং আপনি লগ-আউট হয়ে যাবেন। এগিয়ে যেতে চান?",
          style: AqText.body(size: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("বাতিল", style: AqText.body(size: 13, color: AqColors.muted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await app.unsubscribeSubscription();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.success
                        ? "সাবস্ক্রিপশন সফলভাবে বন্ধ হয়েছে।"
                        : (result.message.isNotEmpty ? result.message : "আনসাবস্ক্রাইব করা যায়নি, আবার চেষ্টা করুন।"),
                  ),
                ),
              );
            },
            child: Text("আনসাবস্ক্রাইব করুন", style: AqText.body(size: 13, color: const Color(0xFF7A5E0B), weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: AqText.body(size: 11, color: AqColors.muted)),
  );

  Widget _input(TextEditingController c, {TextInputType? keyboardType, VoidCallback? onSubmit, String? hint}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      onChanged: (_) => onSubmit?.call(),
      style: AqText.body(size: 13),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AqColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AqColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AqColors.teal700)),
      ),
    );
  }

  Widget _settingsRow({required IconData icon, required String label, required VoidCallback onTap, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF0F5F4))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AqColors.teal700),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AqText.body(size: 13))),
            const Icon(Icons.chevron_right, size: 16, color: AqColors.mutedLight),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Notification settings — functional toggle, persisted locally
// ============================================================
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _waterAlerts = true;
  bool _fishAlerts = true;
  bool _marketAlerts = false;
  bool _loading = true;

  // ---- দৈনিক রিমাইন্ডার ----
  bool _waterReminderOn = false;
  TimeOfDay _waterReminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _feedReminderOn = false;
  TimeOfDay _feedReminderTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final on = await StorageService.getNotificationsOn();
    final water = await StorageService.getWaterReminder();
    final feed = await StorageService.getFeedReminder();
    setState(() {
      _waterAlerts = on;
      _fishAlerts = on;
      _waterReminderOn = water.$1;
      _waterReminderTime = TimeOfDay(hour: water.$2, minute: water.$3);
      _feedReminderOn = feed.$1;
      _feedReminderTime = TimeOfDay(hour: feed.$2, minute: feed.$3);
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await StorageService.setNotificationsOn(_waterAlerts || _fishAlerts || _marketAlerts);
  }

  Future<void> _toggleWaterReminder(bool on) async {
    setState(() => _waterReminderOn = on);
    await StorageService.setWaterReminder(on, _waterReminderTime.hour, _waterReminderTime.minute);
    if (on) {
      await NotificationService.scheduleDailyReminder(
        id: NotificationService.kWaterReminderId,
        title: "🌊 আজ পানি পরীক্ষা করেছেন?",
        body: "নিয়মিত পানির মান পরীক্ষা করলে পুকুরের স্বাস্থ্য ভালো থাকে। এখনই \"পানি\" পেজে গিয়ে রিডিং জমা দিন।",
        hour: _waterReminderTime.hour,
        minute: _waterReminderTime.minute,
      );
    } else {
      await NotificationService.cancelReminder(NotificationService.kWaterReminderId);
    }
  }

  Future<void> _toggleFeedReminder(bool on) async {
    setState(() => _feedReminderOn = on);
    await StorageService.setFeedReminder(on, _feedReminderTime.hour, _feedReminderTime.minute);
    if (on) {
      await NotificationService.scheduleDailyReminder(
        id: NotificationService.kFeedReminderId,
        title: "🐟 খাবার দেওয়ার সময় হয়েছে",
        body: "আপনার পুকুরের মাছকে আজকের নির্ধারিত খাবার দিতে ভুলবেন না।",
        hour: _feedReminderTime.hour,
        minute: _feedReminderTime.minute,
      );
    } else {
      await NotificationService.cancelReminder(NotificationService.kFeedReminderId);
    }
  }

  Future<void> _pickWaterTime() async {
    final picked = await showTimePicker(context: context, initialTime: _waterReminderTime);
    if (picked == null) return;
    setState(() => _waterReminderTime = picked);
    await StorageService.setWaterReminder(_waterReminderOn, picked.hour, picked.minute);
    if (_waterReminderOn) {
      await NotificationService.scheduleDailyReminder(
        id: NotificationService.kWaterReminderId,
        title: "🌊 আজ পানি পরীক্ষা করেছেন?",
        body: "নিয়মিত পানির মান পরীক্ষা করলে পুকুরের স্বাস্থ্য ভালো থাকে। এখনই \"পানি\" পেজে গিয়ে রিডিং জমা দিন।",
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  Future<void> _pickFeedTime() async {
    final picked = await showTimePicker(context: context, initialTime: _feedReminderTime);
    if (picked == null) return;
    setState(() => _feedReminderTime = picked);
    await StorageService.setFeedReminder(_feedReminderOn, picked.hour, picked.minute);
    if (_feedReminderOn) {
      await NotificationService.scheduleDailyReminder(
        id: NotificationService.kFeedReminderId,
        title: "🐟 খাবার দেওয়ার সময় হয়েছে",
        body: "আপনার পুকুরের মাছকে আজকের নির্ধারিত খাবার দিতে ভুলবেন না।",
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? "AM" : "PM";
    return "$h:$m $period";
  }

  @override
  Widget build(BuildContext context) {
    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              AppTopBar(title: "নোটিফিকেশন", onBack: () => Navigator.pop(context)),
              if (_loading)
                const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("দৈনিক রিমাইন্ডার", style: AqText.heading(size: 14)),
                      const SizedBox(height: 4),
                      Text(
                        "এগুলো ফোনেই কাজ করে — ইন্টারনেট না থাকলেও নির্ধারিত সময়ে বার্তা আসবে।",
                        style: AqText.body(size: 11, color: AqColors.muted),
                      ),
                      const SizedBox(height: 10),
                      AppCard(
                        child: Column(
                          children: [
                            _switchRow("পানি পরীক্ষার রিমাইন্ডার", "প্রতিদিন নির্ধারিত সময়ে পানি পরীক্ষার কথা মনে করিয়ে দেবে", _waterReminderOn, _toggleWaterReminder),
                            if (_waterReminderOn) ...[
                              const SizedBox(height: 10),
                              _timeRow(_waterReminderTime, _pickWaterTime),
                            ],
                            const Divider(height: 28, color: Color(0xFFF0F5F4)),
                            _switchRow("খাবার দেওয়ার রিমাইন্ডার", "প্রতিদিন নির্ধারিত সময়ে খাবার দেওয়ার কথা মনে করিয়ে দেবে", _feedReminderOn, _toggleFeedReminder),
                            if (_feedReminderOn) ...[
                              const SizedBox(height: 10),
                              _timeRow(_feedReminderTime, _pickFeedTime),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text("অন্যান্য সতর্কতা", style: AqText.heading(size: 14)),
                      const SizedBox(height: 10),
                      AppCard(
                        child: Column(
                          children: [
                            _switchRow("পানির মান সতর্কতা", "পানির মান ঝুঁকিপূর্ণ হলে জানাবে", _waterAlerts, (v) {
                              setState(() => _waterAlerts = v);
                              _persist();
                            }),
                            const Divider(height: 24, color: Color(0xFFF0F5F4)),
                            _switchRow("মাছের স্বাস্থ্য সতর্কতা", "রোগের লক্ষণ পাওয়া গেলে জানাবে", _fishAlerts, (v) {
                              setState(() => _fishAlerts = v);
                              _persist();
                            }),
                            const Divider(height: 24, color: Color(0xFFF0F5F4)),
                            _switchRow("খাবার অর্ডার আপডেট", "অর্ডারের status বদলালে জানাবে", _marketAlerts, (v) {
                              setState(() => _marketAlerts = v);
                              _persist();
                            }),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Text(
                          "\"পানির মান সতর্কতা\" ও \"মাছের স্বাস্থ্য সতর্কতা\" — এই দুটোর জন্য লাইভ push notification পাঠাতে backend/push-service (যেমন Firebase Cloud Messaging) যোগ করতে হবে। উপরের দৈনিক রিমাইন্ডার দুটো এখনই সম্পূর্ণ কাজ করে (কোনো backend লাগে না)।",
                          textAlign: TextAlign.center,
                          style: AqText.body(size: 11, color: AqColors.mutedLight),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeRow(TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AqColors.teal700),
                const SizedBox(width: 8),
                Text("সময়:", style: AqText.body(size: 12, color: AqColors.muted)),
              ],
            ),
            Text(_fmtTime(time), style: AqText.body(size: 13, color: AqColors.teal700, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(String title, String sub, bool value, void Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AqText.body(size: 13, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(sub, style: AqText.body(size: 11, color: AqColors.muted)),
            ],
          ),
        ),
        Switch(value: value, activeColor: AqColors.teal700, onChanged: onChanged),
      ],
    );
  }
}

// ============================================================
// App settings — language / about (static, functional where possible)
// ============================================================
class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              AppTopBar(title: "অ্যাপ সেটিংস", onBack: () => Navigator.pop(context)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.language_rounded, size: 18, color: AqColors.teal700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ভাষা", style: AqText.body(size: 13, weight: FontWeight.w600)),
                                Text("বাংলা (Bengali)", style: AqText.body(size: 11, color: AqColors.muted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(999)),
                            child: Text("ডিফল্ট", style: AqText.body(size: 10, color: AqColors.teal700, weight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: AqColors.teal700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("অ্যাপ সংস্করণ", style: AqText.body(size: 13, weight: FontWeight.w600)),
                                Text("AquaGuard AI · v1.0.0", style: AqText.body(size: 11, color: AqColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.storage_rounded, size: 18, color: AqColors.teal700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ডেটা সংরক্ষণ", style: AqText.body(size: 13, weight: FontWeight.w600)),
                                Text("এই মুহূর্তে সব তথ্য ফোনেই (offline) সংরক্ষিত।", style: AqText.body(size: 11, color: AqColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "একাধিক ভাষা, ক্লাউড ব্যাকআপ এবং ডিভাইস-জুড়ে সিঙ্ক চালু করতে backend/অ্যাকাউন্ট সিস্টেম যোগ করতে হবে।",
                      textAlign: TextAlign.center,
                      style: AqText.body(size: 11, color: AqColors.mutedLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Help & Support — static info page
// ============================================================
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              AppTopBar(title: "সাহায্য ও সাপোর্ট", onBack: () => Navigator.pop(context)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("সচরাচর জিজ্ঞাসিত প্রশ্ন", style: AqText.heading(size: 14)),
                          const SizedBox(height: 10),
                          _faq("অ্যাপটি কি অফলাইনে কাজ করে?", "হ্যাঁ, বর্তমানে সব তথ্য ফোনেই সংরক্ষিত হয়, ইন্টারনেট ছাড়াও ব্যবহার করা যায়।"),
                          _faq("মাছ স্ক্যান কতটা নির্ভরযোগ্য?", "এটি একটি স্ক্রিনিং টুল, চূড়ান্ত রোগ নির্ণয় নয়। সন্দেহ হলে মৎস্য বিশেষজ্ঞের পরামর্শ নিন।"),
                          _faq("সাবস্ক্রিপশন ফি কীভাবে কাটে?", "সাইন আপ করলে সম্পূর্ণ ফিচার চালু হয়, প্রতিদিন ৳২ ফি প্রযোজ্য (পেমেন্ট গেটওয়ে যুক্ত হলে সক্রিয় হবে)।"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("যোগাযোগ করুন", style: AqText.heading(size: 14)),
                          const SizedBox(height: 10),
                          Text("কোনো সমস্যা বা পরামর্শ থাকলে আমাদের জানান।", style: AqText.body(size: 12, color: AqColors.muted)),
                          const SizedBox(height: 6),
                          Text("সাপোর্ট ইমেইল ও লাইভ চ্যাট চালু করতে backend/সাপোর্ট সিস্টেম যোগ করতে হবে — বর্তমানে এটি একটি প্লেসহোল্ডার।", style: AqText.body(size: 11, color: AqColors.mutedLight)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: AqText.body(size: 12, weight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(a, style: AqText.body(size: 12, color: AqColors.muted)),
        ],
      ),
    );
  }
}

// ============================================================
// AI Assistant (Chatbot) Screen
// ============================================================
class _ChatMessage {
  final String role; // "ai" | "user"
  final String text;
  final String? source; // "gemini" | "local" | null (user message হলে null)
  _ChatMessage({required this.role, required this.text, this.source});
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<String> _visibleQuestions = [];
  bool _typing = false;
  bool _typingLong = false;

  // ---- ভয়েস (speech-to-text ইনপুট + text-to-speech আউটপুট) ----
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _listening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initVoice();
    final app = context.read<AppState>();
    final latestDO = app.waterHistory.isNotEmpty ? app.waterHistory.last.doLevel.toStringAsFixed(1) : "—";
    final latestPH = app.waterHistory.isNotEmpty ? app.waterHistory.last.ph.toStringAsFixed(1) : "—";
    _messages.add(_ChatMessage(
      role: "ai",
      text: "আসসালামু আলাইকুম! আমি আপনার পুকুরের তথ্য জানি — আজকের DO $latestDO mg/L এবং pH $latestPH। কী জানতে চান?",
    ));
    _visibleQuestions = pickRandomQuestions(6);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  // ---- ভয়েস সেটআপ ----
  Future<void> _initVoice() async {
    _speechAvailable = await _speech.initialize(
      onError: (_) => setState(() => _listening = false),
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          setState(() => _listening = false);
        }
      },
    );
    await _tts.setLanguage("bn-BD");
    await _tts.setSpeechRate(0.42); // কৃষকদের বুঝতে সুবিধার জন্য স্বাভাবিকের চেয়ে একটু ধীরে
    await _tts.setPitch(1.0);
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ভয়েস ইনপুট চালু করা যাচ্ছে না — মাইক্রোফোন পারমিশন দিয়েছেন কিনা চেক করুন।")),
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      localeId: "bn_BD",
      onResult: (result) {
        setState(() => _inputCtrl.text = result.recognizedWords);
        if (result.finalResult) {
          final text = result.recognizedWords;
          setState(() => _listening = false);
          if (text.trim().isNotEmpty) _send(text);
        }
      },
    );
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<bool> _checkInternet() async {
    try {
      final lookup = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _send(String text) async {
    if (text.trim().isEmpty) return;
    final app = context.read<AppState>();
    setState(() {
      _messages.add(_ChatMessage(role: "user", text: text));
      _inputCtrl.clear();
      _visibleQuestions = pickRandomQuestions(6, exclude: [text]);
      _typing = true;
      _typingLong = false;
    });
    _scrollToEnd();

    // Render ফ্রি প্ল্যানে backend "ঘুম" থেকে জাগতে ৩০-৫০ সেকেন্ড লাগতে পারে —
    // ৫ সেকেন্ড পরও উত্তর না এলে "AI জাগছে..." দেখিয়ে বোঝানো হয় এটা এখনো কাজ করছে,
    // শুধু আটকে যায়নি।
    final wakeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _typing) setState(() => _typingLong = true);
    });

    final latest = app.waterHistory.isNotEmpty ? app.waterHistory.last : null;
    final pond = app.pondSetup;
    final scan = app.lastFishScan;

    String reply;
    String source;
    try {
      // প্রথমে real Gemini AI backend (aquaguard_backend) কল করার চেষ্টা
      reply = await ApiService.getAssistantResponse(text, {
        "species": pond.species,
        "sizeDecimal": pond.sizeDecimal,
        "quantity": pond.quantity,
        "ph": latest?.ph,
        "do": latest?.doLevel,
        "temp": latest?.temp,
        "waterRisk": app.latestWaterRisk,
        "lastFishScan": scan == null
            ? null
            : (scan.uncertain ? "অনিশ্চিত" : (scan.healthy == true ? "সুস্থ" : "${scan.name ?? 'রোগ শনাক্ত'} (${scan.level ?? ''})")),
      });
      source = "gemini";
    } catch (_) {
      // backend অফলাইন/এরর হলে local rule-based উত্তরে fallback
      reply = ChatEngine.reply(
        question: text,
        pondSetup: app.pondSetup,
        waterRisk: app.latestWaterRisk,
        latestReading: latest,
        lastFishScan: app.lastFishScan,
        growth: app.growth,
      );
      source = "local";

      // ইন্টারনেট আদৌ সংযুক্ত আছে কিনা যাচাই করে কৃষককে স্পষ্ট বার্তা দেওয়া —
      // যাতে "backend সমস্যা" আর "ইন্টারনেট নেই" — এই দুই আলাদা কারণ
      // গুলিয়ে না যায়।
      final hasInternet = await _checkInternet();
      if (mounted && !hasInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "ইন্টারনেট সংযোগ নেই — অনুগ্রহ করে Wi-Fi বা মোবাইল ডেটা চালু করুন। এখন সীমিত (স্থানীয়) উত্তর দেখানো হচ্ছে।",
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFFD5473A),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }

    wakeTimer.cancel();
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(role: "ai", text: reply, source: source));
      _typing = false;
      _typingLong = false;
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(title: "AI সহকারী", onBack: () => app.goTo("dashboard"), right: const ConnectivityBadge()),
              Expanded(
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    ..._messages.map((m) => _bubble(m)),
                    if (_typing) _typingBubble(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("দ্রুত প্রশ্ন", style: AqText.body(size: 11, color: AqColors.muted, weight: FontWeight.w700)),
                        InkWell(
                          onTap: () => setState(() => _visibleQuestions = pickRandomQuestions(6)),
                          child: Row(
                            children: [
                              const Icon(Icons.shuffle_rounded, size: 12, color: AqColors.teal700),
                              const SizedBox(width: 4),
                              Text("নতুন প্রশ্ন", style: AqText.body(size: 11, color: AqColors.teal700, weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _visibleQuestions.map((q) {
                        return InkWell(
                          onTap: () => _send(q),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Color(0x1F0B4F4A), blurRadius: 14, offset: Offset(0, 6))],
                            ),
                            child: Text(q, style: AqText.body(size: 11, color: AqColors.teal700, weight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // ---- input row ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _toggleListening,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _listening ? const Color(0xFFD5473A).withOpacity(0.12) : AqColors.track,
                          borderRadius: BorderRadius.circular(16),
                          border: _listening ? Border.all(color: const Color(0xFFD5473A), width: 1.5) : null,
                        ),
                        child: Icon(
                          _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          size: 18,
                          color: _listening ? const Color(0xFFD5473A) : AqColors.teal700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Color(0x1F0B4F4A), blurRadius: 14, offset: Offset(0, 6))],
                        ),
                        child: TextField(
                          controller: _inputCtrl,
                          onSubmitted: _send,
                          style: AqText.body(size: 13),
                          decoration: InputDecoration(
                            hintText: "প্রশ্ন লিখুন বা মাইক চাপুন…",
                            hintStyle: AqText.body(size: 13, color: AqColors.mutedLight),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _send(_inputCtrl.text),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AqColors.teal700, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(_ChatMessage m) {
    final isUser = m.role == "user";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            InkWell(
              onTap: () => _speak(m.text),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 6, top: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AqColors.track, shape: BoxShape.circle),
                child: const Icon(Icons.volume_up_rounded, size: 13, color: AqColors.teal700),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? AqColors.teal700 : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 20),
                    ),
                    boxShadow: isUser ? null : const [BoxShadow(color: Color(0x1F0B4F4A), blurRadius: 14, offset: Offset(0, 6))],
                  ),
                  child: isUser
                      ? Text(m.text, style: AqText.body(size: 13, color: Colors.white))
                      : _formattedMessage(m.text),
                ),
                // ---- উত্তর কোথা থেকে এসেছে তা যাচাই করার জন্য — Gemini AI (backend) নাকি
                // local rule-based fallback। এভাবে সহজেই বোঝা যায় backend আসলেই কাজ করছে কিনা।
                if (!isUser && m.source != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m.source == "gemini" ? Icons.auto_awesome_rounded : Icons.offline_bolt_rounded,
                          size: 11,
                          color: m.source == "gemini" ? const Color(0xFF1E9E6B) : AqColors.muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          m.source == "gemini" ? "Gemini AI (backend)" : "Local উত্তর (backend সংযোগ পাওয়া যায়নি)",
                          style: AqText.body(size: 10, color: m.source == "gemini" ? const Color(0xFF1E9E6B) : AqColors.muted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- AI-এর উত্তর আরও স্পষ্ট ও পড়ার-সুবিধাজনক করার জন্য ----
  // Gemini-এর উত্তরে প্রায়ই তালিকা/ধাপ থাকে (যেমন "১. ...", "- ...")।
  // সাধারণ প্যারাগ্রাফ হিসেবে দেখালে কৃষকের জন্য পড়া কঠিন হয় —
  // তাই প্রতিটা লাইন আলাদা করে দেখে, তালিকার লাইনগুলোকে bullet/number
  // সহ আলাদা সারি হিসেবে দেখানো হয়, যাতে প্রতিটা পয়েন্ট চোখে পড়ে।
  Widget _formattedMessage(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length <= 1) {
      return Text(text, style: AqText.body(size: 13, color: AqColors.deep, weight: FontWeight.w500));
    }

    final bulletPattern = RegExp(r'^\s*([•\-\*]|\d+[.\)])\s+(.*)$');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = bulletPattern.firstMatch(line);
      if (match != null) {
        final marker = match.group(1)!;
        final content = match.group(2)!;
        final isNumbered = RegExp(r'^\d+[.\)]$').hasMatch(marker);
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNumbered)
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AqColors.teal700.withOpacity(0.12), shape: BoxShape.circle),
                    child: Text(
                      marker.replaceAll(RegExp(r'[.\)]'), ''),
                      style: AqText.body(size: 10, color: AqColors.teal700, weight: FontWeight.w800),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 2),
                    child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: AqColors.teal700, shape: BoxShape.circle)),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(content, style: AqText.body(size: 13, color: AqColors.deep, weight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
            child: Text(line, style: AqText.body(size: 13, color: AqColors.deep, weight: FontWeight.w500)),
          ),
        );
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x1F0B4F4A), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: Text(
                _typingLong ? "AI সংযোগ স্থাপন করা হচ্ছে — অনুগ্রহ করে অপেক্ষা করুন (আনুমানিক ২৫–৪০ সেকেন্ড)" : "লিখছে…",
                style: AqText.body(size: 12, color: AqColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Market Screen — মাছের খাবার বাজার (মাছবাজার)
// আগে এখানে "বাজার দর" (fish price) দেখানো হতো, এখন এর বদলে
// FishFoodMarketService দিয়ে মাছের খাবার অর্ডার করার ফিচার আছে।
// ============================================================

// প্রতিটা খাবারের ধরন অনুযায়ী উপযুক্ত আইকন ও রঙ — emoji-এর বদলে
// পুরো অ্যাপের ডিজাইনের সাথে মিলিয়ে পেশাদার দেখানোর জন্য।
// শুধু ৪টা সংগত, পেশাদার ক্যাটাগরি — কোনো literal/cartoon-type আইকন
// (শিশু, পতাকা, তারা, বুদবুদ) ব্যবহার করা হয়নি, যাতে একটা সুসংগত
// visual language বজায় থাকে।
({IconData icon, Color color}) _foodVisual(FishFoodProduct p) {
  final n = p.name;
  // ১. স্বাস্থ্য সাপ্লিমেন্ট (ভিটামিন/প্রোবায়োটিক) — মেডিকেল আইকন, বেগুনি
  if (n.contains("ভিটামিন") || n.contains("প্রিমিক্স") || n.contains("প্রোবায়োটিক")) {
    return (icon: Icons.medical_services_rounded, color: const Color(0xFF7C6FE0));
  }
  // ২. উচ্চ-প্রোটিন/মাংসাশী ফিড (মাছ/চিংড়ি) — সেট-মিল আইকন, লাল-কমলা
  if (n.contains("চিংড়ি") || n.contains("বাগদা") || p.proteinPercent >= 34) {
    return (icon: Icons.set_meal_rounded, color: const Color(0xFFD5473A));
  }
  // ৩. প্রাকৃতিক/জৈব সাপ্লিমেন্ট (ঘাস/প্ল্যাংকটন) — পাতা আইকন, সবুজ
  if (n.contains("ঘাস") || n.contains("প্ল্যাংকটন") || n.contains("কার্প কম্বো")) {
    return (icon: Icons.eco_rounded, color: const Color(0xFF1E9E6B));
  }
  // ৪. সাধারণ দানাদার/পিলেট ফিড (স্টার্টার/গ্রোয়ার/ফিনিশার/নার্সারি/সিংকিং) — গ্রেইন আইকন, অ্যাম্বার
  return (icon: Icons.grain_rounded, color: const Color(0xFFB08A2E));
}

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String? _speciesFilter;
  bool _loading = true;
  List<FishFoodProduct> _products = [];
  List<FoodOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _speciesFilter = context.read<AppState>().pondSetup.species;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await FishFoodMarketService.fetchProducts(species: _speciesFilter);
    final orders = await FishFoodMarketService.loadOrders();
    if (!mounted) return;
    setState(() {
      _products = products;
      _orders = orders;
      _loading = false;
    });
  }

  Widget _qtyBtn(String s, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(10)),
      child: Text(s, style: AqText.heading(size: 16)),
    ),
  );

  void _openOrderSheet(FishFoodProduct p) {
    double qty = 5;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final total = (p.pricePerKg * qty).round();
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Builder(builder: (context) {
                      final v = _foodVisual(p);
                      return Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: v.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: v.color.withOpacity(0.18), width: 1),
                          boxShadow: [BoxShadow(color: v.color.withOpacity(0.16), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Icon(v.icon, size: 22, color: v.color),
                      );
                    }),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.name, style: AqText.heading(size: 15))),
                  ],
                ),
                const SizedBox(height: 4),
                Text("${p.brand} · ৳${p.pricePerKg}/কেজি · ${p.vendor}", style: AqText.body(size: 12, color: AqColors.muted)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      p.verified ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 12,
                      color: p.verified ? const Color(0xFF1E9E6B) : const Color(0xFFB08A2E),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        p.priceSource,
                        style: AqText.body(size: 10, color: p.verified ? const Color(0xFF1E9E6B) : const Color(0xFFB08A2E)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("পরিমাণ (কেজি)", style: AqText.body(size: 13)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _qtyBtn("−", () => setSheetState(() => qty = (qty - 1).clamp(1, 999))),
                        SizedBox(width: 46, child: Text(qty.toStringAsFixed(0), textAlign: TextAlign.center, style: AqText.body(size: 14, weight: FontWeight.w700))),
                        _qtyBtn("+", () => setSheetState(() => qty += 1)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("মোট মূল্য", style: AqText.body(size: 13, weight: FontWeight.w600)),
                      Text("৳$total", style: AqText.heading(size: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AqColors.teal700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await FishFoodMarketService.placeOrder(p, qty);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("অর্ডার সফল হয়েছে — ${p.name} (${qty.toStringAsFixed(0)} কেজি)")),
                      );
                      _load();
                    },
                    child: Text("অর্ডার নিশ্চিত করুন", style: AqText.body(size: 14, color: Colors.white, weight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showOrders() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("আমার অর্ডার", style: AqText.heading(size: 16)),
                const SizedBox(height: 12),
                if (_orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("এখনো কোনো অর্ডার নেই।", style: AqText.body(size: 13, color: AqColors.muted)),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final o = _orders[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(o.productName, style: AqText.body(size: 12, weight: FontWeight.w700), overflow: TextOverflow.ellipsis, maxLines: 1),
                                    Text("${o.quantityKg.toStringAsFixed(0)} কেজি · ৳${o.totalPrice}", style: AqText.body(size: 11, color: AqColors.muted)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                                child: Text(o.status, style: AqText.body(size: 10, color: AqColors.teal700, weight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AqColors.teal700 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AqColors.teal700 : AqColors.border),
        ),
        child: Text(label, style: AqText.body(size: 12, color: selected ? Colors.white : AqColors.deep, weight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return AqPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AqColors.teal700,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                AppTopBar(
                  title: "মাছবাজার — মাছের খাবার বাজার",
                  onBack: () => app.goTo("dashboard"),
                  right: InkWell(
                    onTap: _showOrders,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.55), shape: BoxShape.circle),
                      child: const Icon(Icons.receipt_long_rounded, size: 18, color: AqColors.teal900),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AqColors.teal900, Color(0xFF178077)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "আপনার মাছের প্রজাতি অনুযায়ী উপযুক্ত খাবার খুঁজে সরাসরি অর্ডার করুন।",
                              style: AqText.body(size: 11, color: AqColors.mist),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "✓ যাচাইকৃত = প্রকাশিত ডিলার মূল্য-তালিকা থেকে নেওয়া। ≈ আনুমানিক = বাজারের সাধারণ রেঞ্জ থেকে অনুমান করা — চূড়ান্ত দাম স্থানীয় ডিলারের কাছে যাচাই করে নিন।",
                                    style: AqText.body(size: 10, color: AqColors.mist),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("প্রজাতি অনুযায়ী ফিল্টার করুন", style: AqText.heading(size: 14)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _filterChip("সব", _speciesFilter == null, () {
                              setState(() => _speciesFilter = null);
                              _load();
                            }),
                            const SizedBox(width: 8),
                            ...speciesList.map((s) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _filterChip(s, _speciesFilter == s, () {
                                setState(() => _speciesFilter = s);
                                _load();
                              }),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator(color: AqColors.teal700)),
                        )
                      else if (_products.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Text("কোনো খাবার পাওয়া যায়নি।", style: AqText.body(size: 13, color: AqColors.muted)),
                        )
                      else
                        ..._products.map((p) {
                          final v = _foodVisual(p);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              onTap: () => _openOrderSheet(p),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: v.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: v.color.withOpacity(0.18), width: 1),
                                      boxShadow: [BoxShadow(color: v.color.withOpacity(0.16), blurRadius: 10, offset: const Offset(0, 4))],
                                    ),
                                    child: Icon(v.icon, size: 22, color: v.color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: AqText.body(size: 13, weight: FontWeight.w700), overflow: TextOverflow.ellipsis, maxLines: 1),
                                        const SizedBox(height: 2),
                                        Text(
                                          p.proteinPercent > 0 ? "${p.brand} · প্রোটিন ${p.proteinPercent}%" : p.brand,
                                          style: AqText.body(size: 11, color: AqColors.muted),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.description,
                                          style: AqText.body(size: 11, color: AqColors.deep),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: p.bestForSpecies.take(3).map((s) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(999)),
                                            child: Text(s, style: AqText.body(size: 9, color: AqColors.teal700, weight: FontWeight.w600)),
                                          )).toList(),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF5A623)),
                                            const SizedBox(width: 2),
                                            Text("${p.rating}", style: AqText.body(size: 11, color: AqColors.muted)),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.local_shipping_outlined, size: 12, color: AqColors.muted),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(p.deliveryEstimate, style: AqText.body(size: 11, color: AqColors.muted), overflow: TextOverflow.ellipsis, maxLines: 1),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(color: AqColors.teal700.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text("৳${p.pricePerKg}", style: AqText.heading(size: 15, color: AqColors.teal700)),
                                            Text("/কেজি", style: AqText.body(size: 10, color: AqColors.muted)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            p.verified ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                            size: 10,
                                            color: p.verified ? const Color(0xFF1E9E6B) : const Color(0xFFB08A2E),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            p.verified ? "যাচাইকৃত" : "আনুমানিক",
                                            style: AqText.body(size: 9, color: p.verified ? const Color(0xFF1E9E6B) : const Color(0xFFB08A2E), weight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ],
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
        ),
        bottomNavigationBar: AppBottomNav(current: "market", onSelect: app.goTo),
      ),
    );
  }
}