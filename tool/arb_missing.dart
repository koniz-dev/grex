// One-shot helper: prints non-metadata keys present in app_en.arb but
// missing from app_ar.arb / app_es.arb. Used while backfilling the
// ar/es ARB files to re-enable the synchronization test.
import 'dart:convert';
import 'dart:io';

void main() {
  final en = json.decode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final ar = json.decode(File('lib/l10n/app_ar.arb').readAsStringSync())
      as Map<String, dynamic>;
  final es = json.decode(File('lib/l10n/app_es.arb').readAsStringSync())
      as Map<String, dynamic>;

  Set<String> top(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  final enKeys = top(en);
  final missingAr = enKeys.difference(top(ar));
  final missingEs = enKeys.difference(top(es));

  print('EN total: ${enKeys.length}');
  print('Missing in AR (${missingAr.length}):');
  for (final k in missingAr.toList()..sort()) {
    print('  $k -> ${en[k]}');
  }
  print('Missing in ES (${missingEs.length}):');
  for (final k in missingEs.toList()..sort()) {
    print('  $k -> ${en[k]}');
  }
}
