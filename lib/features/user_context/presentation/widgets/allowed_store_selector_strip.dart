import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AllowedStoreSelectorStrip extends StatelessWidget {
  const AllowedStoreSelectorStrip({
    required this.stores,
    required this.selectedStoreId,
    required this.onStoreSelected,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  final List<StoreScope> stores;
  final String selectedStoreId;
  final void Function(StoreScope store) onStoreSelected;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (isLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        child: const LinearProgressIndicator(minHeight: 4),
      );
    }

    if (errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
          ),
          if (onRetry != null) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ],
      );
    }

    if (stores.isEmpty) {
      return Text(
        'Nenhuma loja disponivel para sua conta.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      );
    }

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
