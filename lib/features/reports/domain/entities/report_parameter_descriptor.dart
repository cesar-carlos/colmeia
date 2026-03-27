enum ReportParameterType {
  text,
  singleSelect,
  date,
  toggle,
}

class ReportParameterOption {
  const ReportParameterOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class ReportParameterDescriptor {
  const ReportParameterDescriptor({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.initialValue,
    this.options = const <ReportParameterOption>[],
  });

  final String name;
  final String label;
  final ReportParameterType type;
  final bool required;
  final Object? initialValue;
  final List<ReportParameterOption> options;
}
