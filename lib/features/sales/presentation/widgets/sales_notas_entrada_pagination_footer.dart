import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_notice.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Numbered catalog footer: page size, range summary, and page buttons.
class SalesNotasEntradaPaginationFooter extends StatelessWidget {
  const SalesNotasEntradaPaginationFooter({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalItems,
    required this.entityLabel,
    required this.enabled,
    required this.onPageSelected,
    required this.onPageSizeChanged,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int rangeStart;
  final int rangeEnd;
  final int totalItems;
  final String entityLabel;
  final bool enabled;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pageSizeLabel = NumberFormat.decimalPattern(
      l10n.localeName,
    ).format(pageSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTablePaginationFooter(
          currentPage: currentPage,
          totalPages: totalPages,
          pageSize: pageSize,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          totalItems: totalItems,
          entityLabel: entityLabel,
          pageSizeOptions: NotasEntradaFilter.allowedPageSizes,
          itemsPerPageLabel: l10n.reportPaginationItemsPerPage,
          enabled: enabled,
          onPageSizeChanged: onPageSizeChanged,
          onPrevious: currentPage > 1
              ? () => onPageSelected(currentPage - 1)
              : null,
          onNext: currentPage < totalPages
              ? () => onPageSelected(currentPage + 1)
              : null,
          onPageSelected: onPageSelected,
        ),
        AppTablePaginationNotice(
          totalPages: totalPages,
          message: l10n.salesNotasEntradaPaginationNotice(pageSizeLabel),
        ),
      ],
    );
  }
}
