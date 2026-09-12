import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/sales/presentation/sales_notas_entrada_view.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_report_toolbar.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_resumo_table.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_table.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

class SalesNotasEntradaReportCard extends StatelessWidget {
  const SalesNotasEntradaReportCard({
    required this.l10n,
    required this.view,
    required this.notesRows,
    required this.summaryRows,
    required this.totalValorCompra,
    required this.isLoading,
    required this.searchTerm,
    required this.onSearchChanged,
    required this.onViewChanged,
    required this.paginationFooter,
    super.key,
    this.supplierScopeName,
    this.onClearSupplierScope,
    this.onSupplierSelected,
    this.headerTrailing,
    this.loadErrorPanel,
  });

  final AppLocalizations l10n;
  final SalesNotasEntradaView view;
  final List<NotaEntradaRow> notesRows;
  final List<NotaEntradaResumoFornecedorRow> summaryRows;
  final double totalValorCompra;
  final bool isLoading;
  final String? searchTerm;
  final String? supplierScopeName;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SalesNotasEntradaView> onViewChanged;
  final VoidCallback? onClearSupplierScope;
  final ValueChanged<NotaEntradaResumoFornecedorRow>? onSupplierSelected;
  final Widget paginationFooter;
  final Widget? headerTrailing;
  final Widget? loadErrorPanel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final hasSearch = (searchTerm ?? '').trim().isNotEmpty;
    final rowsAreEmpty = switch (view) {
      SalesNotasEntradaView.notes => notesRows.isEmpty,
      SalesNotasEntradaView.bySupplier => summaryRows.isEmpty,
    };

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SalesNotasEntradaReportToolbar(
            searchTerm: searchTerm,
            onSearchChanged: onSearchChanged,
            view: view,
            onViewChanged: onViewChanged,
            supplierScopeName: supplierScopeName,
            onClearSupplierScope: onClearSupplierScope,
            headerTrailing: headerTrailing,
          ),
          SizedBox(height: tokens.contentSpacing),
          if (loadErrorPanel != null) ...<Widget>[
            loadErrorPanel!,
            SizedBox(height: tokens.sectionSpacing),
          ],
          if (isLoading && rowsAreEmpty)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel: l10n.reportLoadingTableSemantics,
              child: appDataGridSkeletonColumn(
                tokens: tokens,
                dividerColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.35,
                ),
              ),
            )
          else if (rowsAreEmpty && loadErrorPanel == null)
            AppInlineErrorPanel(
              variant: AppInlineErrorPanelVariant.plain,
              tone: AppInlinePanelTone.informational,
              message: switch (view) {
                SalesNotasEntradaView.notes =>
                  hasSearch
                      ? l10n.salesNotasEntradaEmptySearch
                      : l10n.salesNotasEntradaEmpty,
                SalesNotasEntradaView.bySupplier =>
                  hasSearch
                      ? l10n.salesNotasEntradaSummaryEmptySearch
                      : l10n.salesNotasEntradaSummaryEmpty,
              },
            )
          else ...<Widget>[
            AppSkeleton(
              enabled: isLoading,
              loadingSemanticsLabel: l10n.reportLoadingTableSemantics,
              child: switch (view) {
                SalesNotasEntradaView.notes => SalesNotasEntradaNotesGrid(
                  l10n: l10n,
                  rows: notesRows,
                  totalValorCompra: totalValorCompra,
                ),
                SalesNotasEntradaView.bySupplier => SalesNotasEntradaResumoGrid(
                  l10n: l10n,
                  rows: summaryRows,
                  totalValorCompra: totalValorCompra,
                  onSupplierSelected: isLoading ? null : onSupplierSelected,
                ),
              },
            ),
            SizedBox(height: tokens.gapSm),
            paginationFooter,
          ],
        ],
      ),
    );
  }
}
