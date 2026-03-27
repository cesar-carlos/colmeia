class RegisterRequestDto {
  const RegisterRequestDto({
    required this.fullName,
    required this.email,
    required this.storeName,
    required this.password,
  });

  final String fullName;
  final String email;
  final String storeName;
  final String password;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'fullName': fullName,
      'email': email,
      'storeName': storeName,
      'password': password,
    };
  }
}
