import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row_percent_metric.dart';

int compareLucratividadeRowsByPercentMetric(
  ResumoProdutoVendaLucratividadeRow a,
  ResumoProdutoVendaLucratividadeRow b,
  LucratividadePercentMetric metric,
) => b.metricBarValue(metric).compareTo(a.metricBarValue(metric));
