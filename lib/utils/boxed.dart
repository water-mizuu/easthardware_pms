import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

@pragma('vm:prefer-inline')
void printBoxed(Object? value, [String? label]) {
  if (kDebugMode) {
    const maxLength = 120;

    final lines = value.toString().split('\n');
    final longestLength = max(label?.length ?? 0, lines.map((e) => e.length).fold(0, max));
    final followedLength = min(longestLength + 2, maxLength);

    final truncatedLabel = label != null && label.isNotEmpty //
        ? label.length > followedLength
            ? '${label.substring(0, followedLength - 5)}...'
            : label
        : '';

    final truncatedLines = lines.map((e) => e.length > followedLength //
        ? '${e.substring(0, followedLength - 5)}...'
        : e);

    final buffer = StringBuffer()
      ..writeln('+ $truncatedLabel ${'-' * (followedLength - (truncatedLabel.length + 2))}+');
    for (final line in truncatedLines) {
      buffer.writeln('| $line ${' ' * (followedLength - (line.length + 2))}|');
    }
    buffer.writeln('+${'-' * followedLength}+');

    stdout.write(buffer);
  }
}
