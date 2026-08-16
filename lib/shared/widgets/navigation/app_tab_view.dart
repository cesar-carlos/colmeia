import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class AppTabViewItem {
  const AppTabViewItem({
    required this.label,
    required this.child,
    this.semanticLabel,
  });

  final String label;
  final Widget child;
  final String? semanticLabel;
}

/// Invoked before switching tabs. Return `false` to keep the current tab.
typedef AppTabChangeGuard = Future<bool> Function(int fromIndex, int toIndex);

/// Compact horizontal tab navigation with inline content switching.
class AppTabView extends StatefulWidget {
  const AppTabView({
    required this.items,
    super.key,
    this.initialIndex = 0,
    this.onChanged,
    this.onTabChangeGuard,
    this.contentPadding,
    this.tabIndexListenable,
  }) : assert(items.length > 0, 'AppTabView requires at least one item.');

  final List<AppTabViewItem> items;
  final int initialIndex;
  final ValueChanged<int>? onChanged;

  /// When set, invoked before the selected tab changes. Return `false` to
  /// block the switch (e.g. unsaved form edits).
  final AppTabChangeGuard? onTabChangeGuard;
  final EdgeInsetsGeometry? contentPadding;

  /// When set, tab selection is driven by this notifier. User taps still
  /// update the notifier so parents can switch tabs programmatically.
  final ValueNotifier<int>? tabIndexListenable;

  @override
  State<AppTabView> createState() => _AppTabViewState();
}

class _AppTabViewState extends State<AppTabView> {
  late final ValueNotifier<int> _selectedIndex;
  late final bool _ownsSelectedIndex;

  @override
  void initState() {
    super.initState();
    final external = widget.tabIndexListenable;
    if (external != null) {
      _ownsSelectedIndex = false;
      _selectedIndex = external
        ..addListener(_onSelectedIndexChanged)
        ..value = _clampIndex(external.value);
    } else {
      _selectedIndex = ValueNotifier<int>(_clampIndex(widget.initialIndex));
      _ownsSelectedIndex = true;
    }
  }

  @override
  void didUpdateWidget(covariant AppTabView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tabIndexListenable != widget.tabIndexListenable) {
      throw StateError(
        'AppTabView.tabIndexListenable must not change after mount.',
      );
    }

    final nextIndex = _clampIndex(_selectedIndex.value);
    if (_selectedIndex.value != nextIndex) {
      _selectedIndex.value = nextIndex;
      return;
    }

    if (!_ownsSelectedIndex) {
      return;
    }

    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex.value = _clampIndex(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    if (_ownsSelectedIndex) {
      _selectedIndex.dispose();
    } else {
      _selectedIndex.removeListener(_onSelectedIndexChanged);
    }
    super.dispose();
  }

  void _onSelectedIndexChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int _clampIndex(int index) {
    if (widget.items.isEmpty) {
      return 0;
    }
    return index.clamp(0, widget.items.length - 1);
  }

  Future<void> _handleTabChange(int index) async {
    if (_selectedIndex.value == index) {
      return;
    }

    final guard = widget.onTabChangeGuard;
    if (guard != null) {
      final allowed = await guard(_selectedIndex.value, index);
      if (!allowed || !mounted) {
        return;
      }
    }

    _selectedIndex.value = index;
    widget.onChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ValueListenableBuilder<int>(
      valueListenable: _selectedIndex,
      builder: (context, selectedIndex, _) {
        if (widget.items.isEmpty) {
          return const SizedBox.shrink();
        }

        final safeIndex = _clampIndex(selectedIndex);
        final selectedItem = widget.items[safeIndex];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(widget.items.length, (index) {
                  final item = widget.items[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == widget.items.length - 1
                          ? 0
                          : tokens.contentSpacing,
                    ),
                    child: _AppTabViewTrigger(
                      label: item.label,
                      semanticLabel: item.semanticLabel,
                      isSelected: index == safeIndex,
                      onPressed: () => _handleTabChange(index),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: tokens.gapXs),
            Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.42),
            ),
            Padding(
              padding:
                  widget.contentPadding ??
                  EdgeInsets.only(top: tokens.contentSpacing),
              child: AnimatedSwitcher(
                duration: kThemeAnimationDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<int>(safeIndex),
                  child: selectedItem.child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AppTabViewTrigger extends StatelessWidget {
  const _AppTabViewTrigger({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final String? semanticLabel;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    final labelStyle = typography.sectionHeaderH2.copyWith(
      fontSize: 15,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: -0.15,
      color: isSelected ? cs.primary : cs.onSurfaceVariant,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel ?? label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.only(top: tokens.gapXs, bottom: tokens.gapSm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? cs.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: tokens.gapSm),
                child: Text(label, style: labelStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
