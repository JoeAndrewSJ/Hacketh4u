import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Test keys - use these for testing with test cards
  static String get razorpayKeyId => 'rzp_test_RQi6JOIl21GQew';
  static String get razorpayKeySecret => '4gSuxwep1DiAuCsryyJUmtAZ';

  // Live keys - use these for real payments
  // static String get razorpayKeyId =>  'rzp_live_RQhzptiNU4dxo7';
  // static String get razorpayKeySecret =>  'Tglh8ieT8q4G3OlIkRG0voOo';

  static bool get isRazorpayConfigured =>
      razorpayKeyId.isNotEmpty && razorpayKeySecret.isNotEmpty;
}
