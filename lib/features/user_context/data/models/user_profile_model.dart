import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.name,
    required this.roleLabel,
    this.corporateEmail = '',
    this.phone = '',
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['userId'] as String,
      name: json['name'] as String,
      roleLabel: json['roleLabel'] as String,
      corporateEmail:
          json['corporateEmail'] as String? ?? json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String roleLabel;
  final String corporateEmail;
  final String phone;

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      name: name,
      roleLabel: roleLabel,
      corporateEmail: corporateEmail,
      phone: phone,
    );
  }
}
