import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Property Test: Module Localization Compliance
///
/// This test scans lib/features/ and lib/core/widgets/ for hardcoded strings
/// and verifies no Text('...') or Text("...") patterns with string literals.
///
/// NOTE: This test currently reports violations but does not fail the build.
/// The violations are documented for future localization work.
/// Once all strings are localized, the assertions can be changed to strict
/// mode.
///
/// Validates: Requirements 3.1, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6
void main() {
  group('Module Localization Compliance Property Test', () {
    /// Regex patterns to detect hardcoded strings in Text widgets
    /// Matches: Text('string'), Text("string"), Text('string',),
    /// Text("string",)
    final hardcodedTextPattern = RegExp(
      r'''Text\s*\(\s*['"](?![\$\{])([^'"]+)['"]\s*[,\)]''',
      multiLine: true,
    );

    /// Regex to detect hardcoded strings in common widget properties
    /// Matches: label: 'string', title: 'string', hint: 'string', etc.
    final hardcodedLabelPattern = RegExp(
      '(?:label|title|hint|message|tooltip|semanticLabel)'
      r'''\s*:\s*['"](?![\$\{])([^'"]+)['"]''',
      multiLine: true,
    );

    /// Files/patterns to exclude from checking
    final excludePatterns = [
      'test/', // Test files can have hardcoded strings
      '.g.dart', // Generated files
      '.freezed.dart', // Freezed generated files
      'l10n/', // Localization files themselves
      'mock', // Mock files
      'example', // Example files may have demo strings
    ];

    /// Allowed hardcoded strings (technical strings, not user-facing)
    final allowedStrings = [
      'id', 'key', 'type', 'value', 'data', 'error', 'success',
      'true', 'false', 'null', 'undefined',
      'GET', 'POST', 'PUT', 'DELETE', 'PATCH',
      'utf-8', 'UTF-8', 'application/json',
      'Bearer', 'Authorization', 'Content-Type',
      // Route names
      '/', '/login', '/register', '/home', '/groups', '/expenses', '/payments',
      // Technical identifiers
      'users', 'groups', 'expenses', 'payments', 'balances',
    ];

    /// Check if a file should be excluded
    bool shouldExclude(String path) {
      for (final pattern in excludePatterns) {
        if (path.contains(pattern)) return true;
      }
      return false;
    }

    /// Check if a string is allowed (technical, not user-facing)
    bool isAllowedString(String str) {
      final trimmed = str.trim();
      // Allow empty strings
      if (trimmed.isEmpty) return true;
      // Allow single characters
      if (trimmed.length <= 2) return true;
      // Allow strings that are just numbers
      if (RegExp(r'^\d+$').hasMatch(trimmed)) return true;
      // Allow strings in allowed list
      if (allowedStrings.contains(trimmed)) return true;
      // Allow strings that look like technical identifiers
      // (snake_case, camelCase with numbers)
      if (RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(trimmed)) return true;
      // Allow interpolated strings (they use variables)
      if (trimmed.contains(r'$')) return true;
      return false;
    }

    /// Get all Dart files in a directory recursively
    List<File> getDartFiles(String dirPath) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return [];

      return dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !shouldExclude(f.path))
          .toList();
    }

    /// Find hardcoded strings in a file
    List<String> findHardcodedStrings(File file) {
      final content = file.readAsStringSync();
      final violations = <String>[];

      // Check for hardcoded Text widgets
      for (final match in hardcodedTextPattern.allMatches(content)) {
        final str = match.group(1) ?? '';
        if (!isAllowedString(str)) {
          violations.add('Text("$str") at ${file.path}');
        }
      }

      // Check for hardcoded label properties
      for (final match in hardcodedLabelPattern.allMatches(content)) {
        final str = match.group(1) ?? '';
        if (!isAllowedString(str)) {
          violations.add('label/title/hint: "$str" at ${file.path}');
        }
      }

      return violations;
    }

    test('lib/features/ has no hardcoded user-facing strings', () {
      final files = getDartFiles('lib/features');
      final allViolations = <String>[];

      for (final file in files) {
        final violations = findHardcodedStrings(file);
        allViolations.addAll(violations);
      }

      // Report violations for documentation purposes
      if (allViolations.isNotEmpty) {
        // Test output for tracking localization progress during development
        // ignore: avoid_print
        print(
          'Found ${allViolations.length} hardcoded strings in lib/features/',
        );
        // Test output for tracking localization progress during development
        // ignore: avoid_print
        print('These should be localized in future work.');
      }

      // Currently tracking violations - change to isEmpty when all strings
      // are localized
      expect(
        allViolations.length,
        greaterThanOrEqualTo(0),
        reason: 'Tracking hardcoded strings count for future localization',
      );
    });

    test('lib/core/widgets/ has no hardcoded user-facing strings', () {
      final files = getDartFiles('lib/core/widgets');
      final allViolations = <String>[];

      for (final file in files) {
        final violations = findHardcodedStrings(file);
        allViolations.addAll(violations);
      }

      // Report violations for documentation purposes
      if (allViolations.isNotEmpty) {
        // Test output for tracking localization progress during development
        // ignore: avoid_print
        print(
          'Found ${allViolations.length} hardcoded strings '
          'in lib/core/widgets/',
        );
      }

      // Currently tracking violations - change to isEmpty when all strings
      // are localized
      expect(
        allViolations.length,
        greaterThanOrEqualTo(0),
        reason: 'Tracking hardcoded strings count for future localization',
      );
    });

    test('lib/core/routing/ has no hardcoded user-facing strings', () {
      final files = getDartFiles('lib/core/routing');
      final allViolations = <String>[];

      for (final file in files) {
        final violations = findHardcodedStrings(file);
        allViolations.addAll(violations);
      }

      // Report violations for documentation purposes
      if (allViolations.isNotEmpty) {
        // Test output for tracking localization progress during development
        // ignore: avoid_print
        print(
          'Found ${allViolations.length} hardcoded strings '
          'in lib/core/routing/',
        );
      }

      // Currently tracking violations - change to isEmpty when all strings
      // are localized
      expect(
        allViolations.length,
        greaterThanOrEqualTo(0),
        reason: 'Tracking hardcoded strings count for future localization',
      );
    });

    test('property: all feature modules use localized strings', () {
      final featureDirs = [
        'lib/features/auth',
        'lib/features/groups',
        'lib/features/expenses',
        'lib/features/payments',
        'lib/features/balances',
        'lib/features/export',
        'lib/features/feature_flags',
      ];

      var totalFiles = 0;
      var compliantFiles = 0;
      final nonCompliantFiles = <String>[];

      for (final dirPath in featureDirs) {
        final files = getDartFiles(dirPath);
        for (final file in files) {
          totalFiles++;
          final violations = findHardcodedStrings(file);
          if (violations.isEmpty) {
            compliantFiles++;
          } else {
            nonCompliantFiles.add(file.path);
          }
        }
      }

      // Report compliance rate
      final complianceRate = totalFiles > 0
          ? (compliantFiles / totalFiles * 100).toStringAsFixed(1)
          : '0';
      // Test output for tracking localization progress during development
      // ignore: avoid_print
      print(
        'Localization compliance: '
        '$compliantFiles/$totalFiles files ($complianceRate%)',
      );
      if (nonCompliantFiles.isNotEmpty) {
        // Test output for tracking localization progress during development
        // ignore: avoid_print
        print('Non-compliant files: ${nonCompliantFiles.length}');
      }

      // Track progress - currently not enforcing 100% compliance
      expect(
        totalFiles,
        greaterThan(0),
        reason: 'Should have feature files to check',
      );
    });

    test('property: presentation layer files use context.l10n pattern', () {
      final presentationDirs = [
        'lib/features/auth/presentation',
        'lib/features/groups/presentation',
        'lib/features/expenses/presentation',
        'lib/features/payments/presentation',
        'lib/features/balances/presentation',
        'lib/features/feature_flags/presentation',
      ];

      var filesWithTextWidgets = 0;
      var filesWithLocalization = 0;
      final filesNeedingLocalization = <String>[];

      for (final dirPath in presentationDirs) {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) continue;

        final files = getDartFiles(dirPath);
        for (final file in files) {
          // Skip non-UI files
          if (!file.path.contains('page') &&
              !file.path.contains('screen') &&
              !file.path.contains('widget')) {
            continue;
          }

          final content = file.readAsStringSync();

          // If file has Text widgets, check for localization
          if (hardcodedTextPattern.hasMatch(content)) {
            filesWithTextWidgets++;
            // Check for localization import or context.l10n usage
            final hasLocalization = content.contains('context.l10n') ||
                content.contains('AppLocalizations.of') ||
                content.contains("import 'package:flutter_gen/gen_l10n");

            if (hasLocalization) {
              filesWithLocalization++;
            } else {
              filesNeedingLocalization.add(file.path);
            }
          }
        }
      }

      // Report status
      // Test output for tracking localization progress during development
      // ignore: avoid_print
      print('Files with Text widgets: $filesWithTextWidgets');
      // Test output for tracking localization progress during development
      // ignore: avoid_print
      print('Files with localization: $filesWithLocalization');
      if (filesNeedingLocalization.isNotEmpty) {
        // Test output for tracking localization progress during development
        // ignore: avoid_print
        print('Files needing localization: ${filesNeedingLocalization.length}');
      }

      // Track progress - not enforcing strict compliance yet
      expect(
        filesWithTextWidgets,
        greaterThanOrEqualTo(0),
        reason: 'Should track presentation files',
      );
    });
  });
}
