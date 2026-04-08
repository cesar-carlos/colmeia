import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:flutter/material.dart';

class AllowedStoreSelectorStrip extends StatelessWidget {
  const AllowedStoreSelectorStrip({
    required this.stores,
    required this.selectedStoreId,
    required this.onStoreSelected,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  final List<StoreScope> stores;
  final String selectedStoreId;
  final void Function(StoreScope store) onStoreSelected;
  final bool isLoading;
  final bool isRefreshing;
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
      return AppInlineErrorPanel(
        message: errorMessage!,
        onRetry: onRetry,
        variant: AppInlineErrorPanelVariant.plain,
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

    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stores.map((store) {
          final isActive = store.id == selectedStoreId;
          return Padding(
            padding: EdgeInsets.only(right: tokens.gapSm),
            child: AppChoiceChip(
              label: store.name,
              selected: isActive,
              onSelected: () => onStoreSelected(store),
              semanticLabel: 'Selecionar loja ${store.name}',
            ),
          );
        }).toList(),
      ),
    );

    if (!isRefreshing) {
      return chips;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          child: const LinearProgressIndicator(minHeight: 4),
        ),
        SizedBox(height: tokens.gapSm),
        chips,
      ],
    );
  }
}
