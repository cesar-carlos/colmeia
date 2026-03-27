import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AllowedStoreSelectorStrip extends StatelessWidget {
  const AllowedStoreSelectorStrip({
    required this.stores,
    required this.selectedStoreId,
    required this.onStoreSelected,
    super.key,
  });

  final List<StoreScope> stores;
  final String selectedStoreId;
  final void Function(StoreScope store) onStoreSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stores.map((store) {
          final isActive = store.id == selectedStoreId;
          return Padding(
            padding: EdgeInsets.only(right: tokens.gapSm),
            child: ChoiceChip(
              label: Text(store.name),
              selected: isActive,
              onSelected: (_) => onStoreSelected(store),
            ),
          );
        }).toList(),
      ),
    );
  }
}
