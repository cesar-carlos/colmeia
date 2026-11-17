import 'dart:math' as math;

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/actions/action_button_helpers.dart';
import 'package:colmeia/shared/widgets/actions/app_destructive_button.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_text_action_button.dart';
import 'package:colmeia/shared/widgets/app_chip_container.dart';
import 'package:colmeia/shared/widgets/app_dialog.dart';
import 'package:colmeia/shared/widgets/app_status_badge.dart';
import 'package:colmeia/shared/widgets/forms/app_checkbox_field.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_form_field_message.dart';
import 'package:colmeia/shared/widgets/forms/app_radio_group.dart';
import 'package:colmeia/shared/widgets/forms/app_slider_field.dart';
import 'package:colmeia/shared/widgets/forms/app_switch_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_nav_menu_item.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_interactive_field.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_section_title.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_grid_source.dart';
import 'package:colmeia/shared/widgets/reports/app_report_header_actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test(
    'report theme refresh notifies once without replacing rows or styles',
    () {
      final context = _ThemeContext(AppTheme.light());
      final source = AppReportGridSource<String>(
        rows: const ['Loja'],
        visibleColumns: [
          AppReportColumn<String>(
            key: 'name',
            label: 'Nome',
            valueGetter: (value) => value,
            cellStyle: AppReportCellStyle.link,
          ),
        ],
        context: context,
      );
      addTearDown(source.dispose);
      final originalRow = source.rows.first;
      final customStyle = AppTheme.light().textTheme.bodyMedium!.copyWith(
        fontSize: 19,
      );
      source.updatePresentation(dataTextStyle: customStyle);
      var notifications = 0;
      source
        ..addListener(() => notifications++)
        ..updatePresentation(dataTextStyle: customStyle);
      expect(notifications, 0);
      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        final previousNotifications = notifications;
        context.setTheme(theme);
        source.updatePresentation(dataTextStyle: customStyle);
        expect(notifications, previousNotifications + 1);
        expect(source.rows.first, same(originalRow));
        expect(source.dataTextStyle, customStyle);
        final text =
            (source.buildRow(originalRow).cells.single as Container).child!
                as Text;
        expect(text.style!.fontSize, 19);
        expect(text.style!.color, theme.colorScheme.surfaceAccent);
        source.updatePresentation(dataTextStyle: customStyle);
        expect(notifications, previousNotifications + 1);
      }
    },
  );
  for (final dark in [false, true]) {
    final theme = dark ? AppTheme.dark() : AppTheme.light();
    final context = _ThemeContext(theme);
    test(
      'switch theme outline contrast and disabled priority (dark: $dark)',
      () {
        final switchTheme = theme.switchTheme;
        final outline = switchTheme.trackOutlineColor!.resolve({})!;
        for (final background in [
          theme.colorScheme.surface,
          theme.colorScheme.surfaceContainerLowest,
          switchTheme.trackColor!.resolve({})!,
        ]) {
          expect(
            _contrast(Color.alphaBlend(outline, background), background),
            greaterThanOrEqualTo(3),
          );
        }
        final disabledOutline = switchTheme.trackOutlineColor!.resolve({
          WidgetState.disabled,
        });
        expect(
          disabledOutline,
          theme.colorScheme.onSurface.withValues(alpha: 0.12),
        );
        expect(
          switchTheme.trackOutlineColor!.resolve({
            WidgetState.disabled,
            WidgetState.selected,
          }),
          disabledOutline,
        );
        expect(
          switchTheme.trackColor!.resolve({WidgetState.selected}),
          theme.colorScheme.primary,
        );
        expect(
          switchTheme.thumbColor!.resolve({WidgetState.selected}),
          theme.colorScheme.onPrimary,
        );
      },
    );
    for (final enabled in [false, true]) {
      for (final selected in [false, true]) {
        test(
          'switch selection (dark: $dark, enabled: $enabled, selected: $selected)',
          () {
            bool? changed;
            final semantics = AppSwitchField(
              value: selected,
              enabled: enabled,
              label: 'Notifications',
              onChanged: (value) => changed = value,
            ).build(context) as Semantics;
            final merged = semantics.child! as MergeSemantics;
            final excluded = merged.child! as ExcludeSemantics;
            final material = excluded.child! as Material;
            final ink = material.child! as InkWell;
            final container = ink.child! as AnimatedContainer;
            final decoration = container.decoration! as BoxDecoration;
            final scheme = theme.colorScheme;
            expect(semantics.properties.toggled, selected);
            expect(semantics.properties.enabled, enabled);
            if (enabled) {
              ink.onTap!();
              expect(changed, !selected);
              if (selected) {
                final background = Color.alphaBlend(
                  decoration.color!,
                  scheme.surface,
                );
                expect(
                  _contrast(
                    (decoration.border! as Border).top.color,
                    background,
                  ),
                  greaterThanOrEqualTo(3),
                );
              }
            } else {
              expect(ink.onTap, isNull);
              expect(semantics.properties.onTap, isNull);
              expect(decoration.color, scheme.surfaceContainerLowest);
              expect(
                (decoration.border! as Border).top.color,
                scheme.onSurface.withValues(alpha: 0.12),
              );
            }
          },
        );
      }
    }
    for (final compact in [false, true]) {
      test('slider indicators contrast (dark: $dark, compact: $compact)', () {
        final base = SliderThemeData(
          disabledThumbColor: theme.colorScheme.outline,
        );
        final slider = resolveAppSliderTheme(
          theme: theme,
          base: base,
          compact: compact,
        );
        expect(slider.trackHeight, compact ? 3 : 4);
        expect(slider.disabledThumbColor, base.disabledThumbColor);
        expect(
          _contrast(slider.thumbColor!, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(slider.activeTrackColor!, slider.inactiveTrackColor!),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(slider.activeTickMarkColor!, slider.activeTrackColor!),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(slider.inactiveTickMarkColor!, slider.inactiveTrackColor!),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(
            slider.valueIndicatorTextStyle!.color!,
            slider.valueIndicatorColor!,
          ),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
    for (final variant in AppStatusBadgeVariant.values) {
      test('status badge $variant contrast (dark: $dark)', () {
        final chip = AppStatusBadge(
          label: 'Status',
          variant: variant,
        ).build(context) as AppChipContainer;
        final text = chip.child as Text;
        final background = Color.alphaBlend(
          chip.backgroundColor,
          theme.colorScheme.surface,
        );
        expect(
          _contrast(text.style!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
    test('focused field borders remain visible (dark: $dark)', () {
      final custom = resolveFormFieldBorderSide(
        colors: theme.appColors,
        scheme: theme.colorScheme,
        enabled: true,
        focused: true,
        hasError: false,
      );
      final native = theme.inputDecorationTheme.focusedBorder!.borderSide;
      for (final border in [custom, native]) {
        expect(
          _contrast(border.color, theme.colorScheme.surfaceContainerLowest),
          greaterThanOrEqualTo(3),
        );
      }
      expect(
        resolveFormFieldBorderSide(
          colors: theme.appColors,
          scheme: theme.colorScheme,
          enabled: true,
          focused: true,
          hasError: true,
        ).color,
        theme.colorScheme.error,
      );
      expect(
        resolveFormFieldBorderSide(
          colors: theme.appColors,
          scheme: theme.colorScheme,
          enabled: false,
          focused: true,
          hasError: true,
        ).color.a,
        closeTo(0.12, 0.01),
      );
    });
    test('empty errors preserve helper messages (dark: $dark)', () {
      for (final error in <String?>[null, '', '   ']) {
        final padding = AppFormFieldMessage(
          helperText: 'Ajuda',
          errorText: error,
        ).build(context) as Padding;
        final text = padding.child! as Text;
        expect(text.data, 'Ajuda');
        expect(text.style!.color, theme.colorScheme.onSurfaceVariant);
      }
      final error = const AppFormFieldMessage(
        helperText: 'Ajuda',
        errorText: 'Erro',
      ).build(context) as Padding;
      expect((error.child! as Text).data, 'Erro');
      expect((error.child! as Text).style!.color, theme.colorScheme.error);
      expect(
        const AppFormFieldMessage(
          helperText: ' ',
          errorText: '',
        ).build(context),
        isA<SizedBox>(),
      );
    });
    test('dialog leading icon remains visible (dark: $dark)', () {
      final material = const AppDialogSurface(
        title: 'Confirmar',
        message: 'Mensagem',
        leadingIcon: Icons.info,
      ).build(context) as Material;
      final column =
          (material.child! as SingleChildScrollView).child! as Column;
      final row = column.children.first as Row;
      final icon = (row.children.first as Padding).child! as Icon;
      expect(_contrast(icon.color!, material.color!), greaterThanOrEqualTo(3));
    });
    for (final customBackground in <Color?>[
      null,
      AppTheme.light().colorScheme.surface,
      AppTheme.dark().colorScheme.surface,
    ]) {
      test('all loading actions contrast with background $customBackground '
          '(dark: $dark)', () {
        final style = customBackground == null
            ? null
            : ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(customBackground),
              );
        final buttons = <StatelessWidget>[
          AppPrimaryButton(
            label: 'Salvar',
            onPressed: () {},
            isLoading: true,
            style: style,
          ),
          AppDestructiveButton(
            label: 'Excluir',
            onPressed: () {},
            isLoading: true,
            style: style,
          ),
          AppFlatButton(
            label: 'Atualizar',
            onPressed: () {},
            isLoading: true,
            style: style,
          ),
          AppSecondaryButton(
            label: 'Voltar',
            onPressed: () {},
            isLoading: true,
            style: style,
          ),
          AppSecondaryButton(
            label: 'Voltar',
            onPressed: () {},
            isLoading: true,
            style: style,
            variant: AppSecondaryButtonVariant.tonal,
          ),
          AppTextActionButton(
            label: 'Abrir',
            onPressed: () {},
            isLoading: true,
            style: style,
          ),
        ];
        for (final widget in buttons) {
          // Inspect state-dependent styles without mounting a widget tree.
          // ignore: invalid_use_of_protected_member
          final semantics = widget.build(context) as Semantics;
          final button = semantics.child! as ButtonStyleButton;
          final progress =
              (button.child! as SizedBox).child! as CircularProgressIndicator;
          final background = Color.alphaBlend(
            button.style!.backgroundColor?.resolve({WidgetState.disabled}) ??
                Colors.transparent,
            theme.colorScheme.surface,
          );
          expect(
            _contrast(progress.color!, background),
            greaterThanOrEqualTo(3),
          );
          expect(button.onPressed, isNull);
          expect(semantics.properties.enabled, isFalse);
        }
      });
    }
    test('explicit loading color is preserved (dark: $dark)', () {
      expect(
        resolveAppActionButtonLoadingColor(
          scheme: theme.colorScheme,
          style: const ButtonStyle(),
          fallbackBackground: theme.colorScheme.surface,
          overrideColor: theme.colorScheme.tertiary,
        ),
        theme.colorScheme.tertiary,
      );
    });
    test(
      'primary loading spinner contrasts with disabled fill (dark: $dark)',
      () {
        final semantics = AppPrimaryButton(
          label: 'Salvar',
          onPressed: () {},
          isLoading: true,
        ).build(context) as Semantics;
        final button = semantics.child! as FilledButton;
        final progress =
            (button.child! as SizedBox).child! as CircularProgressIndicator;
        final background = button.style!.backgroundColor!.resolve({
          WidgetState.disabled,
        })!;
        expect(_contrast(progress.color!, background), greaterThanOrEqualTo(3));
        expect(button.onPressed, isNull);
      },
    );
    for (final selected in [true, false]) {
      for (final enabled in [true, false]) {
        test(
          'custom checkbox selected=$selected enabled=$enabled (dark: $dark)',
          () {
            final events = <bool?>[];
            final semantics = AppCheckboxField(
              label: 'Selecionar',
              value: selected,
              enabled: enabled,
              onChanged: events.add,
            ).build(context) as Semantics;
            final merge = semantics.child! as MergeSemantics;
            final material =
                (merge.child! as ExcludeSemantics).child! as Material;
            final ink = material.child! as InkWell;
            final outer = ink.child! as AnimatedContainer;
            final control =
                (outer.child! as Row).children.first as AnimatedContainer;
            final fill = (control.decoration! as BoxDecoration).color!;
            final outerDecoration = outer.decoration! as BoxDecoration;
            final background = Color.alphaBlend(
              outerDecoration.color!,
              theme.colorScheme.surface,
            );
            final controlBorder =
                ((control.decoration! as BoxDecoration).border! as Border)
                    .top
                    .color;
            final icon = control.child! as Icon;
            expect(semantics.properties.checked, selected);
            expect(semantics.properties.enabled, enabled);
            if (enabled) {
              expect(
                _contrast(
                  Color.alphaBlend(controlBorder, background),
                  background,
                ),
                greaterThanOrEqualTo(3),
              );
              ink.onTap!();
              expect(events, [!selected]);
              if (selected) {
                expect(
                  _contrast(
                    (outerDecoration.border! as Border).top.color,
                    background,
                  ),
                  greaterThanOrEqualTo(3),
                );
                expect(_contrast(icon.color!, fill), greaterThanOrEqualTo(3));
              }
            } else {
              expect(ink.onTap, isNull);
              expect(semantics.properties.onTap, isNull);
              expect(fill, isNot(theme.colorScheme.primary));
              expect(icon.color!.a, closeTo(selected ? 0.38 : 0, 0.01));
              expect(events, isEmpty);
            }
          },
        );
      }
    }
    for (final tone in AppReportHeaderActionTone.values) {
      for (final enabled in [true, false]) {
        test('report header $tone enabled=$enabled (dark: $dark)', () {
          final material = AppReportHeaderActionButton(
            label: 'Exportar',
            icon: Icons.download,
            tone: tone,
            onPressed: enabled ? () {} : null,
          ).build(context) as Material;
          final inkWell = material.child! as InkWell;
          final ink = inkWell.child! as Ink;
          final background = Color.alphaBlend(
            (ink.decoration! as BoxDecoration).color!,
            theme.colorScheme.surface,
          );
          final row = ink.child! as Row;
          final text = row.children.last as Text;
          final icon = row.children.first as Icon;
          expect(icon.color, text.style!.color);
          if (enabled) {
            expect(
              _contrast(text.style!.color!, background),
              greaterThanOrEqualTo(4.5),
            );
          } else {
            expect(inkWell.onTap, isNull);
            expect(text.style!.color!.a, lessThan(1));
          }
        });
      }
    }
    test('profile section icon is visible (dark: $dark)', () {
      final row = const AppProfileSectionTitle(
        icon: Icons.person,
        title: 'Perfil',
      ).build(context) as Row;
      expect(
        _contrast(
          (row.children.first as Icon).color!,
          theme.colorScheme.surface,
        ),
        greaterThanOrEqualTo(3),
      );
    });
    for (final selected in [false, true]) {
      for (final enabled in [false, true]) {
        test('menu selected=$selected enabled=$enabled (dark: $dark)', () {
          var taps = 0;
          final semantics = AppShellNavMenuItem(
            icon: Icons.store,
            title: 'Loja',
            subtitle: 'Resumo',
            selected: selected,
            onTap: enabled ? () => taps++ : null,
          ).build(context) as Semantics;
          final material = semantics.child! as Material;
          final ink = material.child! as InkWell;
          final row = (ink.child! as Padding).child! as Row;
          final column = (row.children.last as Expanded).child as Column;
          final title = column.children.first as Text;
          final subtitle = column.children.last as Text;
          expect(semantics.properties.selected, selected);
          expect(semantics.properties.enabled, enabled);
          if (enabled) {
            final background = Color.alphaBlend(
              material.color!,
              theme.colorScheme.surface,
            );
            for (final text in [title, subtitle]) {
              final foreground = Color.alphaBlend(
                text.style!.color!,
                background,
              );
              expect(
                _contrast(foreground, background),
                greaterThanOrEqualTo(4.5),
              );
            }
            ink.onTap!();
            expect(taps, 1);
          } else {
            expect(ink.onTap, isNull);
            expect(title.style!.color!.a, closeTo(0.38, 0.01));
            expect(subtitle.style!.color, title.style!.color);
            expect(material.color, isNot(theme.colorScheme.primary));
            expect(taps, 0);
          }
        });
      }
    }
    test(
      'brand content remains readable on neutral surfaces (dark: $dark)',
      () {
        for (final background in [
          theme.colorScheme.surface,
          theme.colorScheme.surfaceContainerLowest,
          theme.colorScheme.surfaceContainerHigh,
          theme.colorScheme.surfaceContainerHighest,
        ]) {
          expect(
            _contrast(theme.colorScheme.surfaceAccent, background),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );
    test('report link cells use readable brand emphasis (dark: $dark)', () {
      final source = AppReportGridSource<String>(
        rows: const ['Loja'],
        visibleColumns: [
          AppReportColumn<String>(
            key: 'name',
            label: 'Nome',
            valueGetter: (value) => value,
            cellStyle: AppReportCellStyle.link,
          ),
        ],
        context: context,
      );
      final row = source.buildRow(source.rows.first);
      final text = (row.cells.single as Container).child! as Text;
      expect(text.data, 'Loja');
      expect(
        _contrast(text.style!.color!, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      source.dispose();
    });
    for (final enabled in [true, false]) {
      test('actions respect contrast and disabled state '
          '(dark: $dark, enabled: $enabled)', () {
        final callback = enabled ? () {} : null;
        final buttons = <ButtonStyleButton>[
          AppFlatButton(
            onPressed: callback,
            label: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ).build(context) as FilledButton,
          AppDestructiveButton(
            onPressed: callback,
            label: 'Excluir',
            icon: const Icon(Icons.delete),
          ).build(context) as FilledButton,
          AppTextActionButton(
            onPressed: callback,
            label: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ).build(context) as TextButton,
          AppSecondaryButton(
            onPressed: callback,
            label: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ).build(context) as OutlinedButton,
        ];
        for (final button in buttons) {
          final states = <WidgetState>{if (!enabled) WidgetState.disabled};
          final foreground = button.style!.foregroundColor!.resolve(states)!;
          if (enabled) {
            expect(
              _contrast(
                foreground,
                Color.alphaBlend(
                  button.style!.backgroundColor?.resolve(states) ??
                      Colors.transparent,
                  theme.colorScheme.surface,
                ),
              ),
              greaterThanOrEqualTo(4.5),
            );
          } else {
            expect(button.onPressed, isNull);
            expect(foreground.a, lessThan(1));
          }
          final row = button.child! as Row;
          final iconTheme = row.children.first as StatelessWidget;
          final iconContext = _ThemeContext(theme)
            ..iconTheme = IconTheme(
              data: IconThemeData(color: foreground),
              child: const SizedBox(),
            );
          // Inspect inherited icon configuration without mounting a tree.
          // ignore: invalid_use_of_protected_member
          final inheritedIconTheme = iconTheme.build(iconContext) as IconTheme;
          expect(inheritedIconTheme.data.color, foreground);
        }
      });
    }
    test('selection and input theme contrast (dark: $dark)', () {
      final selected = <WidgetState>{WidgetState.selected};
      final style = theme.segmentedButtonTheme.style!;
      final selectedBackground = style.backgroundColor!.resolve(selected)!;
      final selectedBorder = style.side!.resolve(selected)!.color;
      expect(
        _contrast(
          Color.alphaBlend(selectedBorder, selectedBackground),
          selectedBackground,
        ),
        greaterThanOrEqualTo(3),
      );
      expect(
        style.side!.resolve({WidgetState.selected, WidgetState.disabled}),
        style.side!.resolve({WidgetState.disabled}),
      );
      expect(
        _contrast(
          theme.navigationBarTheme.iconTheme!.resolve(selected)!.color!,
          theme.navigationBarTheme.indicatorColor!,
        ),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(
          style.foregroundColor!.resolve(selected)!,
          style.backgroundColor!.resolve(selected)!,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          theme.navigationRailTheme.selectedIconTheme!.color!,
          theme.navigationRailTheme.indicatorColor!,
        ),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(
          theme.inputDecorationTheme.floatingLabelStyle!.color!,
          theme.inputDecorationTheme.fillColor!,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });
    test('disabled checkbox takes precedence over selection (dark: $dark)', () {
      final fill = theme.checkboxTheme.fillColor!;
      expect(
        fill.resolve({WidgetState.selected, WidgetState.disabled}),
        fill.resolve({WidgetState.disabled}),
      );
      expect(fill.resolve({WidgetState.selected}), theme.colorScheme.primary);
    });
    for (final variant in AppRadioGroupVariant.values) {
      for (final enabled in [true, false]) {
        test(
          'radio $variant enabled=$enabled contrast and action (dark: $dark)',
          () {
            final values = <int?>[];
            final group = AppRadioGroup<int>(
              groupValue: 1,
              onChanged: values.add,
              enabled: enabled,
              variant: variant,
              options: const [
                AppRadioOption(value: 1, label: 'Loja', icon: Icons.store),
              ],
            ).build(context);
            final option =
                (group is Wrap
                        ? group.children.first
                        : (group as Column).children.first)
                    as StatelessWidget;
            // Inspect the option's state without mounting a widget tree.
            // ignore: invalid_use_of_protected_member
            final semantics = option.build(context) as Semantics;
            final material =
                (semantics.child! as ExcludeSemantics).child! as Material;
            final ink = material.child! as InkWell;
            final box = ink.child! as AnimatedContainer;
            final decoration = box.decoration! as BoxDecoration;
            final background = Color.alphaBlend(
              decoration.color!,
              theme.colorScheme.surface,
            );
            final row = box.child! as Row;
            final icon = row.children.first as Icon;
            expect(semantics.properties.enabled, enabled);
            expect(semantics.properties.selected, isTrue);
            if (enabled) {
              expect(
                _contrast((decoration.border! as Border).top.color, background),
                greaterThanOrEqualTo(3),
              );
              expect(
                _contrast(icon.color!, background),
                greaterThanOrEqualTo(3),
              );
              ink.onTap!();
              expect(values, [1]);
            } else {
              expect(
                decoration.color,
                theme.colorScheme.surfaceContainerLowest,
              );
              expect(icon.color!.a, closeTo(0.38, 0.01));
              expect(ink.onTap, isNull);
              expect(semantics.properties.onTap, isNull);
              expect(values, isEmpty);
            }
          },
        );
      }
    }
    test('selected chip has readable contrast (dark: $dark)', () {
      final chip = AppChoiceChip(
        label: 'Selecionado',
        selected: true,
        onSelected: () {},
      ).build(context) as ChoiceChip;
      expect(
        _contrast(
          Color.alphaBlend(chip.side!.color, chip.selectedColor!),
          chip.selectedColor!,
        ),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(chip.labelStyle!.color!, chip.selectedColor!),
        greaterThanOrEqualTo(4.5),
      );
    });
    test('disabled chip mutes its label and icon (dark: $dark)', () {
      final chip = const AppChoiceChip(
        label: 'Indisponível',
        selected: true,
        icon: Icons.store,
      ).build(context) as ChoiceChip;
      expect(chip.onSelected, isNull);
      expect(
        chip.side!.color,
        theme.colorScheme.onSurface.withValues(alpha: 0.12),
      );
      expect(chip.labelStyle!.color!.a, closeTo(0.38, 0.01));
      expect((chip.avatar! as Icon).color, chip.labelStyle!.color);
    });
    test('emphasized profile value remains readable (dark: $dark)', () {
      final material = AppProfileInteractiveField(
        label: 'Nome',
        value: 'Loja',
        onTap: () {},
        emphasizeValue: true,
      ).build(context) as Material;
      final ink = material.child! as InkWell;
      final padding = ink.child! as Padding;
      final row = padding.child! as Row;
      final column = (row.children.first as Expanded).child as Column;
      final value = column.children.last as Text;
      expect(
        _contrast(value.style!.color!, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  }
}

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

class _ThemeContext extends Fake with Diagnosticable implements Element {
  _ThemeContext(ThemeData theme) {
    setTheme(theme);
  }

  void setTheme(ThemeData theme) {
    inherited = Theme(
      data: theme,
      child: const SizedBox(),
    ).build(this) as InheritedWidget;
  }

  InheritedWidget? inherited;
  IconTheme? iconTheme;

  @override
  InheritedElement?
  getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() => null;

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  }) => inherited is T
      ? inherited! as T
      : iconTheme is T
      ? iconTheme! as T
      : null;
}
