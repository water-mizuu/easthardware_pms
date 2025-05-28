import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

@pragma('vm:prefer-inline')
void printBoxed(Object? value, [String? label]) {
  if (kDebugMode) {
    const maxLength = 120;

    final longestLength = max(label?.length ?? 0, value.toString().length);
    final followedLength = min(longestLength + 2, maxLength);

    final valueString = value.toString();

    final truncatedLabel = label != null && label.isNotEmpty //
        ? label.length > followedLength
            ? '${label.substring(0, followedLength - 5)}...'
            : label
        : '';

    final truncatedValue = valueString.length > followedLength //
        ? '${valueString.substring(0, followedLength - 5)}...'
        : valueString;

    final box = '+ $truncatedLabel ${'-' * (followedLength - (truncatedLabel.length + 2))}+\n'
        '| $truncatedValue |\n'
        '+${'-' * followedLength}+';

    stdout.writeln(box);
  }
}
