import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Builds 1-based page indices with `null` for ellipsis when [totalPages]
/// is large.
List<int?> buildPaginationPageSlots({
  required int currentPage,
  required int totalPages,
  int siblingCount = 1,
}) {
  if (totalPages < 1) {
    return <int?>[];
  }
  final last = totalPages;
  final current = currentPage.clamp(1, last);
  if (last <= 7) {
    return List<int?>.generate(last, (i) => i + 1);
  }

  final pages = <int>{1, last};
  for (var i = current - siblingCount; i <= current + siblingCount; i++) {
    if (i >= 1 && i <= last) {
      pages.add(i);
    }
  }
  final sorted = pages.toList()..sort();
  final out = <int?>[];
  for (var i = 0; i < sorted.length; i++) {
    if (i > 0) {
      final gap = sorted[i] - sorted[i - 1];
      if (gap > 1) {
        out.add(null);
      }
    }
    out.add(sorted[i]);
  }
  return out;
}

/// Fixed width for the page-size dropdown (compact numeric labels only).
const double _kCompactPageSizeDropdownWidth = 72;

class AppTablePaginationFooterStyle {
  const AppTablePaginationFooterStyle({
    this.iconButtonSize = 32,
    this.pageNumberMinSize = 32,
    this.cornerRadius = 10,
    this.showTopBorder = true,
  });

  final double iconButtonSize;
  final double pageNumberMinSize;
  final double cornerRadius;
  final bool showTopBorder;
}

/// Table-style footer: page size, range summary, prev/next icon buttons and
/// numbered pages (active uses [ColorScheme.primaryContainer]).
class AppTablePaginationFooter extends StatelessWidget {
  const AppTablePaginationFooter({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalItems,
    required this.entityLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSelected,
    super.key,
    this.pageSizeOptions,
    this.onPageSizeChanged,
    this.itemsPerPageLabel,
    this.showingLabelPrefix = 'Mostrando ',
    this.showingLabelMiddle = ' de ',
    this.style = const AppTablePaginationFooterStyle(),
  });

  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int rangeStart;
  final int rangeEnd;
  final int totalItems;
  final String entityLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSelected;

  final List<int>? pageSizeOptions;
  final ValueChanged<int>? onPageSizeChanged;

  /// Label before the page-size selector. When null a localized default is
  /// used.
  final String? itemsPerPageLabel;
  final String showingLabelPrefix;
  final String showingLabelMiddle;
  final AppTablePaginationFooterStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final scheme = theme.colorScheme;
    final isMobile = AppBreakpoints.isMobile(context);
    final numberFormat = NumberFormat.decimalPattern('pt_BR');
    final resolvedItemsPerPageLabel =
        itemsPerPageLabel ??
        AppLocalizations.of(context).reportPaginationItemsPerPage;

    final borderSide = BorderSide(
      color: scheme.outlineVariant.withValues(alpha: 0.9),
    );
    final decorated = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: style.showTopBorder ? Border(top: borderSide) : null,
      ),
      padding: EdgeInsets.symmetric(vertical: tokens.gapSm),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SummaryRow(
                  isMobile: true,
                  tokens: tokens,
                  scheme: scheme,
                  numberFormat: numberFormat,
                  pageSize: pageSize,
                  pageSizeOptions: pageSizeOptions,
                  onPageSizeChanged: onPageSizeChanged,
                  itemsPerPageLabel: resolvedItemsPerPageLabel,
                  showingLabelPrefix: showingLabelPrefix,
                  showingLabelMiddle: showingLabelMiddle,
                  rangeStart: rangeStart,
                  rangeEnd: rangeEnd,
                  totalItems: totalItems,
                  entityLabel: entityLabel,
                ),
                SizedBox(height: tokens.gapMd),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _PaginationControls(
                    style: style,
                    scheme: scheme,
                    tokens: tokens,
                    currentPage: currentPage,
                    totalPages: totalPages,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onPageSelected: onPageSelected,
                  ),
                ),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryRow(
                    isMobile: false,
                    tokens: tokens,
                    scheme: scheme,
                    numberFormat: numberFormat,
                    pageSize: pageSize,
                    pageSizeOptions: pageSizeOptions,
                    onPageSizeChanged: onPageSizeChanged,
                    itemsPerPageLabel: resolvedItemsPerPageLabel,
                    showingLabelPrefix: showingLabelPrefix,
                    showingLabelMiddle: showingLabelMiddle,
                    rangeStart: rangeStart,
                    rangeEnd: rangeEnd,
                    totalItems: totalItems,
                    entityLabel: entityLabel,
                  ),
                ),
                _PaginationControls(
                  style: style,
                  scheme: scheme,
                  tokens: tokens,
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onPrevious: onPrevious,
                  onNext: onNext,
                  onPageSelected: onPageSelected,
                ),
              ],
            ),
    );

    return Material(
      color: scheme.surface,
      child: decorated,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.isMobile,
    required this.tokens,
    required this.scheme,
    required this.numberFormat,
    required this.pageSize,
    required this.pageSizeOptions,
    required this.onPageSizeChanged,
    required this.itemsPerPageLabel,
    required this.showingLabelPrefix,
    required this.showingLabelMiddle,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalItems,
    required this.entityLabel,
  });

  final bool isMobile;
  final AppThemeTokens tokens;
  final ColorScheme scheme;
  final NumberFormat numberFormat;
  final int pageSize;
  final List<int>? pageSizeOptions;
  final ValueChanged<int>? onPageSizeChanged;
  final String itemsPerPageLabel;
  final String showingLabelPrefix;
  final String showingLabelMiddle;
  final int rangeStart;
  final int rangeEnd;
  final int totalItems;
  final String entityLabel;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).appTypography;
    final labelStyle = typography.caption.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final emphasisStyle = typography.caption.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    );

    final hasPageSizeControl =
        pageSizeOptions != null &&
        pageSizeOptions!.isNotEmpty &&
        onPageSizeChanged != null;

    final pageSizeBlock = hasPageSizeControl
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(itemsPerPageLabel, style: labelStyle),
              SizedBox(width: tokens.gapSm),
              _PageSizeDropdown(
                value: pageSize,
                options: pageSizeOptions!,
                onChanged: onPageSizeChanged!,
              ),
            ],
          )
        : null;

    final summary = Text.rich(
      TextSpan(
        style: labelStyle,
        children: <InlineSpan>[
          TextSpan(text: showingLabelPrefix),
          TextSpan(
            text:
                '${numberFormat.format(rangeStart)}-'
                '${numberFormat.format(rangeEnd)}',
            style: emphasisStyle,
          ),
          TextSpan(text: showingLabelMiddle),
          TextSpan(
            text: numberFormat.format(totalItems),
            style: emphasisStyle,
          ),
          TextSpan(text: ' $entityLabel'),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (pageSizeBlock != null) ...<Widget>[
            pageSizeBlock,
            SizedBox(height: tokens.gapSm),
          ],
          summary,
        ],
      );
    }

    return Row(
      children: <Widget>[
        if (pageSizeBlock != null) ...<Widget>[
          pageSizeBlock,
          SizedBox(width: tokens.gapMd),
        ],
        Expanded(child: summary),
      ],
    );
  }
}

