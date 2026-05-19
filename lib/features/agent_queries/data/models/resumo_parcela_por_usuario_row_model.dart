import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';

class ResumoParcelaPorUsuarioRowModel {
  const ResumoParcelaPorUsuarioRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.qtdVendas,
    required this.valorParcela,
  });

  factory ResumoParcelaPorUsuarioRowModel.fromMap(Map<String, dynamic> map) {
    return ResumoParcelaPorUsuarioRowModel(
      codEmpresa: _readRequiredIntKeys(map, _keysCodEmpresaStyle('CodEmpresa')),
      codFilial: _readRequiredIntKeys(map, _keysCodEmpresaStyle('CodFilial')),
      nomeUsuario: _readNomeUsuario(map),
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
  final int qtdVendas;
  final double valorParcela;

  ResumoParcelaPorUsuarioRow toEntity() {
    return ResumoParcelaPorUsuarioRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeUsuario: nomeUsuario,
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
}
