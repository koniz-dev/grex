// Entry point for regenerating test/coverage_all_test.dart.
//
//   dart run tool/generate_coverage_aggregator.dart          # rewrite it
//   dart run tool/generate_coverage_aggregator.dart --check  # exit 1 if stale
//
// The rules live in tool/coverage_aggregator.dart, which the generated test
// imports too, so the aggregator and its staleness check can never disagree
// about which files belong in coverage. See that file for why any of this is
// necessary.
import 'dart:io';

import 'coverage_aggregator.dart';

void main(List<String> args) {
  final libraries = coverageEligibleLibraries();
  final rendered = renderAggregator(libraries);
  final file = File(aggregatorPath);

  if (args.contains('--check')) {
    final current = file.existsSync() ? file.readAsStringSync() : '';
    if (current != rendered) {
      stderr.writeln(
        '$aggregatorPath is stale. Regenerate with:\n'
        '  dart run tool/generate_coverage_aggregator.dart',
      );
      exit(1);
    }
    stdout.writeln(
      '$aggregatorPath is up to date (${libraries.length} libraries).',
    );
    return;
  }

  file.writeAsStringSync(rendered);
  stdout.writeln('Wrote $aggregatorPath (${libraries.length} libraries).');
}
