import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column_chooser.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:flutter/material.dart';

/// Action bar rendered above the grid.
///
/// Features are gated by booleans in [AppReportViewerStyle]:
/// - search bar
/// - density toggle
/// - column chooser
/// - export (PDF/Excel) dropdown
/// - print
/// - refresh
class AppReportToolbar<T> extends StatefulWidget {
  const AppReportToolbar({
    required this.style,
    required this.columns,
    required this.visibleColumnKeys,
    required this.currentDensity,
    super.key,
    this.events = const AppReportEvents(),
    this.searchTerm,
    this.isLoading = false,
  });

  final AppReportViewerStyle style;
  final AppReportEvents<T> events;
  final List<AppReportColumn<T>> columns;
  final Set<String> visibleColumnKeys;
  final AppReportDensity currentDensity;
  final String? searchTerm;
  final bool isLoading;

  @override
  State<AppReportToolbar<T>> createState() => _AppReportToolbarState<T>();
}

class _AppReportToolbarState<T> extends State<AppReportToolbar<T>> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.searchTerm ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant AppReportToolbar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchTerm != widget.searchTerm &&
        widget.searchTerm != _searchController.text) {
      _searchController.text = widget.searchTerm ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final style = widget.style;

    final hasAnyAction = style.showRefreshAction ||
        style.showExportActions ||
        style.showPrintAction ||
        style.showDensityToggle ||
        style.showColumnChooser;

    if (!style.showSearchBar && !hasAnyAction) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (style.showSearchBar)
            SizedBox(
              width: 220,
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      tokens.formFieldRadius,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            widget.events.onSearchChanged?.call('');
                          },
                        )
                      : null,
                ),
                onChanged: widget.events.onSearchChanged,
              ),
            ),
          if (style.showDensityToggle) _DensityToggle(
            current: widget.currentDensity,
            onChanged: widget.events.onDensityChanged,
          ),
          if (style.showColumnChooser)
            Tooltip(
              message: 'Colunas visíveis',
              child: OutlinedButton.icon(
                icon: const Icon(Icons.view_column_outlined, size: 18),
                label: const Text('Colunas'),
                onPressed: () async {
                  final result = await showAppReportColumnChooser<T>(
                    context: context,
                    columns: widget.columns,
                    currentlyVisible: widget.visibleColumnKeys,
                  );
                  if (result != null) {
                    widget.events.onColumnVisibilityChanged?.call(result);
                  }
                },
              ),
            ),
          if (style.showExportActions)
            _ExportButton(
              onExportPdf: () => widget.events.onExportRequested?.call(
                const AppReportExportRequest(
                  format: AppReportExportFormat.pdf,
                ),
              ),
              onExportExcel: () => widget.events.onExportRequested?.call(
                const AppReportExportRequest(
                  format: AppReportExportFormat.excel,
                ),
              ),
            ),
          if (style.showPrintAction)
            Tooltip(
              message: 'Imprimir',
              child: OutlinedButton.icon(
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Imprimir'),
                onPressed: widget.events.onPrintRequested,
              ),
            ),
          if (style.showRefreshAction)
            Tooltip(
              message: 'Atualizar',
              child: IconButton.outlined(
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                onPressed: widget.isLoading
                    ? null
                    : () => widget.events.onRefresh?.call(),
                tooltip: 'Atualizar dados',
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Density toggle
// ---------------------------------------------------------------------------

class _DensityToggle extends StatelessWidget {
  const _DensityToggle({
    required this.current,
    this.onChanged,
  });

  final AppReportDensity current;
  final ValueChanged<AppReportDensity>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppReportDensity>(
      segments: const <ButtonSegment<AppReportDensity>>[
        ButtonSegment(
          value: AppReportDensity.compact,
          icon: Tooltip(
            message: 'Compacto',
            child: Icon(Icons.density_small_rounded, size: 18),
          ),
        ),
        ButtonSegment(
          value: AppReportDensity.comfortable,
          icon: Tooltip(
            message: 'Confortável',
            child: Icon(Icons.density_medium_rounded, size: 18),
          ),
        ),
        ButtonSegment(
          value: AppReportDensity.expanded,
          icon: Tooltip(
            message: 'Expandido',
            child: Icon(Icons.density_large_rounded, size: 18),
          ),
        ),
      ],
      selected: <AppReportDensity>{current},
      onSelectionChanged: (sel) => onChanged?.call(sel.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStateProperty.all(const Size(36, 36)),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Export button
// ---------------------------------------------------------------------------

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.onExportPdf,
    required this.onExportExcel,
  });

  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (ctx, controller, child) {
        return OutlinedButton.icon(
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Exportar'),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: <Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: onExportPdf,
          child: const Text('Exportar PDF'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.table_chart_outlined),
          onPressed: onExportExcel,
          child: const Text('Exportar Excel'),
        ),
      ],
    );
  }
}
