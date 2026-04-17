import 'package:flutter/foundation.dart';

/// User-visible fallbacks while aggregating SQL rows in the overview
/// repository implementation.
///
/// Built from `AppLocalizations` in the presentation layer; when omitted
/// (e.g. tests), [englishFallback] is used.
@immutable
class OverviewLoadLabels {
  const OverviewLoadLabels({
    required this.unknownPaymentMethodLabel,
    required this.unknownUserNameLabel,
  });

  static const OverviewLoadLabels englishFallback = OverviewLoadLabels(
    unknownPaymentMethodLabel: 'Payment method not specified',
    unknownUserNameLabel: 'User not specified',
  );

  final String unknownPaymentMethodLabel;
  final String unknownUserNameLabel;
}
