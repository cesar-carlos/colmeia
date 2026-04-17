import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/preferences/persisted_filter_map_codec.dart';
import 'package:colmeia/core/preferences/persisted_page_session_store.dart';
import 'package:colmeia/features/settings/presentation/widgets/app_report_numerical_detailing_demo_section.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Demo data model
// ---------------------------------------------------------------------------

enum _OrderStatus { pending, approved, shipped, delivered, cancelled }

class _SaleRow {
  const _SaleRow({
    required this.id,
    required this.product,
    required this.category,
    required this.store,
    required this.status,
    required this.orders,
    required this.revenue,
    required this.date,
    required this.margin,
  });

  final String id;
  final String product;
  final String category;
  final String store;
  final _OrderStatus status;
  final int orders;
  final double revenue;
  final DateTime date;
  final double margin;

  double get unitPrice => orders == 0 ? 0 : revenue / orders;
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

PersistedFilterMapSchema _buildReportViewerDemoRestoreFiltersSchema() {
  return PersistedFilterMapSchema(
    rules: <PersistedFilterRule>[
      PersistedFilterMapSchema.trimmedString('search'),
      PersistedFilterMapSchema.trimmedString('category'),
      PersistedFilterMapSchema.trimmedString('store'),
      PersistedFilterMapSchema.boolean('premiumOnly'),
      PersistedFilterMapSchema.dateRangeFromEpoch(
        targetKey: 'period',
        startEpochKey: 'periodStartMs',
        endEpochKey: 'periodEndMs',
      ),
    ],
  );
}

PersistedFilterMapSchema _buildReportViewerDemoPersistFiltersSchema() {
  return PersistedFilterMapSchema(
    rules: <PersistedFilterRule>[
      PersistedFilterMapSchema.trimmedString('search'),
      PersistedFilterMapSchema.trimmedString('category'),
      PersistedFilterMapSchema.trimmedString('store'),
      PersistedFilterMapSchema.boolean('premiumOnly'),
      PersistedFilterMapSchema.dateRangeToEpoch(
        sourceKey: 'period',
        startEpochKey: 'periodStartMs',
        endEpochKey: 'periodEndMs',
      ),
    ],
  );
}

class _AppReportViewerDemoPageState extends State<AppReportViewerDemoPage> {
  static const int _totalRows = 87;
  static const int _pageSize = 10;
  static const String _sessionNamespace = 'settings.app_report_viewer_demo';
  static const String _filtersSessionKey = 'filters.v1';
  static final PersistedFilterMapSchema _restoreFiltersSchema =
      _buildReportViewerDemoRestoreFiltersSchema();
  static final PersistedFilterMapSchema _persistFiltersSchema =
      _buildReportViewerDemoPersistFiltersSchema();

  late List<_SaleRow> _allRows;
  late AppReportQuery _query;
  late final PersistedPageSessionStore _sessionStore;
  List<_SaleRow> _selectedRows = <_SaleRow>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    _sessionStore = PersistedPageSessionStore(
      prefs: prefs,
      namespace: _sessionNamespace,
    );
    _allRows = _generateFakeRows();
    _query = AppReportQuery(
      pageSize: _pageSize,
      filters: _restoreSavedFilters(),
    );
  }

  List<_SaleRow> get _currentRows {
    var rows = _allRows;

    final search = _query.searchTerm ?? _query.filters['search'] as String?;
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      rows = rows.where((r) {
        return r.id.toLowerCase().contains(lower) ||
            r.store.toLowerCase().contains(lower) ||
            r.product.toLowerCase().contains(lower) ||
            r.category.toLowerCase().contains(lower);
      }).toList();
    }

    final category = _query.filters['category'] as String?;
    if (category != null && category.isNotEmpty) {
      rows = rows.where((r) => r.category == category).toList();
    }

    final store = _query.filters['store'] as String?;
    if (store != null && store.isNotEmpty) {
      rows = rows.where((r) => r.store == store).toList();
    }

    final period = _query.filters['period'] as DateTimeRange?;
    if (period != null) {
      rows = rows
          .where(
            (r) =>
                !r.date.isBefore(period.start) && !r.date.isAfter(period.end),
          )
          .toList();
    }

    final premiumOnly = _query.filters['premiumOnly'] as bool? ?? false;
    if (premiumOnly) {
      rows = rows.where((r) => r.unitPrice >= 1000).toList();
    }

