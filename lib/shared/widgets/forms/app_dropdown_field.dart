import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.searchText,
  });

  final T value;
  final String label;
  final String? searchText;
}

class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    required this.options,
    required this.onChanged,
    super.key,
    this.value,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.density = AppTextFieldDensity.comfortable,
    this.emptyLabel = 'Nenhuma opção disponível.',
    this.semanticsLabel,
    this.menuMaxHeight = 220,

    /// When non-null, replaces the matched option label in the collapsed field.
    this.selectedDisplayLabel,
  });

  final List<AppDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final AppTextFieldDensity density;
  final String emptyLabel;
  final String? semanticsLabel;
  final double menuMaxHeight;
  final String? selectedDisplayLabel;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  bool _expanded = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'AppDropdownField');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _expanded) {
      _setExpanded(false);
    }
  }

  void _setExpanded(bool value) {
    if (_expanded == value) {
      return;
    }

    setState(() => _expanded = value);
    if (value) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
  }

  void _toggleExpanded() {
    if (!widget.enabled) {
      return;
    }

    _setExpanded(!_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final hasError = widget.errorText?.trim().isNotEmpty ?? false;
    final selectedOption = widget.options
        .cast<AppDropdownOption<T>?>()
        .firstWhere(
          (option) => option?.value == widget.value,
          orElse: () => null,
        );

    final displayLabel =
        widget.selectedDisplayLabel ??
        selectedOption?.label ??
        widget.value?.toString() ??
        widget.hintText ??
        'Selecione uma opção';
    final hasCollapsedSelection =
        selectedOption != null ||
        widget.selectedDisplayLabel != null ||
        (widget.value != null && selectedOption == null);

    final borderRadius = BorderRadius.circular(tokens.formFieldRadius + 2);
    final fieldPadding = _contentPadding(tokens, widget.density);
    final borderSide = _resolveBorderSide(
      colors: colors,
      scheme: scheme,
      enabled: widget.enabled,
      expanded: _expanded,
      hasError: hasError,
    );

    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      button: true,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.label case final String label) ...<Widget>[
            Text(
              label.toUpperCase(),
              style: typography.utilityOverline.copyWith(
                color: hasError ? scheme.error : colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.gapSm),
          ],
          TapRegion(
            onTapOutside: (_) => _setExpanded(false),
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    _setExpanded(false),
              },
              child: Focus(
                focusNode: _focusNode,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleExpanded,
                    borderRadius: borderRadius,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: widget.enabled
                            ? scheme.surfaceContainerLowest
                            : scheme.surfaceContainerLow.withValues(
                                alpha: 0.56,
                              ),
                        borderRadius: borderRadius,
                        border: Border.fromBorderSide(borderSide),
                      ),
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: fieldPadding,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    displayLabel,
                                    style: typography.body.copyWith(
                                      color: hasCollapsedSelection
                                          ? colors.onSurface
                                          : colors.onSurfaceVariant,
                                      fontWeight: hasCollapsedSelection
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: tokens.gapSm),
                                AnimatedRotation(
                                  duration: const Duration(milliseconds: 140),
                                  turns: _expanded ? 0.5 : 0,
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    color: colors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _AnimatedDropdownMenu(
                            expanded: _expanded,
                            child: _DropdownMenuContainer(
                              scheme: scheme,
                              dividerColor: scheme.outlineVariant.withValues(
                                alpha: 0.54,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: widget.menuMaxHeight,
                                ),
                                child: widget.options.isEmpty
                                    ? _DropdownEmptyState(
                                        label: widget.emptyLabel,
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: widget.options.length,
                                        separatorBuilder: (_, _) => Divider(
                                          height: 1,
                                          color: scheme.outlineVariant
                                              .withValues(
                                                alpha: 0.34,
                                              ),
                                        ),
                                        itemBuilder: (context, index) {
                                          final option = widget.options[index];
                                          final selected =
                                              option.value == widget.value;
                                          return _DropdownOptionTile(
                                            label: option.label,
                                            selected: selected,
                                            showSelectedIcon: false,
                                            onTap: () {
                                              widget.onChanged(option.value);
                                              _setExpanded(false);
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _FieldMessage(
            helperText: widget.helperText,
            errorText: widget.errorText,
          ),
        ],
      ),
    );
  }
}

class AppMultiSelectSearchField<T> extends StatefulWidget {
  const AppMultiSelectSearchField({
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    super.key,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.searchHintText = 'Search tags...',
    this.emptyResultsLabel = 'Nenhum resultado encontrado.',
    this.density = AppTextFieldDensity.comfortable,
    this.menuMaxHeight = 220,
    this.semanticsLabel,
    this.minimumSelectionCount = 0,
  }) : assert(
         minimumSelectionCount >= 0,
         'minimumSelectionCount must be non-negative',
       );

  final List<AppDropdownOption<T>> options;
  final List<T> selectedValues;
  final ValueChanged<List<T>> onChanged;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final String searchHintText;
  final String emptyResultsLabel;
  final AppTextFieldDensity density;
  final double menuMaxHeight;
  final String? semanticsLabel;

  /// When greater than zero, the user cannot deselect below this many items
  /// (dropdown toggles and chip remove controls respect this).
  final int minimumSelectionCount;

  @override
  State<AppMultiSelectSearchField<T>> createState() =>
      _AppMultiSelectSearchFieldState<T>();
}

class _AppMultiSelectSearchFieldState<T>
    extends State<AppMultiSelectSearchField<T>> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode(debugLabel: 'AppMultiSelectSearchField');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppMultiSelectSearchField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _expanded) {
      // Cannot use _setExpanded(false) here because its !widget.enabled guard
      // would return early — the widget is already disabled at this point.
      // Call setState + unfocus + clear directly, matching _setExpanded(false).
      setState(() => _expanded = false);
      _searchFocusNode.unfocus();
      _searchController.clear();
    }
  }

  void _setExpanded(bool value) {
    if (!widget.enabled) {
      return;
    }

    if (_expanded == value) {
      return;
    }

    setState(() => _expanded = value);
    if (value) {
      _searchFocusNode.requestFocus();
    } else {
      _searchFocusNode.unfocus();
      // Clear search so the next open shows all options, not a stale filter.
      _searchController.clear();
    }
  }

  void _toggleValue(T value) {
    final next = widget.selectedValues.toList(growable: true);
    if (next.contains(value)) {
      next.removeWhere((e) => e == value);
      if (next.length < widget.minimumSelectionCount) {
        return;
      }
    } else {
      next.add(value);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final hasError = widget.errorText?.trim().isNotEmpty ?? false;
    final borderRadius = BorderRadius.circular(tokens.formFieldRadius + 2);
    final fieldPadding = widget.density == AppTextFieldDensity.compact
        ? EdgeInsets.symmetric(
            horizontal: tokens.formFieldPaddingHorizontal,
            vertical: tokens.gapSm,
          )
        : _contentPadding(tokens, widget.density);
    final labelToFieldGap = widget.density == AppTextFieldDensity.compact
        ? tokens.gapXs
        : tokens.gapSm;
    final chipSectionBottomGap = widget.density == AppTextFieldDensity.compact
        ? tokens.gapXs
        : tokens.gapSm;
    final chipWrapSpacing = widget.density == AppTextFieldDensity.compact
        ? tokens.gapXs
        : tokens.gapSm;
    final borderSide = _resolveBorderSide(
      colors: colors,
      scheme: scheme,
      enabled: widget.enabled,
      expanded: _expanded,
      hasError: hasError,
    );
    final query = _searchController.text.trim().toLowerCase();
    final searchFieldStyle = widget.density == AppTextFieldDensity.compact
        ? typography.caption.copyWith(
            color: colors.onSurface,
            height: 1.25,
          )
        : typography.body.copyWith(color: colors.onSurface);
    final searchHintStyle = widget.density == AppTextFieldDensity.compact
        ? typography.caption.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.25,
          )
        : typography.body.copyWith(color: colors.onSurfaceVariant);
    final filteredOptions = widget.options
        .where((option) {
          if (query.isEmpty) {
            return true;
          }
          final haystack = '${option.label} ${option.searchText ?? ''}'
              .toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);

    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.label case final String label) ...<Widget>[
            Text(
              label.toUpperCase(),
              style: typography.utilityOverline.copyWith(
                color: hasError ? scheme.error : colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: labelToFieldGap),
          ],
          TapRegion(
            onTapOutside: (_) => _setExpanded(false),
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    _setExpanded(false),
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? scheme.surfaceContainerLowest
                      : scheme.surfaceContainerLow.withValues(alpha: 0.56),
                  borderRadius: borderRadius,
                  border: Border.fromBorderSide(borderSide),
                ),
                child: Column(
                  children: <Widget>[
                    if (widget.selectedValues.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          fieldPadding.left,
                          fieldPadding.top,
                          fieldPadding.right,
                          chipSectionBottomGap,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: chipWrapSpacing,
                            runSpacing: chipWrapSpacing,
                            children: widget.selectedValues
                                .map((value) {
                                  final option = widget.options
                                      .cast<AppDropdownOption<T>?>()
                                      .firstWhere(
                                        (entry) => entry?.value == value,
                                        orElse: () => null,
                                      );
                                  if (option == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final canRemove =
                                      widget.selectedValues.length >
                                      widget.minimumSelectionCount;

                                  return _MultiSelectChip(
                                    label: option.label.toUpperCase(),
                                    enabled: widget.enabled,
                                    onRemove: canRemove
                                        ? () => _toggleValue(value)
                                        : null,
                                  );
                                })
                                .toList(growable: false),
                          ),
                        ),
                      ),
                    if (widget.selectedValues.isNotEmpty)
                      Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.34),
                      ),
                    Padding(
                      padding: fieldPadding,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              widget.density == AppTextFieldDensity.compact
                              ? kMinInteractiveDimension
                              : 0,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                enabled: widget.enabled,
                                onTap: () => _setExpanded(true),
                                onChanged: (_) =>
                                    setState(() => _expanded = true),
                                style: searchFieldStyle,
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText: widget.searchHintText,
                                  hintStyle: searchHintStyle,
                                ),
                              ),
                            ),
                            SizedBox(width: tokens.gapSm),
                            InkWell(
                              onTap: widget.enabled
                                  ? () => _setExpanded(!_expanded)
                                  : null,
                              borderRadius: BorderRadius.circular(999),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: AnimatedRotation(
                                  duration: const Duration(milliseconds: 140),
                                  turns: _expanded ? 0.5 : 0,
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    size:
                                        widget.density ==
                                            AppTextFieldDensity.compact
                                        ? 20
                                        : 24,
                                    color: colors.outline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _AnimatedDropdownMenu(
                      expanded: _expanded,
                      child: _DropdownMenuContainer(
                        scheme: scheme,
                        dividerColor: scheme.outlineVariant.withValues(
                          alpha: 0.54,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: widget.menuMaxHeight,
                          ),
                          child: filteredOptions.isEmpty
                              ? _DropdownEmptyState(
                                  label: widget.emptyResultsLabel,
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: filteredOptions.length,
                                  separatorBuilder: (_, _) => Divider(
                                    height: 1,
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.34,
                                    ),
                                  ),
                                  itemBuilder: (context, index) {
                                    final option = filteredOptions[index];
                                    final selected = widget.selectedValues
                                        .contains(
                                          option.value,
                                        );
                                    return _DropdownOptionTile(
                                      label: option.label,
                                      selected: selected,
                                      multiSelect: true,
                                      onTap: () => _toggleValue(option.value),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _FieldMessage(
            helperText: widget.helperText,
            errorText: widget.errorText,
          ),
        ],
      ),
    );
  }
}

class _DropdownOptionTile extends StatelessWidget {
  const _DropdownOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.multiSelect = false,
    this.showSelectedIcon = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool multiSelect;
  final bool showSelectedIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final scheme = theme.colorScheme;
    final selectedBackground = theme.brightness == Brightness.dark
        ? const Color(0xFF7A7A7A)
        : const Color(0xFF8A8A8A);
    final selectedForeground = Colors.white.withValues(alpha: 0.98);

    return Material(
      color: selected ? selectedBackground : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.formFieldPaddingHorizontal,
            vertical: tokens.gapSm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: typography.body.copyWith(
                    color: selected ? selectedForeground : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (multiSelect)
                Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: selected
                      ? selectedForeground
                      : scheme.onSurfaceVariant,
                )
              else if (selected && showSelectedIcon)
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: selectedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiSelectChip extends StatelessWidget {
  const _MultiSelectChip({
    required this.label,
    required this.enabled,
    this.onRemove,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled
            ? scheme.primary
            : scheme.primary.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: tokens.gapMd,
          right: onRemove != null ? tokens.gapXs : tokens.gapMd,
          top: tokens.gapXs,
          bottom: tokens.gapXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: theme.appTypography.utilityOverline.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (onRemove != null) ...<Widget>[
              SizedBox(width: tokens.gapXs),
              InkWell(
                onTap: enabled ? onRemove : null,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DropdownEmptyState extends StatelessWidget {
  const _DropdownEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.all(tokens.contentSpacing),
      child: Text(
        label,
        style: theme.appTypography.caption.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DropdownMenuContainer extends StatelessWidget {
  const _DropdownMenuContainer({
    required this.child,
    required this.scheme,
    required this.dividerColor,
  });

  final Widget child;
  final ColorScheme scheme;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: child,
    );
  }
}

class _AnimatedDropdownMenu extends StatelessWidget {
  const _AnimatedDropdownMenu({
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
      child: expanded ? child : const SizedBox.shrink(),
    );
  }
}

class _FieldMessage extends StatelessWidget {
  const _FieldMessage({
    required this.helperText,
    required this.errorText,
  });

  final String? helperText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final message = errorText ?? helperText;
    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(
        top: tokens.gapXs,
        left: tokens.gapXs,
      ),
      child: Text(
        message,
        style: theme.appTypography.caption.copyWith(
          color: errorText != null
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

EdgeInsets _contentPadding(
  AppThemeTokens tokens,
  AppTextFieldDensity density,
) {
  final vertical = density == AppTextFieldDensity.compact
      ? tokens.formFieldPaddingVerticalCompact
      : tokens.formFieldPaddingVerticalComfortable;

  return EdgeInsets.symmetric(
    horizontal: tokens.formFieldPaddingHorizontal,
    vertical: vertical,
  );
}

BorderSide _resolveBorderSide({
  required AppColors colors,
  required ColorScheme scheme,
  required bool enabled,
  required bool expanded,
  required bool hasError,
}) {
  if (!enabled) {
    return BorderSide(color: colors.onSurface.withValues(alpha: 0.12));
  }
  if (hasError) {
    return BorderSide(color: scheme.error, width: 1.5);
  }
  if (expanded) {
    return BorderSide(color: scheme.primary, width: 1.5);
  }
  return BorderSide(color: colors.outlineVariant.withValues(alpha: 0.82));
}
