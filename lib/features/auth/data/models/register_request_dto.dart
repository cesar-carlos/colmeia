class RegisterRequestDto {
  const RegisterRequestDto({
    required this.fullName,
    required this.email,
    required this.password,
    required this.employeeId,
    required this.accessProfile,
    required this.requestedStoreIds,
  });

  final String fullName;
  final String email;
  final String password;
  final String employeeId;
  final String accessProfile;
  final List<String> requestedStoreIds;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'fullName': fullName,
      'email': email,
      'password': password,
      'employeeId': employeeId,
      'accessProfile': accessProfile,
      'requestedStoreIds': requestedStoreIds,
    };
  }
}
