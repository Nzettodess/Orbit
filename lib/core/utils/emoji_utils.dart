// Utility functions for handling emojis in text.
// This was previously duplicated in home.dart, detail_modal.dart, and profile.dart.

/// Remove emojis from text for display or sorting purposes.
/// Preserves all non-emoji characters including spaces and punctuation.
String stripEmojis(String text) {
  // Unicode ranges for common emojis
  final emojiPattern = RegExp(
    r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]',
    unicode: true,
  );
  return text.replaceAll(emojiPattern, '').trim();
}

/// Check if a string contains any emojis
bool containsEmoji(String text) {
  final emojiPattern = RegExp(
    r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]',
    unicode: true,
  );
  return emojiPattern.hasMatch(text);
}

/// Get the first emoji from a string, or null if none
String? getFirstEmoji(String text) {
  final emojiPattern = RegExp(
    r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]',
    unicode: true,
  );
  final match = emojiPattern.firstMatch(text);
  return match?.group(0);
}
