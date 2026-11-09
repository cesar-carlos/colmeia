import 'package:colmeia/features/pwa/domain/offline_package.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';

/// Applies only operations that can be answered by the published snapshot.
class OfflineReportProjection {
  OfflineReportProjection(
    OfflinePackage package,
    String dataset,
    AppReportQuery query,
  ) {
    if (query.filters.isNotEmpty || query.groups.isNotEmpty) {
      throw StateError('Unsupported local query; connection required');
    }
    final source = _source(package, dataset);
    if (source is! List || source.any((row) => row is! Map)) {
      throw StateError('Dataset unavailable; connection required');
    }
    columns = schema[dataset] ?? const <String>[];
    final term = query.searchTerm?.trim().toLowerCase() ?? '';
    rows = source
        .map((row) => Map<String, dynamic>.from(row as Map))
        .where(
          (row) =>
              term.isEmpty ||
              row.values.any(
                (value) => value.toString().toLowerCase().contains(term),
              ),
        )
        .toList();
    rows.sort((left, right) {
      for (final sort in query.sorts) {
        final a = left[sort.columnKey];
        final b = right[sort.columnKey];
        final result = a is num && b is num
            ? a.compareTo(b)
            : '$a'.compareTo('$b');
        if (result != 0) {
          return sort.direction == AppReportSortDirection.ascending
              ? result
              : -result;
        }
      }
      return 0;
    });
    final size = query.pageSize.clamp(1, 100);
    final pages = (rows.length / size).ceil();
    final page = query.page.clamp(1, pages == 0 ? 1 : pages);
    pageInfo = AppReportPageInfo(
      currentPage: page,
      pageSize: size,
      totalRows: rows.length,
      totalPages: pages,
    );
    pageRows = rows.skip((page - 1) * size).take(size).toList(growable: false);
  }
  static Object? _source(OfflinePackage package, String dataset) {
    if (dataset == 'salesByBranch') return package.datasets[dataset];
    final overview = package.datasets['overview'];
    return overview is Map ? overview[dataset] : null;
  }

  static bool isAvailable(OfflinePackage package, String dataset) {
    final source = _source(package, dataset);
    return schema.containsKey(dataset) &&
        source is List &&
        source.every((row) => row is Map);
  }

  late final List<String> columns;
  late final List<Map<String, dynamic>> rows;
  late final List<Map<String, dynamic>> pageRows;
  late final AppReportPageInfo pageInfo;

  static const schema = {
    'salesByBranch': ['nomeFilial', 'qtdVendas', 'totalVenda'],
    'paymentMethods': [
      'label',
      'totalSalesCount',
      'totalAmount',
      'averageTicket',
      'sharePercent',
    ],
    'userRankings': [
      'userName',
      'totalSalesCount',
      'totalAmount',
      'averageTicket',
    ],
    'monthlyParcelTrend': ['anoMes', 'qtdVendas', 'valorParcela'],
    'weekdaySalesTrend': ['weekdayNumber', 'salesCount', 'salesAmount'],
    'weekdayUserSalesTrend': [
      'weekdayNumber',
      'userName',
      'salesCount',
      'salesAmount',
    ],
    'dailySalesTrend': ['saleDate', 'salesCount', 'salesAmount'],
    'lucratividadeTrend': [
      'codEmpresa',
      'codFilial',
      'qtdVendas',
      'qtdItensVendido',
      'valorTotalCustoMedio',
      'custoReposicao',
      'pontoEquilibrio',
      'valorTotalItem',
      'chartAxisLabel',
    ],
  };
  static const datasets = {
    'salesByBranch': 'Vendas por filial',
    'paymentMethods': 'Formas de pagamento',
    'userRankings': 'Vendas por usuário',
    'monthlyParcelTrend': 'Parcelas no período',
    'weekdaySalesTrend': 'Vendas por dia da semana',
    'weekdayUserSalesTrend': 'Vendas por usuário e dia da semana',
    'dailySalesTrend': 'Vendas diárias',
    'lucratividadeTrend': 'Lucratividade',
  };
  static const labels = {
    'nomeFilial': 'Filial',
    'qtdVendas': 'Quantidade de vendas',
    'totalVenda': 'Total de vendas',
    'label': 'Forma de pagamento',
    'totalSalesCount': 'Quantidade de vendas',
    'totalAmount': 'Total',
    'averageTicket': 'Ticket médio',
    'sharePercent': 'Participação (%)',
    'userName': 'Usuário',
    'anoMes': 'Mês',
    'valorParcela': 'Valor das parcelas',
    'weekdayNumber': 'Dia da semana (1–7)',
    'salesCount': 'Quantidade de vendas',
    'salesAmount': 'Total de vendas',
    'saleDate': 'Data',
    'codEmpresa': 'Empresa',
    'codFilial': 'Código da filial',
    'qtdItensVendido': 'Itens vendidos',
    'valorTotalCustoMedio': 'Custo médio',
    'custoReposicao': 'Custo de reposição',
    'pontoEquilibrio': 'Ponto de equilíbrio',
    'valorTotalItem': 'Valor dos itens',
    'chartAxisLabel': 'Período',
  };
}
