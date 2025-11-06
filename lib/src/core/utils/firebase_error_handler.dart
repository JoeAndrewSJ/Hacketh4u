class FirebaseErrorHandler {
  /// Convert Firebase error codes to user-friendly messages
  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      // Authentication Errors
      case 'user-not-found':
        return 'No account found with this email address.\nPlease check your email or sign up for a new account.';

      case 'wrong-password':
        return 'Wrong password.\nPlease try again or reset your password using "Forgot Password".';

      case 'invalid-email':
        return 'Invalid email address.\nPlease enter a valid email address.';

      case 'email-already-in-use':
        return ' Email already registered.\nAn account with this email already exists. Please try logging in instead.';

      case 'weak-password':
        return 'Password too weak.\nPlease choose a stronger password with at least 6 characters.';

      case 'user-disabled':
        return 'Account disabled.\nThis account has been disabled. Please contact support for assistance.';

      case 'too-many-requests':
        return ' Too many failed attempts.\nPlease wait a few minutes and try again.';

      case 'operation-not-allowed':
        return '  Sign-in method not enabled.\nPlease contact support for assistance.';

      case 'invalid-credential':
        return '  Invalid email or password.\nPlease check your credentials and try again.';

      case 'account-exists-with-different-credential':
        return '  Email already in use.\nAn account already exists with this email but uses a different sign-in method.';

      case 'credential-already-in-use':
        return '  Credential already in use.\nThis credential is already associated with a different account.';

      case 'invalid-verification-code':
        return '  Invalid OTP code.\nPlease check the 6-digit code and try again.';

      case 'invalid-verification-id':
        return '  Verification expired.\nPlease request a new verification code.';

      case 'missing-verification-code':
        return '  Missing verification code.\nPlease enter the 6-digit code sent to your phone.';

      case 'missing-verification-id':
        return '  Session expired.\nPlease request a new verification code.';

      case 'phone-number-already-exists':
        return '  Phone number already registered.\nAn account with this phone number already exists.';

      case 'invalid-phone-number':
        return '  Invalid phone number.\nPlease enter a valid 10-digit phone number.';

      case 'missing-phone-number':
        return '  Phone number required.\nPlease enter your phone number.';

      case 'quota-exceeded':
        return '⏳ Too many requests.\nPlease try again after some time.';

      case 'network-request-failed':
        return '📡 Network error.\nPlease check your internet connection and try again.';

      case 'requires-recent-login':
        return '🔒 Authentication required.\nThis operation requires you to log in again.';

      case 'session-expired':
        return '⏰ Session expired.\nYour OTP has expired. Please request a new one.';
      
      // Generic Errors
      case 'unknown':
        return '  An unexpected error occurred.\nPlease try again or contact support if the issue persists.';

      case 'internal-error':
        return '⚠️ Internal server error.\nPlease try again later.';

      default:
        // For unknown error codes, provide a generic message
        if (errorCode.toLowerCase().contains('network')) {
          return '📡 Network error.\nPlease check your internet connection and try again.';
        } else if (errorCode.toLowerCase().contains('timeout')) {
          return '⏳ Request timed out.\nPlease check your connection and try again.';
        } else if (errorCode.toLowerCase().contains('permission')) {
          return '🔒 Permission denied.\nPlease contact support for assistance.';
        } else {
          return '  An error occurred.\nPlease try again. If the problem persists, contact support.';
        }
    }
  }

  /// Extract error code from Firebase exception message
  static String extractErrorCode(String errorMessage) {
    // Firebase error messages typically contain the error code in brackets
    final RegExp errorCodeRegex = RegExp(r'\[([^\]]+)\]');
    final match = errorCodeRegex.firstMatch(errorMessage);
    
    if (match != null) {
      return match.group(1) ?? 'unknown';
    }
    
    // If no brackets found, check for common error patterns
    if (errorMessage.toLowerCase().contains('user-not-found')) {
      return 'user-not-found';
    } else if (errorMessage.toLowerCase().contains('wrong-password')) {
      return 'wrong-password';
    } else if (errorMessage.toLowerCase().contains('invalid-email')) {
      return 'invalid-email';
    } else if (errorMessage.toLowerCase().contains('email-already-in-use')) {
      return 'email-already-in-use';
    } else if (errorMessage.toLowerCase().contains('weak-password')) {
      return 'weak-password';
    } else if (errorMessage.toLowerCase().contains('network')) {
      return 'network-request-failed';
    } else if (errorMessage.toLowerCase().contains('timeout')) {
      return 'timeout';
    }
    
    return 'unknown';
  }

  /// Get user-friendly error message from raw Firebase error
  static String getUserFriendlyMessage(String rawErrorMessage) {
    final errorCode = extractErrorCode(rawErrorMessage);
    return getErrorMessage(errorCode);
  }
}
