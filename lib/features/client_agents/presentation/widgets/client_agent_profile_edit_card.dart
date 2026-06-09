import 'dart:async';

import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_presentation_message_l10n.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_unsaved_changes_dialog.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_tab_view.dart';
import 'package:flutter/material.dart';

class ClientAgentProfileEditCard extends StatefulWidget {
  const ClientAgentProfileEditCard({
    required this.agent,
    required this.controller,
    required this.l10n,
    required this.tokens,
    super.key,
    this.onDirtyChanged,
    this.discardRevision = 0,
  });

  final ClientAgent agent;
  final ClientAgentDetailController controller;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final ValueChanged<bool>? onDirtyChanged;
  final int discardRevision;

  @override
  State<ClientAgentProfileEditCard> createState() =>
      _ClientAgentProfileEditCardState();
}

class _ClientAgentProfileEditCardState
    extends State<ClientAgentProfileEditCard> {
  late final TextEditingController _name;
  late final TextEditingController _tradeName;
  late final TextEditingController _cnpjCpf;
  late final TextEditingController _phone;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _street;
  late final TextEditingController _number;
  late final TextEditingController _district;
  late final TextEditingController _postalCode;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _notes;
  late final TextEditingController _observation;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _tradeName = TextEditingController();
    _cnpjCpf = TextEditingController();
    _phone = TextEditingController();
    _mobile = TextEditingController();
    _email = TextEditingController();
    _street = TextEditingController();
    _number = TextEditingController();
    _district = TextEditingController();
    _postalCode = TextEditingController();
    _city = TextEditingController();
    _state = TextEditingController();
    _notes = TextEditingController();
    _observation = TextEditingController();
    for (final controller in _allFieldControllers) {
      controller.addListener(_notifyDirtyChanged);
    }
    _hydrateFromAgent(widget.agent);
    _notifyDirtyChanged();
  }

  List<TextEditingController> get _allFieldControllers => <TextEditingController>[
    _name,
    _tradeName,
    _cnpjCpf,
    _phone,
    _mobile,
    _email,
    _street,
    _number,
    _district,
    _postalCode,
    _city,
    _state,
    _notes,
    _observation,
  ];

  bool get hasUnsavedChanges => _hasUnsavedChangesComparedTo(widget.agent);

  void _notifyDirtyChanged() {
    widget.onDirtyChanged?.call(hasUnsavedChanges);
  }

  @override
  void didUpdateWidget(ClientAgentProfileEditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newAt = widget.agent.profileUpdatedAt;
    final oldAt = oldWidget.agent.profileUpdatedAt;
    final profileVersionChanged =
        widget.agent.profileVersion != oldWidget.agent.profileVersion;
    if (widget.discardRevision != oldWidget.discardRevision) {
      _hydrateFromAgent(widget.agent);
      return;
    }
    if (widget.agent.agentId != oldWidget.agent.agentId) {
      _hydrateFromAgent(widget.agent);
      return;
    }
    if ((newAt != oldAt || profileVersionChanged) &&
        !_hasUnsavedChangesComparedTo(widget.agent)) {
      _hydrateFromAgent(widget.agent);
    }
  }

  void _hydrateFromAgent(ClientAgent agent) {
    for (final controller in _allFieldControllers) {
      controller.removeListener(_notifyDirtyChanged);
    }
    _name.text = agent.name;
    _tradeName.text = agent.tradeName ?? '';
    final doc = agent.cnpjCpf?.trim().isNotEmpty ?? false
        ? agent.cnpjCpf
        : agent.document;
    _cnpjCpf.text = doc ?? '';
    _phone.text = agent.phone ?? '';
    _mobile.text = agent.mobile ?? '';
    _email.text = agent.email ?? '';
    final a = agent.address;
    _street.text = a?.street ?? '';
    _number.text = a?.number ?? '';
    _district.text = a?.district ?? '';
    _postalCode.text = a?.postalCode ?? '';
    _city.text = a?.city ?? '';
    _state.text = a?.state ?? '';
    _notes.text = agent.notes ?? '';
    _observation.text = agent.observation ?? '';
    for (final controller in _allFieldControllers) {
      controller.addListener(_notifyDirtyChanged);
    }
    _notifyDirtyChanged();
  }

  bool _hasUnsavedChangesComparedTo(ClientAgent agent) {
    final doc = agent.cnpjCpf?.trim().isNotEmpty ?? false
        ? agent.cnpjCpf
        : agent.document;
    final address = agent.address;
    return _name.text != agent.name ||
        _tradeName.text != (agent.tradeName ?? '') ||
        _cnpjCpf.text != (doc ?? '') ||
        _phone.text != (agent.phone ?? '') ||
        _mobile.text != (agent.mobile ?? '') ||
        _email.text != (agent.email ?? '') ||
        _street.text != (address?.street ?? '') ||
        _number.text != (address?.number ?? '') ||
        _district.text != (address?.district ?? '') ||
        _postalCode.text != (address?.postalCode ?? '') ||
        _city.text != (address?.city ?? '') ||
        _state.text != (address?.state ?? '') ||
        _notes.text != (agent.notes ?? '') ||
        _observation.text != (agent.observation ?? '');
  }

  Future<bool> _guardProfileSubTabChange(int fromIndex, int toIndex) async {
    if (fromIndex == toIndex || !hasUnsavedChanges) {
      return true;
    }
    final discard = await confirmDiscardClientAgentUnsavedChanges(
      context,
      widget.l10n,
    );
    if (discard && mounted) {
      _hydrateFromAgent(widget.agent);
    }
    return discard;
  }

  @override
  void dispose() {
    for (final controller in _allFieldControllers) {
      controller.removeListener(_notifyDirtyChanged);
    }
    _name.dispose();
    _tradeName.dispose();
    _cnpjCpf.dispose();
    _phone.dispose();
    _mobile.dispose();
    _email.dispose();
    _street.dispose();
    _number.dispose();
    _district.dispose();
    _postalCode.dispose();
    _city.dispose();
    _state.dispose();
    _notes.dispose();
    _observation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final tokens = widget.tokens;
    final c = widget.controller;
    final theme = Theme.of(context);
    final profileSaveError = c.profileSaveError == null
        ? null
        : localizeClientAgentsPresentationMessage(c.profileSaveError!, l10n);
    final profileSaveSuccess = c.profileSaveSuccess == null
        ? null
        : localizeClientAgentsPresentationMessage(c.profileSaveSuccess!, l10n);

    return AppSectionCardWithHeading(
      title: l10n.clientAgentDetailSectionEditProfile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTabView(
            contentPadding: EdgeInsets.zero,
            onTabChangeGuard: _guardProfileSubTabChange,
            items: <AppTabViewItem>[
              AppTabViewItem(
                label: l10n.clientAgentDetailTabEditIdentification,
                child: _ProfileIdentificationFields(
                  l10n: l10n,
                  tokens: tokens,
                  name: _name,
                  tradeName: _tradeName,
                  cnpjCpf: _cnpjCpf,
                  email: _email,
                  phone: _phone,
                  mobile: _mobile,
                ),
              ),
              AppTabViewItem(
                label: l10n.clientAgentDetailTabEditAddress,
                child: _ProfileAddressFields(
                  l10n: l10n,
                  tokens: tokens,
                  street: _street,
                  number: _number,
                  district: _district,
                  postalCode: _postalCode,
                  city: _city,
                  state: _state,
                ),
              ),
              AppTabViewItem(
                label: l10n.clientAgentDetailTabEditNotes,
                child: _ProfileNotesFields(
                  l10n: l10n,
                  tokens: tokens,
                  notes: _notes,
                  observation: _observation,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.gapMd),
          AppPrimaryButton(
            label: c.isOnRetryCooldown
                ? l10n.clientAgentDetailRetryAfterCountdown(
                    c.retryAfterGate.remaining?.inSeconds ?? 0,
                  )
                : l10n.clientAgentDetailSaveProfile,
            icon: const Icon(Icons.save_outlined),
            isLoading: c.isSavingProfile,
            onPressed: c.isSavingProfile || c.isOnRetryCooldown
                ? null
                : () {
                    c.clearProfileFeedback();
                    unawaited(
                      c.saveAgentProfile(
                        agentId: widget.agent.agentId,
                        name: _name.text,
                        tradeName: _tradeName.text,
                        cnpjCpf: _cnpjCpf.text,
                        phone: _phone.text,
                        mobile: _mobile.text,
                        email: _email.text,
                        street: _street.text,
                        number: _number.text,
                        district: _district.text,
                        postalCode: _postalCode.text,
                        city: _city.text,
                        state: _state.text,
                        notes: _notes.text,
                        observation: _observation.text,
                      ),
                    );
                  },
          ),
          if (profileSaveError != null) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            Text(
              profileSaveError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (profileSaveSuccess != null) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            Text(
              profileSaveSuccess,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileIdentificationFields extends StatelessWidget {
  const _ProfileIdentificationFields({
    required this.l10n,
    required this.tokens,
    required this.name,
    required this.tradeName,
    required this.cnpjCpf,
    required this.email,
    required this.phone,
    required this.mobile,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final TextEditingController name;
  final TextEditingController tradeName;
  final TextEditingController cnpjCpf;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController mobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: name,
          label: l10n.clientAgentFieldLegalName,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: tokens.gapSm),
        AppTextField(
          controller: tradeName,
          label: l10n.clientAgentFieldTradeName,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: tokens.gapSm),
        AppTextField(
          controller: cnpjCpf,
          label: l10n.clientAgentFieldCnpjCpf,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: tokens.gapMd),
        AppTextField(
          controller: email,
          label: l10n.clientAgentFieldEmail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: tokens.gapSm),
        AppTextField(
          controller: phone,
          label: l10n.clientAgentFieldPhone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: tokens.gapSm),
        AppTextField(
          controller: mobile,
          label: l10n.clientAgentFieldMobile,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class _ProfileAddressFields extends StatelessWidget {
  const _ProfileAddressFields({
    required this.l10n,
    required this.tokens,
    required this.street,
    required this.number,
    required this.district,
    required this.postalCode,
    required this.city,
    required this.state,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final TextEditingController street;
  final TextEditingController number;
  final TextEditingController district;
  final TextEditingController postalCode;
  final TextEditingController city;
  final TextEditingController state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: street,
          label: l10n.clientAgentFieldStreet,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: tokens.gapSm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: AppTextField(
                controller: number,
                label: l10n.clientAgentFieldNumber,
                textInputAction: TextInputAction.next,
              ),
            ),
            SizedBox(width: tokens.gapSm),
            Expanded(
              flex: 3,
              child: AppTextField(
                controller: district,
                label: l10n.clientAgentFieldDistrict,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.gapSm),
        AppTextField(
          controller: postalCode,
          label: l10n.clientAgentFieldPostalCode,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: tokens.gapSm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: AppTextField(
                controller: city,
                label: l10n.clientAgentFieldCity,
                textInputAction: TextInputAction.next,
              ),
            ),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: AppTextField(
                controller: state,
                label: l10n.clientAgentFieldState,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileNotesFields extends StatelessWidget {
  const _ProfileNotesFields({
    required this.l10n,
    required this.tokens,
    required this.notes,
    required this.observation,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final TextEditingController notes;
  final TextEditingController observation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: notes,
          label: l10n.clientAgentFieldNotes,
          maxLines: 3,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: tokens.gapSm),
        AppTextField(
          controller: observation,
          label: l10n.clientAgentFieldObservation,
          maxLines: 3,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
