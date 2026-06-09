import 'dart:async';

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/utils/app_debouncer.dart';
import 'package:colmeia/shared/widgets/forms/app_form_field_message.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppAsyncSearchOption<T> {
  const AppAsyncSearchOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class AppAsyncSearchQuery {
  const AppAsyncSearchQuery({
    required this.searchTerm,
    required this.page,
    this.pageSize = 20,
  });

  final String searchTerm;
  final int page;
  final int pageSize;
}

class AppAsyncSearchLoadResult<T> {
  const AppAsyncSearchLoadResult({
    required this.options,
    required this.hasMore,
    this.selectedOption,
    this.errorMessage,
  });

  final List<AppAsyncSearchOption<T>> options;
  final bool hasMore;
  final AppAsyncSearchOption<T>? selectedOption;
  final String? errorMessage;
}

typedef AppAsyncSearchLoader<T> =
    Future<AppAsyncSearchLoadResult<T>> Function(AppAsyncSearchQuery query);

typedef AppAsyncSearchChanged<T> =
    void Function(
      T? value, {
      String? label,
    });

class AppAsyncSearchField<T> extends StatefulWidget {
  const AppAsyncSearchField({
    required this.loader,
    required this.onChanged,
    super.key,
    this.value,
    this.selectedDisplayLabel,
    this.label,
    this.hintText,
    this.searchHintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.density = AppTextFieldDensity.comfortable,
    this.menuMaxHeight = 220,
    this.minSearchLength = 2,
    this.debounceDuration = const Duration(milliseconds: 250),
    this.minSearchLengthHint,
    this.emptyResultsLabel,
    this.clearOptionLabel,
    this.semanticsLabel,
    this.pageSize = 20,
  });

  final AppAsyncSearchLoader<T> loader;
  final AppAsyncSearchChanged<T> onChanged;
  final T? value;
  final String? selectedDisplayLabel;
  final String? label;
  final String? hintText;
  final String? searchHintText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final AppTextFieldDensity density;
  final double menuMaxHeight;
  final int minSearchLength;
  final Duration debounceDuration;
  final String? minSearchLengthHint;
  final String? emptyResultsLabel;
  final String? clearOptionLabel;
  final String? semanticsLabel;
  final int pageSize;

  @override
  State<AppAsyncSearchField<T>> createState() => _AppAsyncSearchFieldState<T>();
}

