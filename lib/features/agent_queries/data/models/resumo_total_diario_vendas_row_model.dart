import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';

class ResumoTotalDiarioVendasRowModel {
  const ResumoTotalDiarioVendasRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.dataVenda,
    required this.qtdVendas,
    required this.valorTotalDiarioVenda,
  });

  factory ResumoTotalDiarioVendasRowModel.fromMap(Map<String, dynamic> map) {
    return ResumoTotalDiarioVendasRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      dataVenda: AgentQueriesSqlRowMapReader.readDataVendaCalendarDate(map),
      qtdVendas: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdVendas'),
      ),
      valorTotalDiarioVenda: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
          'ValorTotalDiarioVenda',
        ),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final DateTime dataVenda;
  final int qtdVendas;
  final double valorTotalDiarioVenda;

  ResumoTotalDiarioVendasRow toEntity() {
    return ResumoTotalDiarioVendasRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      dataVenda: dataVenda,
      qtdVendas: qtdVendas,
      valorTotalDiarioVenda: valorTotalDiarioVenda,
    );
  }
}
