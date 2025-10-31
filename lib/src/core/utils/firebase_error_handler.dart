class FirebaseErrorHandler {
  /// Convert Firebase error codes to user-friendly messages
  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      // Authentication Errors
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or sign up for a new account.';
      
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      
      case 'invalid-email':
        return 'Please enter a valid email address.';
      
      case 'email-already-in-use':
        return 'An account with this email already exists. Please try logging in instead.';
      
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password with at least 6 characters.';
      
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method.';
      
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check the code and try again.';
      
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please request a new verification code.';
      
      case 'missing-verification-code':
        return 'Please enter the verification code.';
      
      case 'missing-verification-id':
        return 'Verification ID is missing. Please request a new verification code.';
      
      case 'phone-number-already-exists':
        return 'An account with this phone number already exists.';
      
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      
      case 'missing-phone-number':
        return 'Please enter your phone number.';
      
      case 'quota-exceeded':
        return 'Too many requests. Please try again later.';
      
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      
      // Generic Errors
      case 'unknown':
        return 'An unexpected error occurred. Please try again.';
      
      case 'internal-error':
        return 'Internal server error. Please try again later.';
      
      default:
        // For unknown error codes, provide a generic message
        if (errorCode.toLowerCase().contains('network')) {
          return 'Network error. Please check your internet connection and try again.';
        } else if (errorCode.toLowerCase().contains('timeout')) {
          return 'Request timed out. Please try again.';
        } else if (errorCode.toLowerCase().contains('permission')) {
          return 'Permission denied. Please contact support.';
        } else {
          return 'An error occurred. Please try again.';
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
