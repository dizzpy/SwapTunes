/// Common input validators for SwapTunes forms.
///
/// Used by profile setup, post creation, and other input screens.
class Validators {
  Validators._();

  /// Validates that the value is not null or empty.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates username: min 3 chars, alphanumeric + underscores only.
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  /// Validates full name: min 1 character.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  /// Validates genre selection: minimum 3 genres.
  static String? genres(Set<String> selected) {
    if (selected.length < 3) {
      return 'Please select at least 3 genres';
    }
    return null;
  }

  /// Validates post content: min 1 char, max 1000 chars.
  static String? postContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Post content is required';
    }
    if (value.trim().length > 1000) {
      return 'Post content cannot exceed 1000 characters';
    }
    return null;
  }

  /// Validates comment content: min 1 char, max 500 chars.
  static String? commentContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Comment cannot be empty';
    }
    if (value.trim().length > 500) {
      return 'Comment cannot exceed 500 characters';
    }
    return null;
  }

  /// Validates optional URL fields.
  static String? optionalUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      return 'Please enter a valid URL';
    }
    return null;
  }
}
