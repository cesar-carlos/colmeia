import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_approved_agents_repository.dart';
import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:colmeia/features/pwa/domain/offline_download_stage.dart';
import 'package:colmeia/features/pwa/domain/offline_package.dart';
import 'package:colmeia/features/pwa/domain/offline_package_exception.dart';
import 'package:colmeia/features/pwa/domain/push_subscriptions.dart';
import 'package:colmeia/features/pwa/presentation/offline_report_projection.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:colmeia/shared/widgets/reports/app_report_viewer.dart';
import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';
import 'package:flutter/material.dart';

class PwaOfflinePage extends StatefulWidget {
  const PwaOfflinePage({super.key});
  @override
  State<PwaOfflinePage> createState() => _PwaOfflinePageState();
}

class _PwaOfflinePageState extends State<PwaOfflinePage> {
  final PwaPackageService _packages = getIt<PwaPackageService>();
  final AuthController _auth = getIt<AuthController>();
  final _names = <String, String>{};
  final _saved = <String, OfflinePackage?>{};
  String? _message;
  OfflineDownloadStage? _stage;
  final _sizes = <String, int>{};
  ({int usage, int quota})? _storage;
  bool _busy = false;
  bool _downloading = false;
  String? _downloadingAgent;
  String? _selected;
  String _dataset = 'salesByBranch';
  AppReportQuery _query = const AppReportQuery();
  Timer? _expiry;
  @override
  void initState() {
    super.initState();
    _auth.addListener(_authChanged);
    unawaited(_load());
  }

