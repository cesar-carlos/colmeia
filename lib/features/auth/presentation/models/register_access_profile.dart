import 'package:flutter/material.dart';

enum RegisterAccessProfile {
  vendedor,
  gerente,
  analista,
}

extension RegisterAccessProfileX on RegisterAccessProfile {
  String get label => switch (this) {
    RegisterAccessProfile.vendedor => 'Vendedor',
    RegisterAccessProfile.gerente => 'Gerente',
    RegisterAccessProfile.analista => 'Analista',
  };

  IconData get icon => switch (this) {
    RegisterAccessProfile.vendedor => Icons.person_outline,
    RegisterAccessProfile.gerente => Icons.manage_accounts_outlined,
    RegisterAccessProfile.analista => Icons.leaderboard_outlined,
  };
}