class _PageSizeDropdown extends StatelessWidget {
  const _PageSizeDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kCompactPageSizeDropdownWidth,
      child: AppDropdownField<int>(
        value: value,
        options: options
            .map((n) => AppDropdownOption<int>(value: n, label: '$n'))
            .toList(growable: false),
        density: AppTextFieldDensity.compact,
        onChanged: (v) {
          if (v != null) {
            onChanged(v);
          }
        },
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.style,
    required this.scheme,
    required this.tokens,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSelected,
  });

  final AppTablePaginationFooterStyle style;
  final ColorScheme scheme;
  final AppThemeTokens tokens;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).appTypography;
    final l10n = AppLocalizations.of(context);
    final slots = buildPaginationPageSlots(
      currentPage: currentPage,
      totalPages: totalPages,
    );

    final canPrev = currentPage > 1 && totalPages > 0;
    final canNext = currentPage < totalPages && totalPages > 0;

    final pageChunks = <Widget>[];
    for (final slot in slots) {
      if (slot == null) {
        pageChunks.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.gapXs),
            child: Text(
              '...',
              style: typography.body.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      } else {
        pageChunks.add(
          _PageNumberCell(
            page: slot,
            selected: slot == currentPage,
            minSize: style.pageNumberMinSize,
            cornerRadius: style.cornerRadius,
            scheme: scheme,
            onTap: () => onPageSelected(slot),
          ),
        );
      }
      pageChunks.add(SizedBox(width: tokens.gapXs));
    }
    if (pageChunks.isNotEmpty) {
      pageChunks.removeLast();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _PaginationIconButton(
          tooltip: l10n.reportPaginationPrevious,
          icon: Icons.chevron_left_rounded,
          onPressed: canPrev ? onPrevious : null,
          size: style.iconButtonSize,
          cornerRadius: style.cornerRadius,
          scheme: scheme,
        ),
        SizedBox(width: tokens.gapXs),
        ...pageChunks,
        _PaginationIconButton(
          tooltip: l10n.reportPaginationNext,
          icon: Icons.chevron_right_rounded,
          onPressed: canNext ? onNext : null,
          size: style.iconButtonSize,
          cornerRadius: style.cornerRadius,
          scheme: scheme,
        ),
      ],
    );
  }
}

class _PaginationIconButton extends StatelessWidget {
  const _PaginationIconButton({
    required this.icon,
    required this.onPressed,
    required this.size,
    required this.cornerRadius,
    required this.scheme,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double cornerRadius;
  final ColorScheme scheme;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: enabled
              ? scheme.surfaceContainerLow
              : scheme.surfaceContainerHighest.withValues(alpha: 0.48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(
                alpha: enabled ? 0.72 : 0.4,
              ),
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(cornerRadius),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return scheme.primary.withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.hovered)) {
                return scheme.primary.withValues(alpha: 0.04);
              }
              return null;
            }),
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageNumberCell extends StatelessWidget {
  const _PageNumberCell({
    required this.page,
    required this.selected,
    required this.minSize,
    required this.cornerRadius,
    required this.scheme,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final double minSize;
  final double cornerRadius;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '$page';
    final textStyle = Theme.of(context).appTypography.utilityOverline.copyWith(
      letterSpacing: 0.2,
      color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );
    final borderColor = selected
        ? scheme.primary.withValues(alpha: 0.22)
        : scheme.outlineVariant.withValues(alpha: 0.56);

    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(context).reportPaginationPageNumber(page),
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(cornerRadius),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return scheme.primary.withValues(alpha: 0.04);
            }
            return null;
          }),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minSize,
              minHeight: minSize,
            ),
            child: Center(
              child: Text(label, style: textStyle),
            ),
          ),
        ),
      ),
    );
  }
}
