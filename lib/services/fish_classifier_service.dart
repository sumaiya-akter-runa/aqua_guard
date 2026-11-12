import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// ============================================================
// প্রতিটা রোগের বিস্তারিত তথ্য
// ============================================================
// ============================================================
// সততার সাথে সীমাবদ্ধতা জানানো (disclaimer)
// ------------------------------------------------------------
// এই রোগ শনাক্তকরণ একটি image-classification AI মডেল থেকে এসেছে,
// যা একটি Kaggle-প্রকাশিত ছবির dataset (Freshwater Fish Disease
// Aquaculture in South Asia) দিয়ে প্রশিক্ষিত এবং test set-এ প্রায়
// ৮৭% accuracy দেখিয়েছে। এটি কোনো সরকারি/প্রাতিষ্ঠানিক (BFRI, DoF,
// FAO ইত্যাদি) সংস্থা কর্তৃক যাচাই বা অনুমোদিত রোগনির্ণয় পদ্ধতি নয় —
// এটি একটি সহায়ক অনুমান মাত্র, চূড়ান্ত চিকিৎসা সিদ্ধান্ত নয়।
// লক্ষণ/কারণ/করণীয় টেক্সটগুলো সাধারণ aquaculture জ্ঞান থেকে লেখা,
// নির্দিষ্ট কোনো গবেষণাপত্র থেকে উদ্ধৃত নয়।
// ============================================================
const String kDiseaseDetectionDisclaimer =
    "এই ফলাফল একটি AI মডেলের অনুমান (dataset পরীক্ষায় ~৮৭% নির্ভুল), "
    "কোনো সরকারি/প্রাতিষ্ঠানিক অনুমোদিত রোগনির্ণয় না। গুরুত্বপূর্ণ "
    "সিদ্ধান্তের আগে মৎস্য বিশেষজ্ঞের পরামর্শ নিন।";

class DiseaseInfo {
  final String id;
  final String name;
  final String level; // ভালো / সতর্ক / ঝুঁকি / বিপদ
  final List<String> signs;
  final List<String> causes;
  final List<String> pondActions;
  final String expertNote;

  DiseaseInfo({
    required this.id,
    required this.name,
    required this.level,
    required this.signs,
    required this.causes,
    required this.pondActions,
    required this.expertNote,
  });
}

