// ============================================================
// SubscriptionService — bdApps OTP + Subscription API
// ============================================================
// Quizora-এর lib/api/api_endpoints.dart + lib/provider/subscription_provider.dart
// এর সমতুল্য, কিন্তু প্রজেক্টে আগে থেকে থাকা `package:http` স্টাইলে লেখা
// (ApiService.dart-এর মতোই), যাতে আলাদা করে Dio যোগ করতে না হয়।
//
// এই ফাইলটা AquaGuard-এর নিজের PHP backend (backend_reference ফোল্ডারের
// send_otp.php / verify_otp.php / check_subscription.php / unsubscribe.php)
// কে কল করে — bdApps-এর সার্ভারকে কখনো সরাসরি কল করে না।
//
// baseUrl বদলানো ছাড়া এই ফাইলে আর কিছু বদলানোর দরকার নেই।
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class SubscriptionApiEndpoints {
  // AquaGuard-এর জন্য cPanel-এ আলাদা করে বানানো ফোল্ডার — লক্ষ্য করো এটা
  // "Nadb26143" (ছোট হাতের), Quizora-র "NADB26143" (বড় হাতের) থেকে আলাদা।
  // Linux সার্ভারে case-sensitive হওয়ায় এই দুটো সম্পূর্ণ আলাদা ফোল্ডার —
  // তাই Quizora-র লাইভ ফাইলের সাথে কোনো conflict নেই।
  static const String baseUrl =
      "https://bdappsdigitalapps.com/Nadb26143";

  static const String sendOtpUrl = "$baseUrl/send_otp.php";
  static const String verifyOtpUrl = "$baseUrl/verify_otp.php";
  static const String checkSubscriptionUrl = "$baseUrl/check_subscription.php";
  static const String unsubscribeUrl = "$baseUrl/unsubscribe.php";
}

class SubscriptionResult {
  final bool success;
  final String? referenceNo;
  final String? statusCode;
  final String? statusDetail;
  final bool alreadySubscribed;
  final String? subscriptionStatus;
  final String message;

  SubscriptionResult({
    required this.success,
    this.referenceNo,
    this.statusCode,
    this.statusDetail,
    this.alreadySubscribed = false,
    this.subscriptionStatus,
    this.message = "",
  });

  @override
  String toString() =>
      "SubscriptionResult(success:$success, statusCode:$statusCode, message:$message)";
}

class SubscriptionService {
  static const _timeout = Duration(seconds: 20);

  // ------------------------------------------------------------
  // ১. OTP পাঠানো — ফোন নম্বর দিয়ে
  // ------------------------------------------------------------
  static Future<SubscriptionResult> sendOtp(String phone) async {
    try {
      final res = await http
          .post(
            Uri.parse(SubscriptionApiEndpoints.sendOtpUrl),
            body: {"user_mobile": phone},
          )
          .timeout(_timeout);

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

      return SubscriptionResult(
        success: body["success"] == true,
        referenceNo: body["referenceNo"]?.toString(),
        statusCode: body["statusCode"]?.toString(),
        statusDetail: body["statusDetail"]?.toString(),
        alreadySubscribed: body["alreadySubscribed"] == true,
        message: body["message"]?.toString() ?? "",
      );
    } catch (e) {
      return SubscriptionResult(success: false, message: "OTP পাঠাতে সমস্যা হয়েছে: $e");
    }
  }

  // ------------------------------------------------------------
  // ২. OTP ভেরিফাই — এখানেই আসল সাবস্ক্রিপশন অ্যাক্টিভেট হয়
  // ------------------------------------------------------------
  static Future<SubscriptionResult> verifyOtp(String otp, String referenceNo) async {
    try {
      final res = await http
          .post(
            Uri.parse(SubscriptionApiEndpoints.verifyOtpUrl),
            body: {"Otp": otp, "referenceNo": referenceNo},
          )
          .timeout(_timeout);

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final statusCode = body["statusCode"]?.toString() ?? "";

      return SubscriptionResult(
        success: statusCode == "S1000",
        statusCode: statusCode,
        statusDetail: body["statusDetail"]?.toString(),
        subscriptionStatus: body["subscriptionStatus"]?.toString(),
        message: body["statusDetail"]?.toString() ?? "",
      );
    } catch (e) {
      return SubscriptionResult(success: false, message: "OTP ভেরিফাই করতে সমস্যা হয়েছে: $e");
    }
  }

  // ------------------------------------------------------------
  // ৩. সাবস্ক্রিপশন স্ট্যাটাস চেক
  // ------------------------------------------------------------
  static Future<SubscriptionResult> checkStatus(String phone) async {
    try {
      final res = await http
          .post(
            Uri.parse(SubscriptionApiEndpoints.checkSubscriptionUrl),
            body: {"user_mobile": phone},
          )
          .timeout(_timeout);

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

      return SubscriptionResult(
        success: body["isSubscribed"] == true,
        subscriptionStatus: body["subscriptionStatus"]?.toString(),
        statusCode: body["statusCode"]?.toString(),
        statusDetail: body["statusDetail"]?.toString(),
      );
    } catch (e) {
      return SubscriptionResult(success: false, message: "স্ট্যাটাস চেক করতে সমস্যা হয়েছে: $e");
    }
  }

  // ------------------------------------------------------------
  // ৪. আনসাবস্ক্রাইব
  // ------------------------------------------------------------
  static Future<SubscriptionResult> unsubscribe(String phone) async {
    try {
      final res = await http
          .post(
            Uri.parse(SubscriptionApiEndpoints.unsubscribeUrl),
            body: {"user_mobile": phone},
          )
          .timeout(_timeout);

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

      return SubscriptionResult(
        success: body["success"] == true,
        subscriptionStatus: body["subscriptionStatus"]?.toString(),
        statusCode: body["statusCode"]?.toString(),
        statusDetail: body["statusDetail"]?.toString(),
        message: body["statusDetail"]?.toString() ?? "",
      );
    } catch (e) {
      return SubscriptionResult(success: false, message: "আনসাবস্ক্রাইব করতে সমস্যা হয়েছে: $e");
    }
  }
}
