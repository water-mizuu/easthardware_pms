#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main() async {
  final workspaceDir = Directory(r'c:\Programming\Projects\easthardware_pms\lib');

  print('Starting bulk update of debug blocks...');

  // Get all Dart files
  final dartFiles = await workspaceDir
      .list(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  print('Found ${dartFiles.length} Dart files');

  var filesModified = 0;
  var totalReplacements = 0;

  for (final file in dartFiles) {
    try {
      final content = await file.readAsString();
      var newContent = content;

      // Skip if already using isDebugMode
      if (content.contains('isDebugMode')) {
        continue;
      }

      // Skip if doesn't have kDebugMode
      if (!content.contains('kDebugMode')) {
        continue;
      }

      var fileChanged = false;

      // Replace if (kDebugMode) with if (isDebugMode)
      final kDebugModeRegex = RegExp(r'if\s*\(\s*kDebugMode\s*\)');
      if (kDebugModeRegex.hasMatch(content)) {
        newContent = newContent.replaceAll(kDebugModeRegex, 'if (isDebugMode)');
        fileChanged = true;
        totalReplacements += kDebugModeRegex.allMatches(content).length;
      }

      // Replace print( with printBoxed( inside debug blocks
      final printRegex = RegExp(r'print\s*\(');
      if (printRegex.hasMatch(content)) {
        // This is a simple replacement - in practice, we'd need more sophisticated parsing
        // to ensure we only replace prints inside debug blocks
        newContent = newContent.replaceAll(printRegex, 'printBoxed(');
        fileChanged = true;
      }

      // Add import for debug constants if file uses debug blocks
      if (fileChanged && !content.contains('debug_constants.dart')) {
        // Find import section
        final importRegex = RegExp(r'''import\s+['\"]package:easthardware_pms/[^'\"]+['\"];''');
        final importMatches = importRegex.allMatches(content);

        if (importMatches.isNotEmpty) {
          final lastImport = importMatches.last;
          final insertPoint = lastImport.end;

          newContent =
              "${newContent.substring(0, insertPoint)}\nimport 'package:easthardware_pms/domain/constants/debug_constants.dart';${newContent.substring(insertPoint)}";
        }
      }

      // Remove unused kDebugMode import if present
      if (fileChanged && content.contains("import 'package:flutter/foundation.dart';")) {
        // Check if kDebugMode is still used elsewhere
        if (!newContent.contains('kDebugMode')) {
          newContent = newContent.replaceAll("import 'package:flutter/foundation.dart';\n", '');
          newContent = newContent.replaceAll("import 'package:flutter/foundation.dart';", '');
        }
      }

      if (fileChanged) {
        await file.writeAsString(newContent);
        filesModified++;
        print('Updated: ${file.path}');
      }
    } catch (e) {
      print('Error processing ${file.path}: $e');
    }
  }

  print('\nUpdate complete!');
  print('Files modified: $filesModified');
  print('Total replacements: $totalReplacements');
}
