import 'water_rule_engine.dart';

// ============================================================
// Feed Suggestion Engine — JSX computeFeedSuggestion() এর Dart ভার্সন
// ============================================================

class FeedNote {
  final String text;
  final String level;
  FeedNote({required this.text, required this.level});
}

class FeedSuggestion {
  final double suggestedKg;
  final double biomassKg;
  final double ratePct;
  final List<FeedNote> notes;

  FeedSuggestion({
    required this.suggestedKg,
    required this.biomassKg,
    required this.ratePct,
    required this.notes,
  });
}

class FeedEngine {
  // ============================================================
  // Source: FAO Aquaculture Feed Management Manual — carp feeding
  // table (fao.org/4/s4314e/s4314e09.htm) ও FAO AFRIS Indian major
  // carp (Catla) feeding table (fao.org/fileadmin/user_upload/
  // affris/docs/Catla/English/table_16.htm)। ছোট মাছের জন্য শরীরের
  // ওজনের তুলনায় বেশি % খাবার লাগে, বড় মাছে কম — এই বাস্তবতা এখানে
  // প্রতিফলিত করা হয়েছে (আগে সবসময় নির্বিশেষে 3% ব্যবহার হতো)।
  // ============================================================
  static double _baseFeedRateForWeight(double weightG) {
    if (weightG < 5) return 0.09; // 9%
    if (weightG < 20) return 0.07; // 7%
    if (weightG < 50) return 0.06; // 6%
    if (weightG < 100) return 0.05; // 5%
    if (weightG < 300) return 0.04; // 4%
    if (weightG < 1000) return 0.03; // 3%
    return 0.02; // 1000g+ — FAO টেবিলের বাইরে, রক্ষণশীল অনুমান
  }

  /// diseaseDetected: true = disease found, false = healthy, null = not scanned yet
  static FeedSuggestion computeFeedSuggestion({
    required double sizeDecimal,
    required int quantity,
    required double avgWeightG,
    required String waterRisk,
    bool? diseaseDetected,
  }) {
    // বৃদ্ধি (growth) ট্যাবে এখনো কোনো ওজন এন্ট্রি না থাকলে (avgWeightG == 0),
    // একটা যুক্তিসঙ্গত ডিফল্ট পোনার গড় ওজন ধরে নেওয়া হয় — তা না হলে
    // বায়োমাস সবসময় 0 থাকত এবং "মাছের সংখ্যা" বদলালেও সাজেশনে কোনো প্রভাব পড়ত না।
    const defaultJuvenileWeightG = 50.0;
    final usingDefaultWeight = avgWeightG <= 0;
    final effectiveWeightG = usingDefaultWeight ? defaultJuvenileWeightG : avgWeightG;

    final biomassKg = (effectiveWeightG.clamp(0, double.infinity) * quantity) / 1000;
    double ratePct = _baseFeedRateForWeight(effectiveWeightG); // FAO size-based rate (আগে flat 0.03 ছিল)
    final notes = <FeedNote>[];

    if (usingDefaultWeight) {
      notes.add(FeedNote(
        text: "এখনো কোনো ওজন এন্ট্রি নেই — আনুমানিক ${defaultJuvenileWeightG.toStringAsFixed(0)} গ্রাম গড় ওজন ধরে হিসাব করা হয়েছে। \"বৃদ্ধি\" ট্যাবে প্রকৃত ওজন যোগ করলে হিসাব আরও নির্ভুল হবে।",
        level: "সতর্ক",
      ));
    }

    if (waterRisk == "বিপদ") {
      ratePct *= 0.5;
      notes.add(FeedNote(text: "পানির মান বিপদজনক পর্যায়ে — খাবার প্রায় অর্ধেক কমানো হয়েছে।", level: "বিপদ"));
    } else if (waterRisk == "ঝুঁকি") {
      ratePct *= 0.7;
      notes.add(FeedNote(text: "পানির মান ঝুঁকিপূর্ণ — খাবার কিছুটা কমানো হয়েছে।", level: "ঝুঁকি"));
    } else if (waterRisk == "সতর্ক") {
      ratePct *= 0.9;
      notes.add(FeedNote(text: "পানির মান সতর্ক পর্যায়ে — খাবার সামান্য কমানো হয়েছে।", level: "সতর্ক"));
    } else {
      notes.add(FeedNote(text: "পানির মান ভালো — স্বাভাবিক হারে খাবার দেওয়া যায়।", level: "ভালো"));
    }

    if (diseaseDetected == true) {
      ratePct *= 0.6;
      notes.add(FeedNote(text: "সাম্প্রতিক ফিশ স্ক্যানে সম্ভাব্য সমস্যা পাওয়া গেছে — খাবার কমিয়ে মাছ পর্যবেক্ষণ করুন।", level: "ঝুঁকি"));
    } else if (diseaseDetected == false) {
      notes.add(FeedNote(text: "সাম্প্রতিক স্ক্যানে মাছ সুস্থ মনে হয়েছে — খাবারে বাড়তি সতর্কতার দরকার নেই।", level: "ভালো"));
    } else {
      notes.add(FeedNote(text: "এখনো কোনো ফিশ স্ক্যান করা হয়নি — নিয়মিত স্ক্যান করলে সুপারিশ আরও নির্ভুল হবে।", level: "সতর্ক"));
    }

    final bySizeFloor = (sizeDecimal * 0.015).clamp(0.1, double.infinity);
    final rawKg = double.parse((biomassKg * ratePct).toStringAsFixed(2));
    final suggestedKg = biomassKg > 0 ? rawKg.clamp(0.1, double.infinity) : bySizeFloor;

    return FeedSuggestion(
      suggestedKg: suggestedKg.toDouble(),
      biomassKg: double.parse(biomassKg.toStringAsFixed(1)),
      ratePct: ratePct,
      notes: notes,
    );
  }
}

