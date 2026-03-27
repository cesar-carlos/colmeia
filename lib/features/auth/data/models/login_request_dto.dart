class LoginRequestDto {
  const LoginRequestDto({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'email': email,
      'password': password,
    };
  }
}
