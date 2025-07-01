extension CompareLowercaseExtension on String {
  /// Compares two strings in a case-insensitive manner.
  int compareToLowercase(String other) {
    return toLowerCase().compareTo(other.toLowerCase());
  }
}
