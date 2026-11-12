// ============================================================
// AquaGuard AI — Core Data Models
// ============================================================

class Farmer {
  String name;
  String phone;
  String district;
  bool subscribed;
  DateTime? subscribedSince;

  Farmer({
    this.name = "",
    this.phone = "",
    this.district = "চট্টগ্রাম",
    this.subscribed = false,
    this.subscribedSince,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "phone": phone,
        "district": district,
        "subscribed": subscribed,
        "subscribedSince": subscribedSince?.toIso8601String(),
      };

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
        name: json["name"] ?? "",
        phone: json["phone"] ?? "",
        district: json["district"] ?? "চট্টগ্রাম",
        subscribed: json["subscribed"] ?? false,
        subscribedSince: json["subscribedSince"] != null
            ? DateTime.tryParse(json["subscribedSince"])
            : null,
      );
}

class PondSetup {
  String farmName;
  String pondName;
  double sizeDecimal;
  int quantity;
  String species;
  String stockingDate;

  PondSetup({
    this.farmName = "রহিম ফিশ ফার্ম",
    this.pondName = "পুকুর ১",
    this.sizeDecimal = 50,
    this.quantity = 3000,
    this.species = "রুই/কাতলা",
    this.stockingDate = "2026-06-15",
  });

  Map<String, dynamic> toJson() => {
        "farmName": farmName,
        "pondName": pondName,
        "sizeDecimal": sizeDecimal,
        "quantity": quantity,
        "species": species,
        "stockingDate": stockingDate,
      };

  factory PondSetup.fromJson(Map<String, dynamic> json) => PondSetup(
        farmName: json["farmName"] ?? "রহিম ফিশ ফার্ম",
        pondName: json["pondName"] ?? "পুকুর ১",
        sizeDecimal: (json["sizeDecimal"] ?? 50).toDouble(),
        quantity: json["quantity"] ?? 3000,
        species: json["species"] ?? "রুই/কাতলা",
        stockingDate: json["stockingDate"] ?? "2026-06-15",
      );
}

class WaterReading {
  final DateTime timestamp;
  final String day;
  final double ph;
  final double doLevel; // dissolved oxygen
  final double temp;
  final double ammonia;
  final double? turbidity;
  final double? nitrite;
  final double? nitrate;
  final double? alkalinity;
  final double? salinity;

  WaterReading({
    required this.timestamp,
    required this.day,
    required this.ph,
    required this.doLevel,
    required this.temp,
    required this.ammonia,
    this.turbidity,
    this.nitrite,
    this.nitrate,
    this.alkalinity,
    this.salinity,
  });

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp.toIso8601String(),
        "day": day,
        "ph": ph,
        "do": doLevel,
        "temp": temp,
        "ammonia": ammonia,
        "turbidity": turbidity,
        "nitrite": nitrite,
        "nitrate": nitrate,
        "alkalinity": alkalinity,
        "salinity": salinity,
      };

  factory WaterReading.fromJson(Map<String, dynamic> json) => WaterReading(
        timestamp: DateTime.parse(json["timestamp"]),
        day: json["day"],
        ph: (json["ph"] as num).toDouble(),
        doLevel: (json["do"] as num).toDouble(),
        temp: (json["temp"] as num).toDouble(),
        ammonia: (json["ammonia"] as num).toDouble(),
        turbidity: (json["turbidity"] as num?)?.toDouble(),
        nitrite: (json["nitrite"] as num?)?.toDouble(),
        nitrate: (json["nitrate"] as num?)?.toDouble(),
        alkalinity: (json["alkalinity"] as num?)?.toDouble(),
        salinity: (json["salinity"] as num?)?.toDouble(),
      );
}

class FishScanResult {
  final DateTime timestamp;
  final bool uncertain;
  final double confidence;
  final String? diseaseId;
  final String? name;
  final String? level; // ভালো / সতর্ক / ঝুঁকি / বিপদ
  final List<String> signs;
  final List<String> causes;
  final List<String> pondActions;
  final String? expertNote;
  final bool? healthy; // true = healthy, false = disease detected, null = uncertain
  final String? imagePath;

  FishScanResult({
    required this.timestamp,
    required this.uncertain,
    required this.confidence,
    this.diseaseId,
    this.name,
    this.level,
    this.signs = const [],
    this.causes = const [],
    this.pondActions = const [],
    this.expertNote,
    this.healthy,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp.toIso8601String(),
        "uncertain": uncertain,
        "confidence": confidence,
        "diseaseId": diseaseId,
        "name": name,
        "level": level,
        "signs": signs,
        "causes": causes,
        "pondActions": pondActions,
        "expertNote": expertNote,
        "healthy": healthy,
        "imagePath": imagePath,
      };

  factory FishScanResult.fromJson(Map<String, dynamic> json) => FishScanResult(
        timestamp: DateTime.parse(json["timestamp"]),
        uncertain: json["uncertain"] ?? false,
        confidence: (json["confidence"] as num).toDouble(),
        diseaseId: json["diseaseId"],
        name: json["name"],
        level: json["level"],
        signs: List<String>.from(json["signs"] ?? []),
        causes: List<String>.from(json["causes"] ?? []),
        pondActions: List<String>.from(json["pondActions"] ?? []),
        expertNote: json["expertNote"],
        healthy: json["healthy"],
        imagePath: json["imagePath"],
      );
}

class FeedEntry {
  final DateTime timestamp;
  final double amountKg;
  final String note;

  FeedEntry({required this.timestamp, required this.amountKg, this.note = ""});

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp.toIso8601String(),
        "amountKg": amountKg,
        "note": note,
      };

  factory FeedEntry.fromJson(Map<String, dynamic> json) => FeedEntry(
        timestamp: DateTime.parse(json["timestamp"]),
        amountKg: (json["amountKg"] as num).toDouble(),
        note: json["note"] ?? "",
      );
}

class GrowthEntry {
  final DateTime timestamp;
  final String week;
  final double weightG;
  final double? lengthCm;

  GrowthEntry({required this.timestamp, required this.week, required this.weightG, this.lengthCm});

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp.toIso8601String(),
        "week": week,
        "weightG": weightG,
        "lengthCm": lengthCm,
      };

  factory GrowthEntry.fromJson(Map<String, dynamic> json) => GrowthEntry(
        timestamp: DateTime.parse(json["timestamp"]),
        week: json["week"],
        weightG: (json["weightG"] as num).toDouble(),
        lengthCm: json["lengthCm"] == null ? null : (json["lengthCm"] as num).toDouble(),
      );
}

class AppAlert {
  final DateTime timestamp;
  final String title;
  final String message;
  final String level; // ভালো / সতর্ক / ঝুঁকি / বিপদ
  bool read;

  AppAlert({
    required this.timestamp,
    required this.title,
    required this.message,
    required this.level,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp.toIso8601String(),
        "title": title,
        "message": message,
        "level": level,
        "read": read,
      };

  factory AppAlert.fromJson(Map<String, dynamic> json) => AppAlert(
        timestamp: DateTime.parse(json["timestamp"]),
        title: json["title"],
        message: json["message"],
        level: json["level"],
        read: json["read"] ?? false,
      );
}
