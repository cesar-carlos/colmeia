import 'package:colmeia/core/errors/app_failure.dart';
import 'package:flutter/foundation.dart';

enum SalesTrendReloadOutcomeKind {
  success,
  failure,
  cancelled,
  superseded,
}

@immutable
class SalesTrendReloadOutcome {
  const SalesTrendReloadOutcome._(
    this.kind, {
    this.loadFailure,
    this.dimensionOptionsFailure,
  });

  const SalesTrendReloadOutcome.success({
    AppFailure? dimensionOptionsFailure,
  }) : this._(
         SalesTrendReloadOutcomeKind.success,
         dimensionOptionsFailure: dimensionOptionsFailure,
       );

  const SalesTrendReloadOutcome.failure({
    AppFailure? loadFailure,
    AppFailure? dimensionOptionsFailure,
  }) : this._(
         SalesTrendReloadOutcomeKind.failure,
         loadFailure: loadFailure,
         dimensionOptionsFailure: dimensionOptionsFailure,
       );

  const SalesTrendReloadOutcome.cancelled()
    : this._(SalesTrendReloadOutcomeKind.cancelled);

  const SalesTrendReloadOutcome.superseded()
    : this._(SalesTrendReloadOutcomeKind.superseded);

  final SalesTrendReloadOutcomeKind kind;
  final AppFailure? loadFailure;
  final AppFailure? dimensionOptionsFailure;

  bool get isSuccess => kind == SalesTrendReloadOutcomeKind.success;

  bool get isFailure => kind == SalesTrendReloadOutcomeKind.failure;

  bool get isCancelled => kind == SalesTrendReloadOutcomeKind.cancelled;

  bool get isSuperseded => kind == SalesTrendReloadOutcomeKind.superseded;
}

typedef SalesProdutoTendenciaReloadOutcome = SalesTrendReloadOutcome;

typedef SalesProdutoTendenciaMediaMovelReloadOutcome = SalesTrendReloadOutcome;
