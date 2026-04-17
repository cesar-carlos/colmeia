import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';

class ResumoParcelasDiaSemanaUsuarioRowModel {
  const ResumoParcelasDiaSemanaUsuarioRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.diaSemanaNumero,
    required this.diaSemana,
    required this.qtdVendas,
    required this.valorParcela,
  });

  factory ResumoParcelasDiaSemanaUsuarioRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final codEmpresa = AgentQueriesSqlRowMapReader.readRequiredInt(
      map,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
    );
    final codFilial = AgentQueriesSqlRowMapReader.readRequiredInt(
      map,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
    );
    final nomeUsuario = AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
      map,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeUsuario'),
    );
    final diaSemanaNumero = AgentQueriesSqlRowMapReader.readRequiredInt(
      map,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('DiaSemanaNumero'),
    );
    final diaSemana = AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
      map,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('DiaSemana'),
    );
    final expectedDiaSemana = ResumoParcelasDiaSemanaLabels.labelFor(
      diaSemanaNumero,
    );
    if (diaSemana != expectedDiaSemana) {
      throw FormatException(
        'DiaSemana "$diaSemana" does not match DiaSemanaNumero '
        '$diaSemanaNumero (expected "$expectedDiaSemana")',
      );
    }
    return ResumoParcelasDiaSemanaUsuarioRowModel(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeUsuario: nomeUsuario,
      diaSemanaNumero: diaSemanaNumero,
      diaSemana: diaSemana,
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

  final int codEmpresa;
  final int codFilial;
  final String nomeUsuario;
  final int diaSemanaNumero;
  final String diaSemana;
  final int qtdVendas;
  final double valorParcela;

  ResumoParcelasDiaSemanaUsuarioRow toEntity() {
    return ResumoParcelasDiaSemanaUsuarioRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeUsuario: nomeUsuario,
      diaSemanaNumero: diaSemanaNumero,
      diaSemana: ResumoParcelasDiaSemanaLabels.labelFor(diaSemanaNumero),
      qtdVendas: qtdVendas,
      valorParcela: valorParcela,
    );
  }
}