// ============================================================
// Species-wise feed recommendation table
// ============================================================
class FeedOption {
  final String name;
  final String note;
  final String category; // "main" (প্রধান খাবার) | "supplement" (সম্পূরক/বিকল্প)
  FeedOption({required this.name, required this.note, this.category = "main"});
}

const List<String> speciesList = [
  "রুই/কাতলা",
  "তেলাপিয়া",
  "পাঙাশ",
  "শিং/মাগুর",
  "কই",
  "গ্রাস কার্প",
  "সিলভার কার্প",
  "চিংড়ি (গলদা)",
  "মৃগেল",
  "পাবদা",
];

final Map<String, List<FeedOption>> feedBySpecies = {
  "রুই/কাতলা": [
    FeedOption(name: "পিলেট ফিড (গ্রোয়ার, ২৫-৩০% প্রোটিন)", note: "সাধারণ বৃদ্ধির জন্য প্রধান খাবার", category: "main"),
    FeedOption(name: "স্টার্টার পিলেট (৩০-৩৫% প্রোটিন)", note: "পোনা অবস্থায় দ্রুত বৃদ্ধির জন্য", category: "main"),
    FeedOption(name: "সয়াবিন মিল ফিড (২৮-৩২% প্রোটিন)", note: "পিলেট না পেলে ভালো বিকল্প প্রধান খাবার", category: "main"),
    FeedOption(name: "সরিষার খৈল + চালের কুঁড়া মিশ্রণ", note: "সাশ্রয়ী ঐতিহ্যবাহী সম্পূরক", category: "supplement"),
    FeedOption(name: "তিলের খৈল", note: "সরিষার খৈল না পেলে বিকল্প সম্পূরক", category: "supplement"),
    FeedOption(name: "ভুট্টা গুঁড়া", note: "শক্তির সম্পূরক উৎস", category: "supplement"),
    FeedOption(name: "গমের ভুসি", note: "আটা কলে সহজে পাওয়া যায়, সাশ্রয়ী সম্পূরক", category: "supplement"),
  ],
  "তেলাপিয়া": [
    FeedOption(name: "উচ্চ প্রোটিন পিলেট (৩০-৩৫%)", note: "দ্রুত বৃদ্ধির জন্য প্রধান খাবার", category: "main"),
    FeedOption(name: "সয়াবিন মিল ফিড", note: "উদ্ভিজ্জ প্রোটিনের ভালো উৎস, প্রধান খাবার হিসেবেও চলে", category: "main"),
    FeedOption(name: "শাক-সবজি ভিত্তিক ফিড", note: "কম খরচে সম্পূরক", category: "supplement"),
    FeedOption(name: "চালের কুঁড়া মিশ্রণ", note: "সহায়ক সম্পূরক খাবার", category: "supplement"),
    FeedOption(name: "চিটাগুড় মিশ্রিত ভুসি", note: "শক্তি বাড়াতে সাশ্রয়ী সম্পূরক", category: "supplement"),
    FeedOption(name: "ভাঙা ডাল/মসুরের অবশিষ্টাংশ", note: "স্থানীয়ভাবে সহজলভ্য প্রোটিন সম্পূরক", category: "supplement"),
    FeedOption(name: "ডিমের খোসা গুঁড়া", note: "ঘরে থাকা ডিমের খোসা শুকিয়ে গুঁড়া করে দিন — ক্যালসিয়াম সহায়ক", category: "supplement"),
    FeedOption(name: "রান্নাঘরের সবজির খোসা/উচ্ছিষ্ট (সেদ্ধ করে)", note: "খাদ্য অপচয় কমিয়ে সম্পূরক হিসেবে ব্যবহার করা যায়", category: "supplement"),
  ],
  "পাঙাশ": [
    FeedOption(name: "ভাসমান (ফ্লোটিং) পিলেট ফিড", note: "পানির উপরে খাওয়ার অভ্যাস অনুযায়ী উপযুক্ত প্রধান খাবার", category: "main"),
    FeedOption(name: "ফিশমিল মিশ্রিত ফিড (২৮-৩২% প্রোটিন)", note: "দ্রুত বৃদ্ধির জন্য প্রধান খাবার", category: "main"),
    FeedOption(name: "সয়াবিন মিল মিশ্রিত ফিড", note: "ফিশমিল না পেলে ভালো বিকল্প", category: "main"),
    FeedOption(name: "গমের ভুসি", note: "সম্পূরক/সাশ্রয়ী খাবার", category: "supplement"),
    FeedOption(name: "সরিষার খৈল মিশ্রণ", note: "সহায়ক প্রোটিন সম্পূরক", category: "supplement"),
    FeedOption(name: "চিটাগুড় মিশ্রিত কুঁড়া", note: "শক্তি বাড়ানোর সাশ্রয়ী সম্পূরক", category: "supplement"),
    FeedOption(name: "হাঁস-মুরগির নাড়িভুঁড়ি (সেদ্ধ করে)", note: "গ্রামে সহজলভ্য প্রাণিজ প্রোটিন সম্পূরক, পরিমিত পরিমাণে", category: "supplement"),
  ],
  "শিং/মাগুর": [
    FeedOption(name: "উচ্চ প্রোটিন ফিশমিল ফিড (৩৫-৪০%)", note: "মাংসাশী প্রজাতির জন্য অপরিহার্য প্রধান খাবার", category: "main"),
    FeedOption(name: "পিলেট ফিড (ক্যাটফিশ স্পেশাল)", note: "বাজারে সহজলভ্য প্রক্রিয়াজাত প্রধান খাবার", category: "main"),
    FeedOption(name: "প্রক্রিয়াজাত প্রাণিজ উপজাত", note: "অতিরিক্ত প্রোটিন সহায়ক, পরিমিত পরিমাণে", category: "supplement"),
    FeedOption(name: "রক্তগুঁড়া মিশ্রণ (ব্লাডমিল)", note: "প্রোটিন সম্পূরক হিসেবে সীমিত মাত্রায়", category: "supplement"),
    FeedOption(name: "শামুকের মাংস", note: "স্থানীয়ভাবে সহজলভ্য প্রাণিজ প্রোটিন সম্পূরক", category: "supplement"),
    FeedOption(name: "কেঁচো (আর্থওয়ার্ম) সম্পূরক", note: "প্রাকৃতিক উচ্চ-প্রোটিন সম্পূরক, সীমিত পরিমাণে", category: "supplement"),
    FeedOption(name: "হাঁস-মুরগির নাড়িভুঁড়ি (সেদ্ধ করে)", note: "গ্রামে সহজলভ্য সাশ্রয়ী প্রাণিজ প্রোটিন", category: "supplement"),
  ],
  "কই": [
    FeedOption(name: "পিলেট ফিড (স্মল/মিডিয়াম পিস)", note: "সহজপাচ্য, নিয়মিত প্রধান খাবার", category: "main"),
    FeedOption(name: "উচ্চ প্রোটিন স্টার্টার ফিড", note: "পোনা অবস্থায় উপযোগী প্রধান খাবার", category: "main"),
    FeedOption(name: "সয়াবিন মিল ফিড", note: "পিলেট না পেলে বিকল্প প্রধান খাবার", category: "main"),
    FeedOption(name: "চালের কুঁড়া", note: "সাশ্রয়ী সম্পূরক খাবার", category: "supplement"),
    FeedOption(name: "সরিষার খৈল", note: "সাশ্রয়ী সম্পূরক বিকল্প", category: "supplement"),
    FeedOption(name: "গমের ভুসি", note: "সহজলভ্য, সাশ্রয়ী সম্পূরক", category: "supplement"),
  ],
  "গ্রাস কার্প": [
    FeedOption(name: "নরম জলজ উদ্ভিদ/ঘাস", note: "প্রধান প্রাকৃতিক খাবার, সহজলভ্য হলে অগ্রাধিকার দিন", category: "main"),
    FeedOption(name: "নেপিয়ার ঘাস (কচি অংশ)", note: "স্থানীয়ভাবে চাষযোগ্য বিকল্প প্রধান খাবার", category: "main"),
    FeedOption(name: "কচুরিপানার কচি অংশ", note: "সহজলভ্য হলে ভালো প্রাকৃতিক সম্পূরক", category: "supplement"),
    FeedOption(name: "সবুজ শাক-সবজির অবশিষ্টাংশ", note: "সম্পূরক প্রাকৃতিক খাবার", category: "supplement"),
    FeedOption(name: "পিলেট ফিড (নিম্ন প্রোটিন)", note: "প্রাকৃতিক খাবার কম থাকলে সম্পূরক হিসেবে", category: "supplement"),
    FeedOption(name: "চালের কুঁড়া", note: "মাঝেমধ্যে সম্পূরক", category: "supplement"),
    FeedOption(name: "লাউ/মিষ্টিকুমড়ার লতাপাতা", note: "বাড়ির আশেপাশে সহজলভ্য প্রাকৃতিক সম্পূরক", category: "supplement"),
  ],
  "সিলভার কার্প": [
    FeedOption(name: "প্রাকৃতিক প্ল্যাংকটন (সার প্রয়োগে বৃদ্ধি)", note: "প্রধান খাদ্য উৎস — জৈব/রাসায়নিক সার দিয়ে পুকুরে প্ল্যাংকটন উৎপাদন বাড়ান", category: "main"),
    FeedOption(name: "চালের কুঁড়ার গোলা (পানিতে গুলে)", note: "প্ল্যাংকটন কম থাকলে সহায়ক সম্পূরক", category: "supplement"),
    FeedOption(name: "চালের কুঁড়া (সূক্ষ্ম গুঁড়া)", note: "সম্পূরক হিসেবে সীমিত পরিমাণে", category: "supplement"),
    FeedOption(name: "সয়াবিন মিল (গুঁড়া)", note: "মাঝেমধ্যে সম্পূরক প্রোটিন", category: "supplement"),
    FeedOption(name: "পচনশীল গোবর/জৈব সার (কম্পোস্ট করে)", note: "সরাসরি খাবার না — পুকুরে প্ল্যাংকটন বাড়িয়ে পরোক্ষভাবে খাদ্য জোগায়", category: "supplement"),
  ],
  "চিংড়ি (গলদা)": [
    FeedOption(name: "উচ্চ প্রোটিন চিংড়ি পিলেট (৩৫-৪০%)", note: "দ্রুত বৃদ্ধির জন্য প্রধান খাবার", category: "main"),
    FeedOption(name: "ভাসমান পিলেট (চিংড়ি স্পেশাল)", note: "নিয়মিত খাওয়ানোর সুবিধাজনক প্রধান খাবার", category: "main"),
    FeedOption(name: "সয়াবিন মিল ফিড", note: "পিলেট না পেলে বিকল্প প্রধান খাবার", category: "main"),
    FeedOption(name: "শামুক/ঝিনুকের মাংস", note: "প্রাকৃতিক প্রোটিন উৎস, সহজলভ্য হলে দিন", category: "supplement"),
    FeedOption(name: "মাছ কাটার বর্জ্য (রান্না করে)", note: "সাশ্রয়ী প্রাণিজ প্রোটিন সম্পূরক", category: "supplement"),
    FeedOption(name: "সেদ্ধ চালের কুঁড়া মিশ্রণ", note: "সাশ্রয়ী সম্পূরক খাবার", category: "supplement"),
    FeedOption(name: "শামুক-ঝিনুকের খোসা গুঁড়া", note: "ক্যালসিয়াম সহায়ক, খোলস মজবুত করতে সাহায্য করে", category: "supplement"),
  ],
  "মৃগেল": [
    FeedOption(name: "পিলেট ফিড (গ্রোয়ার, ২৫-৩০% প্রোটিন)", note: "সাধারণ বৃদ্ধির জন্য প্রধান খাবার", category: "main"),
    FeedOption(name: "সয়াবিন মিল ফিড", note: "পিলেট না পেলে বিকল্প প্রধান খাবার", category: "main"),
    FeedOption(name: "সরিষার খৈল মিশ্রণ", note: "সাশ্রয়ী ঐতিহ্যবাহী সম্পূরক", category: "supplement"),
    FeedOption(name: "তিলের খৈল", note: "সরিষার খৈলের বিকল্প সম্পূরক", category: "supplement"),
    FeedOption(name: "চালের কুঁড়া", note: "সহায়ক সম্পূরক খাবার", category: "supplement"),
    FeedOption(name: "ভুট্টা গুঁড়া", note: "শক্তির সম্পূরক উৎস", category: "supplement"),
    FeedOption(name: "গমের ভুসি", note: "সহজলভ্য, সাশ্রয়ী সম্পূরক", category: "supplement"),
  ],
  "পাবদা": [
    FeedOption(name: "উচ্চ প্রোটিন পিলেট (৩০-৩৫%)", note: "ছোট আকারের প্রজাতির জন্য উপযুক্ত প্রধান খাবার", category: "main"),
    FeedOption(name: "ফিশমিল মিশ্রিত স্টার্টার ফিড", note: "পোনা অবস্থায় দ্রুত বৃদ্ধির জন্য প্রধান খাবার", category: "main"),
    FeedOption(name: "সয়াবিন মিল ফিড", note: "বিকল্প প্রধান খাবার", category: "main"),
    FeedOption(name: "চালের কুঁড়া মিশ্রণ", note: "সহায়ক সাশ্রয়ী সম্পূরক", category: "supplement"),
    FeedOption(name: "সরিষার খৈল মিশ্রণ", note: "সহায়ক সাশ্রয়ী সম্পূরক", category: "supplement"),
    FeedOption(name: "রান্নাঘরের বাড়তি ভাত (গোলা করে)", note: "ঘরে থাকা ভাত ফেলে না দিয়ে সম্পূরক হিসেবে দিতে পারেন", category: "supplement"),
  ],
};

