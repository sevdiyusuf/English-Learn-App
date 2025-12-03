/// Input validation utilities for user inputs
class InputValidator {
  /// Validates a word input
  /// Returns null if valid, error message if invalid
  static String? validateWord(String word) {
    if (word.isEmpty) {
      return 'Kelime boş olamaz';
    }

    // Trim whitespace
    final trimmed = word.trim();
    if (trimmed.isEmpty) {
      return 'Kelime sadece boşluk içeremez';
    }

    // Check length (reasonable limits)
    if (trimmed.length < 2) {
      return 'Kelime en az 2 karakter olmalıdır';
    }
    if (trimmed.length > 50) {
      return 'Kelime en fazla 50 karakter olabilir';
    }

    // Check for XSS patterns (basic protection)
    if (_containsXSSPattern(trimmed)) {
      return 'Geçersiz karakterler içeriyor';
    }

    // Check for only whitespace or special characters
    if (!_containsValidCharacters(trimmed)) {
      return 'Kelime geçerli karakterler içermelidir';
    }

    return null; // Valid
  }

  /// Sanitizes a word input (removes dangerous characters)
  static String sanitizeWord(String word) {
    // Remove HTML tags and script content
    String sanitized = word
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '') // Remove javascript: protocol
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), ''); // Remove event handlers

    // Trim and normalize whitespace
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');

    return sanitized;
  }

  /// Checks if input contains XSS patterns
  static bool _containsXSSPattern(String input) {
    final xssPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // Event handlers
      RegExp(r'<iframe', caseSensitive: false),
      RegExp(r'<object', caseSensitive: false),
      RegExp(r'<embed', caseSensitive: false),
      RegExp(r'<link', caseSensitive: false),
      RegExp(r'<style', caseSensitive: false),
    ];

    for (final pattern in xssPatterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }

    return false;
  }

  /// Checks if input contains valid characters (letters, numbers, basic punctuation)
  static bool _containsValidCharacters(String input) {
    // Allow letters (including Turkish characters), numbers, spaces, and basic punctuation
    final validPattern = RegExp(r'^[a-zA-ZçğıöşüÇĞİÖŞÜ0-9\s\-\.]+$');
    return validPattern.hasMatch(input);
  }

  /// Validates room code format
  static String? validateRoomCode(String code) {
    if (code.isEmpty) {
      return 'Oda kodu boş olamaz';
    }

    final trimmed = code.trim().toUpperCase();
    
    // Room codes should be 4-6 alphanumeric characters
    if (trimmed.length < 4 || trimmed.length > 6) {
      return 'Oda kodu 4-6 karakter olmalıdır';
    }

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(trimmed)) {
      return 'Oda kodu sadece harf ve rakam içerebilir';
    }

    return null;
  }

  /// Validates username
  static String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'Kullanıcı adı boş olamaz';
    }

    final trimmed = username.trim();
    
    if (trimmed.length < 2) {
      return 'Kullanıcı adı en az 2 karakter olmalıdır';
    }

    if (trimmed.length > 20) {
      return 'Kullanıcı adı en fazla 20 karakter olabilir';
    }

    if (_containsXSSPattern(trimmed)) {
      return 'Geçersiz karakterler içeriyor';
    }

    return null;
  }
}

