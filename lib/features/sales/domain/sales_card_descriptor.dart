import 'package:flutter/material.dart';

class SalesCardDescriptor {
  const SalesCardDescriptor({
    required this.id,
    required this.icon,
    required this.l10nTitleKey,
  });

  final String id;
  final IconData icon;
  final String l10nTitleKey;

  String get route => '/sales/$id';
}

const List<SalesCardDescriptor> allSalesCards = <SalesCardDescriptor>[
  SalesCardDescriptor(
    id: 'open_accounts',
    icon: Icons.receipt_long_outlined,
    l10nTitleKey: 'salesCardOpenAccountsTitle',
  ),
  SalesCardDescriptor(
    id: 'paid_accounts',
    icon: Icons.check_circle_outline,
    l10nTitleKey: 'salesCardPaidAccountsTitle',
  ),
  SalesCardDescriptor(
    id: 'payment_history',
    icon: Icons.history,
    l10nTitleKey: 'salesCardPaymentHistoryTitle',
  ),
  SalesCardDescriptor(
    id: 'new_payment',
    icon: Icons.add_circle_outline,
    l10nTitleKey: 'salesCardNewPaymentTitle',
  ),
];

SalesCardDescriptor? findSalesCardById(String id) {
  for (final c in allSalesCards) {
    if (c.id == id) {
      return c;
    }
  }
  return null;
}
