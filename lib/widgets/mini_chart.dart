import 'package:flutter/material.dart';

// ============================================================
// MiniLineChart — নির্ভরতা-মুক্ত (কোনো নতুন প্যাকেজ লাগে না) লাইন চার্ট।
// পানির প্রবণতা আর বৃদ্ধির গ্রাফ দেখানোর জন্য ব্যবহার হয়।
// ============================================================
class ChartSeries {
  final String label;
  final List<double> values;
  final Color color;
  ChartSeries({required this.label, required this.values, required this.color});
}

class MiniLineChart extends StatelessWidget {
  final List<String> xLabels;
  final List<ChartSeries> series;
  final double height;
  final String? unit;
  /// ঐচ্ছিক — "ভালো" পরিসীমা (যেমন pH-এর জন্য ৭.০–৮.৫) দেখানোর জন্য।
  /// দেওয়া হলে চার্টে হালকা সবুজ ব্যান্ড হিসেবে আঁকা হবে, যাতে কৃষক
  /// এক নজরে বুঝতে পারেন রিডিং নিরাপদ পরিসীমায় আছে কিনা।
  final double? safeMin;
  final double? safeMax;

  const MiniLineChart({
    super.key,
    required this.xLabels,
    required this.series,
    this.height = 160,
    this.unit,
    this.safeMin,
    this.safeMax,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = series.any((s) => s.values.isNotEmpty);
    if (!hasData) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            "এখনো পর্যাপ্ত ডেটা নেই",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (series.isNotEmpty)
              Expanded(
                child: Wrap(
                  spacing: 14,
                  children: series
                      .map((s) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(s.label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    ],
                  ))
                      .toList(),
                ),
              ),
            if (safeMin != null && safeMax != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: const Color(0xFFD8F0DE)),
                  const SizedBox(width: 5),
                  Text("নিরাপদ পরিসীমা", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              series: series,
              xLabels: xLabels,
              safeMin: safeMin,
              safeMax: safeMax,
              unit: unit,
            ),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ChartSeries> series;
  final List<String> xLabels;
  final double? safeMin;
  final double? safeMax;
  final String? unit;

  _LineChartPainter({
    required this.series,
    required this.xLabels,
    this.safeMin,
    this.safeMax,
    this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const bottomPad = 20.0;
    const topPad = 10.0;
    const rightPad = 8.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    // --- min/max across all series ---
    double minV = double.infinity, maxV = -double.infinity;
    for (final s in series) {
      for (final v in s.values) {
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
    }
    if (minV == double.infinity) return;
    if (minV == maxV) {
      minV -= 1;
      maxV += 1;
    }
    final pad = (maxV - minV) * 0.15;
    minV -= pad;
    maxV += pad;

    // ---- ব্যাকগ্রাউন্ডে "নিরাপদ পরিসীমা" ব্যান্ড আঁকো (থাকলে) ----
    // এতে কৃষক এক নজরে দেখতে পারবেন লাইনটা সবুজ অংশের ভেতরে না বাইরে
    if (safeMin != null && safeMax != null) {
      final bandTop = (safeMax! > maxV) ? topPad : topPad + chartH * (1 - (safeMax! - minV) / (maxV - minV));
      final bandBottom = (safeMin! < minV) ? topPad + chartH : topPad + chartH * (1 - (safeMin! - minV) / (maxV - minV));
      final bandPaint = Paint()..color = const Color(0xFFD8F0DE);
      canvas.drawRect(
        Rect.fromLTRB(leftPad, bandTop.clamp(topPad, topPad + chartH), leftPad + chartW, bandBottom.clamp(topPad, topPad + chartH)),
        bandPaint,
      );
    }

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    final axisTextStyle = TextStyle(fontSize: 9, color: Colors.grey.shade600);

    // horizontal grid lines + y labels (min, mid, max)
    for (int i = 0; i <= 2; i++) {
      final y = topPad + chartH * (i / 2);
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);
      final value = maxV - (maxV - minV) * (i / 2);
      final tp = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(1), style: axisTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // find max points count for x spacing
    final maxLen = series.map((s) => s.values.length).fold(0, (a, b) => a > b ? a : b);
    if (maxLen < 2) {
      // single point — just draw a dot
      for (final s in series) {
        if (s.values.length == 1) {
          final dotPaint = Paint()..color = s.color;
          canvas.drawCircle(Offset(leftPad + chartW / 2, topPad + chartH / 2), 4, dotPaint);
        }
      }
    } else {
      for (final s in series) {
        if (s.values.length < 2) continue;
        final linePaint = Paint()
          ..color = s.color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final path = Path();
        for (int i = 0; i < s.values.length; i++) {
          final x = leftPad + chartW * (i / (s.values.length - 1));
          final norm = (s.values[i] - minV) / (maxV - minV);
          final y = topPad + chartH * (1 - norm);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, linePaint);

        // dots
        final dotPaint = Paint()..color = s.color;
        for (int i = 0; i < s.values.length; i++) {
          final x = leftPad + chartW * (i / (s.values.length - 1));
          final norm = (s.values[i] - minV) / (maxV - minV);
          final y = topPad + chartH * (1 - norm);
          canvas.drawCircle(Offset(x, y), 3, dotPaint);

          // সর্বশেষ পয়েন্টে মান লেখা — কৃষক সরাসরি সংখ্যাটা দেখতে পাবেন
          if (i == s.values.length - 1) {
            final labelText = s.values[i].toStringAsFixed(s.values[i] >= 10 ? 0 : 1);
            final tp = TextPainter(
              text: TextSpan(
                text: labelText,
                style: TextStyle(fontSize: 10, color: s.color, fontWeight: FontWeight.bold),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            final labelX = (x + tp.width + 4 > size.width) ? x - tp.width - 4 : x + 4;
            // পয়েন্টটা চার্টের একদম উপরের দিকে থাকলে লেবেল উপরে না বসিয়ে
            // নিচে বসাও — নাহলে legend/চার্টের বাইরের সাথে লেগে যেতে পারে
            final wantsAbove = (y - tp.height - 2) >= topPad;
            final labelY = wantsAbove ? y - tp.height - 2 : y + 6;
            tp.paint(canvas, Offset(labelX, labelY));
          }
        }
      }
    }

    // x labels — প্রথম, মাঝখান, শেষ দেখানো হয়; কিন্তু একই তারিখ পাশাপাশি
    // দুইবার (যেমন একই দিনে একাধিক রিডিং থাকলে "৩০/৮, ৩০/৮") এড়ানো হচ্ছে
    if (xLabels.isNotEmpty) {
      final rawIndices = [0, xLabels.length ~/ 2, xLabels.length - 1];
      final seenLabels = <String>{};
      final indices = <int>[];
      for (final i in rawIndices) {
        if (i < 0 || i >= xLabels.length) continue;
        if (seenLabels.contains(xLabels[i])) continue;
        seenLabels.add(xLabels[i]);
        indices.add(i);
      }
      for (final i in indices) {
        final x = maxLen > 1 ? leftPad + chartW * (i / (maxLen - 1)) : leftPad + chartW / 2;
        final tp = TextPainter(
          text: TextSpan(text: xLabels[i], style: axisTextStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPad + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}