class _AppAsyncSearchFieldState<T> extends State<AppAsyncSearchField<T>> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late final AppDebouncer _debouncer;

  bool _expanded = false;
  bool _loading = false;
  bool _loadingMore = false;
  String? _panelErrorMessage;
  int _requestGeneration = 0;
  int _loadedPage = 0;
  bool _hasMore = false;
  List<AppAsyncSearchOption<T>> _options = <AppAsyncSearchOption<T>>[];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode(debugLabel: 'AppAsyncSearchField');
    _scrollController = ScrollController()..addListener(_onScroll);
    _debouncer = AppDebouncer(duration: widget.debounceDuration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppAsyncSearchField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _expanded) {
      _setExpanded(false);
    }
    if (oldWidget.debounceDuration != widget.debounceDuration) {
      _debouncer.dispose();
      _debouncer = AppDebouncer(duration: widget.debounceDuration);
    }
  }

  void _setExpanded(bool value) {
    if (!widget.enabled && value) {
      return;
    }
    if (_expanded == value) {
      return;
    }
    setState(() => _expanded = value);
    if (value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _expanded) {
          _focusNode.requestFocus();
        }
      });
    } else {
      _focusNode.unfocus();
      _searchController.clear();
      _resetPanelState();
    }
  }

  void _resetPanelState() {
    _loading = false;
    _loadingMore = false;
    _panelErrorMessage = null;
    _loadedPage = 0;
    _hasMore = false;
    _options = <AppAsyncSearchOption<T>>[];
    ++_requestGeneration;
  }

  void _onSearchChanged(String value) {
    if (!_expanded) {
      setState(() => _expanded = true);
    }
    _debouncer.run(() => unawaited(_loadPage(reset: true)));
  }

  void _onScroll() {
    if (!_hasMore ||
        _loading ||
        _loadingMore ||
        !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 48) {
      unawaited(_loadPage(reset: false));
    }
  }

  Future<void> _loadPage({required bool reset}) async {
    final trimmed = _searchController.text.trim();
    if (trimmed.length < widget.minSearchLength) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        _panelErrorMessage = null;
        _options = <AppAsyncSearchOption<T>>[];
        _hasMore = false;
        _loadedPage = 0;
      });
      return;
    }

    final nextPage = reset ? 1 : _loadedPage + 1;
    if (!reset && (!_hasMore || _loadingMore)) {
      return;
    }

    final generation = ++_requestGeneration;
    if (!mounted) {
      return;
    }
    setState(() {
      if (reset) {
        _loading = true;
        _loadingMore = false;
        _panelErrorMessage = null;
        _options = <AppAsyncSearchOption<T>>[];
        _loadedPage = 0;
        _hasMore = false;
      } else {
        _loadingMore = true;
      }
    });

    final result = await widget.loader(
      AppAsyncSearchQuery(
        searchTerm: trimmed,
        page: nextPage,
        pageSize: widget.pageSize,
      ),
    );

    if (!mounted || generation != _requestGeneration) {
      return;
    }

    final errorMessage = result.errorMessage?.trim();
    if (errorMessage != null && errorMessage.isNotEmpty) {
      setState(() {
        _loading = false;
        _loadingMore = false;
        _panelErrorMessage = errorMessage;
        if (reset) {
          _options = <AppAsyncSearchOption<T>>[];
          _loadedPage = 0;
          _hasMore = false;
        }
      });
      return;
    }

    setState(() {
      _loading = false;
      _loadingMore = false;
      _panelErrorMessage = null;
      _loadedPage = nextPage;
      _hasMore = result.hasMore;
      _options = reset
          ? List<AppAsyncSearchOption<T>>.of(result.options)
          : <AppAsyncSearchOption<T>>[..._options, ...result.options];
    });
  }

  void _selectOption(AppAsyncSearchOption<T> option) {
    widget.onChanged(option.value, label: option.label);
    _setExpanded(false);
  }

  void _clearSelection() {
    widget.onChanged(null);
    _setExpanded(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasError = widget.errorText?.trim().isNotEmpty ?? false;
    final hasSelection =
        widget.value != null || widget.selectedDisplayLabel != null;
    final resolvedMinSearchLengthHint =
        widget.minSearchLengthHint ??
        l10n.appAsyncSearchMinSearchLengthHint(widget.minSearchLength);
    final resolvedEmptyResultsLabel =
        widget.emptyResultsLabel ?? l10n.appAsyncSearchEmptyResults;
    final collapsedLabel = hasSelection
        ? (widget.selectedDisplayLabel ?? widget.value.toString())
        : (widget.hintText ?? l10n.appAsyncSearchSelectOptionHint);
    final borderRadius = BorderRadius.circular(tokens.formFieldRadius + 2);
    final fieldPadding = _contentPadding(tokens, widget.density);
    final borderSide = resolveFormFieldBorderSide(
      colors: colors,
      scheme: scheme,
      enabled: widget.enabled,
      focused: _expanded,
      hasError: hasError,
    );
    final searchTerm = _searchController.text.trim();
    final belowMinLength =
        _expanded && searchTerm.length < widget.minSearchLength;

    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      textField: true,
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
                    Padding(
                      padding: fieldPadding,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _expanded
                                ? TextField(
                                    controller: _searchController,
                                    focusNode: _focusNode,
                                    enabled: widget.enabled,
                                    onChanged: _onSearchChanged,
                                    style: typography.body.copyWith(
                                      color: colors.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText:
                                          widget.searchHintText ??
                                          widget.hintText ??
                                          l10n.appAsyncSearchSearchHint,
                                      hintStyle: typography.body.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: widget.enabled
                                        ? () => _setExpanded(true)
                                        : null,
                                    child: Text(
                                      collapsedLabel,
                                      style: typography.body.copyWith(
                                        color: hasSelection
                                            ? colors.onSurface
                                            : colors.onSurfaceVariant,
                                        fontWeight: hasSelection
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                                duration: const Duration(
                                  milliseconds: 140,
                                ),
                                turns: _expanded ? 0.5 : 0,
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  color: colors.outline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AnimatedAsyncSearchMenu(
                      expanded: _expanded,
                      child: _AsyncSearchMenuContainer(
                        scheme: scheme,
                        dividerColor: scheme.outlineVariant.withValues(
                          alpha: 0.54,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: widget.menuMaxHeight,
                          ),
                          child: _buildPanelContent(
                            theme: theme,
                            tokens: tokens,
                            belowMinLength: belowMinLength,
                            minSearchLengthHint: resolvedMinSearchLengthHint,
                            emptyResultsLabel: resolvedEmptyResultsLabel,
                            retryLabel: l10n.appAsyncSearchRetry,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppFormFieldMessage(
            helperText: widget.helperText,
            errorText: widget.errorText,
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent({
    required ThemeData theme,
    required AppThemeTokens tokens,
    required bool belowMinLength,
    required String minSearchLengthHint,
    required String emptyResultsLabel,
    required String retryLabel,
  }) {
    if (belowMinLength && !_loading) {
      return _AsyncSearchPanelMessage(label: minSearchLengthHint);
    }
    if (_panelErrorMessage != null) {
      return _AsyncSearchPanelError(
        message: _panelErrorMessage!,
        retryLabel: retryLabel,
        onRetry: () => unawaited(_loadPage(reset: true)),
      );
    }
    if (_loading && _options.isEmpty) {
      return _AsyncSearchLoadingSkeleton(tokens: tokens);
    }
    if (_options.isEmpty && !_loading) {
      return _AsyncSearchPanelMessage(label: emptyResultsLabel);
    }

    final clearLabel = widget.clearOptionLabel;
    final itemCount =
        _options.length + (clearLabel == null ? 0 : 1) + (_loadingMore ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.34),
      ),
      itemBuilder: (context, index) {
        if (clearLabel != null && index == 0) {
          return _AsyncSearchOptionTile(
            label: clearLabel,
            selected: widget.value == null,
            onTap: _clearSelection,
          );
        }
        final optionIndex = index - (clearLabel == null ? 0 : 1);
        if (optionIndex >= _options.length) {
          return const _AsyncSearchLoadingMoreTile();
        }
        final option = _options[optionIndex];
        return _AsyncSearchOptionTile(
          label: option.label,
          selected: option.value == widget.value,
          onTap: () => _selectOption(option),
        );
      },
    );
  }
}

class _AsyncSearchOptionTile extends StatelessWidget {
  const _AsyncSearchOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final scheme = theme.colorScheme;
    final selectedBackground = scheme.inverseSurface;
    final selectedForeground = scheme.onInverseSurface;

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
              if (selected)
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

class _AsyncSearchPanelMessage extends StatelessWidget {
  const _AsyncSearchPanelMessage({required this.label});

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

class _AsyncSearchPanelError extends StatelessWidget {
  const _AsyncSearchPanelError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.all(tokens.contentSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: theme.appTypography.caption.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: tokens.gapSm),
          TextButton(
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _AsyncSearchLoadingSkeleton extends StatelessWidget {
  const _AsyncSearchLoadingSkeleton({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;

    return Column(
      children: List<Widget>.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.formFieldPaddingHorizontal,
            vertical: tokens.gapSm,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 14,
              width: index.isEven ? 180 : 140,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular(tokens.gapXs),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AsyncSearchLoadingMoreTile extends StatelessWidget {
  const _AsyncSearchLoadingMoreTile();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.formFieldPaddingHorizontal,
        vertical: tokens.gapSm,
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _AsyncSearchMenuContainer extends StatelessWidget {
  const _AsyncSearchMenuContainer({
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

class _AnimatedAsyncSearchMenu extends StatelessWidget {
  const _AnimatedAsyncSearchMenu({
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
            // SizeTransition.axisAlignment is deprecated but still required
            // for top-aligned expand/collapse until a non-deprecated API exists.
            // ignore: deprecated_member_use
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: expanded ? child : const SizedBox.shrink(),
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
