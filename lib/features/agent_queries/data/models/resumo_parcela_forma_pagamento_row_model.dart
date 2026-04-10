import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';

class ResumoParcelaFormaPagamentoRowModel {
  const ResumoParcelaFormaPagamentoRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.anoDataVenda,
    required this.mesDataVenda,
    required this.anoMesDataVenda,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  factory ResumoParcelaFormaPagamentoRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final anoDataVenda = _readRequiredIntKeys(
      map,
      _keysCodEmpresaStyle('AnoDataVenda'),
    );
    final mesDataVenda = _readRequiredIntKeys(
      map,
      _keysCodEmpresaStyle('MesDataVenda'),
    );
    final anoMesDataVenda = _readRequiredAnoMesDataVenda(map);

    if (anoMesDataVenda.contains('/') &&
        !ResumoParcelaFormaPagamentoRow.isAnoMesConsistent(
          anoMesDataVenda: anoMesDataVenda,
          anoDataVenda: anoDataVenda,
          mesDataVenda: mesDataVenda,
        )) {
      throw FormatException(
        'AnoMesDataVenda "$anoMesDataVenda" is inconsistent with '
        'AnoDataVenda=$anoDataVenda MesDataVenda=$mesDataVenda',
      );
    }

    return ResumoParcelaFormaPagamentoRowModel(
      codEmpresa: _readRequiredIntKeys(map, _keysCodEmpresaStyle('CodEmpresa')),
      codFilial: _readRequiredIntKeys(map, _keysCodEmpresaStyle('CodFilial')),
      nomeUsuario: _readNomeUsuario(map),
      anoDataVenda: anoDataVenda,
      mesDataVenda: mesDataVenda,
      anoMesDataVenda: anoMesDataVenda,
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
  final String nomeUsuario;
  final int anoDataVenda;
  final int mesDataVenda;
  final String anoMesDataVenda;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;

  ResumoParcelaFormaPagamentoRow toEntity() {
    return ResumoParcelaFormaPagamentoRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeUsuario: nomeUsuario,
      anoDataVenda: anoDataVenda,
      mesDataVenda: mesDataVenda,
      anoMesDataVenda: anoMesDataVenda,
      codFormaPagamento: codFormaPagamento,
      descricaoFormaPagamento: descricaoFormaPagamento,
      qtdVendas: qtdVendas,
      valorParcela: valorParcela,
    );
  }

  /// PascalCase, camelCase, and all-lowercase keys (some bridges normalize
  /// column names to lowercase in JSON).
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

  static String _readNomeUsuario(Map<String, dynamic> map) {
    final raw = _lookupFirst(map, _keysCodEmpresaStyle('NomeUsuario'));
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return 'Usuario nao informado';
  }

  static String _readRequiredAnoMesDataVenda(Map<String, dynamic> map) {
    final keys = _keysCodEmpresaStyle('AnoMesDataVenda');
    final value = _lookupFirst(map, keys);
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    } else if (value is num) {
      return value.toString();
    }
    throw const FormatException(
      'Invalid or missing "AnoMesDataVenda" in agent SQL row',
    );
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
