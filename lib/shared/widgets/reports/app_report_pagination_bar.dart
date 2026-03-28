import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';

/// Enhanced pagination bar for the report viewer (AppReportViewer).
///
/// Shows:
/// - "Exibindo X a Y de Z registros" label
/// - Page number buttons (compact when many pages)
/// - Previous / next navigation
/// - Page size selector
class AppReportPaginationBar extends StatelessWidget {
  const AppReportPaginationBar({
    required this.pageInfo,
    super.key,
    this.onPageChanged,
    this.onPageSizeChanged,
    this.availablePageSizes = const <int>[5, 10, 20, 50],
    this.isLoading = false,
  });

  final AppReportPageInfo pageInfo;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> availablePageSizes;
  final bool isLoading;

  static const int _maxDirectPageButtons = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: tokens.gapMd,
      runSpacing: tokens.gapSm,
      children: <Widget>[
        _CountLabel(pageInfo: pageInfo),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _prevButton(context),
            SizedBox(width: tokens.gapSm),
            _pageButtons(context),
            SizedBox(width: tokens.gapSm),
            _nextButton(context),
          ],
        ),
        _PageSizeSelector(
          current: pageInfo.pageSize,
          options: availablePageSizes,
          onChanged: isLoading ? null : onPageSizeChanged,
        ),
      ],
    );
  }

  Widget _prevButton(BuildContext context) {
    return IconButton.outlined(
      icon: const Icon(Icons.chevron_left_rounded),
      tooltip: 'Página anterior',
      onPressed: (!isLoading && pageInfo.hasPreviousPage)
          ? () => onPageChanged?.call(pageInfo.currentPage - 1)
          : null,
    );
  }

  Widget _nextButton(BuildContext context) {
    return IconButton.outlined(
      icon: const Icon(Icons.chevron_right_rounded),
      tooltip: 'Próxima página',
      onPressed: (!isLoading && pageInfo.hasNextPage)
          ? () => onPageChanged?.call(pageInfo.currentPage + 1)
          : null,
    );
  }

  Widget _pageButtons(BuildContext context) {
    final theme = Theme.of(context);
    final total = pageInfo.totalPages;
    final current = pageInfo.currentPage;

    if (total <= 1) {
      return Text(
        '$current / $total',
        style: theme.textTheme.labelLarge,
      );
    }

    if (total <= _maxDirectPageButtons) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(total, (i) {
          final page = i + 1;
          return _PageButton(
            page: page,
            isCurrent: page == current,
            isLoading: isLoading,
            onTap: () => onPageChanged?.call(page),
          );
        }),
      );
    }

    // Compact: first, ...gap..., around current, ...gap..., last
    final pages = _buildCompactPages(current, total);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pages.map<Widget>((page) {
        if (page == -1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: theme.textTheme.bodyMedium),
          );
        }
        return _PageButton(
          page: page,
          isCurrent: page == current,
          isLoading: isLoading,
          onTap: () => onPageChanged?.call(page),
        );
      }).toList(growable: false),
    );
  }

  static List<int> _buildCompactPages(int current, int total) {
    final result = <int>{}..add(1)..add(total);
    for (var i = current - 1; i <= current + 1; i++) {
      if (i >= 1 && i <= total) result.add(i);
    }
    final sorted = result.toList()..sort();
    final withGaps = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      withGaps.add(sorted[i]);
      if (i < sorted.length - 1 && sorted[i + 1] - sorted[i] > 1) {
        withGaps.add(-1);
      }
    }
    return withGaps;
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.pageInfo});

  final AppReportPageInfo pageInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = pageInfo.firstRowIndex;
    final last = pageInfo.lastRowIndex;
    final total = pageInfo.totalRows;

    return Semantics(
      liveRegion: true,
      child: Text(
        'Exibindo $first a $last de $total registros',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.isCurrent,
    required this.onTap,
    required this.isLoading,
  });

  final int page;
  final bool isCurrent;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCurrent) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
          child: Text('$page'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: isLoading ? null : onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),
        child: Text('$page'),
      ),
    );
  }
}

class _PageSizeSelector extends StatelessWidget {
  const _PageSizeSelector({
    required this.current,
    required this.options,
    this.onChanged,
  });

  final int current;
  final List<int> options;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOptions =
        options.contains(current) ? options : <int>[current, ...options]
          ..sort();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Linhas por página:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        DropdownButton<int>(
          value: current,
          isDense: true,
          underline: const SizedBox.shrink(),
          items: effectiveOptions.map((size) {
            return DropdownMenuItem<int>(
              value: size,
              child: Text('$size'),
            );
          }).toList(growable: false),
          onChanged: onChanged != null
              ? (v) {
                  if (v != null) onChanged!(v);
                }
              : null,
        ),
      ],
    );
  }
}
