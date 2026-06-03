import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Representative median for a successful overview batch E2E on a warm bridge.
///
/// Calibrated conservatively for local/CI variance; raise only after intentional
/// perf work. Soft guard uses [kE2eSoftPerfMedianMultiple] × this value.
const Duration kOverviewBatchLoaderE2eMedianSuccessDuration = Duration(
  seconds: 90,
);

const int kE2eSoftPerfMedianMultiple = 5;

/// Set `E2E_SOFT_PERF_GUARD=0` to disable ceiling assertions (elapsed is still logged).
bool get e2eSoftPerfGuardEnabled {
  final raw = Platform.environment['E2E_SOFT_PERF_GUARD']?.toLowerCase().trim();
  return raw != '0' && raw != 'false' && raw != 'no';
}

void e2eRecordSuccessElapsed({
  required String label,
  required Duration elapsed,
  required Duration median,
}) {
  final ceiling = Duration(
    microseconds: median.inMicroseconds * kE2eSoftPerfMedianMultiple,
  );
  // ignore: avoid_print -- intentional E2E timing breadcrumb for median calibration.
  print(
    'E2E perf $label: ${elapsed.inMilliseconds}ms '
    '(median ${median.inMilliseconds}ms, '
    'soft ceiling ${ceiling.inMilliseconds}ms)',
  );
}

void e2eAssertSoftPerfWithinMedianMultiple({
  required String label,
  required Duration elapsed,
  required Duration median,
}) {
  e2eRecordSuccessElapsed(label: label, elapsed: elapsed, median: median);
  if (!e2eSoftPerfGuardEnabled) {
    return;
  }
  final ceiling = Duration(
    microseconds: median.inMicroseconds * kE2eSoftPerfMedianMultiple,
  );
  expect(
    elapsed,
    lessThanOrEqualTo(ceiling),
    reason:
        '$label E2E took ${elapsed.inMilliseconds}ms, above soft ceiling '
        '${ceiling.inMilliseconds}ms ($kE2eSoftPerfMedianMultiple× median '
        '${median.inMilliseconds}ms). Set E2E_SOFT_PERF_GUARD=0 to skip or '
        'raise kOverviewBatchLoaderE2eMedianSuccessDuration after review.',
  );
}
