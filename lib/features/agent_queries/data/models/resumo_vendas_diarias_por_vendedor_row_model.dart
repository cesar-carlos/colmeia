import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';

class ResumoVendasDiariasPorVendedorRowModel {
  const ResumoVendasDiariasPorVendedorRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.dataVenda,
    required this.codVendedor,
    required this.nomeVendedor,
    required this.qtdeItens,
    required this.valorAcrescimo,
    required this.valorDesconto,
    required this.valorBruto,
    required this.valorLiquido,
  });

  factory ResumoVendasDiariasPorVendedorRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoVendasDiariasPorVendedorRowModel(
      codEmpresa: _readRequiredIntKeys(map, _keys('CodEmpresa')),
      codFilial: _readRequiredIntKeys(map, _keys('CodFilial')),
      dataVenda: AgentQueriesSqlRowMapReader.readDataVendaCalendarDate(map),
      codVendedor: _readOptionalIntKeys(map, _keys('CodVendedor')),
      nomeVendedor: _readNomeVendedor(map),
      qtdeItens: _readRequiredDoubleKeys(map, _keys('QtdeItens')),
      valorAcrescimo: _readRequiredDoubleKeys(map, _keys('ValorAcrescimo')),
      valorDesconto: _readRequiredDoubleKeys(map, _keys('ValorDesconto')),
      valorBruto: _readRequiredDoubleKeys(map, _keys('ValorBruto')),
      valorLiquido: _readRequiredDoubleKeys(map, _keys('ValorLiquido')),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final DateTime dataVenda;
  final int? codVendedor;
  final String nomeVendedor;
  final double qtdeItens;
  final double valorAcrescimo;
  final double valorDesconto;
  final double valorBruto;
  final double valorLiquido;

  ResumoVendasDiariasPorVendedorRow toEntity() {
    return ResumoVendasDiariasPorVendedorRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      dataVenda: dataVenda,
      codVendedor: codVendedor,
      nomeVendedor: nomeVendedor,
      qtdeItens: qtdeItens,
      valorAcrescimo: valorAcrescimo,
      valorDesconto: valorDesconto,
      valorBruto: valorBruto,
      valorLiquido: valorLiquido,
    );
  }

  static List<String> _keys(String pascal) {
    return <String>[
      pascal,
      _pascalToCamel(pascal),
      pascal.toLowerCase(),
    ];
  }

  static String _pascalToCamel(String pascal) {
    if (pascal.isEmpty) {
      return pascal;
    }
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  static Object? _lookupFirst(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (map.containsKey(k)) {
        return map[k];
      }
    }
    return null;
  }

  static String _readNomeVendedor(Map<String, dynamic> map) {
    final raw = _lookupFirst(map, _keys('NomeVendedor'));
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return 'Vendedor nao informado';
  }

  static int _readRequiredIntKeys(Map<String, dynamic> map, List<String> keys) {
    final value = _lookupFirst(map, keys);
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }

  static int? _readOptionalIntKeys(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _lookupFirst(map, keys);
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final parsed = int.tryParse(trimmed);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException(
      'Invalid "${keys.first}" in agent SQL row',
    );
  }

  static double _readRequiredDoubleKeys(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _lookupFirst(map, keys);
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }
}
