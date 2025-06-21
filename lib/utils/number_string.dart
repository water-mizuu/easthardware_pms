extension NumberStringExtension on num {
  String toNumberString() {
    if (this == toInt()) {
      return toInt().toString();
    } else {
      return toStringAsFixed(2);
    }
  }
}
