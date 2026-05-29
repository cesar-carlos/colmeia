import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_form_field_message.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Slider compartilhado que segue o padrao visual de `AppDropdownField` e
/// `AppDatePickerField`: label overline em caixa alta acima, controle com
/// borda customizada e helper/error inline abaixo.
///
/// Otimizacao de perf: o slider mantem um `_dragValue` local enquanto o
/// usuario arrasta. Sem isso, cada tick de arrasto dispararia [onChanged]
/// no consumidor, causando rebuilds em cascata (controller + filtros + grafico).
/// Com este buffer, [onChanged] (se fornecido) recebe atualizacoes leves para
/// feedback visual *opcional*, e [onChangeEnd] e a fonte canonica para
/// persistir o valor final no estado externo (ex.: filtros, controllers).
///
/// Para reduzir rebuilds, prefira **somente** [onChangeEnd] como callback
/// efetivo e deixe [onChanged] em `null`. O slider continua animando
/// suavemente porque renderiza a partir do estado local.
class AppSliderField extends StatefulWidget {
  const AppSliderField({
    required this.value,
    required this.min,
    required this.max,
    super.key,
    this.label,
    this.valueLabelBuilder,
    this.helperText,
    this.errorText,
    this.divisions,
    this.enabled = true,
    this.density = AppTextFieldDensity.comfortable,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticsLabel,
  }) : assert(min < max, 'min must be < max'),
       assert(value >= min && value <= max, 'value must be in [min, max]');

  final double value;
  final double min;
  final double max;
  final int? divisions;

  /// Disparado em cada tick de arrasto. Opcional: deixe em `null` para
  /// minimizar rebuilds. O slider renderiza pelo estado local, entao a
  /// animacao do thumb nao depende deste callback.
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;

  /// Disparado quando o usuario solta o slider. Use este como **fonte
  /// canonica** do novo valor para reduzir cascata de rebuilds.
  final ValueChanged<double>? onChangeEnd;

  final String? label;

  /// Builder do texto formatado mostrado a direita do label; ex.: "R$ 0,00".
  /// Recebe o valor *que esta sendo arrastado* em tempo real, garantindo
  /// feedback imediato sem custo de rebuild externo.
  final String Function(double effectiveValue)? valueLabelBuilder;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final AppTextFieldDensity density;
  final String? semanticsLabel;

  @override
  State<AppSliderField> createState() => _AppSliderFieldState();
}

class _AppSliderFieldState extends State<AppSliderField> {
  double? _dragValue;

  double get _effectiveValue => _dragValue ?? widget.value;

  @override
  void didUpdateWidget(covariant AppSliderField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o consumidor mudou o valor externamente sem ser via drag (ex.: reset),
    // sai do modo drag para refletir o novo estado canonico.
    if (_dragValue != null && oldWidget.value != widget.value) {
      _dragValue = null;
    }
  }

  void _handleChanged(double value) {
    setState(() => _dragValue = value);
    widget.onChanged?.call(value);
  }

  void _handleChangeEnd(double value) {
    setState(() => _dragValue = null);
    widget.onChangeEnd?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final hasError = widget.errorText?.trim().isNotEmpty ?? false;
    final compact = widget.density == AppTextFieldDensity.compact;
    final labelGap = compact ? tokens.gapXs : tokens.formLabelToControlGap;
    final overlineColor = hasError
        ? scheme.error
        : (widget.enabled
              ? colors.onSurfaceVariant
              : colors.onSurface.withValues(alpha: 0.38));
    final effective = _effectiveValue.clamp(widget.min, widget.max);
    final formattedValue = widget.valueLabelBuilder?.call(effective);

    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      enabled: widget.enabled,
      slider: true,
      value: formattedValue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.label != null || formattedValue != null) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                if (widget.label != null)
                  Expanded(
                    child: Text(
                      widget.label!.toUpperCase(),
                      style: typography.utilityOverline.copyWith(
                        color: overlineColor,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (formattedValue != null)
                  Text(
                    formattedValue,
                    style: typography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: widget.enabled
                          ? colors.onSurface
                          : colors.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
              ],
            ),
            SizedBox(height: labelGap),
          ],
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: compact ? 3 : 4,
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.outlineVariant.withValues(alpha: 0.6),
              thumbColor: scheme.primary,
              overlayColor: scheme.primary.withValues(alpha: 0.12),
              valueIndicatorColor: scheme.inverseSurface,
              valueIndicatorTextStyle: typography.caption.copyWith(
                color: scheme.onInverseSurface,
                fontWeight: FontWeight.w600,
              ),
              showValueIndicator: ShowValueIndicator.onlyForDiscrete,
            ),
            child: Slider(
              value: effective,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              label: formattedValue,
              onChanged: widget.enabled ? _handleChanged : null,
              onChangeStart: widget.enabled ? widget.onChangeStart : null,
              onChangeEnd: widget.enabled ? _handleChangeEnd : null,
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
}
