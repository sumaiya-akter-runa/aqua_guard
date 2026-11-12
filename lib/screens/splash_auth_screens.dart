import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/aq_theme.dart';
import '../services/subscription_service.dart';

// ============================================================
// Splash Screen — JSX Splash({onDone}) এর সমতুল্য
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _init();
  }

  Future<void> _init() async {
    final appState = context.read<AppState>();
    await appState.init();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AqColors.splashGradient),
        child: Stack(
          children: [
            // decorative blur blobs (JSX .aq-blob1/2/3)
            Positioned(
              top: -60,
              left: -70,
              child: _blob(260, const Color(0x24F5B942)),
            ),
            Positioned(
              bottom: -50,
              right: -60,
              child: _blob(220, const Color(0x292DD4BF)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -6 * _floatCtrl.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 50, offset: Offset(0, 20))],
                      ),
                      child: const Icon(Icons.waves_rounded, color: AqColors.gold, size: 44),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("AquaGuard AI", style: AqText.heading(size: 28, color: Colors.white)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "বাংলাদেশের মৎস্যচাষিদের জন্য স্মার্ট পুকুর সহায়ক",
                      textAlign: TextAlign.center,
                      style: AqText.body(size: 13, color: AqColors.mist),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _LoadingDots(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = (_ctrl.value + (i * 0.2)) % 1.0;
            final scale = 0.8 + (0.4 * (1 - (t - 0.5).abs() * 2)).clamp(0.0, 0.4);
            final opacity = 0.3 + (0.7 * (1 - (t - 0.5).abs() * 2)).clamp(0.0, 0.7);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AqColors.gold, shape: BoxShape.circle)),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ============================================================
// Onboarding Screen — শুধু প্রথমবার (Splash-এর পরে, সাইন আপের আগে)
// দেখানো হয়। সাবস্ক্রাইব করলে ঠিক কী কী সুবিধা পাবে সেটা এখানে
// বুঝিয়ে দেওয়া হয়। "শুরু করুন" চাপলে AuthScreen (সাইন আপ) এ যাবে,
// আর দ্বিতীয়বার অ্যাপ খুললে এই স্ক্রিন আর দেখাবে না
// (AppState.completeOnboarding() flag সেভ করে রাখে)।
// ============================================================
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const List<Map<String, dynamic>> _benefits = [
    {"icon": Icons.water_drop_outlined, "title": "দৈনিক পানির মান পরীক্ষা", "desc": "৯টি প্যারামিটার পরীক্ষা করে সহজ ভাষায় করণীয় বলে দেয়"},
    {"icon": Icons.set_meal_outlined, "title": "মাছ স্ক্যান", "desc": "মাছের ছবি তুলে সম্ভাব্য রোগ ও করণীয় জানুন"},
    {"icon": Icons.restaurant_outlined, "title": "খাবার সুপারিশ ও বৃদ্ধি ট্র্যাকিং", "desc": "প্রতিদিন সঠিক খাবারের পরিমাণ ও সাপ্তাহিক বৃদ্ধির গ্রাফ"},
    {"icon": Icons.speed_outlined, "title": "পুকুরের স্বাস্থ্য স্কোর", "desc": "সবকিছু মিলিয়ে এক নজরে পুকুরের সার্বিক অবস্থা"},
    {"icon": Icons.smart_toy_outlined, "title": "AI সহকারী", "desc": "আপনার পুকুরের তথ্য দিয়েই প্রশ্নের উত্তর দেয়"},
    {"icon": Icons.storefront_outlined, "title": "বাজার দর", "desc": "মাছের সাম্প্রতিক বাজার দর ও পরামর্শ"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AqColors.authGradient),
        child: Stack(
          children: [
            Positioned(top: -60, left: -70, child: _OnboardBlob(260, const Color(0x24F5B942))),
            Positioned(bottom: -50, right: -60, child: _OnboardBlob(220, const Color(0x292DD4BF))),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Icon(Icons.waves_rounded, color: AqColors.gold, size: 34),
                  const SizedBox(height: 8),
                  Text("সাবস্ক্রাইব করলে যা যা পাবেন", style: AqText.heading(size: 19, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    "AquaGuard AI-এর পূর্ণ সুবিধা",
                    style: AqText.body(size: 12, color: AqColors.mist),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.97),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 50, offset: Offset(0, 20))],
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: _benefits.length,
                        separatorBuilder: (_, __) => const Divider(height: 22, color: AqColors.border),
                        itemBuilder: (context, i) {
                          final b = _benefits[i];
                          final IconData icon = b["icon"] as IconData;
                          final String title = b["title"] as String;
                          final String desc = b["desc"] as String;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(12)),
                                child: Icon(icon, size: 18, color: AqColors.teal700),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: AqText.body(size: 13.5, color: AqColors.deep, weight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(desc, style: AqText.body(size: 11.5, color: AqColors.muted)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        "সাইন আপ করার পর মোবাইলে OTP আসবে — ভেরিফাই করলেই সাবস্ক্রিপশন শুরু হয়ে যাবে (Robi ৳2.78/দিন, Cirkle ৳5/দিন, VAT সহ, যেকোনো সময় বন্ধ করা যাবে)।",
                        textAlign: TextAlign.center,
                        style: AqText.body(size: 11, color: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AqColors.gold,
                          foregroundColor: AqColors.deep,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () => context.read<AppState>().completeOnboarding(),
                        child: Text("শুরু করুন", style: AqText.body(size: 15, color: AqColors.deep, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _OnboardBlob(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ============================================================
// Auth Screen — JSX AuthScreen({onAuth}) এর সমতুল্য
// (Local-only এখন — নাম ও ফোন নম্বর সেভ হয় ফোনেই; পরে backend বসালে
//  submit()-এর জায়গায় API কল যোগ করা যাবে)
// ============================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String _mode = "signup"; // "signup" | "login"
  String _step = "form"; // "form" | "otp"
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _error = "";
  bool _loading = false;
  String? _referenceNo;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ধাপ ১: নাম/নম্বর সাবমিট করলে bdApps-কে OTP পাঠাতে বলা হয়।
  Future<void> _sendOtp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (_mode == "signup" && name.isEmpty) {
      setState(() => _error = "দয়া করে আপনার নাম লিখুন।");
      return;
    }
    if (phone.isEmpty || phone.length < 11) {
      setState(() => _error = "সঠিক মোবাইল নম্বর দিন (কমপক্ষে ১১ ডিজিট)।");
      return;
    }

    setState(() {
      _error = "";
      _loading = true;
    });

    final result = await SubscriptionService.sendOtp(phone);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.alreadySubscribed) {
      // এই নম্বর আগে থেকেই সাবস্ক্রাইবড — সরাসরি লগইন করিয়ে দাও, OTP লাগবে না।
      final displayName = _mode == "signup" ? name : (name.isNotEmpty ? name : "কৃষক");
      context.read<AppState>().login(displayName, phone);
      return;
    }

    if (!result.success || result.referenceNo == null) {
      setState(() => _error = result.message.isNotEmpty
          ? result.message
          : "OTP পাঠানো যায়নি, একটু পরে আবার চেষ্টা করো।");
      return;
    }

    setState(() {
      _referenceNo = result.referenceNo;
      _step = "otp";
    });
  }

  // ধাপ ২: OTP ভেরিফাই — সফল হলেই সাবস্ক্রিপশন অ্যাক্টিভ হয়ে লগইন হবে।
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _error = "OTP লিখুন।");
      return;
    }
    if (_referenceNo == null) {
      setState(() => _error = "প্রথমে আবার OTP পাঠাও।");
      return;
    }

    setState(() {
      _error = "";
      _loading = true;
    });

    final result = await SubscriptionService.verifyOtp(otp, _referenceNo!);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      setState(() => _error = result.message.isNotEmpty
          ? result.message
          : "OTP মেলেনি, আবার চেষ্টা করো।");
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final displayName = _mode == "signup" ? name : (name.isNotEmpty ? name : "কৃষক");
    if (!mounted) return;
    context.read<AppState>().login(displayName, phone);
  }

  void _backToForm() {
    setState(() {
      _step = "form";
      _error = "";
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AqColors.authGradient),
        child: Stack(
          children: [
            Positioned(top: -60, left: -70, child: _blob(260, const Color(0x24F5B942))),
            Positioned(bottom: -50, right: -60, child: _blob(220, const Color(0x292DD4BF))),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.waves_rounded, color: AqColors.gold, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("AquaGuard AI", style: AqText.heading(size: 20, color: Colors.white)),
                                Text(
                                  _step == "otp" ? "OTP দিয়ে ভেরিফাই করুন" : "শুরু করতে সাইন আপ করুন",
                                  style: AqText.body(size: 11, color: AqColors.mist),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.97),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 50, offset: Offset(0, 20))],
                        ),
                        child: _step == "otp" ? _buildOtpStep() : _buildFormStep(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // segmented control
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AqColors.track, borderRadius: BorderRadius.circular(999)),
          child: Row(
            children: [
              Expanded(child: _segButton("সাইন আপ", "signup")),
              Expanded(child: _segButton("লগইন", "login")),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_mode == "signup") ...[
          Text("আপনার নাম", style: AqText.body(size: 12, color: AqColors.muted)),
          const SizedBox(height: 4),
          _field(_nameController, "যেমন: মোঃ রহিম উদ্দিন"),
          const SizedBox(height: 12),
        ],
        Text("মোবাইল নম্বর", style: AqText.body(size: 12, color: AqColors.muted)),
        const SizedBox(height: 4),
        _field(_phoneController, "01XXXXXXXXX", keyboardType: TextInputType.phone),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_error, style: AqText.body(size: 12, color: const Color(0xFFD5473A))),
        ],
        if (_mode == "signup") ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFFFF6D9), borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.emoji_events_outlined, size: 15, color: Color(0xFF9A6F06)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "সাইন আপ করলে AquaGuard AI-এর সম্পূর্ণ ফিচার (পানি বিশ্লেষণ, ফিশ স্ক্যান, AI সহকারী ইত্যাদি) সক্রিয় হবে — এর জন্য প্রতিদিন সাবস্ক্রিপশন ফি প্রযোজ্য। মোবাইলে একটা OTP আসবে, সেটা দিয়ে ভেরিফাই করলেই সাবস্ক্রিপশন শুরু হবে।",
                    style: AqText.body(size: 11, color: const Color(0xFF7A5E0B)),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AqColors.teal700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _loading ? null : _sendOtp,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(
                    _mode == "signup" ? "OTP পাঠান" : "লগইন করুন",
                    style: AqText.body(size: 15, color: Colors.white, weight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "শুধুমাত্র Robi ও Cirkle গ্রাহকদের জন্য সাবস্ক্রিপশন সুবিধা প্রযোজ্য।",
          textAlign: TextAlign.center,
          style: AqText.body(size: 10, color: AqColors.mutedLight),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "${_phoneController.text.trim()} নম্বরে পাঠানো ৬-সংখ্যার কোডটি লিখুন।",
          style: AqText.body(size: 13, color: AqColors.muted),
        ),
        const SizedBox(height: 12),
        _field(_otpController, "৬-সংখ্যার OTP", keyboardType: TextInputType.number),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_error, style: AqText.body(size: 12, color: const Color(0xFFD5473A))),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AqColors.teal700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _loading ? null : _verifyOtp,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(
                    "ভেরিফাই করুন",
                    style: AqText.body(size: 15, color: Colors.white, weight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _loading ? null : _backToForm,
          child: Text("নম্বর পাল্টাতে চাও? ফিরে যাও", style: AqText.body(size: 12, color: AqColors.muted)),
        ),
      ],
    );
  }

  Widget _segButton(String label, String mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AqColors.teal700 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AqText.body(size: 13, color: active ? Colors.white : AqColors.muted, weight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AqText.body(size: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AqText.body(size: 14, color: AqColors.mutedLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AqColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AqColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AqColors.teal700)),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}
