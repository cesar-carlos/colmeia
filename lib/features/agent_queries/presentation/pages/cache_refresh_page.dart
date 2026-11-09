import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';

import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_report.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:colmeia/features/agent_queries/presentation/controllers/cache_refresh_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CacheRefreshPage extends StatelessWidget {
  const CacheRefreshPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CacheRefreshController>();
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Atualização de dados')),
      body: ListView.builder(
        padding: context.pageScrollPadding(tokens),
        itemCount: c.records.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atualizações automáticas enquanto o aplicativo estiver aberto. Servidores offline aguardam reconexão sem bloquear os demais.',
                ),
                if (c.error != null)
                  AppInlineErrorPanel(
                    message: c.error!,
                    onRetry: () => unawaited(c.load(catalog: true)),
                  ),
                if (c.busy) const LinearProgressIndicator(),
                TextButton.icon(
                  onPressed: c.busy ? null : () => _edit(context, c),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo agendamento'),
                ),
                if (c.records.isEmpty)
                  const Text(
                    'Nenhum agendamento. Selecione um agente e um relatório para começar.',
                  ),
              ],
            );
          }
          return Padding(
            padding: EdgeInsets.only(top: tokens.gapSm),
            child: _ScheduleCard(record: c.records[index - 1], controller: c),
          );
        },
      ),
    );
  }
}

