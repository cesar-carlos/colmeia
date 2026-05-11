class AgentQueryLoadedRows<Row> {
  const AgentQueryLoadedRows({
    required this.rows,
    int? sourceRowCount,
  }) : sourceRowCount = sourceRowCount ?? rows.length;

  final List<Row> rows;
  final int sourceRowCount;
}
