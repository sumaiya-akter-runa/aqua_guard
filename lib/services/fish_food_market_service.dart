import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// ফিশপান্ডা — মাছের খাবার মার্কেটপ্লেস সার্ভিস
//
// এই ফাইলটা এমনভাবে বানানো, যাতে এখনই কাজ করে (local ডেটা দিয়ে),
// কিন্তু backend/real API বসালে শুধু নিচের kFoodApiBaseUrl আর
// এন্ডপয়েন্ট বসিয়ে দিলেই আসল লাইভ ডেটা আসা শুরু করবে —
// UI (fishpanda_screen)-এর কোনো কোড পাল্টাতে হবে না।
// ============================================================

// TODO(backend): backend রেডি হলে এখানে আসল API ঠিকানা বসান।
// যেমন: "https://api.aquaguard.app"
// TODO(backend): `fishpanda_backend` ফোল্ডারের সার্ভার Render/Railway-তে
// ডিপ্লয় করার পর এখানে সেই আসল URL বসান। যেমন:
// "https://fishpanda-backend.onrender.com"
const String kFoodApiBaseUrl = "https://api.aquaguard.app";

class FishFoodProduct {
  final String id;
  final String name;
  final String brand;
  final String emoji;
  final int proteinPercent;
  final int pricePerKg;
  final List<String> bestForSpecies;
  final String description;
  final String vendor;
  final String deliveryEstimate;
  final double rating;
  // ---- মূল্যের সত্যতা/উৎস — প্রতিটা প্রোডাক্টের দাম কতটা যাচাইযোগ্য তা
  // স্পষ্টভাবে জানানোর জন্য (দেখুন web/VALIDITY_AND_SOURCES.md)।
  // verified=true মানে প্রকাশিত ডিলার মূল্য-তালিকা থেকে নেওয়া;
  // false মানে বাজারের সাধারণ রেঞ্জ থেকে অনুমান করা, নিশ্চিত না।
  final bool verified;
  final String priceSource;

  const FishFoodProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.emoji,
    required this.proteinPercent,
    required this.pricePerKg,
    required this.bestForSpecies,
    required this.description,
    required this.vendor,
    required this.deliveryEstimate,
    required this.rating,
    this.verified = false,
    this.priceSource = "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  });

  factory FishFoodProduct.fromJson(Map<String, dynamic> j) => FishFoodProduct(
    id: j["id"] as String,
    name: j["name"] as String,
    brand: j["brand"] as String,
    emoji: j["emoji"] as String? ?? "🌾",
    proteinPercent: j["proteinPercent"] as int? ?? 0,
    pricePerKg: j["pricePerKg"] as int? ?? 0,
    bestForSpecies: (j["bestForSpecies"] as List?)?.map((e) => e.toString()).toList() ?? [],
    description: j["description"] as String? ?? "",
    vendor: j["vendor"] as String? ?? "",
    deliveryEstimate: j["deliveryEstimate"] as String? ?? "",
    rating: (j["rating"] as num?)?.toDouble() ?? 4.5,
    verified: j["verified"] as bool? ?? false,
    priceSource: j["priceSource"] as String? ?? "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  );
}

class FoodOrder {
  final String productId;
  final String productName;
  final double quantityKg;
  final int totalPrice;
  final DateTime timestamp;
  String status; // "প্রক্রিয়াধীন" | "নিশ্চিত হয়েছে"

  FoodOrder({
    required this.productId,
    required this.productName,
    required this.quantityKg,
    required this.totalPrice,
    required this.timestamp,
    this.status = "প্রক্রিয়াধীন",
  });

  Map<String, dynamic> toJson() => {
    "productId": productId,
    "productName": productName,
    "quantityKg": quantityKg,
    "totalPrice": totalPrice,
    "timestamp": timestamp.toIso8601String(),
    "status": status,
  };

