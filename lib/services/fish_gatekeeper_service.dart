import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// ============================================================
// Fish Gatekeeper (FINAL) — নিজস্বভাবে ট্রেইন করা বাইনারি (Fish vs Not-Fish)
// মডেল, dataset0+1+2+3 (নিজের farm ছবিসহ) দিয়ে ঠিকভাবে ট্রেইন করা।
// ------------------------------------------------------------
// Training data:
//   - Fish (positive)     → dataset0 (নিজের MatsyaDx-BD farm ছবি) +
//     dataset1, dataset2, dataset3 (Kaggle/দক্ষিণ এশীয় fish disease
//     dataset) — মোট ৬,০৪৫টা ছবি
//   - Not Fish (negative)  → TensorFlow Flowers (৩,৬৭০টা) + CIFAR-10-এর
//     বিভিন্ন সাধারণ বস্তু (গাড়ি/পাখি/বিড়াল/কুকুর/হরিণ ইত্যাদি, ২,৩৭৫টা) —
//     মোট ৬,০৪৫টা ছবি (fish-এর সাথে perfectly balanced)
//
// ✅ Test accuracy: 99.83%, fish ক্লাসে precision/recall/f1 = 1.00
//
// ⚠️ সততার সাথে সীমাবদ্ধতা:
// Negative-এ এখনো মানুষ/কাপড়/ঘরবাড়ির মতো ছবি নেই — ভবিষ্যতে আরও
// বৈচিত্র্য যোগ করে retrain করলে আরও শক্তিশালী হবে।
// ============================================================

class GatekeeperResult {
  final bool looksLikeFish;
  final double fishProbability; // ০ (not_fish) থেকে ১ (fish)

  GatekeeperResult({
    required this.looksLikeFish,
    required this.fishProbability,
  });
}

class FishGatekeeperService {
  Interpreter? _interpreter;
  static const int inputSize = 224;
  bool get isLoaded => _interpreter != null;

  // ⚠️ এই নতুন model-এ label ম্যাপিং আগের V2-এর চেয়ে আলাদা —
  // এবার Colab notebook-এ explicitly "label": 1 = fish, "label": 0 = not_fish
  // ধরে DataFrame বানানো হয়েছে (ফোল্ডার-নাম alphabetical sort না)।
  // তাই sigmoid output সরাসরি P(fish) বোঝায় — উল্টানোর (1.0 - x) দরকার নেই।
  static const double _threshold = 0.5;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/fish_gatekeeper_binary.tflite');
  }

  Future<GatekeeperResult> check(File imageFile) async {
    if (_interpreter == null) {
      throw StateError("Gatekeeper মডেল লোড হয়নি — আগে loadModel() কল করো।");
    }

    final rawImage = img.decodeImage(await imageFile.readAsBytes())!;
    final resized = img.copyResize(rawImage, width: inputSize, height: inputSize);

    // এই মডেল EfficientNetB0 দিয়ে বানানো, যেটার নিজস্ব preprocessing
    // built-in আছে (raw 0-255 ইনপুট আশা করে, ম্যানুয়াল normalization
    // লাগে না) — তাই এখানে raw pixel value পাঠানো হচ্ছে, disease
    // classifier-এর মতোই।
    var input = List.generate(
      1,
          (_) => List.generate(
        inputSize,
            (y) => List.generate(
          inputSize,
              (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );

    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);
    _interpreter!.run(input, output);

    // sigmoid output সরাসরি P(fish) — কোনো উল্টানো (1.0 - x) লাগবে না।
    final double fishProbability = output[0][0];
    final bool looksLikeFish = fishProbability >= _threshold;

    return GatekeeperResult(
      looksLikeFish: looksLikeFish,
      fishProbability: fishProbability,
    );
  }

  void dispose() {
    _interpreter?.close();
  }
}