  void _authChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final user = _auth.session?.userId;
    if (user == null) return;
    try {
      _storage = await _packages.platform.storageEstimate();
      final selected = await _packages.selectedAgents(user);
      _names.clear();
      _saved.clear();
      _sizes.clear();
      for (final id in selected) {
        _names[id] = id;
        final package = await _packages.read(user, id);
        _saved[id] = package;
        if (package != null) {
          _sizes[id] = utf8.encode(jsonEncode(package.toJson())).length;
        }
      }
      if (_packages.platform.online) {
        var page = 1;
        while (true) {
          final result = await getIt<ClientApprovedAgentsRepository>()
              .loadApprovedAgents(
                userId: user,
                query: PaginatedQuery(page: page, pageSize: 100),
                includeOnlineStatus: false,
              );
          final data = result.getOrThrow();
          for (final agent in data.items) {
            _names[agent.agentId] = agent.name;
          }
          if (data.items.isEmpty || page * data.pageSize >= data.total) break;
          page++;
        }
      }
      if (!mounted || _auth.session?.userId != user) return;
      _expiry?.cancel();
      final expirations =
          _saved.values
              .whereType<OfflinePackage>()
              .map((p) => p.authorization.expiresAt)
              .toList()
            ..sort();
      if (expirations.isNotEmpty) {
        final remaining = expirations.first.difference(DateTime.now().toUtc());
        _expiry = Timer(remaining.isNegative ? Duration.zero : remaining, () {
          if (mounted) {
            setState(() {
              _saved.clear();
              _selected = null;
            });
          }
        });
      }
    } on Object catch (error) {
      _message = error is AppFailure
          ? error.displayMessage
          : 'Não foi possível carregar os pacotes.';
    }
    if (mounted) setState(() {});
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      await _load();
    } on Object catch (error) {
      _message = switch (error) {
        AppFailure() => error.displayMessage,
        OfflinePackageException(:final issue) => switch (issue) {
          OfflinePackageIssue.connectionRequired =>
            'Conecte-se à internet para atualizar o pacote.',
          OfflinePackageIssue.cancelled =>
            'Download cancelado. O pacote anterior foi mantido.',
          OfflinePackageIssue.authorizationExpired =>
            'Valide seu acesso online para preparar o pacote.',
          OfflinePackageIssue.storageUnavailable => 'Não foi possível salvar. Libere espaço no navegador e tente novamente.',
          OfflinePackageIssue.incomplete => 'O agente não retornou todos os dados. O pacote anterior foi mantido; tente novamente quando ele estiver disponível.',
        },
        _ =>
          'Não foi possível concluir. Verifique a conexão e tente novamente.',
      };
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _export(OfflinePackage package) async {
    final user = _auth.session?.userId;
    if (user == null ||
        !package.authorization.permits(
          user,
          package.agentId,
          DateTime.now().toUtc(),
        )) {
      throw StateError('Offline authorization expired');
    }
    _packages.platform.beginWork();
    try {
      final projection = OfflineReportProjection(package, _dataset, _query);
      final rows = projection.rows;
      final keys = projection.columns;
      String cell(Object? value) {
        var text = (value ?? '').toString();
        if (value is String && RegExp(r'^[=+@\-\t\r]').hasMatch(text)) {
          text = "'$text";
        }
        return '"${text.replaceAll('"', '""')}"';
      }

      final lines = <String>[
        keys.map((key) => cell(OfflineReportProjection.labels[key])).join(';'),
        ...rows.map((row) => keys.map((key) => cell(row[key])).join(';')),
      ];
      await shareExportBytes(
        bytes: Uint8List.fromList(utf8.encode('\uFEFF${lines.join('\r\n')}')),
        fileName: 'dados-offline.csv',
        mimeType: 'text/csv',
      );
    } finally {
      _packages.platform.endWork();
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _auth.removeListener(_authChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.session?.userId;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Entre novamente para acessar os dados.')),
      );
    }
    final platform = getIt<PwaPlatform>();
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final package = _saved[_selected];
    final projection =
        package == null ||
            !OfflineReportProjection.isAvailable(package, _dataset)
        ? null
        : OfflineReportProjection(package, _dataset, _query);
    return Scaffold(
      appBar: AppBar(title: const Text('Disponível offline')),
      body: ListView(
        padding: context.pageScrollPadding(tokens),
        children: [
          const Text(
            'Selecione uma loja ou agente para preparar os últimos 30 dias. A autorização offline dura até 24 horas. O dia atual pode estar parcial.',
          ),
          if (_storage case final storage?)
            Text(
              'Armazenamento do site: ${(storage.usage / (1024 * 1024)).toStringAsFixed(1)} MB usados de ${(storage.quota / (1024 * 1024)).toStringAsFixed(1)} MB estimados pelo navegador.',
            ),
          Wrap(
            spacing: tokens.gapSm,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        if (!await platform.install()) {
                          _message = 'Use a opção de instalar aplicativo no menu do navegador.';
                        }
                      }),
                child: const Text('Instalar aplicativo'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        final granted = await platform.persistStorage();
                        _message = granted
                            ? 'Armazenamento persistente autorizado.'
                            : 'O navegador poderá remover dados locais quando precisar de espaço.';
                      }),
                child: const Text('Preservar dados locais'),
              ),
              TextButton(
                onPressed: _busy || !platform.online
                    ? null
                    : () => _run(() => getIt<PushSubscriptions>().enable(user)),
                child: const Text('Ativar notificações'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () =>
                          _run(() => getIt<PushSubscriptions>().disable(user)),
                child: const Text('Desativar notificações'),
              ),
            ],
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_stage != null)
            Text(switch (_stage!) {
              OfflineDownloadStage.authorizing => 'Validando acesso…',
              OfflineDownloadStage.downloading =>
                'Baixando os dados dos últimos 30 dias…',
              OfflineDownloadStage.revalidating => 'Confirmando permissões…',
              OfflineDownloadStage.saving => 'Salvando pacote no dispositivo…',
            }),
          if (_downloading)
            TextButton(
              onPressed: () => _packages.cancel(agentId: _downloadingAgent),
              child: const Text('Cancelar download'),
            ),
          if (_message != null) Text(_message!, semanticsLabel: _message),
          for (final entry in _names.entries)
            ListTile(
              title: Text(entry.value),
              subtitle: Text(
                _saved[entry.key] == null
                    ? 'Sem pacote válido'
                    : 'Atualizado em ${_saved[entry.key]!.savedAt.toLocal()} · ${((_sizes[entry.key] ?? 0) / 1024).toStringAsFixed(1)} KB',
              ),
              onTap: () => setState(() {
                _selected = entry.key;
              }),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Baixar ou atualizar pacote',
                    onPressed: _busy || !platform.online
                        ? null
                        : () => _run(
                            () async {
                              setState(() {
                                _downloading = true;
                                _downloadingAgent = entry.key;
                              });
                              try {
                                await _packages.synchronize(
                                  user,
                                  entry.key,
                                  onProgress: (stage) {
                                    if (mounted) setState(() => _stage = stage);
                                  },
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _downloading = false;
                                    _downloadingAgent = null;
                                    _stage = null;
                                  });
                                }
                              }
                            },
                          ),
                    icon: const Icon(Icons.download),
                  ),
                  IconButton(
                    tooltip: 'Remover pacote',
                    onPressed: _busy
                        ? null
                        : () => _run(() => _packages.remove(user, entry.key)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          if (package != null &&
              package.authorization.permits(
                user,
                package.agentId,
                DateTime.now().toUtc(),
              )) ...[
            Text(
              'Período: ${package.periodStart.toLocal()} a ${package.periodEnd.toLocal()}',
            ),
            TextButton(
              onPressed: _busy || projection == null
                  ? null
                  : () => _run(() => _export(package)),
              child: const Text('Exportar consulta local'),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _dataset,
              decoration: const InputDecoration(labelText: 'Consulta local'),
              items: OfflineReportProjection.datasets.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _dataset = value;
                    _query = const AppReportQuery();
                  });
                }
              },
            ),
            if (projection == null)
              const Text(
                'Requer conexão: esta consulta não está disponível no pacote.',
              )
            else
              AppReportViewer<Map<String, dynamic>>(
                title: OfflineReportProjection.datasets[_dataset],
                rows: projection.pageRows,
                pageInfo: projection.pageInfo,
                query: _query,
                events: AppReportEvents(
                  onQueryChanged: (query) => setState(() {
                    _query = query;
                  }),
                ),
                columns: [
                  for (final key in projection.columns)
                    AppReportColumn(
                      key: key,
                      label: OfflineReportProjection.labels[key]!,
                      valueGetter: (row) => row[key],
                      numeric:
                          projection.rows.isNotEmpty &&
                          projection.rows.first[key] is num,
                    ),
                ],
                style: const AppReportViewerStyle(
                  gridHeight: 420,
                  showExportActions: false,
                  showRefreshAction: false,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
