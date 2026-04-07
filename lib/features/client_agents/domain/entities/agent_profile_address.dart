class AgentProfileAddress {
  const AgentProfileAddress({
    required this.street,
    required this.number,
    required this.district,
    required this.postalCode,
    required this.city,
    required this.state,
  });

  final String? street;
  final String? number;
  final String? district;
  final String? postalCode;
  final String? city;
  final String? state;

  String get shortLabel {
    final cityName = city?.trim();
    final stateCode = state?.trim();
    if ((cityName == null || cityName.isEmpty) &&
        (stateCode == null || stateCode.isEmpty)) {
      return '';
    }
    if (cityName == null || cityName.isEmpty) {
      return stateCode!;
    }
    if (stateCode == null || stateCode.isEmpty) {
      return cityName;
    }
    return '$cityName/$stateCode';
  }
}
