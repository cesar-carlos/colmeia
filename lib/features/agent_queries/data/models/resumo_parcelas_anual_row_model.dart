import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';

class ResumoParcelasAnualRowModel {
  const ResumoParcelasAnualRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.anoDataVenda,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  factory ResumoParcelasAnualRowModel.fromMap(Map<String, dynamic> map) {
    return ResumoParcelasAnualRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      anoDataVenda: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('AnoDataVenda'),
      ),
      codFormaPagamento: _readCodFormaPagamento(map),
      descricaoFormaPagamento:
          AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'DescricaoFormaPagamento',
            ),
          ),
      qtdVendas: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdVendas'),
      ),
      valorParcela: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorParcela'),
      ),
    );
  }

  static String _readCodFormaPagamento(Map<String, dynamic> map) {
    final keys = AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
      'CodFormaPagamento',
    );
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(map, keys);
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    if (raw is num) {
      final n = raw.toDouble();
      if (n == n.roundToDouble()) {
        return n.toInt().toString();
      }
      return raw.toString();
    }
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int anoDataVenda;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;

  ResumoParcelasAnualRow toEntity() {
    return ResumoParcelasAnualRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      anoDataVenda: anoDataVenda,
      codFormaPagamento: codFormaPagamento,
      descricaoFormaPagamento: descricaoFormaPagamento,
      qtdVendas: qtdVendas,
      valorParcela: valorParcela,
    );
  }
}
