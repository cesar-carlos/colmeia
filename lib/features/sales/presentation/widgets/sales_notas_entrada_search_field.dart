import 'dart:async';

import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_search.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Compact supplier search field with debounce and a clear suffix.
class SalesNotasEntradaSearchField extends StatefulWidget {
  const SalesNotasEntradaSearchField({
    required this.searchTerm,
    required this.onSearchChanged,
    required this.hintText,
    super.key,
    this.enabled = true,
  });

  final String? searchTerm;
  final ValueChanged<String> onSearchChanged;
  final String hintText;
  final bool enabled;

  @override
  State<SalesNotasEntradaSearchField> createState() =>
      _SalesNotasEntradaSearchFieldState();
}

class _SalesNotasEntradaSearchFieldState
    extends State<SalesNotasEntradaSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchTerm ?? '');
    _focusNode = FocusNode(debugLabel: 'SalesNotasEntradaSearchField');
  }

  @override
  void didUpdateWidget(covariant SalesNotasEntradaSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadFocus = _focusNode.hasFocus;
    final next = widget.searchTerm ?? '';
    if (!hadFocus &&
        oldWidget.searchTerm != widget.searchTerm &&
        next != _controller.text) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _emit(String term) {
    _debounce?.cancel();
    _debounce = Timer(
      SalesNotasEntradaSearch.debounce,
      () => widget.onSearchChanged(term),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      focusNode: _focusNode,
      hintText: widget.hintText,
      prefixIcon: Icons.search_rounded,
      density: AppTextFieldDensity.compact,
      enabled: widget.enabled,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (term) {
        _debounce?.cancel();
        widget.onSearchChanged(term);
      },
      suffix: _SearchClearButton(
        controller: _controller,
        onCleared: () {
          _debounce?.cancel();
          widget.onSearchChanged('');
        },
      ),
      onChanged: _emit,
    );
  }
}

class _SearchClearButton extends StatelessWidget {
  const _SearchClearButton({
    required this.controller,
    required this.onCleared,
  });

  final TextEditingController controller;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) {
          return const SizedBox.shrink();
        }
        return IconButton(
          icon: const Icon(Icons.close_rounded, size: 18),
          tooltip: AppLocalizations.of(context).reportClearSearchTooltip,
          onPressed: () {
            controller.clear();
            onCleared();
          },
        );
      },
    );
  }
}
