import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';

/// Pagination bar for the report viewer, aligned with the shared table footer.
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

  @override
  Widget build(BuildContext context) {
    final rangeStart =
        pageInfo.hasInvalidDisplayedRange || pageInfo.totalRows == 0
        ? 0
        : pageInfo.firstRowIndex;
    final rangeEnd = pageInfo.hasInvalidDisplayedRange
        ? 0
        : pageInfo.lastRowIndex;

    return AppTablePaginationFooter(
      currentPage: pageInfo.currentPage,
      totalPages: pageInfo.totalPages,
      pageSize: pageInfo.pageSize,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      totalItems: pageInfo.totalRows,
      entityLabel: 'registros',
      pageSizeOptions: availablePageSizes,
      itemsPerPageLabel: 'Linhas por pagina:',
      style: const AppTablePaginationFooterStyle(showTopBorder: false),
      onPageSizeChanged: isLoading
          ? null
          : (size) => onPageSizeChanged?.call(size),
      onPrevious: (!isLoading && pageInfo.hasPreviousPage)
          ? () => onPageChanged?.call(pageInfo.currentPage - 1)
          : null,
      onNext: (!isLoading && pageInfo.hasNextPage)
          ? () => onPageChanged?.call(pageInfo.currentPage + 1)
          : null,
      onPageSelected: (page) {
        if (!isLoading) {
          onPageChanged?.call(page);
        }
      },
    );
  }
}