    if (_query.sorts.isNotEmpty) {
      final sort = _query.sorts.first;
      rows = List<_SaleRow>.from(rows)
        ..sort((a, b) {
          final int cmp;
          switch (sort.columnKey) {
            case 'date':
              cmp = a.date.compareTo(b.date);
            case 'id':
              cmp = a.id.compareTo(b.id);
            case 'product':
              cmp = a.product.compareTo(b.product);
            case 'category':
              cmp = a.category.compareTo(b.category);
            case 'store':
              cmp = a.store.compareTo(b.store);
            case 'quantity':
              cmp = a.orders.compareTo(b.orders);
            case 'unitPrice':
              cmp = a.unitPrice.compareTo(b.unitPrice);
            case 'total':
              cmp = a.revenue.compareTo(b.revenue);
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
    final totalRevenue = rows.fold<double>(0, (sum, row) => sum + row.revenue);
    final totalUnits = rows.fold<int>(0, (sum, row) => sum + row.orders);
    final avgTicket = rows.isEmpty
        ? 0.0
        : rows.fold<double>(0, (sum, row) => sum + row.revenue) / rows.length;
    final storeCount = rows.map((row) => row.store).toSet().length;
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return <AppReportSummaryItem>[
      AppReportSummaryItem(
        label: 'Volume total',
        value: currencyFmt.format(totalRevenue),
        icon: Icons.payments_outlined,
      ),
      AppReportSummaryItem(
        label: 'Itens vendidos',
        value: NumberFormat.decimalPattern('pt_BR').format(totalUnits),
        icon: Icons.inventory_2_outlined,
      ),
      AppReportSummaryItem(
        label: 'Ticket médio',
        value: currencyFmt.format(avgTicket),
        icon: Icons.local_offer_outlined,
        detailLabel: 'por transação filtrada',
      ),
      AppReportSummaryItem(
        label: 'Lojas ativas',
        value: '$storeCount',
        icon: Icons.storefront_outlined,
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
    unawaited(_persistFilters(_query.filters));
  }

  int get _activeFilterCount {
    return _filters
        .where((filter) => filter.hasActiveValue(_query.filters))
        .length;
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
        title: 'Transactions Table',
        subtitle: 'Demo visual inspirada em catálogo e pedidos',
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

  Map<String, Object?> _restoreSavedFilters() {
    final decoded = _sessionStore.restoreJsonMap(suffix: _filtersSessionKey);
    return _restoreFiltersSchema.apply(decoded);
  }

  Future<void> _persistFilters(Map<String, Object?> filters) async {
    final payload = _persistFiltersSchema.apply(filters);

    await _sessionStore.persistJsonMap(
      suffix: _filtersSessionKey,
      value: payload,
    );
  }

  // -------------------------------------------------------------------------
  // Columns
  // -------------------------------------------------------------------------

  static final NumberFormat _currencyFmt = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
  );
  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd', 'pt_BR');

  List<AppReportColumn<_SaleRow>> get _columns => <AppReportColumn<_SaleRow>>[
    AppReportColumn<_SaleRow>(
      key: 'date',
      label: 'Date',
      valueGetter: _getDate,
      formatter: (value) => _dateFmt.format(value! as DateTime),
      width: 110,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideNarrow,
    ),
    const AppReportColumn<_SaleRow>(
      key: 'id',
      label: 'ID',
      valueGetter: _getId,
      cellStyle: AppReportCellStyle.link,
      formatter: _formatTransactionId,
      width: 96,
    ),
    const AppReportColumn<_SaleRow>(
      key: 'product',
      label: 'Item',
      valueGetter: _getProduct,
      leadingBuilder: _buildProductLeading,
      minWidth: 260,
      aggregations: <AppReportAggregation>[AppReportAggregation.count],
    ),
    const AppReportColumn<_SaleRow>(
      key: 'quantity',
      label: 'Quantity',
      valueGetter: _getOrders,
      numeric: true,
      aggregations: <AppReportAggregation>[
        AppReportAggregation.sum,
      ],
      width: 90,
    ),
    AppReportColumn<_SaleRow>(
      key: 'unitPrice',
      label: 'Unit Price',
      valueGetter: _getUnitPrice,
      formatter: _currencyFmt.format,
      numeric: true,
      width: 120,
    ),
    AppReportColumn<_SaleRow>(
      key: 'total',
      label: 'Total',
      valueGetter: _getRevenue,
      formatter: _currencyFmt.format,
      numeric: true,
      aggregations: <AppReportAggregation>[AppReportAggregation.sum],
      width: 130,
    ),
    const AppReportColumn<_SaleRow>(
      key: 'category',
      label: 'Category',
      valueGetter: _getCategory,
      groupable: true,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideWide,
    ),
    const AppReportColumn<_SaleRow>(
      key: 'store',
      label: 'Store',
      valueGetter: _getStore,
      groupable: true,
      hideBelowBreakpoint: AppBreakpoints.reportColumnHideExtraNarrow,
    ),
  ];

  static Object? _getId(_SaleRow r) => r.id;
  static Object? _getProduct(_SaleRow r) => r.product;
  static Object? _getCategory(_SaleRow r) => r.category;
  static Object? _getStore(_SaleRow r) => r.store;
  static Object? _getOrders(_SaleRow r) => r.orders;
  static Object? _getUnitPrice(_SaleRow r) => r.unitPrice;
  static Object? _getRevenue(_SaleRow r) => r.revenue;
  static Object? _getDate(_SaleRow r) => r.date;

  static String _formatTransactionId(Object? value) => '#TRX-${value ?? ''}';

  static Widget _buildProductLeading(
    BuildContext context,
    _SaleRow row,
    Object? value,
  ) {
    final theme = Theme.of(context);
    final seed = row.product.codeUnitAt(row.product.length - 1);
    final colors = <Color>[
      theme.colorScheme.primaryContainer,
      theme.colorScheme.tertiaryContainer,
      theme.colorScheme.secondaryContainer,
    ];
    final color = colors[seed % colors.length];

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        size: 16,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filters
  // -------------------------------------------------------------------------

  static final List<AppReportFilterDescriptor> _filters =
      <AppReportFilterDescriptor>[
        const AppReportFilterDescriptor(
          name: 'search',
          label: 'Search items',
          type: AppReportFilterType.search,
          hint: 'Filter by product name...',
        ),
        const AppReportFilterDescriptor(
          name: 'period',
          label: 'Date range',
          type: AppReportFilterType.dateRange,
        ),
        AppReportFilterDescriptor(
          name: 'category',
          label: 'Category',
          type: AppReportFilterType.singleSelect,
          options: _categories
              .map((value) => AppReportFilterOption(value: value, label: value))
              .toList(),
        ),
        AppReportFilterDescriptor(
          name: 'store',
          label: 'Store',
          type: AppReportFilterType.singleSelect,
          options: _stores
              .map((s) => AppReportFilterOption(value: s, label: s))
              .toList(),
        ),
        const AppReportFilterDescriptor(
          name: 'premiumOnly',
          label: 'Only premium items',
          type: AppReportFilterType.toggle,
          hint: r'Show only items with unit price above R$ 1.000',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('AppReportViewer — Demo')),
      body: ListView(
        padding: EdgeInsets.all(tokens.contentSpacing),
        children: <Widget>[
          const AppShellPageIntro(
            eyebrow: 'Componentes compartilhados',
            title: 'Report Viewer',
            subtitle:
                'Inclui o preset Detalhamento numérico e a demo minimal de '
                'transações com filtros em sheet, persistência local e '
                'paginação estilo catálogo.',
          ),
          SizedBox(height: tokens.sectionSpacing),
          _ReportViewerShowcaseCard(
            totalRows: _currentRows.length,
            selectedRows: _selectedRows.length,
            groupingDescription: _describeGroups(_query.groups),
            activeFilters: _activeFilterCount,
          ),
          SizedBox(height: tokens.sectionSpacing),
          const AppReportNumericalDetailingDemoSection(),
          SizedBox(height: tokens.sectionSpacing),
          SizedBox(
            height: 720,
            child: AppReportViewer<_SaleRow>(
              title: 'Transactions Table',
              subtitle: 'Minimal preset inspired by e-commerce reporting',
              contextChips: <String>[
                'Store: All Stores',
                'Period: Oct 2023',
                '${_currentRows.length} transactions',
                if (_activeFilterCount == 0)
                  'Filters: none'
                else
                  'Filters: $_activeFilterCount active',
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
                      content: Text('Selecionado: ${row.product}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              style:
                  AppReportViewerStyle.minimal(
                    filterLayout: AppReportFilterLayout.sheet,
                    showExportActions: true,
                    entityLabel: 'pedidos',
                  ).copyWith(
                    allowMultiSelection: true,
                    showRowDetailOnTap: true,
                    itemsPerPageLabel: 'Rows:',
                    showingLabelPrefix: 'Showing ',
                    showingLabelMiddle: ' of ',
                  ),
              isLoading: _isLoading,
              emptyMessage: 'No transactions match the selected filters.',
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Fake data generation
  // -------------------------------------------------------------------------

  static const List<String> _categories = <String>[
    'Laptops',
    'Audio',
    'Wearables',
    'Accessories',
    'Phones',
  ];

  static const List<String> _stores = <String>[
    'Loja Centro',
    'Loja Norte',
    'Loja Sul',
    'Loja Leste',
  ];

  static const List<String> _products = <String>[
    'MacBook Pro M2 14"',
    'Wireless Noise Cancelling Headphones',
    'Series 9 Smartwatch - Stainless',
    'Thunderbolt 4 Pro Cable (2m)',
    'Phone 15 Pro Max 256GB',
    'Mechanical Keyboard RGB',
    'Portable SSD 2TB',
    'Studio Display 27"',
  ];

  static List<_SaleRow> _generateFakeRows() {
    final rows = <_SaleRow>[];
    final baseDate = DateTime(2023, 10, 22);
    final unitPrices = <double>[
      1999,
      299,
      749,
      129,
      1199,
      189,
      249,
      1599,
    ];

    for (var i = 0; i < _totalRows; i++) {
      final productIndex = i % _products.length;
      final quantity = (i % 12) + 1;
      final unitPrice = unitPrices[productIndex];
      rows.add(
        _SaleRow(
          id: '${9480 + i}',
          store: _stores[i % _stores.length],
          category: _categories[productIndex % _categories.length],
          product: _products[productIndex],
          status: _OrderStatus.values[i % _OrderStatus.values.length],
          orders: quantity,
          revenue: unitPrice * quantity,
          date: baseDate.add(Duration(days: i ~/ 3)),
          margin: 5.0 + (i * 1.7) % 35,
        ),
      );
    }

    return rows;
  }

  static String _describeGroups(List<AppReportGroupDescriptor> groups) {
    if (groups.isEmpty) {
      return 'Grouping: none';
    }

    final labels = groups
        .map((group) => _groupLabel(group.columnKey))
        .join(' / ');
    return 'Grouping: $labels';
  }

  static String _groupChangeMessage(List<AppReportGroupDescriptor> groups) {
    if (groups.isEmpty) {
      return 'Grouping cleared';
    }

    final labels = groups
        .map((group) => _groupLabel(group.columnKey))
        .join(', ');
    return 'Grouped by $labels';
  }

  static String _groupToggleMessage(AppReportGroupToggleEvent event) {
    final action = event.isExpanded ? 'expanded' : 'collapsed';
    final label = _groupLabel(event.columnKey);
    return '$label: ${event.groupKey} $action';
  }

  static String _groupLabel(String key) {
    return switch (key) {
      'category' => 'Category',
      'store' => 'Store',
      'date' => 'Date',
      _ => key,
    };
  }
}

class _ReportViewerShowcaseCard extends StatelessWidget {
  const _ReportViewerShowcaseCard({
    required this.totalRows,
    required this.selectedRows,
    required this.groupingDescription,
    required this.activeFilters,
  });

  final int totalRows;
  final int selectedRows;
  final String groupingDescription;
  final int activeFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return AppSectionCardWithHeading(
      titleWidget: _ReportViewerShowcaseHeading(theme: theme, tokens: tokens),
      subtitle:
          'Showcase focused on the minimal transaction-table presentation '
          'with inline filters and compact actions.',
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
          AppTagChip(label: '$totalRows rows'),
          if (selectedRows > 0) AppTagChip(label: '$selectedRows selected'),
          AppTagChip(
            label: activeFilters == 0
                ? 'No saved filters'
                : '$activeFilters saved filters',
          ),
          AppTagChip(label: groupingDescription),
          const AppTagChip(label: 'Filter sheet + minimal grid'),
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
            'Minimal transaction surface',
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
          'MINIMAL',
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
        _ReportViewerLegendChip(label: 'Compact toolbar'),
        _ReportViewerLegendChip(label: 'Primary filter sheet'),
        _ReportViewerLegendChip(label: 'Saved last filters'),
        _ReportViewerLegendChip(label: 'Catalog-style pagination'),
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
