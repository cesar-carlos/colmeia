import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:flutter/foundation.dart';

enum SalesLiveMapReloadOutcomeKind {
  completed,
  cancelled,
  superseded,
  blockedByCooldown,
}

@immutable
class SalesLiveMapReloadOutcome {
  const SalesLiveMapReloadOutcome._(this.kind, this.result);

  const SalesLiveMapReloadOutcome.completed([SalesLiveMapLoadResult? result])
    : this._(SalesLiveMapReloadOutcomeKind.completed, result);

  const SalesLiveMapReloadOutcome.cancelled([SalesLiveMapLoadResult? result])
    : this._(SalesLiveMapReloadOutcomeKind.cancelled, result);

  const SalesLiveMapReloadOutcome.superseded([SalesLiveMapLoadResult? result])
    : this._(SalesLiveMapReloadOutcomeKind.superseded, result);

  const SalesLiveMapReloadOutcome.blockedByCooldown([
    SalesLiveMapLoadResult? result,
  ]) : this._(SalesLiveMapReloadOutcomeKind.blockedByCooldown, result);

  final SalesLiveMapReloadOutcomeKind kind;
  final SalesLiveMapLoadResult? result;

  bool get isCompleted => kind == SalesLiveMapReloadOutcomeKind.completed;

  bool get isCancelled => kind == SalesLiveMapReloadOutcomeKind.cancelled;

  bool get isSuperseded => kind == SalesLiveMapReloadOutcomeKind.superseded;

  bool get isBlockedByCooldown =>
      kind == SalesLiveMapReloadOutcomeKind.blockedByCooldown;
}