Future<void> _edit(
  BuildContext context,
  CacheRefreshController c, [
  CacheRefreshRecord? record,
]) => showDialog<void>(
  context: context,
  builder: (_) => _ScheduleEditor(controller: c, record: record),
);

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.record, required this.controller});
  final CacheRefreshRecord record;
  final CacheRefreshController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final s = record.schedule;
    final state = c.coordinator.unpersistedState(s.id) ?? record.state;
    final report = c.reports.where((r) => r.id == s.reportId).firstOrNull;
    final agent = c.agents.where((a) => a.agentId == s.agentId).firstOrNull;
    final status = c.coordinator.runningIds.contains(s.id)
        ? CacheRefreshStatus.running
        : state.status;
    final label = switch (status) {
      CacheRefreshStatus.waiting => 'Aguardando atualização',
      CacheRefreshStatus.running => 'Atualizando',
      CacheRefreshStatus.waitingAgent => 'Aguardando agente',
      CacheRefreshStatus.waitingConnection => 'Aguardando conexão',
      CacheRefreshStatus.deferred => 'Tentativa adiada',
      CacheRefreshStatus.paused => 'Pausado',
      CacheRefreshStatus.accessUnavailable => 'Acesso indisponível',
    };
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.isQuarantined
                ? 'Agendamento incompatível'
                : report?.label ?? s.reportId,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!record.isQuarantined) Text(agent?.name ?? s.agentId),
          if (record.isQuarantined)
            const AppInlineErrorPanel(
              message: 'Este registro está corrompido ou usa uma versão não suportada. Os dados foram preservados. Remova o registro e crie um novo agendamento; os demais continuam funcionando.',
            ),
          if (!record.isQuarantined)
            Text(
              report?.supportsFixedPeriod == false &&
                      s.reportId != 'offlinePackage'
                  ? 'Período próprio da consulta · ${_intervalLabel(s.interval)}'
                  : s.period == CacheRefreshPeriod.last30Days
                  ? 'Últimos 30 dias · ${_intervalLabel(s.interval)}'
                  : '${_date(s.start)} a ${_date(s.end)} · ${_intervalLabel(s.interval)}',
            ),
          Text(label),
          if (state.reason != null && !record.isQuarantined)
            Text(_reason(state.reason!)),
          if (state.durationMs != null)
            Text(
              'Duração da última execução: ${(state.durationMs! / 1000).toStringAsFixed(1)} s',
            ),
          if (record.snapshotBytes > 0)
            Text(
              'Cache local: ${(record.snapshotBytes / 1024).toStringAsFixed(1)} KB',
            ),
          Text(
            'Última coleta: ${_timestamp(state.lastSuccess, 'Ainda não concluída')}',
          ),
          Text(
            'Próxima tentativa: ${_timestamp(state.nextAttempt, 'Assim que possível')}',
          ),
          if (report?.note != null) Text(report!.note!),
          if (record.currentDayPartial)
            const Text('Inclui o dia corrente, ainda parcial.'),
          Wrap(
            children: [
              TextButton(
                onPressed:
                    c.busy || status == CacheRefreshStatus.running || !s.enabled
                    ? null
                    : () => c.coordinator.requestNow(s.id),
                child: const Text('Atualizar agora'),
              ),
              TextButton(
                onPressed: c.busy || record.isQuarantined
                    ? null
                    : () => unawaited(c.toggle(record)),
                child: Text(s.enabled ? 'Pausar' : 'Retomar'),
              ),
              TextButton(
                onPressed: c.busy || record.isQuarantined
                    ? null
                    : () => _edit(context, c, record),
                child: const Text('Editar'),
              ),
              TextButton(
                onPressed: c.busy ? null : () => unawaited(c.remove(record)),
                child: const Text('Remover agendamento'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _intervalLabel(Duration value) => value.inMinutes < 60
    ? '${value.inMinutes} minutos'
    : '${value.inHours} ${value.inHours == 1 ? 'hora' : 'horas'}';

String _date(DateTime? value) =>
    value == null ? '—' : AppBrFormatters.shortDate(value);

String _reason(String reason) => switch (reason) {
  'capacity_busy' => 'Aguardando uma das duas vagas compartilhadas entre abas.',
  'agent_unavailable' => 'O agente ainda não está disponível. A atualização será retomada após reconciliação.',
  'access_denied' => 'O acesso foi recusado. Confirme sua autorização antes de criar outro agendamento.',
  'invalid_filters' =>
    'Edite os filtros ou o período para retomar este agendamento.',
  'storage_unavailable' => 'Não foi possível gravar o cache. Verifique o espaço disponível no dispositivo.',
  _ => 'A última tentativa falhou. Os dados anteriores foram mantidos; uma nova tentativa está agendada.',
};

String _timestamp(DateTime? value, String fallback) =>
    value == null ? fallback : AppBrFormatters.shortDateTime(value.toLocal());

class _ScheduleEditor extends StatefulWidget {
  const _ScheduleEditor({required this.controller, this.record});
  final CacheRefreshController controller;
  final CacheRefreshRecord? record;
  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  String? _agent;
  late String _report;
  late CacheRefreshPeriod _period;
  late Duration _interval;
  DateTimeRange? _range;
  final _fields = <String, TextEditingController>{};
  String? _error;
  bool _saving = false;
  CacheRefreshReport get _descriptor =>
      widget.controller.reports.firstWhere((r) => r.id == _report);
  @override
  void initState() {
    super.initState();
    final s = widget.record?.schedule;
    _agent = s?.agentId;
    _report = s?.reportId ?? widget.controller.reports.first.id;
    _period = s?.period ?? CacheRefreshPeriod.last30Days;
    _interval = s?.interval ?? CacheRefreshSchedule.defaultInterval;
    if (s?.start != null && s?.end != null) {
      _range = DateTimeRange(start: s!.start!, end: s.end!);
    }
    _resetFields(s?.filters ?? {});
  }

  void _resetFields(Map<String, Object?> values) {
    for (final field in _fields.values) {
      field.dispose();
    }
    _fields.clear();
    for (final key in _descriptor.fields.keys) {
      _fields[key] = TextEditingController(text: values[key]?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final user = widget.controller.userId;
    if (user == null ||
        _agent == null ||
        (_period == CacheRefreshPeriod.fixed && _range == null)) {
      setState(() => _error = 'Selecione o agente e o período.');
      return;
    }
    final filters = <String, Object?>{};
    for (final entry in _fields.entries) {
      final raw = entry.value.text.trim();
      if (raw.isEmpty) continue;
      if (_descriptor.fields[entry.key] == RefreshFilterType.integer) {
        final value = int.tryParse(raw);
        if (value == null) {
          setState(() => _error = 'Informe um número inteiro em ${entry.key}.');
          return;
        }
        filters[entry.key] = value;
      } else {
        filters[entry.key] = raw;
      }
    }
    setState(() => _saving = true);
    final saved = await widget.controller.save(
      CacheRefreshSchedule(
        id: widget.record?.schedule.id ?? const Uuid().v4(),
        userId: user,
        agentId: _agent!,
        reportId: _report,
        period: _period,
        interval: _interval,
        filters: filters,
        start: _period == CacheRefreshPeriod.fixed ? _range?.start : null,
        end: _period == CacheRefreshPeriod.fixed ? _range?.end : null,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return AlertDialog(
      title: Text(
        widget.record == null ? 'Agendar atualização' : 'Editar atualização',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) AppInlineErrorPanel(message: _error!),
              AppDropdownField<String>(
                label: 'Agente',
                value: _agent,
                enabled: !_saving,
                options: c.agents
                    .map(
                      (a) => AppDropdownOption(value: a.agentId, label: a.name),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _agent = v),
              ),
              SizedBox(height: tokens.gapSm),
              AppDropdownField<String>(
                label: 'Relatório',
                value: _report,
                enabled: !_saving,
                options: c.reports
                    .where(
                      (r) =>
                          r.id != 'offlinePackage' ||
                          widget.record?.schedule.reportId == r.id,
                    )
                    .map((r) => AppDropdownOption(value: r.id, label: r.label))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _report = v;
                      _resetFields({});
                      if (!_descriptor.supportsFixedPeriod) {
                        _period = CacheRefreshPeriod.last30Days;
                      }
                    });
                  }
                },
              ),
              if (_descriptor.note != null) Text(_descriptor.note!),
              AppDropdownField<CacheRefreshPeriod>(
                label: 'Período',
                value: _period,
                enabled: !_saving,
                options: [
                  const AppDropdownOption(
                    value: CacheRefreshPeriod.last30Days,
                    label: 'Últimos 30 dias / período próprio da consulta',
                  ),
                  if (_descriptor.supportsFixedPeriod)
                    const AppDropdownOption(
                      value: CacheRefreshPeriod.fixed,
                      label: 'Datas fixas',
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _period = v);
                },
              ),
              if (_period == CacheRefreshPeriod.fixed)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final selected = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(now.year - 10),
                            lastDate: now,
                            initialDateRange: _range,
                          );
                          if (selected != null && mounted) {
                            setState(() => _range = selected);
                          }
                        },
                  child: Text(
                    _range == null
                        ? 'Selecionar datas'
                        : '${_date(_range!.start)} a ${_date(_range!.end)}',
                  ),
                ),
              AppDropdownField<Duration>(
                label: 'Frequência',
                value: _interval,
                enabled: !_saving,
                options: const [
                  AppDropdownOption(
                    value: Duration(minutes: 15),
                    label: '15 minutos',
                  ),
                  AppDropdownOption(value: Duration(hours: 1), label: '1 hora'),
                  AppDropdownOption(
                    value: CacheRefreshSchedule.defaultInterval,
                    label: '2 horas',
                  ),
                  AppDropdownOption(
                    value: Duration(hours: 24),
                    label: '24 horas',
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _interval = v);
                },
              ),
              for (final entry in _fields.entries)
                Padding(
                  padding: EdgeInsets.only(top: tokens.gapSm),
                  child: AppTextField(
                    controller: entry.value,
                    label: _filterLabels[entry.key] ?? entry.key,
                    enabled: !_saving,
                    keyboardType:
                        _descriptor.fields[entry.key] ==
                            RefreshFilterType.integer
                        ? TextInputType.number
                        : TextInputType.text,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

const _filterLabels = {
  'searchTerm': 'Pesquisar',
  'page': 'Página (padrão: 1)',
  'pageSize': 'Itens por página',
  'codEmpresa': 'Código da empresa',
  'codFilial': 'Código da filial',
  'codFornecedor': 'Código do fornecedor',
  'codVendedor': 'Código do vendedor',
  'bairro': 'Bairro',
  'municipio': 'Município',
  'compraId': 'Identificador da compra',
  'codMarca': 'Código da marca',
  'codGrupoProduto': 'Código do grupo de produtos',
};
