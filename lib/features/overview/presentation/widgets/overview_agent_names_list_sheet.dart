import 'dart:math' as math;

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

/// Returns trimmed, non-empty names, sorted case-insensitively, with
/// case-insensitive duplicates removed (first occurrence wins).
List<String> normalizeOverviewAgentNames(List<String> names) {
  final trimmed =
      (names
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toList())
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  final seenLower = <String>{};
  final out = <String>[];
  for (final n in trimmed) {
    final key = n.toLowerCase();
    if (seenLower.add(key)) {
      out.add(n);
    }
  }
  return out;
}

abstract final class _OverviewAgentNamesListSheetLayout {
  static const double maxWidth = 560;
  static const double initialChildSize = 0.55;
  static const double minChildSize = 0.35;
  static const double maxChildSize = 0.94;
}

/// [normalizedAgentNames] must be the result of [normalizeOverviewAgentNames].
Future<void> showOverviewAgentNamesListSheet({
  required BuildContext context,
  required String title,
  required List<String> normalizedAgentNames,
}) async {
  if (normalizedAgentNames.isEmpty) {
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => _OverviewAgentNamesListSheet(
      title: title,
      agentNames: normalizedAgentNames,
    ),
  );
}

class _OverviewAgentNamesListSheet extends StatefulWidget {
  const _OverviewAgentNamesListSheet({
    required this.title,
    required this.agentNames,
  });

  final String title;
  final List<String> agentNames;

  @override
  State<_OverviewAgentNamesListSheet> createState() =>
      _OverviewAgentNamesListSheetState();
}

class _OverviewAgentNamesListSheetState
    extends State<_OverviewAgentNamesListSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  List<String> get _filtered {
    final q = _query;
    if (q.isEmpty) {
      return widget.agentNames;
    }
    return widget.agentNames
        .where((name) => name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.extension<AppTypographyTokens>()!;
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: _OverviewAgentNamesListSheetLayout.initialChildSize,
        minChildSize: _OverviewAgentNamesListSheetLayout.minChildSize,
        maxChildSize: _OverviewAgentNamesListSheetLayout.maxChildSize,
        builder: (context, scrollController) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(
                  _OverviewAgentNamesListSheetLayout.maxWidth,
                  MediaQuery.sizeOf(context).width,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.contentSpacing,
                      tokens.gapSm,
                      tokens.contentSpacing,
                      tokens.gapSm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.title,
                            style: typography.sectionHeaderH2.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.contentSpacing,
                      tokens.gapSm,
                      tokens.contentSpacing,
                      tokens.gapSm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.overviewAgentFilterSheetSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            tokens.formFieldRadius,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(tokens.contentSpacing),
                              child: Text(
                                l10n.overviewAgentFilterNoSearchResults,
                                textAlign: TextAlign.center,
                                style: typography.body.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(
                              tokens.contentSpacing,
                              0,
                              tokens.contentSpacing,
                              tokens.contentSpacing,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final name = filtered[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: tokens.gapSm),
                                child: Semantics(
                                  label: name,
                                  child: SelectableText(
                                    name,
                                    style: typography.body.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