// ============================================================
// Solution Engine — JSX computeSolution() এর Dart ভার্সন
// ============================================================
class SolutionResult {
  final String overall;
  final List<String> steps;
  final List<FeedOption> feedOptions;
  final double suggestedKg;
  final bool? diseaseDetected;

  SolutionResult({
    required this.overall,
    required this.steps,
    required this.feedOptions,
    required this.suggestedKg,
    required this.diseaseDetected,
  });
}

class SolutionEngine {
  static SolutionResult computeSolution({
    required String waterRisk,
    bool? fishHealthy, // null = no scan, true = healthy, false = diseased
    bool? fishUncertain,
    String? fishLevel,
    String? fishName,
    List<String>? fishPondActions,
    String? fishExpertNote,
    required FeedSuggestion feedSuggestion,
    required String species,
  }) {
    const order = ["ভালো", "সতর্ক", "ঝুঁকি", "বিপদ"];

    bool? diseaseDetected;
    if (fishHealthy == null) {
      diseaseDetected = null;
    } else if (fishUncertain == true) {
      diseaseDetected = null;
    } else {
      diseaseDetected = fishHealthy == false;
    }

    final effectiveFishLevel = diseaseDetected == true ? (fishLevel ?? "ঝুঁকি") : "ভালো";

    final waterIdx = order.indexOf(waterRisk);
    final fishIdx = order.indexOf(effectiveFishLevel);
    final overall = order[waterIdx > fishIdx ? waterIdx : fishIdx];

    final steps = List<String>.from(WaterRuleEngine.stepGuide[overall] ?? []);

    if (diseaseDetected == true && fishPondActions != null && fishPondActions.isNotEmpty) {
      steps.add("মাছের ক্ষেত্রে (${fishName ?? ''}): ${fishPondActions[0]}");
      if (fishPondActions.length > 1) steps.add(fishPondActions[1]);
      if (fishExpertNote != null) steps.add(fishExpertNote);
    } else if (diseaseDetected == null && fishUncertain == true) {
      steps.add("সাম্প্রতিক ফিশ স্ক্যান অনিশ্চিত ছিল — স্পষ্ট আলোয় আবার স্ক্যান করুন।");
    }

    final feedOptions = feedBySpecies[species] ?? feedBySpecies["রুই/কাতলা"]!;

    return SolutionResult(
      overall: overall,
      steps: steps,
      feedOptions: feedOptions,
      suggestedKg: feedSuggestion.suggestedKg,
      diseaseDetected: diseaseDetected,
    );
  }
}