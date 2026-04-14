import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:flutter/material.dart';

const double _kPaymentSummaryTableTypeScale = 0.92;
const int _kPaymentSummaryMaxRowsBeforeInnerScroll = 8;
const double _kPaymentSummaryInnerListMaxHeight = 320;

TextStyle _scaledPaymentSummaryTextStyle(TextStyle base) {
  final fs = base.fontSize;
  if (fs == null) {
    return base;
  }
  return base.copyWith(fontSize: fs * _kPaymentSummaryTableTypeScale);
}

TextStyle _tabularFigures(TextStyle style) {
  return style.copyWith(
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}

class OverviewPaymentSummaryTable extends StatelessWidget {
  const OverviewPaymentSummaryTable({
    required this.l10n,
    required this.methods,
    required this.showSkeleton,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewPaymentMethodBreakdown> methods;
  final bool showSkeleton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    final Widget body;
    if (methods.isEmpty) {
      if (showSkeleton) {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _PaymentTableHeader(l10n: l10n),
            SizedBox(height: tokens.gapMd * 3),
          ],
        );
      } else {
        body = AppInlineErrorPanel(
          tone: AppInlinePanelTone.informational,
          variant: AppInlineErrorPanelVariant.plain,
          title: l10n.dashboardPaymentSummaryEmptyTitle,
          message: l10n.dashboardPaymentSummaryEmptyMessage,
        );
      }
    } else if (methods.length <= _kPaymentSummaryMaxRowsBeforeInnerScroll) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PaymentTableHeader(l10n: l10n),
          ...methods.asMap().entries.map(
                (e) => _PaymentTableRow(
                  l10n: l10n,
                  method: e.value,
                  showTopDivider: e.key > 0,
                ),
              ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PaymentTableHeader(l10n: l10n),
          SizedBox(
            height: _kPaymentSummaryInnerListMaxHeight,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              itemCount: methods.length,
              itemBuilder: (context, index) {
                return _PaymentTableRow(
                  l10n: l10n,
                  method: methods[index],
                  showTopDivider: index > 0,
                );
              },
            ),
          ),
        ],
      );
    }

    return AppSectionCardWithHeading(
      title: l10n.dashboardPaymentSummaryTitle,
      subtitle: l10n.dashboardPaymentSummarySubtitle,
      style: AppSectionCardWithHeadingStyle(
        titleTextStyle: _scaledPaymentSummaryTextStyle(
          typography.sectionHeaderH2,
        ),
        subtitleTextStyle: _scaledPaymentSummaryTextStyle(
          typography.caption.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      child: body,
    );
  }
}

class _PaymentTableHeader extends StatelessWidget {
  const _PaymentTableHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    final style = _scaledPaymentSummaryTextStyle(
      typography.utilityOverline,
    ).copyWith(
      color: cs.onSurfaceVariant,
    );
    final bodyStyle = _scaledPaymentSummaryTextStyle(typography.body);
    final highlightStyle = bodyStyle.copyWith(fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeSemantics(
          child: Opacity(
            opacity: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ' ',
                style: highlightStyle,
                maxLines: 1,
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Tooltip(
              message: l10n.dashboardPaymentSummaryTooltipRevenueAbbr,
              child: Text(
                l10n.dashboardPaymentSummaryHeaderRevenueAbbr,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: tokens.gapMd),
            Text(
              l10n.dashboardPaymentSummaryHeaderSales,
              style: style,
              textAlign: TextAlign.right,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(width: tokens.gapMd),
            Text(
              l10n.dashboardPaymentSummaryHeaderAvgTicket,
              style: style,
              textAlign: TextAlign.right,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(width: tokens.gapMd),
            Tooltip(
              message: l10n.dashboardPaymentSummaryTooltipParticipationAbbr,
              child: Text(
                l10n.dashboardPaymentSummaryHeaderParticipationAbbr,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.gapSm),
        Divider(
          height: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ],
    );
  }
}

class _PaymentSummaryValuesScrollRow extends StatelessWidget {
  const _PaymentSummaryValuesScrollRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.centerRight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaymentTableRow extends StatelessWidget {
  const _PaymentTableRow({
    required this.l10n,
    required this.method,
    required this.showTopDivider,
  });

  final AppLocalizations l10n;
  final OverviewPaymentMethodBreakdown method;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final bodyStyle = _tabularFigures(
      _scaledPaymentSummaryTextStyle(typography.body),
    );
    final highlightStyle = bodyStyle.copyWith(fontWeight: FontWeight.w600);
    final percentText = method.sharePercent.toStringAsFixed(1);
    final lang = Localizations.localeOf(context).languageCode;
    final percentSemanticsValue = lang == 'en'
        ? percentText
        : percentText.replaceAll('.', ',');
    final amountStyle = _tabularFigures(
      bodyStyle.copyWith(fontWeight: FontWeight.w600),
    );
    final percentStyle = _tabularFigures(
      bodyStyle.copyWith(color: cs.onSurface),
    );
    final amountText = AppBrFormatters.currency(method.totalAmount);
    final averageTicketText = AppBrFormatters.currency(method.averageTicket);

    final title = Semantics(
      label: l10n.overviewSemanticsPaymentMethodRow(method.label),
      child: Text(
        method.label,
        style: highlightStyle,
        textAlign: TextAlign.left,
        maxLines: 3,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final valuesRow = _PaymentSummaryValuesScrollRow(
      children: <Widget>[
        Semantics(
          label: l10n.overviewSemanticsRevenue(amountText),
          child: ExcludeSemantics(
            child: Text(
              amountText,
              style: amountStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: tokens.gapMd),
        Semantics(
          label: l10n.overviewSemanticsSalesCount(
            method.totalSalesCount.toString(),
          ),
          child: ExcludeSemantics(
            child: Text(
              method.totalSalesCount.toString(),
              style: bodyStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: tokens.gapMd),
        Semantics(
          label: l10n.overviewSemanticsAvgTicket(averageTicketText),
          child: ExcludeSemantics(
            child: Text(
              averageTicketText,
              style: bodyStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: tokens.gapMd),
        Semantics(
          label: l10n.overviewSemanticsSharePercent(percentSemanticsValue),
          child: ExcludeSemantics(
            child: Text(
              '$percentText%',
              style: percentStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        title,
        SizedBox(height: tokens.gapXs),
        valuesRow,
      ],
    );

    return DecoratedBox(
      decoration: showTopDivider
          ? BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            )
          : const BoxDecoration(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.gapSm),
        child: column,
      ),
    );
  }
}
