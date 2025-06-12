import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Prints a boxed representation of the given [value] to the console.
/// If [label] is provided, it will be displayed at the top of the box.
///
/// This function is intended for debugging purposes and is only active in debug mode.
/// Using this function should have no side effects such as mutations
@pragma('vm:prefer-inline')
void printBoxed(Object? value, [String? label]) {
  if (kDebugMode) {
    _printBoxed(value, label);
  }
}

void _printBoxed(Object? value, [String? label]) {
  const maxLength = 160;

  final lines = value.toString().split('\n');
  final longestLength = max(label?.length ?? 0, lines.map((e) => e.length).fold(0, max));
  final followedLength = min(longestLength + 2, maxLength);

  final truncatedLabel = label != null && label.isNotEmpty //
      ? label.length > followedLength
          ? ' ${label.substring(0, followedLength - 5)}... '
          : " $label "
      : '';

  final truncatedLines = lines.map((e) => e.length > followedLength //
      ? '${e.substring(0, followedLength - 5)}...'
      : e);

  final buffer = StringBuffer()
    ..writeln(
        '+$truncatedLabel${'-' * (followedLength - (truncatedLabel.isNotEmpty ? truncatedLabel.length + 2 : 0))}+');

  for (final line in truncatedLines) {
    buffer.writeln('| $line ${' ' * (followedLength - (line.length + 2))}|');
  }
  buffer.writeln('+${'-' * followedLength}+');

  stdout.write(buffer);
}
