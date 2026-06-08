import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart'
    show AppInlineErrorPanel, AppInlinePanelTone;
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class OverviewChartNotFoundPage extends StatelessWidget {
  const OverviewChartNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return SingleChildScrollView(
      padding: context.pageScrollPadding(
        tokens,
        horizontalAdjustment:
            AppPageSpacingPresets.dashboardHorizontalAdjustment,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppShellPageIntro(
            title: l10n.overviewChartNotFoundTitle,
            subtitle: l10n.overviewHomeSubtitle,
            sectionLabel: l10n.shellNavDashboardLabel,
            onSectionLabelTap: () => context.goTo(AppRoute.dashboard),
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppInlineErrorPanel(
            message: l10n.overviewChartNotFoundMessage,
            tone: AppInlinePanelTone.informational,
          ),
          SizedBox(height: tokens.contentSpacing),
          AppPrimaryButton(
            label: l10n.overviewChartNotFoundBackAction,
            onPressed: () => context.goTo(AppRoute.dashboard),
          ),
        ],
      ),
    );
  }
}
