import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';

class ResumoParcelaFormaPagamentoRowModelV2 {
  const ResumoParcelaFormaPagamentoRowModelV2({
    required this.codEmpresa,
    required this.codFilial,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  factory ResumoParcelaFormaPagamentoRowModelV2.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoParcelaFormaPagamentoRowModelV2(
      codEmpresa: _readRequiredIntKeys(map, _keysCodEmpresaStyle('CodEmpresa')),
      codFilial: _readRequiredIntKeys(map, _keysCodEmpresaStyle('CodFilial')),
      codFormaPagamento: _readRequiredStringKeys(
        map,
        _keysCodEmpresaStyle('CodFormaPagamento'),
      ),
      descricaoFormaPagamento: _readRequiredStringKeys(
        map,
        _keysCodEmpresaStyle('DescricaoFormaPagamento'),
      ),
      qtdVendas: _readRequiredIntKeys(map, _keysCodEmpresaStyle('QtdVendas')),
      valorParcela: _readRequiredDoubleKeys(
        map,
        _keysCodEmpresaStyle('ValorParcela'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;

  ResumoParcelaFormaPagamentoRowV2 toEntity() {
    return ResumoParcelaFormaPagamentoRowV2(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      codFormaPagamento: codFormaPagamento,
      descricaoFormaPagamento: descricaoFormaPagamento,
      qtdVendas: qtdVendas,
      valorParcela: valorParcela,
    );
  }

  static List<String> _keysCodEmpresaStyle(String pascal) {
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

  static int _readRequiredIntKeys(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
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

  static String _readRequiredStringKeys(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _lookupFirst(map, keys);
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }
}
