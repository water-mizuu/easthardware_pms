extension DurationHelpersExtension<N extends num> on N {
  /// Converts the number to a Duration in seconds.
  Duration get seconds => Duration(seconds: toInt());
  Duration get sec => seconds;

  /// Converts the number to a Duration in minutes.
  Duration get minutes => Duration(minutes: toInt());

  /// Converts the number to a Duration in hours.
  Duration get hours => Duration(hours: toInt());

  /// Converts the number to a Duration in days.
  Duration get days => Duration(days: toInt());

  /// Converts the number to a Duration in milliseconds.
  Duration get milliseconds => Duration(milliseconds: toInt());
  Duration get ms => milliseconds;

  /// Converts the number to a Duration in microseconds.
  Duration get microseconds => Duration(microseconds: toInt());
}
