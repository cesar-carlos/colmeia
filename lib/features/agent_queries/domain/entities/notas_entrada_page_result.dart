import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';

/// One numbered page of entrada notes, with the filtered catalog total.
class NotasEntradaPageResult {
  const NotasEntradaPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<NotaEntradaRow> items;
  final int totalCount;
}
