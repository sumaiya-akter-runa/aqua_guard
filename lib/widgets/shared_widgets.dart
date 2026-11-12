import 'package:flutter/material.dart';
import '../theme/aq_theme.dart';

// ============================================================
// রঙের হেল্পার (backward-compatible — পুরনো screen কোড এগুলো ব্যবহার করতে পারে)
// ============================================================
Color riskColor(String level) => riskInfo(level).color;
Color riskBgColor(String level) => riskInfo(level).bg;
String riskEmoji(String level) => riskInfo(level).emoji;

// ============================================================
// TopBar — JSX TopBar({title, onBack, right}) এর সমতুল্য
// ============================================================
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? right;

  const AppTopBar({super.key, required this.title, this.onBack, this.right});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          if (onBack != null) ...[
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 18, color: AqColors.teal900),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title, style: AqText.heading(size: 20)),
          ),
          if (right != null) right!,
        ],
      ),
    );
  }
}

// ============================================================
// RiskPill — JSX RiskPill({level}) এর সমতুল্য
// ============================================================
class RiskPill extends StatelessWidget {
  final String level;
  const RiskPill({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final r = riskInfo(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: r.bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: r.solid, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              "${r.emoji} ${r.label} · ${r.en}",
              style: AqText.body(size: 12, color: r.color, weight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AppCard — JSX Card({children, onClick}) এর সমতুল্য
// ============================================================
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x260B4F4A), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ============================================================
// RippleGauge — JSX RippleGauge({score}) এর সরলীকৃত Flutter সংস্করণ
// (একটা ভরাট বৃত্ত water-level অনুযায়ী রঙ পাল্টায়, animate করে ভরাট হয়)
// ============================================================
class RippleGauge extends StatelessWidget {
  final int score;
  const RippleGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = score.clamp(0, 100);
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return CustomPaint(
                size: const Size(160, 160),
                painter: _GaugePainter(value),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$pct", style: AqText.heading(size: 30, color: pct > 45 ? Colors.white : AqColors.deep)),
              Text("/ ১০০", style: AqText.body(size: 11, color: pct > 45 ? Colors.white : AqColors.deep, weight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..1
  _GaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()..color = AqColors.track;
    canvas.drawCircle(center, radius, bgPaint);

    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    final fillHeight = size.height * (1 - value);
    final fillRect = Rect.fromLTWH(0, fillHeight, size.width, size.height);
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AqColors.teal200, AqColors.teal900],
    );
    final fillPaint = Paint()..shader = gradient.createShader(fillRect);
    canvas.drawRect(fillRect, fillPaint);
    canvas.restore();

    final borderPaint = Paint()
      ..color = AqColors.teal900.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.value != value;
}

// ============================================================
// BottomNav — JSX bottom nav bar এর সমতুল্য
// ============================================================
class NavItem {
  final String id;
  final IconData icon;
  final String label;
  const NavItem({required this.id, required this.icon, required this.label});
}

const List<NavItem> navItems = [
  NavItem(id: "dashboard", icon: Icons.home_rounded, label: "হোম"),
  NavItem(id: "water", icon: Icons.water_drop_rounded, label: "পানি"),
  NavItem(id: "fish", icon: Icons.camera_alt_rounded, label: "স্ক্যান"),
  NavItem(id: "feed", icon: Icons.eco_rounded, label: "খাবার"),
  NavItem(id: "assistant", icon: Icons.chat_bubble_rounded, label: "সহকারী"),
];

class AppBottomNav extends StatelessWidget {
  final String current;
  final void Function(String) onSelect;

  const AppBottomNav({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: const [BoxShadow(color: Color(0x330B4F4A), blurRadius: 24, offset: Offset(0, -8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: navItems.map((n) {
            final active = current == n.id;
            final color = active ? AqColors.teal700 : AqColors.mutedLight;
            return InkWell(
              onTap: () => onSelect(n.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(n.icon, size: 20, color: color),
                    const SizedBox(height: 3),
                    Text(n.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================
// Section heading helper
// ============================================================
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: AqText.heading(size: 16)),
    );
  }
}

// ============================================================
// "শীঘ্রই আসছে" ব্যাজ — backend-নির্ভর ফিচারের জন্য
// ============================================================
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AqColors.track,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AqColors.border),
      ),
      child: Text(
        "শীঘ্রই আসছে",
        style: AqText.body(size: 10, color: AqColors.teal700, weight: FontWeight.w700),
      ),
    );
  }
}

// ============================================================
// Page background wrapper — JSX-এর mint gradient background
// ============================================================
class AqPageBackground extends StatelessWidget {
  final Widget child;
  const AqPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AqColors.pageGradient),
      child: child,
    );
  }
}
