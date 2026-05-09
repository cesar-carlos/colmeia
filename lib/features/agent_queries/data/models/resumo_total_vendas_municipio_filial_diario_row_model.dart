import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_row.dart';

class ResumoTotalVendasMunicipioFilialDiarioRowModel {
  const ResumoTotalVendasMunicipioFilialDiarioRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.codMunicipioFilial,
    required this.nomeMunicipioFilial,
    required this.ufMunicipioFilial,
    required this.dataVenda,
    required this.qtdVendas,
    required this.totalVenda,
    this.nomeFantasiaFilial,
    this.cepFilial,
    this.codigoIbgeMunicipioFilial,
  });

  factory ResumoTotalVendasMunicipioFilialDiarioRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoTotalVendasMunicipioFilialDiarioRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      nomeFilial: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeFilial'),
      ),
      codMunicipioFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMunicipioFilial'),
      ),
      nomeMunicipioFilial:
          AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'NomeMunicipioFilial',
            ),
          ),
      ufMunicipioFilial: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('UFMunicipioFilial'),
      ),
      dataVenda: AgentQueriesSqlRowMapReader.readDataVendaCalendarDate(map),
      qtdVendas: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdVendas'),
      ),
      totalVenda: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalVenda'),
      ),
      nomeFantasiaFilial: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeFantasiaFilial'),
      ),
      cepFilial: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CEPFilial'),
      ),
      codigoIbgeMunicipioFilial:
          AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'CodigoIBGEMunicipioFilial',
            ),
          ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final int codMunicipioFilial;
  final String nomeMunicipioFilial;
  final String ufMunicipioFilial;
  final DateTime dataVenda;
  final int qtdVendas;
  final double totalVenda;
  final String? nomeFantasiaFilial;
  final String? cepFilial;
  final String? codigoIbgeMunicipioFilial;

  ResumoTotalVendasMunicipioFilialDiarioRow toEntity() {
    return ResumoTotalVendasMunicipioFilialDiarioRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeFilial: nomeFilial,
      codMunicipioFilial: codMunicipioFilial,
      nomeMunicipioFilial: nomeMunicipioFilial,
      ufMunicipioFilial: ufMunicipioFilial,
      dataVenda: dataVenda,
      qtdVendas: qtdVendas,
      totalVenda: totalVenda,
      nomeFantasiaFilial: nomeFantasiaFilial,
      cepFilial: cepFilial,
      codigoIbgeMunicipioFilial: codigoIbgeMunicipioFilial,
    );
  }
}
