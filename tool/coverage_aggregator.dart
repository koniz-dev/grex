// Builds test/coverage_all_test.dart -- an aggregator that imports every
// coverage-eligible library under lib/.
//
// Why this exists: `flutter test --coverage` instruments only the libraries a
// run actually loads. A file no test imports, directly or transitively, is not
// reported as 0% covered -- it is absent from lcov.info entirely, so it never
// reaches the denominator and every layer percentage comes out flattering.
// Worse, the loaded set is not identical across platforms, so local and CI
// disagreed at file granularity (issue #15).
//
// Importing a library is enough to load it, so the aggregator drags every
// eligible file into the report whether or not a real test touches it.
//
// The entry point lives in tool/generate_coverage_aggregator.dart. This file is
// a plain library so the generated test can import the same rules it was built
// from -- one definition of "coverage-eligible", used to write the aggregator
// and to check it has not gone stale.
import 'dart:io';

/// Path of the generated aggregator, relative to the repository root.
const aggregatorPath = 'test/coverage_all_test.dart';

/// Whether [path] is a file whose lines should reach the coverage denominator.
///
/// These rules are duplicated in two places that cannot share Dart code: the
/// `excluded()` function in `scripts/linux/testing/calculate_layer_coverage.sh`
/// and the `lcov --remove` filter in `.github/workflows/test.yml`. Keep all
/// three in sync -- a file excluded there but not here is imported for nothing,
/// and one excluded here but not there lands in the denominator as permanently
/// uncovered and drags the gate down.
bool isCoverageEligible(String path) {
  final normalized = path.replaceAll(r'\', '/');
  if (!normalized.startsWith('lib/')) return false;
  if (!normalized.endsWith('.dart')) return false;

  const suffixExclusions = [
    '.g.dart',
    '.freezed.dart',
    '.config.dart',
    '_test.dart',
  ];
  for (final suffix in suffixExclusions) {
    if (normalized.endsWith(suffix)) return false;
  }

  const segmentExclusions = ['/generated/', '/l10n/', '/test/'];
  for (final segment in segmentExclusions) {
    if (normalized.contains(segment)) return false;
  }

  const basenameExclusions = [
    'main.dart',
    'test_helpers.dart',
    'test_fixtures.dart',
  ];
  return !basenameExclusions.contains(normalized.split('/').last);
}

/// Every coverage-eligible library under `lib/`, as `package:grex/...` URIs,
/// sorted so the generated file is byte-identical across machines.
List<String> coverageEligibleLibraries({String root = '.'}) {
  final prefix = root == '.' ? '' : '$root/';

  return Directory('${prefix}lib')
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/'))
      .map(
        (path) =>
            path.startsWith(prefix) ? path.substring(prefix.length) : path,
      )
      .where(isCoverageEligible)
      .map((path) => 'package:grex/${path.substring('lib/'.length)}')
      .toList()
    ..sort();
}

/// The `package:grex/...` imports declared by an already-generated aggregator.
List<String> declaredImports(String source) {
  final pattern = RegExp("^import '(package:grex/[^']+)';", multiLine: true);
  return pattern.allMatches(source).map((match) => match.group(1)!).toList()
    ..sort();
}

const _header = '''
// GENERATED FILE -- DO NOT EDIT BY HAND.
//
// Regenerate with:
//   dart run tool/generate_coverage_aggregator.dart
//
// `flutter test --coverage` instruments only the libraries a run loads. A file
// no test imports is absent from lcov.info entirely -- not reported as 0% -- so
// it never reaches the denominator and every layer percentage reads higher than
// the truth. Importing every eligible library here forces all of them into the
// report.
//
// The test below fails when this list drifts from the filesystem, so a new file
// under lib/ cannot quietly escape measurement.
//
// ignore_for_file: unused_import

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
''';

const _body = r'''
import '../tool/coverage_aggregator.dart';

void main() {
  test('every library under lib/ is imported for coverage', () {
    final source = File(aggregatorPath).readAsStringSync();

    expect(
      declaredImports(source),
      equals(coverageEligibleLibraries()),
      reason:
          'The coverage aggregator is stale, so some libraries are missing '
          'from lcov.info and every layer percentage reads higher than the '
          'truth. Regenerate it with:\n'
          '  dart run tool/generate_coverage_aggregator.dart',
    );
  });
}
''';

/// Render the aggregator source for [libraries].
String renderAggregator(List<String> libraries) {
  final imports = libraries.map((library) => "import '$library';").join('\n');
  return '$_header$imports\n$_body';
}
