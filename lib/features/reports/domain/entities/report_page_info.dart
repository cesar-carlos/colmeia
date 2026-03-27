class ReportPageInfo {
  const ReportPageInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRows,
    required this.totalPages,
  });

  final int currentPage;
  final int pageSize;
  final int totalRows;
  final int totalPages;
}
