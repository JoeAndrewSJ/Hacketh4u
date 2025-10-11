class PhoneUtils {
  /// Formats phone number with country code if not present
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If already has country code (starts with country code), return as is
    if (cleaned.length >= 10) {
      // Check if it starts with a country code
      if (cleaned.length == 10) {
        // Assume US number if 10 digits
        return '+1$cleaned';
      } else if (cleaned.length > 10) {
        // Has country code
        return '+$cleaned';
      }
    }
    
    // If less than 10 digits, it's invalid
    if (cleaned.length < 10) {
      throw Exception('Phone number must be at least 10 digits');
    }
    
    return '+$cleaned';
  }
  
  /// Validates phone number format
  static bool isValidPhoneNumber(String phoneNumber) {
    final formatted = formatPhoneNumber(phoneNumber);
    // Basic validation: should start with + and have 10-15 digits after country code
    return RegExp(r'^\+\d{10,15}$').hasMatch(formatted);
  }
  
  /// Gets country code from phone number
  static String getCountryCode(String phoneNumber) {
    final formatted = formatPhoneNumber(phoneNumber);
    final match = RegExp(r'^\+(\d{1,4})').firstMatch(formatted);
    return match?.group(1) ?? '';
  }
  
  /// Formats phone number for display
  static String formatForDisplay(String phoneNumber) {
    try {
      final formatted = formatPhoneNumber(phoneNumber);
      final countryCode = getCountryCode(formatted);
      
      // Ensure we have enough characters for the country code + 1
      if (formatted.length <= countryCode.length + 1) {
        return formatted; // Return as is if too short
      }
      
      final number = formatted.substring(countryCode.length + 1); // +1 for the +
      
      if (countryCode == '1' && number.length == 10) {
        // US format: +1 (XXX) XXX-XXXX
        return '+$countryCode (${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6)}';
      } else if (countryCode == '91' && number.length == 10) {
        // India format: +91 XXXXX XXXXX
        return '+$countryCode ${number.substring(0, 5)} ${number.substring(5)}';
      }
      
      // Default format
      return formatted;
    } catch (e) {
      // If any error occurs, return the original phone number
      return phoneNumber;
    }
  }
}
