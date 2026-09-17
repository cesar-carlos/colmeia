import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_columns.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_totals_footer.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_compact_data_grid_scroll_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

class SalesNotasEntradaNotesGrid extends StatelessWidget {
  const SalesNotasEntradaNotesGrid({
    required this.l10n,
    required this.rows,
    required this.totalValorCompra,
    super.key,
  });

  final AppLocalizations l10n;
  final List<NotaEntradaRow> rows;
  final double totalValorCompra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final labels = SalesNotasEntradaColumnLabels.fromL10n(l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        final outer = constraints.maxWidth;
        final compactChave =
            outer.isFinite && outer > 0 && outer < AppBreakpoints.mobile;
        final minTable = SalesNotasEntradaTableLayout.minScrollContentWidth(
          tokens,
          compactChave: compactChave,
        );
        final hasHorizontalOverflow =
            outer.isFinite && outer > 0 && minTable > outer;
        final contentWidth = outer.isFinite && outer > 0
            ? math.max(outer, minTable)
            : minTable;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (hasHorizontalOverflow) ...<Widget>[
              Text(
                l10n.salesNotasEntradaHorizontalScrollCaption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.gapXs),
            ],
            AppCompactDataGridScrollTable(
              contentWidth: contentWidth,
              itemCount: rows.length,
              semanticsHint: hasHorizontalOverflow
                  ? l10n.salesNotasEntradaHorizontalScrollCaption
                  : null,
              showHorizontalFade: hasHorizontalOverflow,
              header: SalesNotasEntradaTableHeader(
                labels: labels,
                compactChave: compactChave,
              ),
              footer: SalesNotasEntradaNotesTotalsFooter(
                totalValorCompra: totalValorCompra,
                compactChave: compactChave,
              ),
              itemBuilder: (context, index) {
                return SalesNotasEntradaTableRow(
                  row: rows[index],
                  compactChave: compactChave,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class SalesNotasEntradaTableHeader extends StatelessWidget {
  const SalesNotasEntradaTableHeader({
    required this.labels,
    required this.compactChave,
    super.key,
  });

  final SalesNotasEntradaColumnLabels labels;
  final bool compactChave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final labelStyle = appDataGridHeaderLabelStyle(theme: theme);
    final endLabelStyle = appDataGridHeaderLabelStyle(
      theme: theme,
      textAlign: TextAlign.end,
    );

    return DecoratedBox(
      decoration: appDataGridHeaderDecoration(theme.colorScheme),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kAppCompactHeaderRowHeight,
        ),
        child: Padding(
          padding: appDataGridRowPadding(tokens),
          child: Row(
            children: <Widget>[
              _FixedCell(
                width: SalesNotasEntradaTableLayout.documentoWidth,
                child: Text(labels.documento, style: labelStyle),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.dateWidth,
                child: Text(labels.emissao, style: labelStyle),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.dateWidth,
                child: Text(labels.entrada, style: labelStyle),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.chaveAcessoWidth(
                  compactChave: compactChave,
                ),
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      width:
                          SalesNotasEntradaTableLayout.chaveAcessoCopySlotWidth,
                    ),
                    Expanded(
                      child: Text(labels.chaveAcesso, style: labelStyle),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: SalesNotasEntradaTableLayout.fornecedorMinWidth,
                  ),
                  child: Text(labels.fornecedor, style: labelStyle),
                ),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.cnpjWidth,
                child: Text(labels.cnpjCpf, style: labelStyle),
              ),
              _FixedCell(
                width: SalesNotasEntradaTableLayout.valorWidth,
                child: Text(
                  labels.valorTotal,
                  style: endLabelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesNotasEntradaTableRow extends StatelessWidget {
  const SalesNotasEntradaTableRow({
    required this.row,
    required this.compactChave,
    super.key,
  });

  final NotaEntradaRow row;
  final bool compactChave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];
    final bodyStyle = theme.textTheme.bodyMedium;
    final tabularStyle = bodyStyle?.copyWith(fontFeatures: tabularFigures);
    final mutedTabularStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: tabularFigures,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kAppCompactDataRowHeight),
      child: Padding(
        padding: appDataGridRowPadding(tokens),
        child: Row(
          children: <Widget>[
            _FixedCell(
              width: SalesNotasEntradaTableLayout.documentoWidth,
              child: Text(
                row.numeroDocumento,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle,
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.dateWidth,
              child: Text(
                formatSalesNotasEntradaDate(row.dataEmissao),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mutedTabularStyle,
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.dateWidth,
              child: Text(
                formatSalesNotasEntradaDate(row.dataEntrada),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mutedTabularStyle,
              ),
            ),
            _ChaveAcessoCell(
              value: row.chaveAcesso,
              style: tabularStyle,
              compactChave: compactChave,
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: SalesNotasEntradaTableLayout.fornecedorMinWidth,
                ),
                child: Text(
                  row.nomeFornecedor,
                  softWrap: true,
                  maxLines: 3,
                ),
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.cnpjWidth,
              child: Text(
                formatSalesNotasEntradaTaxId(row.cnpjCpfFornecedor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle,
              ),
            ),
            _FixedCell(
              width: SalesNotasEntradaTableLayout.valorWidth,
              child: Text(
                formatSalesNotasEntradaCurrency(row.valorTotalCompra),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChaveAcessoCell extends StatefulWidget {
  const _ChaveAcessoCell({
    required this.value,
    required this.style,
    required this.compactChave,
  });

  final String? value;
  final TextStyle? style;
  final bool compactChave;

  @override
  State<_ChaveAcessoCell> createState() => _ChaveAcessoCellState();
}

class _ChaveAcessoCellState extends State<_ChaveAcessoCell> {
  final ValueNotifier<bool> _copied = ValueNotifier<bool>(false);
  Timer? _copiedTimer;

  @override
  void didUpdateWidget(covariant _ChaveAcessoCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) {
      return;
    }
    _copiedTimer?.cancel();
    _copied.value = false;
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _copied.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final clipboardText = salesNotasEntradaChaveAcessoClipboardText(
      widget.value,
    );
    if (clipboardText == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: clipboardText));
    if (!mounted) {
      return;
    }
    _copied.value = true;
    _copiedTimer?.cancel();
    _copiedTimer = Timer(
      SalesNotasEntradaTableLayout.chaveAcessoCopiedFeedbackDuration,
      () {
        if (mounted) {
          _copied.value = false;
        }
      },
    );
    if (MediaQuery.supportsAnnounceOf(context)) {
      await SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context).salesNotasEntradaCopiedSnackbar,
        Directionality.of(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final clipboardText = salesNotasEntradaChaveAcessoClipboardText(
      widget.value,
    );
    final hasChave = clipboardText != null;
    final display = formatSalesNotasEntradaChaveAcesso(
      widget.value,
      compact: widget.compactChave,
    );
    final isMissing = (widget.value?.trim() ?? '').isEmpty;
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return _FixedCell(
      width: SalesNotasEntradaTableLayout.chaveAcessoWidth(
        compactChave: widget.compactChave,
      ),
      child: GestureDetector(
        onLongPress: hasChave ? () => unawaited(_copy()) : null,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: SalesNotasEntradaTableLayout.chaveAcessoCopyButtonSize,
              child: hasChave
                  ? ValueListenableBuilder<bool>(
                      valueListenable: _copied,
                      builder: (context, copied, _) {
                        return IconButton(
                          icon: Icon(
                            copied ? Icons.check_rounded : Icons.copy_rounded,
                            size: SalesNotasEntradaTableLayout
                                .chaveAcessoCopyIconSize,
                          ),
                          tooltip: l10n.salesNotasEntradaCopyChaveAcessoTooltip,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: SalesNotasEntradaTableLayout
                                .chaveAcessoCopyButtonSize,
                            height: SalesNotasEntradaTableLayout
                                .chaveAcessoCopyButtonSize,
                          ),
                          style: const ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: WidgetStatePropertyAll<EdgeInsets>(
                              EdgeInsets.zero,
                            ),
                          ),
                          onPressed: () => unawaited(_copy()),
                        );
                      },
                    )
                  : null,
            ),
            const SizedBox(
              width: SalesNotasEntradaTableLayout.chaveAcessoCopyGap,
            ),
            Expanded(
              child: Semantics(
                label: isMissing
                    ? l10n.salesNotasEntradaChaveAcessoMissing
                    : null,
                child: Text(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hasChave ? widget.style : mutedStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedCell extends StatelessWidget {
  const _FixedCell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}
