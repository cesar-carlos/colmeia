import 'package:colmeia/features/sales/application/sales_live_map_internal_labels.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_option.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:colmeia/shared/utils/app_branch_display_name.dart';

abstract final class SalesLiveMapL10n {
  static String branchPointSubtitle(
    AppLocalizations l10n, {
    required String agentName,
    required int companyCode,
    required int branchCode,
  }) {
    return l10n.salesLiveMapBranchPointSubtitle(
      agentName,
      companyCode,
      branchCode,
    );
  }

  static String displayCity(AppLocalizations l10n, String city) {
    if (city == SalesLiveMapInternalLabels.missingMunicipalityCity) {
      return l10n.salesLiveMapMissingMunicipalityLabel;
    }
    return city;
  }

  static String? displaySalesDataStatusLabel(
    AppLocalizations l10n,
    String? label,
  ) {
    if (label == null) {
      return null;
    }
    if (label == SalesLiveMapInternalLabels.salesUnavailableFallback) {
      return l10n.brazilStoreSalesMapSalesUnavailableFallback;
    }
    return label;
  }

  static String formatUnmappedBranchLabel(
    AppLocalizations l10n,
    SalesLiveMapBranchOption branch,
  ) {
    final city = displayCity(l10n, branch.city);
    final location = '$city / ${branch.uf}';
    final display = resolveAppBranchDisplayModel(
      registrationName: branch.registrationName,
      fantasyName: branch.fantasyName,
      fallbackName: branch.registrationName,
    );
    final primary = display.primaryName;
    final secondary = display.secondaryName;
    final nameLabel = secondary == null ? primary : '$primary - $secondary';
    return '$nameLabel - $location - ${appBranchDisplayName(branch.agentName)}';
  }
}
