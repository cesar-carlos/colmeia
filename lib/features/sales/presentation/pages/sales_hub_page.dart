import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/sales/domain/sales_card_descriptor.dart';
import 'package:colmeia/features/sales/presentation/localization/sales_card_descriptor_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_grid.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class SalesHubPage extends StatelessWidget {
  const SalesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(l10n.salesHubTitle),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: context.pageScrollPadding(tokens),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppShellPageIntro(
                  subtitle: l10n.salesHubSubtitle,
                ),
                SizedBox(height: tokens.sectionSpacing),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.maxWidth >=
                        kAppHubNavigationSalesHubWideBreakpoint;
                    final isSingleCardRow = allSalesCards.length == 1;
                    final singleCardMaxWidth =
                        tokens.chartCompactHeight + tokens.contentSpacing;

                    return AppHubNavigationGrid(
                      density: AppHubNavigationCardDensity.standard,
                      itemCount: allSalesCards.length,
                      spacing: tokens.gapMd,
                      maxColumns: isWide ? 4 : 2,
                      maxCardWidth: isSingleCardRow ? singleCardMaxWidth : null,
                      wrapAlignment: isSingleCardRow
                          ? WrapAlignment.center
                          : WrapAlignment.start,
                      itemBuilder: (context, index, layout) {
                        final card = allSalesCards[index];
                        final title = card.resolvedTitle(l10n);

                        return AppHubNavigationCard(
                          icon: card.icon,
                          label: title,
                          tooltipMessage: title,
                          labelStyle: layout.narrowLabelStyle,
                          onTap: () {
                            unawaited(
                              context.pushTo<void>(
                                AppRoute.salesCard,
                                pathParameters: <String, String>{
                                  'cardId': card.id,
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
