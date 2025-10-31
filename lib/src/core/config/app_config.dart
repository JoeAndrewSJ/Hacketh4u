import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Temporarily hardcoded for testing - replace with environment variables later
  static String get razorpayKeyId => 'rzp_test_RQi6JOIl21GQew';
  static String get razorpayKeySecret => '4gSuxwep1DiAuCsryyJUmtAZ';
  
  static bool get isRazorpayConfigured => 
      razorpayKeyId.isNotEmpty && razorpayKeySecret.isNotEmpty;
}
