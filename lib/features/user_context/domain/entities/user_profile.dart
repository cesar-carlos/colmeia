class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.roleLabel,
    this.corporateEmail = '',
    this.phone = '',
  });

  final String id;
  final String name;
  final String roleLabel;
  final String corporateEmail;
  final String phone;

  bool get hasCorporateEmail => corporateEmail.trim().isNotEmpty;
  bool get hasPhone => phone.trim().isNotEmpty;
}
