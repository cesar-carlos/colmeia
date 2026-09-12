import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_pagination_footer.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_table.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

@immutable
class SalesNotasEntradaGridSnapshot {
  const SalesNotasEntradaGridSnapshot({
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalPages,
    required this.isLoading,
    this.searchTerm,
    this.loadFailure,
    this.selectedAgentId,
  });

  factory SalesNotasEntradaGridSnapshot.initial() {
    return const SalesNotasEntradaGridSnapshot(
      rows: <NotaEntradaRow>[],
      page: 1,
      pageSize: 50,
      totalCount: 0,
      rangeStart: 0,
      rangeEnd: 0,
      totalPages: 0,
      isLoading: false,
    );
  }

  final List<NotaEntradaRow> rows;
  final int page;
  final int pageSize;
  final int totalCount;
  final int rangeStart;
  final int rangeEnd;
  final int totalPages;
  final String? searchTerm;
  final bool isLoading;
  final AppFailure? loadFailure;
  final String? selectedAgentId;

  @override
  bool operator ==(Object other) {
    return other is SalesNotasEntradaGridSnapshot &&
        identical(rows, other.rows) &&
        page == other.page &&
        pageSize == other.pageSize &&
        totalCount == other.totalCount &&
        rangeStart == other.rangeStart &&
        rangeEnd == other.rangeEnd &&
        totalPages == other.totalPages &&
        searchTerm == other.searchTerm &&
        isLoading == other.isLoading &&
        identical(loadFailure, other.loadFailure) &&
        selectedAgentId == other.selectedAgentId;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(rows),
    page,
    pageSize,
    totalCount,
    rangeStart,
    rangeEnd,
    totalPages,
    searchTerm,
    isLoading,
    identityHashCode(loadFailure),
    selectedAgentId,
  );
}

class SalesNotasEntradaFullscreen extends StatelessWidget {
  const SalesNotasEntradaFullscreen({
    required this.snapshot,
    required this.onSearchChanged,
    required this.onPageSelected,
    required this.onPageSizeChanged,
    this.loadErrorPanel,
    super.key,
  });

  final SalesNotasEntradaGridSnapshot snapshot;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int> onPageSizeChanged;
  final Widget? loadErrorPanel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SalesNotasEntradaTable(
      l10n: l10n,
      rows: snapshot.rows,
      isLoading: snapshot.isLoading,
      searchTerm: snapshot.searchTerm,
      onSearchChanged: onSearchChanged,
      loadErrorPanel: loadErrorPanel,
      paginationFooter: SalesNotasEntradaPaginationFooter(
        currentPage: snapshot.page,
        totalPages: snapshot.totalPages,
        pageSize: snapshot.pageSize,
        rangeStart: snapshot.rangeStart,
        rangeEnd: snapshot.rangeEnd,
        totalItems: snapshot.totalCount,
        entityLabel: l10n.salesNotasEntradaEntityLabel,
        enabled: !snapshot.isLoading,
        onPageSelected: onPageSelected,
        onPageSizeChanged: onPageSizeChanged,
      ),
    );
  }
}
