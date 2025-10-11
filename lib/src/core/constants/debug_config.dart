class DebugConfig {
  // Set to true to enable debug mode with mock authentication
  static const bool isDebugMode = false;
  
  // Mock phone number for testing (only works in debug mode)
  static const String mockPhoneNumber = '+1234567890';
  static const String mockOtp = '123456';
  
  // Mock user credentials for testing
  static const String mockEmail = 'test@hackethos4u.com';
  static const String mockPassword = 'password123';
  static const String mockName = 'Test User';
  
  // Check if we should use mock authentication
  static bool shouldUseMockAuth() {
    return isDebugMode;
  }
  
  // Get mock verification ID for testing
  static String getMockVerificationId() {
    return 'mock_verification_id_12345';
  }
}