final Map<String, DiseaseInfo> diseaseInfoMap = {
  "Healthy Fish": DiseaseInfo(
    id: "healthy",
    name: "সুস্থ মাছ",
    level: "ভালো",
    signs: [
      "স্বাভাবিক রং ও উজ্জ্বল চামড়া",
      "সক্রিয় সাঁতার ও স্বাভাবিক খাবার গ্রহণ",
      "কোনো দৃশ্যমান ক্ষত বা দাগ নেই",
    ],
    causes: [],
    pondActions: [
      "নিয়মিত পানির মান পর্যবেক্ষণ চালিয়ে যান।",
      "সময়মতো খাবার দিন, অতিরিক্ত খাওয়াবেন না।",
    ],
    expertNote: "মাছ সুস্থ আছে। নিয়মিত পর্যবেক্ষণ চালিয়ে যান।",
  ),

  // Source: FAO "Integrated Fish Farming in China", Ch.6 — "Erythroderma"
  // fao.org/4/ac264e/ac264e07.htm
  "Bacterial Red disease": DiseaseInfo(
    id: "bacterial_red",
    name: "ব্যাকটেরিয়াল রেড ডিজিজ (Erythroderma)",
    level: "ঝুঁকি",
    signs: [
      "শরীরে প্রদাহ, রক্তক্ষরণ ও আঁইশ ঝরে পড়া (বিশেষত পেটের দুই পাশে)",
      "পাখনার গোড়ায় রক্তবর্ণ দাগ, পাখনার প্রান্ত ক্ষয়ে যাওয়া",
      "চোয়ালের উপরে-নিচে লালচে দাগ",
    ],
    causes: [
      "নেটিং/পরিবহনের সময় শারীরিক আঘাত দিয়ে ব্যাকটেরিয়ার প্রবেশ",
      "ঠান্ডাজনিত ক্ষত (frostbite) বা শক্ত বস্তুতে ঘষা লাগা",
      "সারা বছর ঘটতে পারে, তবে আঘাতের সাথে সরাসরি সম্পর্কিত",
    ],
    pondActions: [
      "মাছ ধরা/স্থানান্তরের সময় সাবধানে, আলতোভাবে করুন যাতে আঘাত না লাগে।",
      "পুকুর ভালোভাবে পরিষ্কার ও জীবাণুমুক্ত রাখুন।",
      "নতুন পোনা মজুদের আগে সংক্ষিপ্ত জীবাণুনাশক স্নান বিবেচনা করুন (বিশেষজ্ঞের পরামর্শে)।",
    ],
    expertNote:
        "লক্ষণ FAO-এর বর্ণনা করা 'Erythroderma'-র সাথে মিলে যায় — তবে চূড়ান্ত নিশ্চয়তার জন্য মৎস্য বিশেষজ্ঞের পরামর্শ নিন। [Source: FAO, Integrated Fish Farming in China, Ch.6]",
  ),

  // Source: FAO Ch.6 — "Enteritis" (Aeromonas-related bacterial disease)
  "Bacterial diseases - Aeromoniasis": DiseaseInfo(
    id: "aeromoniasis",
    name: "অ্যারোমোনিয়াসিস (Enteritis-type)",
    level: "ঝুঁকি",
    signs: [
      "পেট ফোলা, লালচে দাগসহ",
      "পাখনা প্রদাহযুক্ত ও ক্ষয়প্রাপ্ত, মলদ্বার লাল ও ফোলা",
      "পেটে চাপ দিলে হলুদাভ শ্লেষ্মা নির্গত হওয়া",
      "খাবারে অনীহা, ধীরে ও একা সাঁতার কাটা",
    ],
    causes: [
      "পানির তাপমাত্রা ~২৫°C-এর কাছাকাছি হলে ব্যাকটেরিয়ার সংক্রমণ ক্ষমতা বাড়ে",
      "পানির মান খারাপ হওয়া, বাতাসের চাপ কমে যাওয়া",
      "অতিরিক্ত খাওয়ানো (overfeeding)",
    ],
    pondActions: [
      "সাময়িকভাবে খাবার কমান — overfeeding এই রোগের একটা পরিচিত কারণ।",
      "পানির গুণমান পরীক্ষা করুন ও প্রয়োজনে আংশিক পরিবর্তন করুন।",
      "রোগ-মৌসুমে (গরমকালে) খাদ্য নিয়ন্ত্রণ ও নিয়মিত পর্যবেক্ষণ চালিয়ে যান।",
    ],
    expertNote:
        "৫০-৯০% পর্যন্ত মৃত্যুহার হতে পারে বলে FAO-এর তথ্যে উল্লেখ আছে (মূলত grass/black carp-এ) — দ্রুত ব্যবস্থা জরুরি, বিশেষজ্ঞের পরামর্শ নিন। [Source: FAO, Integrated Fish Farming in China, Ch.6]",
  ),

  // Source: FAO Ch.6 — "Bacterial gill rot"
  "Bacterial gill disease": DiseaseInfo(
    id: "gill_disease",
    name: "ব্যাকটেরিয়াল গিল রট (Gill Rot)",
    level: "ঝুঁকি",
    signs: [
      "মাথাসহ শরীর কালচে হয়ে যাওয়া",
      "ফুলকা কাদা/শ্লেষ্মায় ঢাকা, পচা ও ফ্যাকাশে",
      "গুরুতর ক্ষেত্রে অপারকুলামের (গিল-কভার) চামড়া ক্ষয়ে স্বচ্ছ দাগ পড়া",
    ],
    causes: [
      "পানির তাপমাত্রা ২০°C-এর উপরে গেলে বেশি দেখা যায় (সর্বোচ্চ প্রকোপ ২৮-৩৫°C)",
      "শীতকালে (১৫°C-এর নিচে) সাধারণত দেখা যায় না",
      "প্রায়ই enteritis (অন্ত্রের প্রদাহ)-এর সাথে একসাথে ঘটে",
    ],
    pondActions: [
      "সাপ্তাহিক পুকুর জীবাণুমুক্তকরণ বিবেচনা করুন (বিশেষজ্ঞের পরামর্শে চুন/জীবাণুনাশক)।",
      "পানির তাপমাত্রা ও DO নিয়মিত পর্যবেক্ষণ করুন — গরম মৌসুমে বাড়তি সতর্কতা।",
      "এয়ারেশন বাড়ান, ফুলকার সমস্যা দ্রুত অবনতি হতে পারে।",
    ],
    expertNote:
        "ফুলকার সমস্যা দ্রুত মাছের মৃত্যুর কারণ হতে পারে — অক্সিজেন লেভেল অগ্রাধিকার দিন, প্রয়োজনে দ্রুত বিশেষজ্ঞের পরামর্শ নিন। [Source: FAO, Integrated Fish Farming in China, Ch.6]",
  ),

  // Source: FAO Ch.6 — "Saprolegniasis" (সরাসরি নাম মিলে যায়)
  "Fungal diseases Saprolegniasis": DiseaseInfo(
    id: "fungal",
    name: "ছত্রাকজনিত রোগ (Saprolegniasis)",
    level: "সতর্ক",
    signs: [
      "শরীরে ধূসর/তুলার মতো flocculent (তুলতুলে) আবরণ",
      "চামড়া ও পেশিতে সুতার মতো (hyphae) বৃদ্ধি, ৩ সেমি পর্যন্ত লম্বা হতে পারে",
      "অস্বাভাবিক আচরণ — শরীর ঘষা, অতিরিক্ত শ্লেষ্মা নিঃসরণ",
    ],
    causes: [
      "আগে থেকে থাকা ক্ষত/আঘাতে ছত্রাকের spore (Saprolegnia/Achlya) আটকে যাওয়া",
      "নেটিং, পরিবহন বা মজুদের সময় লেগে থাকা আঘাত",
      "উচ্চ ঘনত্বে মজুদ করা শীতকালীন (overwintering) পুকুরে বেশি দেখা যায়",
    ],
    pondActions: [
      "মাছ ধরা/পরিবহনের সময় আঘাত এড়াতে সতর্ক থাকুন — এটাই প্রধান প্রতিরোধ।",
      "পুকুর চুন দিয়ে জীবাণুমুক্ত করুন (নতুন মজুদের আগে)।",
      "আক্রান্ত মাছ আলাদা করুন, রোগ ২৪ ঘণ্টার মধ্যে সারা শরীরে ছড়াতে পারে (মৃত মাছে)।",
    ],
    expertNote:
        "সাধারণত আঘাতপ্রাপ্ত/দুর্বল মাছে বেশি হয় — আঘাত এড়ানোই মূল প্রতিরোধ। [Source: FAO, Integrated Fish Farming in China, Ch.6]",
  ),

  // Source: FAO Ch.6 — "Invasive Diseases" section (Trichodinasis,
  // Dactylogyrosis, Lernaeasis, Ichthyophythiriasis ইত্যাদির সংক্ষিপ্তসার)
  "Parasitic diseases": DiseaseInfo(
    id: "parasitic",
    name: "পরজীবীজনিত রোগ",
    level: "সতর্ক",
    signs: [
      "শরীর/ফুলকায় সাদা বিন্দু বা পুঁজের মতো দাগ (\"white dot disease\"-এর মতো)",
      "শরীর ঘষার প্রবণতা, পানির উপরিভাগে বেশি সময় থাকা",
      "শ্বাসকষ্ট, ফ্যাকাশে/অ্যানিমিক ফুলকা, ধীর ও একা সাঁতার",
    ],
    causes: [
      "বহিঃপরজীবী সংক্রমণ (Trichodina, Dactylogyrus, Lernaea, Ichthyophthirius প্রভৃতি)",
      "উচ্চ ঘনত্বে মজুদ ও দুর্বল পানির মান পরজীবীর বিস্তার বাড়ায়",
      "নতুন মাছ/পোনা quarantine ছাড়া সরাসরি পুকুরে ছাড়া",
    ],
    pondActions: [
      "নতুন মাছ মজুদের আগে আলাদাভাবে quarantine করুন ভবিষ্যতে।",
      "মজুদ ঘনত্ব কমানো বিবেচনা করুন, বিশেষত ছোট/অগভীর পুকুরে।",
      "চিকিৎসার জন্য (লবণ স্নান, নির্দিষ্ট রাসায়নিক) বিশেষজ্ঞের তত্ত্বাবধানে সিদ্ধান্ত নিন — নিজে থেকে ডোজ ঠিক করবেন না।",
    ],
    expertNote:
        "পরজীবী দ্রুত ছড়াতে ও পোনা/ফিঙ্গারলিং পর্যায়ে গুরুতর ক্ষতি করতে পারে — নিশ্চিত হতে মৎস্য বিশেষজ্ঞের পরামর্শ নিন। [Source: FAO, Integrated Fish Farming in China, Ch.6]",
  ),

  // ⚠️ honest note: এই ক্লাসের জন্য উপরের FAO অধ্যায়ে সরাসরি মিল
  // পাওয়া যায়নি ("white tail" নাম প্রধানত freshwater চিংড়িতে বেশি
  // পরিচিত সাহিত্যে, মাছে কম নথিভুক্ত) — তাই এই এন্ট্রি এখনো সাধারণ
  // জ্ঞান-ভিত্তিক, স্পষ্টভাবে চিহ্নিত করা হলো।
  "Viral diseases White tail disease": DiseaseInfo(
    id: "white_tail",
    name: "ভাইরাল হোয়াইট টেইল ডিজিজ",
    level: "বিপদ",
    signs: [
      "লেজের অংশ সাদাটে/অস্বচ্ছ হয়ে যাওয়া",
      "পেশিতে সাদা ভাব",
      "অস্বাভাবিকভাবে অলস হয়ে যাওয়া",
    ],
    causes: [
      "ভাইরাস সংক্রমণ",
      "স্ট্রেসপূর্ণ পরিবেশ ও দুর্বল পানির মান",
    ],
    pondActions: [
      "আক্রান্ত মাছ দ্রুত আলাদা করুন।",
      "পানির গুণমান উন্নত করুন।",
      "নতুন মজুদ করার আগে উৎস যাচাই করুন।",
    ],
    expertNote:
        "⚠️ এই রোগের তথ্য এখনো সাধারণ জ্ঞান-ভিত্তিক, নির্দিষ্ট গবেষণা-উদ্ধৃত না — ভাইরাল রোগের কোনো সরাসরি চিকিৎসা নেই, দ্রুত বিশেষজ্ঞের পরামর্শ ও সংক্রমণ নিয়ন্ত্রণ জরুরি।",
  ),
};

