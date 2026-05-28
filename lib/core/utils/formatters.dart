/// Phone number and identifier formatting utilities for BikeBuddy.
class Formatters {
  /// Normalizes a Kenyan phone number into the standard DB format: `254xxxxxxxxx`.
  /// 
  /// Supports:
  /// - `0701343452` -> `254701343452`
  /// - `+254701343452` -> `254701343452`
  /// - `701343452` -> `254701343452`
  /// - `254701343452` -> `254701343452`
  static String? normalizePhoneNumber(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    
    // Strip everything except digits
    String cleaned = input.replaceAll(RegExp(r'\D'), '');
    
    // If it starts with 254 and has 12 digits, it is already fully normalized
    if (cleaned.startsWith('254') && cleaned.length == 12) {
      return cleaned;
    }
    
    // If it starts with 0 and has 10 digits (e.g., 0701343452 -> 701343452)
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '254${cleaned.substring(1)}';
    }
    
    // If it is 9 digits (e.g., 701343452)
    if (cleaned.length == 9) {
      return '254$cleaned';
    }
    
    return cleaned;
  }

  /// Validates standard Kenyan phone formats.
  static bool isValidPhoneNumber(String? input) {
    if (input == null || input.trim().isEmpty) return false;
    final normalized = normalizePhoneNumber(input);
    if (normalized == null) return false;
    
    // Normalized number should be exactly 12 digits starting with 254
    return RegExp(r'^254\d{9}$').hasMatch(normalized);
  }

  /// Validates National ID or Admission / Registration numbers.
  /// - National ID: 7 to 9 digits.
  /// - Admission: Alphanumeric with optional slashes, dashes, dots, length 4 to 20.
  static bool isValidIdOrAdmission(String? input) {
    if (input == null || input.trim().isEmpty) return false;
    final cleaned = input.trim();
    
    // Check if it's a numeric national ID (7 to 9 digits)
    final isNationalId = RegExp(r'^\d{7,9}$').hasMatch(cleaned);
    if (isNationalId) return true;
    
    // Check if it's an admission number (alphanumeric, allowing / - . and length 4 to 20)
    final isAdmission = RegExp(r'^[a-zA-Z0-9\/\-\.]{4,20}$').hasMatch(cleaned);
    
    // Must contain at least one character (letter or number)
    return isAdmission;
  }
}
