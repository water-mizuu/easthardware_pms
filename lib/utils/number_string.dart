extension NumberStringExtension on num {
  String toNumberString() {
    if (this == toInt()) {
      return toInt().toString();
    } else {
      return toStringAsFixed(2);
    }
  }

  String toFileSizeString() {
    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    // Format with appropriate decimal places
    String formatted;
    if (size >= 100) {
      formatted = size.toStringAsFixed(0);
    } else if (size >= 10) {
      formatted = size.toStringAsFixed(1);
    } else {
      formatted = size.toStringAsFixed(2);
    }

    return '$formatted ${units[unitIndex]}';
  }
}
