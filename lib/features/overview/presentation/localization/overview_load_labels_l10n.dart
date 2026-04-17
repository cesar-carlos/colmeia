import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/l10n/app_localizations.dart';

extension OverviewLoadLabelsL10n on AppLocalizations {
  OverviewLoadLabels get overviewLoadLabels => OverviewLoadLabels(
        unknownPaymentMethodLabel: overviewResumoUnknownPaymentMethod,
        unknownUserNameLabel: overviewResumoUnknownUserName,
      );
}