  factory FoodOrder.fromJson(Map<String, dynamic> j) => FoodOrder(
    productId: j["productId"],
    productName: j["productName"],
    quantityKg: (j["quantityKg"] as num).toDouble(),
    totalPrice: j["totalPrice"],
    timestamp: DateTime.parse(j["timestamp"]),
    status: j["status"] ?? "প্রক্রিয়াধীন",
  );
}

// ------------------------------------------------------------
// Local ফলব্যাক ক্যাটালগ — backend না থাকলে/API ব্যর্থ হলে এটা দেখানো হয়।
// প্রতিটা প্রজাতির জন্য কোন খাবার সবচেয়ে উপযুক্ত সেটা "bestForSpecies"-এ আছে।
// ------------------------------------------------------------
final List<FishFoodProduct> _localCatalog = [
  FishFoodProduct(
    id: "f001",
    name: "গ্রোয়ার পিলেট ফিড (২৮% প্রোটিন)",
    brand: "Narish Feed",
    emoji: "🌾",
    proteinPercent: 28,
    pricePerKg: 49,
    bestForSpecies: ["রুই/কাতলা", "মৃগেল", "গ্রাস কার্প"],
    description: "সাধারণ বৃদ্ধির জন্য সুষম ভাসমান পিলেট ফিড — কার্প জাতীয় মাছের জন্য সবচেয়ে জনপ্রিয় পছন্দ।",
    vendor: "নারিশ অফিসিয়াল ডিলার",
    deliveryEstimate: "১-২ দিন",
    rating: 4.5,
    verified: true,
    priceSource: "নারিশ ফিড প্রকাশিত মূল্য-তালিকা (২০২৬) — amarprio.com",
  ),
  FishFoodProduct(
    id: "f002",
    name: "স্টার্টার পিলেট (৩৫% প্রোটিন)",
    brand: "Narish Feed",
    emoji: "🐣",
    proteinPercent: 35,
    pricePerKg: 51,
    bestForSpecies: ["রুই/কাতলা", "কই", "তেলাপিয়া"],
    description: "পোনা অবস্থায় দ্রুত ও সুস্থ বৃদ্ধির জন্য উচ্চ প্রোটিন সমৃদ্ধ ভাসমান খাবার।",
    vendor: "নারিশ অফিসিয়াল ডিলার",
    deliveryEstimate: "১-২ দিন",
    rating: 4.7,
    verified: true,
    priceSource: "নারিশ ফিড প্রকাশিত মূল্য-তালিকা (২০২৬) — amarprio.com",
  ),
  FishFoodProduct(
    id: "f011",
    name: "নার্সারি পাউডার/মাইক্রো ফিড",
    brand: "Narish Feed",
    emoji: "🍼",
    proteinPercent: 40,
    pricePerKg: 59,
    bestForSpecies: ["রুই/কাতলা", "তেলাপিয়া", "মৃগেল", "কই"],
    description: "একদম ছোট পোনার জন্য গুঁড়া/মাইক্রো দানার খাবার — হ্যাচারি ও নার্সারি পর্যায়ে ব্যবহৃত হয়।",
    vendor: "নারিশ অফিসিয়াল ডিলার",
    deliveryEstimate: "১-২ দিন",
    rating: 4.6,
    verified: true,
    priceSource: "নারিশ ফিড প্রকাশিত মূল্য-তালিকা (২০২৬) — amarprio.com",
  ),
  FishFoodProduct(
    id: "f009",
    name: "সিংকিং (তলদেশে ডোবা) ফিড — সাশ্রয়ী",
    brand: "Narish Feed",
    emoji: "🌾",
    proteinPercent: 20,
    pricePerKg: 43,
    bestForSpecies: ["রুই/কাতলা", "মৃগেল", "পাঙাশ", "কই"],
    description: "তলদেশে ডুবে থাকা সাশ্রয়ী দানাদার ফিড — বাজেট-বান্ধব সাধারণ বিকল্প।",
    vendor: "নারিশ অফিসিয়াল ডিলার",
    deliveryEstimate: "১-২ দিন",
    rating: 4.2,
    verified: true,
    priceSource: "নারিশ ফিড প্রকাশিত মূল্য-তালিকা (২০২৬) — amarprio.com",
  ),
  FishFoodProduct(
    id: "f010",
    name: "প্রিমিয়াম মাল্টি-স্পিসিস গ্রোয়ার",
    brand: "AquaFeed BD",
    emoji: "⭐",
    proteinPercent: 26,
    pricePerKg: 52,
    bestForSpecies: ["রুই/কাতলা", "তেলাপিয়া", "পাঙাশ", "কই", "মৃগেল", "পাবদা"],
    description: "একাধিক প্রজাতির জন্য উপযোগী সাধারণ উদ্দেশ্যের গ্রোয়ার ফিড — মিশ্র চাষে সুবিধাজনক।",
    vendor: "AquaFeed BD",
    deliveryEstimate: "১-২ দিন",
    rating: 4.4,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f013",
    name: "ফিনিশার পিলেট (হার্ভেস্টের আগে, ২৪% প্রোটিন)",
    brand: "Provita",
    emoji: "🏁",
    proteinPercent: 24,
    pricePerKg: 52,
    bestForSpecies: ["রুই/কাতলা", "তেলাপিয়া", "পাঙাশ"],
    description: "হার্ভেস্টের আগে শেষ ধাপে ব্যবহারের জন্য — মাংসের গুণমান ও রং ভালো রাখতে সহায়ক।",
    vendor: "Provita ফিড ডিলার",
    deliveryEstimate: "২-৩ দিন",
    rating: 4.3,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f003",
    name: "ভাসমান (ফ্লোটিং) পিলেট — তেলাপিয়া স্পেশাল",
    brand: "TilaGrow",
    emoji: "🐟",
    proteinPercent: 32,
    pricePerKg: 78,
    bestForSpecies: ["তেলাপিয়া", "কই"],
    description: "পানির উপরে ভেসে থাকে বলে খাওয়ার অপচয় কম হয়, দ্রুত বৃদ্ধির জন্য উপযোগী।",
    vendor: "TilaGrow বাংলাদেশ",
    deliveryEstimate: "১-২ দিন",
    rating: 4.4,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f004",
    name: "ফ্লোটিং ক্যাটফিশ ফিড",
    brand: "PangasFeed",
    emoji: "🐠",
    proteinPercent: 30,
    pricePerKg: 70,
    bestForSpecies: ["পাঙাশ"],
    description: "পাঙাশের খাওয়ার অভ্যাস অনুযায়ী ডিজাইন করা ভাসমান ফিড, কম খরচে ভালো বৃদ্ধি দেয়।",
    vendor: "PangasFeed ডিলার নেটওয়ার্ক",
    deliveryEstimate: "২-৩ দিন",
    rating: 4.3,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f005",
    name: "উচ্চ প্রোটিন ক্যাটফিশ ফিড (৪০%)",
    brand: "CarnivorePro",
    emoji: "🍖",
    proteinPercent: 40,
    pricePerKg: 140,
    bestForSpecies: ["শিং/মাগুর"],
    description: "মাংসাশী প্রজাতির জন্য বিশেষভাবে তৈরি উচ্চ প্রোটিন ফিশমিল ফিড।",
    vendor: "CarnivorePro অফিসিয়াল স্টোর",
    deliveryEstimate: "৩-৪ দিন",
    rating: 4.6,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f012",
    name: "কই মাছের বিশেষ ফ্লোটিং ফিড (৩০%)",
    brand: "Quality Feeds",
    emoji: "🐟",
    proteinPercent: 30,
    pricePerKg: 68,
    bestForSpecies: ["কই"],
    description: "কই মাছের দ্রুত বৃদ্ধি ও ঘনত্বে চাষের জন্য বিশেষভাবে তৈরি ভাসমান ফিড।",
    vendor: "Quality Feeds ডিলার",
    deliveryEstimate: "২-৩ দিন",
    rating: 4.3,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f017",
    name: "পাবদা/টেংরা স্পেশাল ফিড (৩৪%)",
    brand: "CarnivorePro",
    emoji: "🐟",
    proteinPercent: 34,
    pricePerKg: 120,
    bestForSpecies: ["পাবদা"],
    description: "ছোট আকারের উচ্চমূল্যের মাছ (পাবদা, টেংরা) চাষের জন্য বিশেষ পুষ্টি সমৃদ্ধ ফিড।",
    vendor: "CarnivorePro অফিসিয়াল স্টোর",
    deliveryEstimate: "৩-৪ দিন",
    rating: 4.4,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f006",
    name: "প্রাকৃতিক ঘাস-ভিত্তিক ফিড সাপ্লিমেন্ট",
    brand: "GreenPond",
    emoji: "🌿",
    proteinPercent: 18,
    pricePerKg: 40,
    bestForSpecies: ["গ্রাস কার্প"],
    description: "প্রাকৃতিক জলজ ঘাসের পাশাপাশি সম্পূরক হিসেবে ব্যবহারের জন্য সাশ্রয়ী খাবার।",
    vendor: "GreenPond এগ্রো",
    deliveryEstimate: "২-৩ দিন",
    rating: 4.1,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f016",
    name: "সিলভার/গ্রাস কার্প কম্বো ফিড (২২%)",
    brand: "GreenPond",
    emoji: "🌿",
    proteinPercent: 22,
    pricePerKg: 46,
    bestForSpecies: ["সিলভার কার্প", "গ্রাস কার্প"],
    description: "সিলভার ও গ্রাস কার্প একসাথে (পলিকালচার) চাষে ব্যবহারের জন্য সুষম ফিড।",
    vendor: "GreenPond এগ্রো",
    deliveryEstimate: "২-৩ দিন",
    rating: 4.0,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f007",
    name: "প্ল্যাংকটন বুস্টার (জৈব সার-ভিত্তিক)",
    brand: "PlanktoGrow",
    emoji: "🦠",
    proteinPercent: 12,
    pricePerKg: 55,
    bestForSpecies: ["সিলভার কার্প"],
    description: "পুকুরে প্রাকৃতিক প্ল্যাংকটন উৎপাদন বাড়িয়ে সিলভার কার্পের প্রধান খাদ্য উৎস নিশ্চিত করে।",
    vendor: "PlanktoGrow বাংলাদেশ",
    deliveryEstimate: "৩-৫ দিন",
    rating: 4.0,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f008",
    name: "চিংড়ি স্পেশাল পিলেট — গলদা (৩৮%)",
    brand: "GoldaFeed",
    emoji: "🦐",
    proteinPercent: 38,
    pricePerKg: 165,
    bestForSpecies: ["চিংড়ি (গলদা)"],
    description: "গলদা চিংড়ির দ্রুত বৃদ্ধি ও রপ্তানিযোগ্য মান নিশ্চিত করতে বিশেষভাবে তৈরি ফিড।",
    vendor: "GoldaFeed এক্সপোর্ট কোয়ালিটি",
    deliveryEstimate: "৩-৪ দিন",
    rating: 4.8,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f018",
    name: "বাগদা চিংড়ি (লবণ পানি) ফিড (৩৬%)",
    brand: "GoldaFeed",
    emoji: "🦐",
    proteinPercent: 36,
    pricePerKg: 150,
    bestForSpecies: ["চিংড়ি (গলদা)"],
    description: "লবণাক্ত পানির বাগদা চিংড়ি চাষের জন্য বিশেষভাবে তৈরি উচ্চ প্রোটিন ফিড।",
    vendor: "GoldaFeed এক্সপোর্ট কোয়ালিটি",
    deliveryEstimate: "৩-৪ দিন",
    rating: 4.5,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f014",
    name: "ভিটামিন ও মিনারেল প্রিমিক্স",
    brand: "AquaVit",
    emoji: "💊",
    proteinPercent: 0,
    pricePerKg: 250,
    bestForSpecies: ["রুই/কাতলা", "তেলাপিয়া", "পাঙাশ", "কই", "মৃগেল", "শিং/মাগুর", "চিংড়ি (গলদা)"],
    description: "নিয়মিত খাবারের সাথে মিশিয়ে দেওয়ার সম্পূরক — রোগ প্রতিরোধ ক্ষমতা ও বৃদ্ধি বাড়াতে সহায়ক।",
    vendor: "AquaVit হেলথ কেয়ার",
    deliveryEstimate: "৩-৫ দিন",
    rating: 4.2,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
  FishFoodProduct(
    id: "f015",
    name: "প্রোবায়োটিক গাট হেলথ সাপ্লিমেন্ট",
    brand: "AquaVit",
    emoji: "🧪",
    proteinPercent: 0,
    pricePerKg: 300,
    bestForSpecies: ["রুই/কাতলা", "তেলাপিয়া", "পাঙাশ", "কই", "শিং/মাগুর"],
    description: "পরিপাকতন্ত্রের স্বাস্থ্য ভালো রাখে, খাবার হজম ও শোষণ ক্ষমতা বাড়ায় — অল্প পরিমাণে ব্যবহার করতে হয়।",
    vendor: "AquaVit হেলথ কেয়ার",
    deliveryEstimate: "৩-৫ দিন",
    rating: 4.1,
    verified: false,
    priceSource: "আনুমানিক বাজার মূল্য — স্থানীয় ডিলারের কাছে যাচাই করে নিন",
  ),
];

class FishFoodMarketService {
  static const _ordersKey = "fishpanda_orders_v1";

  /// প্রজাতি অনুযায়ী (বা সব) খাবারের তালিকা আনে।
  /// আগে real API-তে চেষ্টা করে (backend থাকলে), ব্যর্থ/timeout হলে
  /// নীরবে local catalog ব্যবহার করে — তাই এখনই কাজ করবে,
  /// backend বসানোর পর কোনো UI কোড না পাল্টিয়েই লাইভ ডেটা আসবে।
  static Future<List<FishFoodProduct>> fetchProducts({String? species}) async {
    try {
      final uri = Uri.parse("$kFoodApiBaseUrl/food-market/products").replace(
        queryParameters: species != null ? {"species": species} : null,
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => FishFoodProduct.fromJson(e)).toList();
      }
    } catch (_) {
      // backend এখনো নেই / নেটওয়ার্ক নেই — নিচে local catalog দিয়ে fallback হবে
    }

    await Future.delayed(const Duration(milliseconds: 350)); // বাস্তব লোডিং অনুভূতির জন্য
    if (species == null || species.isEmpty) return List.of(_localCatalog);
    final matched = _localCatalog.where((p) => p.bestForSpecies.contains(species)).toList();
    return matched.isNotEmpty ? matched : List.of(_localCatalog);
  }

  /// অর্ডার বসানো — এখন local storage-এ সেভ হয় (demo)।
  /// TODO(backend): এখানে real order/payment API কল বসাতে হবে
  /// (যেমন POST $kFoodApiBaseUrl/food-market/orders), তাহলে সত্যিকারের
  /// অর্ডার ট্র্যাকিং, পেমেন্ট ও ডেলিভারি কাজ করবে।
  static Future<FoodOrder> placeOrder(FishFoodProduct product, double quantityKg) async {
    final order = FoodOrder(
      productId: product.id,
      productName: product.name,
      quantityKg: quantityKg,
      totalPrice: (product.pricePerKg * quantityKg).round(),
      timestamp: DateTime.now(),
    );

    try {
      final uri = Uri.parse("$kFoodApiBaseUrl/food-market/orders");
      await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(order.toJson()),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // backend নেই — শুধু local এ সেভ হয়ে থাকবে (নিচে)
    }

    final orders = await loadOrders();
    orders.insert(0, order);
    await _saveOrders(orders);
    return order;
  }

  static Future<List<FoodOrder>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => FoodOrder.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveOrders(List<FoodOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = orders.length > 30 ? orders.sublist(0, 30) : orders;
    await prefs.setString(_ordersKey, jsonEncode(trimmed.map((o) => o.toJson()).toList()));
  }
}