class FishClassificationResult {
  final bool uncertain;
  final double confidence;
  final String? message;
  final String? rawLabel;
  final DiseaseInfo? info;

  FishClassificationResult({
    required this.uncertain,
    required this.confidence,
    this.message,
    this.rawLabel,
    this.info,
  });

  bool get isHealthy => info?.id == "healthy";

  /// AI রোগ-শনাক্তকরণের সীমাবদ্ধতা জানানোর জন্য — UI-তে সবসময় ছোট করে দেখানো উচিত
  String get disclaimer => kDiseaseDetectionDisclaimer;
}

class AquaGuardClassifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  static const int inputSize = 224;
  bool get isLoaded => _interpreter != null;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/aquaguard_multiclass_model.tflite',
    );
    final data = await rootBundle.loadString('assets/multiclass_labels.txt');
    _labels = data.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  Future<FishClassificationResult> classifyImage(File imageFile) async {
    if (_interpreter == null) {
      throw StateError("Model লোড হয়নি — আগে loadModel() কল করো।");
    }

    final rawImage = img.decodeImage(await imageFile.readAsBytes())!;
    final resized = img.copyResize(rawImage, width: inputSize, height: inputSize);

    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
          },
        ),
      ),
    );

    final numClasses = _labels.length;
    var output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);
    _interpreter!.run(input, output);

    final probs = List<double>.from(output[0]);

    int maxIdx = 0;
    double maxProb = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIdx = i;
      }
    }

    if (maxProb < 0.70) {
      return FishClassificationResult(
        uncertain: true,
        confidence: maxProb,
        message: "স্পষ্টভাবে নির্ণয় করা যাচ্ছে না। মাছের কাছ থেকে স্পষ্ট আলোয়, কাছাকাছি থেকে ছবি তুলুন।",
      );
    }

    final predictedLabel = _labels[maxIdx];
    final info = diseaseInfoMap[predictedLabel];

    if (info == null) {
      return FishClassificationResult(
        uncertain: true,
        confidence: maxProb,
        message: "ফলাফল প্রক্রিয়াকরণে সমস্যা হয়েছে। আবার চেষ্টা করুন।",
      );
    }

    return FishClassificationResult(
      uncertain: false,
      confidence: maxProb,
      rawLabel: predictedLabel,
      info: info,
    );
  }

  void dispose() {
    _interpreter?.close();
  }
}
