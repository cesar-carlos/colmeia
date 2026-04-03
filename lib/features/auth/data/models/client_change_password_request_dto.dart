class ClientChangePasswordRequestDto {
  const ClientChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}
