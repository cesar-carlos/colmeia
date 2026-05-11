import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';

class ResumoTotalVendasMunicipioFilialPeriodoRowModel {
  const ResumoTotalVendasMunicipioFilialPeriodoRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.qtdVendas,
    required this.totalVenda,
    this.codMunicipioFilial,
    this.nomeMunicipioFilial,
    this.ufMunicipioFilial,
    this.nomeFantasiaFilial,
    this.cepFilial,
    this.codigoIbgeMunicipioFilial,
  });

  factory ResumoTotalVendasMunicipioFilialPeriodoRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoTotalVendasMunicipioFilialPeriodoRowModel(
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
      codMunicipioFilial: AgentQueriesSqlRowMapReader.readOptionalIntStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMunicipioFilial'),
      ),
      nomeMunicipioFilial:
          AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'NomeMunicipioFilial',
            ),
          ),
      ufMunicipioFilial:
          AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
            map,
            AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(
              'UFMunicipioFilial',
            ),
          ),
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
  final int? codMunicipioFilial;
  final String? nomeMunicipioFilial;
  final String? ufMunicipioFilial;
  final int qtdVendas;
  final double totalVenda;
  final String? nomeFantasiaFilial;
  final String? cepFilial;
  final String? codigoIbgeMunicipioFilial;

  ResumoTotalVendasMunicipioFilialPeriodoRow toEntity() {
    return ResumoTotalVendasMunicipioFilialPeriodoRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeFilial: nomeFilial,
      codMunicipioFilial: codMunicipioFilial,
      nomeMunicipioFilial: nomeMunicipioFilial,
      ufMunicipioFilial: ufMunicipioFilial,
      qtdVendas: qtdVendas,
      totalVenda: totalVenda,
      nomeFantasiaFilial: nomeFantasiaFilial,
      cepFilial: cepFilial,
      codigoIbgeMunicipioFilial: codigoIbgeMunicipioFilial,
    );
  }
}
