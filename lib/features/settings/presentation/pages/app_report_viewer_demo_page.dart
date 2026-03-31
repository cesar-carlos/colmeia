import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_status_badge.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_export_handler.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:colmeia/shared/widgets/reports/app_report_viewer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Demo data model
// ---------------------------------------------------------------------------

enum _OrderStatus { pending, approved, shipped, delivered, cancelled }

class _SaleRow {
  const _SaleRow({
    required this.id,
    required this.seller,
    required this.store,
    required this.product,
    required this.status,
    required this.orders,
    required this.revenue,
    required this.date,
    required this.margin,
  });

  final String id;
  final String seller;
  final String store;
  final String product;
  final _OrderStatus status;
  final int orders;
  final double revenue;
  final DateTime date;
  final double margin;
}

// ---------------------------------------------------------------------------
// Demo page
// ---------------------------------------------------------------------------

class AppReportViewerDemoPage extends StatefulWidget {
  const AppReportViewerDemoPage({super.key});

  @override
  State<AppReportViewerDemoPage> createState() =>
      _AppReportViewerDemoPageState();
}

class _AppReportViewerDemoPageState extends State<AppReportViewerDemoPage> {
  static const int _totalRows = 87;
  static const int _pageSize = 10;

  late List<_SaleRow> _allRows;
  late AppReportQuery _query;
  List<_SaleRow> _selectedRows = <_SaleRow>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _allRows = _generateFakeRows();
    _query = const AppReportQuery(pageSize: _pageSize);
  }

  List<_SaleRow> get _currentRows {
    var rows = _allRows;

    final search = _query.searchTerm;
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      rows = rows.where((r) {
        return r.seller.toLowerCase().contains(lower) ||
            r.store.toLowerCase().contains(lower) ||
            r.product.toLowerCase().contains(lower);
      }).toList();
    }

    final store = _query.filters['store'] as String?;
    if (store != null && store.isNotEmpty) {
      rows = rows.where((r) => r.store == store).toList();
    }

    final status = _query.filters['status'] as String?;
    if (status != null && status.isNotEmpty) {
      final enumVal = _OrderStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => _OrderStatus.pending,
      );
      rows = rows.where((r) => r.status == enumVal).toList();
    }

    if (_query.sorts.isNotEmpty) {
      final sort = _query.sorts.first;
      rows = List<_SaleRow>.from(rows)
        ..sort((a, b) {
          final int cmp;
          switch (sort.columnKey) {
            case 'seller':
              cmp = a.seller.compareTo(b.seller);
            case 'store':
              cmp = a.store.compareTo(b.store);
            case 'orders':
              cmp = a.orders.compareTo(b.orders);
            case 'revenue':
              cmp = a.revenue.compareTo(b.revenue);
            case 'margin':
              cmp = a.margin.compareTo(b.margin);
            default:
              cmp = 0;
          }
          return sort.direction == AppReportSortDirection.ascending
              ? cmp
              : -cmp;
        });
    }

    return rows;
  }

  List<_SaleRow> get _pageRows {
    final filtered = _currentRows;
    final start = (_query.page - 1) * _query.pageSize;
    final end = (start + _query.pageSize).clamp(0, filtered.length);
    if (start >= filtered.length) return <_SaleRow>[];
    return filtered.sublist(start, end);
  }

  AppReportPageInfo get _pageInfo {
    final totalFiltered = _currentRows.length;
    final totalPages = totalFiltered == 0
        ? 0
        : (totalFiltered / _query.pageSize).ceil().clamp(1, 999);
    return AppReportPageInfo(
      currentPage: _query.page,
      pageSize: _query.pageSize,
      totalRows: totalFiltered,
      totalPages: totalPages,
    );
  }

  List<AppReportSummaryItem> get _summaries {
    final rows = _currentRows;
    final totalRevenue = rows.fold<double>(0, (s, r) => s + r.revenue);
    final totalOrders = rows.fold<int>(0, (s, r) => s + r.orders);
    final avgMargin = rows.isEmpty
        ? 0.0
        : rows.fold<double>(0, (s, r) => s + r.margin) / rows.length;
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return <AppReportSummaryItem>[
      AppReportSummaryItem(
        label: 'Receita total',
        value: currencyFmt.format(totalRevenue),
        icon: Icons.payments_outlined,
      ),
      AppReportSummaryItem(
        label: 'Total de pedidos',
        value: NumberFormat.decimalPattern('pt_BR').format(totalOrders),
        icon: Icons.shopping_bag_outlined,
      ),
      AppReportSummaryItem(
        label: 'Margem média',
        value: '${avgMargin.toStringAsFixed(1)}%',
        icon: Icons.percent_rounded,
        detailLabel: 'dos registros filtrados',
      ),
      AppReportSummaryItem(
        label: 'Registros',
        value: '${rows.length}',
        icon: Icons.table_rows_outlined,
      ),
    ];
  }

  /// Applies query immediately. Local fake data — no artificial delay so the
  /// viewer skeleton does not flash on every search keystroke.
  void _onQueryChanged(AppReportQuery query) {
    setState(() {
      _query = query;
      _selectedRows = <_SaleRow>[];
      final total = _currentRows.length;
      if (total == 0) {
        _query = _query.copyWith(page: 1);
      } else {
        final maxPage = (total / _query.pageSize).ceil();
        final clamped = _query.page.clamp(1, maxPage);
        if (clamped != _query.page) {
          _query = _query.copyWith(page: clamped);
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _allRows = _generateFakeRows();
      _selectedRows = <_SaleRow>[];
      _isLoading = false;
    });
  }

  Future<void> _onExportRequested(AppReportExportRequest request) async {
    final rows = switch (request.scope) {
      AppReportExportScope.allPages => _currentRows,
      AppReportExportScope.currentPage => _pageRows,
      AppReportExportScope.selection => _selectedRows,
    };

    try {
      await AppReportExportHandler.export<_SaleRow>(
        request: request,
        columns: _columns,
        rows: rows,
        title: 'Vendas por vendedor',
        subtitle: 'Demo — dados gerados automaticamente',
        summaryItems: _summaries,
        filters: _filters,
        filterValues: _query.filters,
        context: context,
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao exportar.')),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Columns
  // -------------------------------------------------------------------------

  static final NumberFormat _currencyFmt = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
  );
  static final DateFormat _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final NumberFormat _pctFmt = NumberFormat('#0.0', 'pt_BR');

  List<AppReportColumn<_SaleRow>> get _columns => <AppReportColumn<_SaleRow>>[
    const AppReportColumn<_SaleRow>(
      key: 'id',
      label: 'Nº',
      valueGetter: _getId,
      width: 60,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideNarrow,
    ),
    const AppReportColumn<_SaleRow>(
      key: 'seller',
      label: 'Vendedor',
      valueGetter: _getSeller,
      aggregations: <AppReportAggregation>[AppReportAggregation.count],
      groupable: true,
    ),
    const AppReportColumn<_SaleRow>(
      key: 'store',
      label: 'Loja',
      valueGetter: _getStore,
      groupable: true,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideExtraNarrow,
    ),
    const AppReportColumn<_SaleRow>(
      key: 'product',
      label: 'Produto',
      valueGetter: _getProduct,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideWide,
    ),
    AppReportColumn<_SaleRow>(
      key: 'status',
      label: 'Status',
      valueGetter: _getStatus,
      formatter: (v) => _statusLabel(v! as _OrderStatus),
      cellBuilder: (ctx, row, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: _StatusChip(status: row.status),
      ),
      width: 120,
      sortable: false,
      groupable: true,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideNarrow,
    ),
    const AppReportColumn<_SaleRow>(
      key: 'orders',
      label: 'Pedidos',
      valueGetter: _getOrders,
      numeric: true,
      aggregations: <AppReportAggregation>[
        AppReportAggregation.sum,
        AppReportAggregation.average,
      ],
      width: 80,
    ),
    AppReportColumn<_SaleRow>(
      key: 'revenue',
      label: 'Faturamento',
      valueGetter: _getRevenue,
      formatter: _currencyFmt.format,
      numeric: true,
      aggregations: <AppReportAggregation>[AppReportAggregation.sum],
      width: 130,
    ),
    AppReportColumn<_SaleRow>(
      key: 'margin',
      label: 'Margem',
      valueGetter: _getMargin,
      formatter: (v) => '${_pctFmt.format(v)}%',
      numeric: true,
      aggregations: <AppReportAggregation>[AppReportAggregation.average],
      width: 90,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideMedium,
    ),
    AppReportColumn<_SaleRow>(
      key: 'date',
      label: 'Data',
      valueGetter: _getDate,
      formatter: (v) => _dateFmt.format(v! as DateTime),
      width: 100,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideWide,
    ),
  ];

  static Object? _getId(_SaleRow r) => r.id;
  static Object? _getSeller(_SaleRow r) => r.seller;
  static Object? _getStore(_SaleRow r) => r.store;
  static Object? _getProduct(_SaleRow r) => r.product;
  static Object? _getStatus(_SaleRow r) => r.status;
  static Object? _getOrders(_SaleRow r) => r.orders;
  static Object? _getRevenue(_SaleRow r) => r.revenue;
  static Object? _getMargin(_SaleRow r) => r.margin;
  static Object? _getDate(_SaleRow r) => r.date;

  // -------------------------------------------------------------------------
  // Filters
  // -------------------------------------------------------------------------

  static final List<AppReportFilterDescriptor> _filters =
      <AppReportFilterDescriptor>[
        const AppReportFilterDescriptor(
          name: 'search',
          label: 'Busca geral',
          type: AppReportFilterType.search,
          hint: 'Vendedor, loja ou produto',
        ),
        AppReportFilterDescriptor(
          name: 'store',
          label: 'Loja',
          type: AppReportFilterType.singleSelect,
          options: _stores
              .map((s) => AppReportFilterOption(value: s, label: s))
              .toList(),
        ),
        AppReportFilterDescriptor(
          name: 'status',
          label: 'Status do pedido',
          type: AppReportFilterType.singleSelect,
          options: _OrderStatus.values
              .map(
                (s) => AppReportFilterOption(
                  value: s.name,
                  label: _statusLabel(s),
                ),
              )
              .toList(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('AppReportViewer — Demo')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.contentSpacing,
              tokens.contentSpacing,
              tokens.contentSpacing,
              0,
            ),
            child: const AppShellPageIntro(
              eyebrow: 'Componentes compartilhados',
              title: 'Report Viewer',
              subtitle:
                  'Tabela ERP genérica com filtros, paginação, export, '
                  'agrupamento e seleção de colunas.',
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.contentSpacing,
              tokens.sectionSpacing,
              tokens.contentSpacing,
              0,
            ),
            child: _ReportViewerShowcaseCard(
              totalRows: _currentRows.length,
              selectedRows: _selectedRows.length,
              groupingDescription: _describeGroups(_query.groups),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: tokens.sectionSpacing),
              child: AppReportViewer<_SaleRow>(
                title: 'Vendas por vendedor',
                subtitle: 'Demonstração com dados sintéticos',
                contextChips: <String>[
                  'Loja: Todas',
                  'Período: 2025',
                  '${_currentRows.length} registros',
                  _describeGroups(_query.groups),
                ],
                columns: _columns,
                rows: _pageRows,
                pageInfo: _pageInfo,
                summaryItems: _summaries,
                filters: _filters,
                filterValues: _query.filters,
                selectedRows: _selectedRows,
                query: _query,
                events: AppReportEvents<_SaleRow>(
                  onQueryChanged: _onQueryChanged,
                  onRefresh: _onRefresh,
                  onExportRequested: _onExportRequested,
                  onGroupChanged: (groups) {
                    setState(() {
                      _query = _query.withGroups(groups);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_groupChangeMessage(groups)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onGroupStateChanged: (groups) {
                    setState(() {
                      _query = _query.withGroups(groups);
                    });
                  },
                  onGroupExpanded: (event) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_groupToggleMessage(event)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onGroupCollapsed: (event) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_groupToggleMessage(event)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onRowSelection: (rows) {
                    setState(() => _selectedRows = rows);
                  },
                  onRowTap: (row, _) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selecionado: ${row.seller}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                style: const AppReportViewerStyle(
                  showColumnChooser: true,
                  showGroupingChooser: true,
                  showDensityToggle: true,
                  showSearchBar: true,
                  showRowDetailOnTap: true,
                  allowMultiSelection: true,
                  filtersStartExpanded: false,
                ),
                isLoading: _isLoading,
                emptyMessage: 'Nenhum resultado para os filtros aplicados.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Fake data generation
  // -------------------------------------------------------------------------

  static const List<String> _sellers = <String>[
    'Ana Costa',
    'Bruno Lima',
    'Carla Souza',
    'Diego Alves',
    'Eduarda Nunes',
    'Fábio Torres',
    'Gabriela Rocha',
  ];

  static const List<String> _stores = <String>[
    'Loja Centro',
    'Loja Norte',
    'Loja Sul',
    'Loja Leste',
  ];

  static const List<String> _products = <String>[
    'Produto A',
    'Produto B',
    'Produto C',
    'Produto D',
    'Produto E',
    'Produto F',
  ];

  static List<_SaleRow> _generateFakeRows() {
    final rows = <_SaleRow>[];
    final baseDate = DateTime(2025);

    for (var i = 0; i < _totalRows; i++) {
      rows.add(
        _SaleRow(
          id: '${1000 + i}',
          seller: _sellers[i % _sellers.length],
          store: _stores[i % _stores.length],
          product: _products[i % _products.length],
          status: _OrderStatus.values[i % _OrderStatus.values.length],
          orders: 10 + (i * 3) % 90,
          revenue: 1500.0 + (i * 237.43) % 48000,
          date: baseDate.add(Duration(days: i * 3)),
          margin: 5.0 + (i * 1.7) % 35,
        ),
      );
    }

    return rows;
  }

  static String _statusLabel(_OrderStatus status) {
    return switch (status) {
      _OrderStatus.pending => 'Pendente',
      _OrderStatus.approved => 'Aprovado',
      _OrderStatus.shipped => 'Enviado',
      _OrderStatus.delivered => 'Entregue',
      _OrderStatus.cancelled => 'Cancelado',
    };
  }

  static String _describeGroups(List<AppReportGroupDescriptor> groups) {
    if (groups.isEmpty) {
      return 'Agrupamento: Nenhum';
    }

    final labels = groups
        .map((group) => _groupLabel(group.columnKey))
        .join(' / ');
    return 'Agrupamento: $labels';
  }

  static String _groupChangeMessage(List<AppReportGroupDescriptor> groups) {
    if (groups.isEmpty) {
      return 'Agrupamento removido';
    }

    final labels = groups
        .map((group) => _groupLabel(group.columnKey))
        .join(', ');
    return 'Agrupado por $labels';
  }

  static String _groupToggleMessage(AppReportGroupToggleEvent event) {
    final action = event.isExpanded ? 'expandido' : 'recolhido';
    final label = _groupLabel(event.columnKey);
    return '$label: ${event.groupKey} $action';
  }

  static String _groupLabel(String key) {
    return switch (key) {
      'seller' => 'Vendedor',
      'store' => 'Loja',
      'status' => 'Status',
      _ => key,
    };
  }
}

class _ReportViewerShowcaseCard extends StatelessWidget {
  const _ReportViewerShowcaseCard({
    required this.totalRows,
    required this.selectedRows,
    required this.groupingDescription,
  });

  final int totalRows;
  final int selectedRows;
  final String groupingDescription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return AppSectionCardWithHeading(
      padding: EdgeInsets.fromLTRB(
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing + tokens.gapSm,
      ),
      titleWidget: _ReportViewerShowcaseHeading(theme: theme, tokens: tokens),
      subtitle:
          'Viewer completo para cenários tabulares com filtros, resumo, '
          'agrupamento e exportação em uma única superfície.',
      headingTrailing: const _ReportViewerShowcaseBadge(),
      headingBottom: const _ReportViewerShowcaseLegend(),
      style: AppSectionCardWithHeadingStyle(
        titleTextStyle: theme.appTypography.sectionHeaderH2.copyWith(
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: theme.appTypography.caption.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          AppTagChip(label: '$totalRows registros'),
          if (selectedRows > 0) AppTagChip(label: '$selectedRows selecionados'),
          AppTagChip(label: groupingDescription),
          const AppTagChip(label: 'Filtros + toolbar + grid'),
        ],
      ),
    );
  }
}

class _ReportViewerShowcaseHeading extends StatelessWidget {
  const _ReportViewerShowcaseHeading({
    required this.theme,
    required this.tokens,
  });

  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.gapSm),
            child: Icon(
              Icons.table_rows_rounded,
              size: 18,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        SizedBox(width: tokens.gapMd),
        Expanded(
          child: Text(
            'Superfície tabular compartilhada',
            style: theme.appTypography.sectionHeaderH2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportViewerShowcaseBadge extends StatelessWidget {
  const _ReportViewerShowcaseBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          'ERP',
          style: theme.appTypography.utilityOverline.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _ReportViewerShowcaseLegend extends StatelessWidget {
  const _ReportViewerShowcaseLegend();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: const <Widget>[
        _ReportViewerLegendChip(label: 'Toolbar contextual'),
        _ReportViewerLegendChip(label: 'Filtros colapsáveis'),
        _ReportViewerLegendChip(label: 'Grid com agrupamento'),
      ],
    );
  }
}

class _ReportViewerLegendChip extends StatelessWidget {
  const _ReportViewerLegendChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          label,
          style: theme.appTypography.caption.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (status) {
      _OrderStatus.pending => ('Pendente', AppStatusBadgeVariant.warning),
      _OrderStatus.approved => ('Aprovado', AppStatusBadgeVariant.info),
      _OrderStatus.shipped => ('Enviado', AppStatusBadgeVariant.info),
      _OrderStatus.delivered => ('Entregue', AppStatusBadgeVariant.success),
      _OrderStatus.cancelled => ('Cancelado', AppStatusBadgeVariant.error),
    };

    return AppStatusBadge(
      label: label,
      variant: variant,
    );
  }
}
