import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_grid.dart';
import 'package:flutter/material.dart';

/// Descriptor for one chart entry in a sales trend chart navigation grid.
final class SalesTrendChartNavItem<T> {
  const SalesTrendChartNavItem({
    required this.id,
    required this.icon,
    required this.navLabel,
    required this.title,
    this.subtitle,
  });

  final T id;
  final IconData icon;
  final String navLabel;
  final String title;
  final String? subtitle;
}

/// Shared compact navigation grid for sales trend chart fullscreen views.
class SalesTrendChartNavGrid<T> extends StatelessWidget {
  const SalesTrendChartNavGrid({
    required this.items,
    required this.l10n,
    required this.onChartSelected,
    required this.isChartReady,
    required this.loadingSemanticsLabel,
    super.key,
    this.loading = false,
    this.sectionTitle,
  });

  final List<SalesTrendChartNavItem<T>> items;
  final AppLocalizations l10n;
  final ValueChanged<T> onChartSelected;
  final bool Function(T chartId) isChartReady;
  final String loadingSemanticsLabel;
  final bool loading;
  final String? sectionTitle;

  bool get _anyChartReady => items.any((item) => isChartReady(item.id));

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final showInitialSkeleton = loading && !_anyChartReady;

    final grid = AppHubNavigationGrid(
      density: AppHubNavigationCardDensity.chartNav,
      itemCount: items.length,
      itemBuilder: (context, index, layout) {
        final item = items[index];
        final ready = isChartReady(item.id);
        final semanticsLabel = _semanticsLabel(
          l10n: l10n,
          title: item.title,
          ready: ready,
          loading: loading,
        );
        final tooltipMessage = resolveAppHubNavigationTooltipMessage(
          label: item.title,
          subtitle: item.subtitle,
        );

        return AppHubNavigationCard(
          density: AppHubNavigationCardDensity.chartNav,
          icon: item.icon,
          label: item.navLabel,
          tooltipMessage: tooltipMessage,
          labelStyle: layout.narrowLabelStyle,
          showReadyBadge: ready,
          semanticsLabel: semanticsLabel,
          onTap: ready ? () => onChartSelected(item.id) : null,
        );
      },
    );

    final resolvedGrid = showInitialSkeleton
        ? AppSkeleton(
            enabled: true,
            loadingSemanticsLabel: loadingSemanticsLabel,
            child: grid,
          )
        : grid;

    final title = sectionTitle;
    if (title == null || title.trim().isEmpty) {
      return resolvedGrid;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.gapSm),
        resolvedGrid,
      ],
    );
  }
}

String _semanticsLabel({
  required AppLocalizations l10n,
  required String title,
  required bool ready,
  required bool loading,
}) {
  if (ready) {
    return title;
  }
  if (loading) {
    return '$title, ${l10n.overviewChartNavLoadingSemanticsSuffix}';
  }
  return '$title, ${l10n.salesProdutoTendenciaChartNavUnavailableSemanticsSuffix}';
}
