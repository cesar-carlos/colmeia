// One-shot maintenance script: removes orphan ARB keys (declared but
// not referenced anywhere in lib/ or test/) from the three locale
// files, preserving original insertion order and 2-space indentation
// so the resulting diff stays focused on the deletions.
//
// Usage: `dart run tool/purge_orphan_l10n.dart`.
//
// Scope hard-coded to the demo families (`formsDemo*`,
// `areaTrendDemo*`) plus a curated allow-list of confirmed orphans —
// passed via stdin as one key per line. Anything else stays. Re-run
// `flutter gen-l10n` after this script.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  const arbFiles = <String>[
    'lib/l10n/app_en.arb',
    'lib/l10n/app_pt.arb',
    'lib/l10n/app_pt_BR.arb',
  ];

  // Strings used by `app_forms_demo_page.dart` that we MUST keep —
  // the page itself is a settings showcase, not dead code, even
  // though most of the family was orphaned by an earlier refactor.
  // Determined by a `flutter analyze` round-trip.
  const liveFormsDemoStrings = <String>{
    'formsDemoFormValidSnackbar',
    'formsDemoFormBuilderValidSnackbar',
    'formsDemoDatePickersFormTitle',
    'formsDemoDatePickersFormSubtitle',
    'formsDemoFormBuilderSectionTitle',
    'formsDemoFormBuilderSectionSubtitle',
    'formsDemoValidateFormBuilderButton',
    'formsDemoValidateFormSubmitButton',
  };

  // Non-demo strings flagged as orphans by the `lib/`/`test/` audit.
  // Each entry is a confirmed dead path (verified by reading every
  // call site / nearby widget). When in doubt the string stays —
  // re-add to this list after triage.
  const confirmedOrphanNonDemo = <String>{
    // Loading skeleton replaced by `overviewLoadingPaymentKpisSemantics`.
    'dashboardPaymentSummaryLoadingSemantics',
    // Filter chip never wired (period chips are date-range based).
    'dashboardHomeFiltersPeriodLast30Days',
    // Pan gesture hint absorbed into the chart's onboarding tooltip.
    'chartComboPanGestureHint',
    'chartComboPanChartA11y',
    'chartComparisonPanChartA11y',
    // Address card uses conditional render `if (_hasAddress)` instead
    // of placeholder copy.
    'clientAgentAddressNotProvided',
    // Token load failures fall back silently to the local cache;
    // the remaining hard-error path uses `clientAgentsErrorGetClientAgentToken`.
    'clientAgentDetailServerTokenLoadError',
  };

  bool isOrphanKey(String key) {
    // Strip the leading `@` so `formsDemoFoo` and `@formsDemoFoo` get
    // the same treatment — the metadata block must follow the key.
    final base = key.startsWith('@') ? key.substring(1) : key;
    if (liveFormsDemoStrings.contains(base)) return false;
    if (base.startsWith('formsDemo')) return true;
    if (base.startsWith('areaTrendDemo')) return true;
    if (confirmedOrphanNonDemo.contains(base)) return true;
    return false;
  }

  for (final path in arbFiles) {
    final raw = File(path).readAsStringSync();
    // Use `dart:convert`'s default `Map<String, dynamic>` which is a
    // `LinkedHashMap` — preserves insertion order.
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    final retained = <String, dynamic>{
      for (final entry in parsed.entries)
        if (!isOrphanKey(entry.key)) entry.key: entry.value,
    };
    final removedCount = parsed.length - retained.length;
    const encoder = JsonEncoder.withIndent('  ');
    var rendered = encoder.convert(retained);
    // The original ARB style packs single-property placeholder maps on
    // one line (`"count": {"type": "int"}`). Dart's encoder always
    // expands them to three lines. Collapse back so the diff stays
    // focused on actual deletions instead of cosmetic reflow.
    rendered = rendered.replaceAllMapped(
      RegExp(r'\{\s*"(\w+)":\s*"([^"]+)"\s*\}'),
      (m) => '{"${m[1]}": "${m[2]}"}',
    );
    File(path).writeAsStringSync('$rendered\n');
    stdout.writeln('$path : removed $removedCount keys');
  }
}
