import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/sales/presentation/sales_notas_entrada_view.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_pagination_footer.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_report_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

@immutable
class SalesNotasEntradaGridSnapshot {
  const SalesNotasEntradaGridSnapshot({
    required this.view,
    required this.notesRows,
    required this.summaryRows,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalValorCompra,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalPages,
    required this.isLoading,
    this.searchTerm,
    this.supplierScopeName,
    this.loadFailure,
    this.selectedAgentId,
  });

  factory SalesNotasEntradaGridSnapshot.initial() {
    return const SalesNotasEntradaGridSnapshot(
      view: SalesNotasEntradaView.notes,
      notesRows: <NotaEntradaRow>[],
      summaryRows: <NotaEntradaResumoFornecedorRow>[],
      page: 1,
      pageSize: 50,
      totalCount: 0,
      totalValorCompra: 0,
      rangeStart: 0,
      rangeEnd: 0,
      totalPages: 0,
      isLoading: false,
    );
  }

  final SalesNotasEntradaView view;
  final List<NotaEntradaRow> notesRows;
  final List<NotaEntradaResumoFornecedorRow> summaryRows;
  final int page;
  final int pageSize;
  final int totalCount;
  final double totalValorCompra;
  final int rangeStart;
  final int rangeEnd;
  final int totalPages;
  final String? searchTerm;
  final String? supplierScopeName;
  final bool isLoading;
  final AppFailure? loadFailure;
  final String? selectedAgentId;

  @override
  bool operator ==(Object other) {
    return other is SalesNotasEntradaGridSnapshot &&
        view == other.view &&
        identical(notesRows, other.notesRows) &&
        identical(summaryRows, other.summaryRows) &&
        page == other.page &&
        pageSize == other.pageSize &&
        totalCount == other.totalCount &&
        totalValorCompra == other.totalValorCompra &&
        rangeStart == other.rangeStart &&
        rangeEnd == other.rangeEnd &&
        totalPages == other.totalPages &&
        searchTerm == other.searchTerm &&
        supplierScopeName == other.supplierScopeName &&
        isLoading == other.isLoading &&
        identical(loadFailure, other.loadFailure) &&
        selectedAgentId == other.selectedAgentId;
  }

  @override
  int get hashCode => Object.hash(
    view,
    identityHashCode(notesRows),
    identityHashCode(summaryRows),
    page,
    pageSize,
    totalCount,
    totalValorCompra,
    rangeStart,
    rangeEnd,
    totalPages,
    searchTerm,
    supplierScopeName,
    isLoading,
    identityHashCode(loadFailure),
    selectedAgentId,
  );
}

class SalesNotasEntradaFullscreen extends StatelessWidget {
  const SalesNotasEntradaFullscreen({
    required this.snapshot,
    required this.onSearchChanged,
    required this.onViewChanged,
    required this.onPageSelected,
    required this.onPageSizeChanged,
    this.onClearSupplierScope,
    this.onSupplierSelected,
    this.loadErrorPanel,
    super.key,
  });

  final SalesNotasEntradaGridSnapshot snapshot;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SalesNotasEntradaView> onViewChanged;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback? onClearSupplierScope;
  final ValueChanged<NotaEntradaResumoFornecedorRow>? onSupplierSelected;
  final Widget? loadErrorPanel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SalesNotasEntradaReportCard(
      l10n: l10n,
      view: snapshot.view,
      notesRows: snapshot.notesRows,
      summaryRows: snapshot.summaryRows,
      totalValorCompra: snapshot.totalValorCompra,
      isLoading: snapshot.isLoading,
      searchTerm: snapshot.searchTerm,
      supplierScopeName: snapshot.supplierScopeName,
      onSearchChanged: onSearchChanged,
      onViewChanged: onViewChanged,
      onClearSupplierScope: onClearSupplierScope,
      onSupplierSelected: onSupplierSelected,
      loadErrorPanel: loadErrorPanel,
      paginationFooter: SalesNotasEntradaPaginationFooter(
        currentPage: snapshot.page,
        totalPages: snapshot.totalPages,
        pageSize: snapshot.pageSize,
        rangeStart: snapshot.rangeStart,
        rangeEnd: snapshot.rangeEnd,
        totalItems: snapshot.totalCount,
        entityLabel: switch (snapshot.view) {
          SalesNotasEntradaView.notes => l10n.salesNotasEntradaEntityLabel,
          SalesNotasEntradaView.bySupplier =>
            l10n.salesNotasEntradaSummaryEntityLabel,
        },
        enabled: !snapshot.isLoading,
        onPageSelected: onPageSelected,
        onPageSizeChanged: onPageSizeChanged,
      ),
    );
  }
}
