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
  const maxLength = 80;
  const minContentWidth = 10; // Minimum content width inside the box

  // Calculate the maximum content width (accounting for borders: | content |)
  const maxContentWidth = maxLength - 4; // 2 for borders + 2 for spaces

  final lines = value.toString().split('\n');
  final longestLineLength = lines.map((e) => e.length).fold(0, max);
  final labelLength = label?.length ?? 0; // Determine the actual content width we'll use
  final contentWidth = min(
    max(max(longestLineLength, labelLength), minContentWidth),
    maxContentWidth,
  );

  // Total box width (content + borders and spaces)
  final boxWidth = contentWidth + 4;

  // Prepare the label for the top border
  final truncatedLabel = label != null && label.isNotEmpty
      ? label.length > contentWidth
          ? ' ${label.substring(0, contentWidth - 4)}... '
          : ' $label '
      : '';
  // Wrap content lines if they're too long
  final wrappedLines = <String>[];
  for (final line in lines) {
    if (line.length <= contentWidth) {
      wrappedLines.add(line);
    } else {
      // Wrap long lines
      for (var i = 0; i < line.length; i += contentWidth) {
        final end = min(i + contentWidth, line.length);
        wrappedLines.add(line.substring(i, end));
      }
    }
  }

  final buffer = StringBuffer();

  // Top border with label
  final labelPadding = boxWidth - 2 - truncatedLabel.length;
  buffer.writeln('+$truncatedLabel${'-' * labelPadding}+');
  // Content lines
  for (final line in wrappedLines) {
    final padding = contentWidth - line.length;
    buffer.writeln('| $line${' ' * padding} |');
  }

  // Bottom border
  buffer.writeln('+${'-' * (boxWidth - 2)}+');

  stdout.write(buffer);
}
