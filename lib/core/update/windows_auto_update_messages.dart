import 'package:colmeia/core/update/windows_auto_update_state.dart';

abstract final class WindowsAutoUpdateMessages {
  static const settingsTitle = 'Atualizacoes do app';
  static const checkButtonLabel = 'Verificar atualizacoes';
  static const checkingButtonLabel = 'Verificando atualizacoes...';
  static const checkButtonSemanticsLabel = 'Verificar atualizacoes';

  static const initReadyHeadline =
      'Atualizacoes automaticas prontas neste build Windows.';
  static const initReadyDetails =
      'O feed oficial foi configurado e o app checara novas releases em background.';

  static const initFailedHeadline =
      'Nao foi possivel inicializar o auto-update.';
  static const initFailedDetails =
      'Revise a conectividade e tente novamente. Se o problema persistir, reinstale uma versao publicada pelo GitHub Releases.';

  static const checkingHeadline = 'Verificando atualizacoes...';
  static const checkingDetailsForeground =
      'Consultando o feed oficial para encontrar uma release mais recente.';
  static const checkingDetailsBackground =
      'Checagem inicial em background em andamento.';
  static const checkingDetailsNative =
      'Consultando o feed oficial configurado para este build.';

  static const checkFailedHeadline =
      'Nao foi possivel verificar atualizacoes agora.';
  static const checkFailedDetails =
      'Revise a conectividade e tente novamente.';

  static const updaterErrorHeadline =
      'Nao foi possivel concluir a verificacao de atualizacoes.';
  static const updaterErrorDetails =
      'O verificador nativo encontrou um problema. Tente novamente em instantes.';

  static const updateAvailableHeadline = 'Nova versao encontrada.';
  static const updateAvailableDetails =
      'O fluxo nativo do Windows/WinSparkle assumiu o download da atualizacao para esta instalacao.';

  static const readyToInstallHeadline = 'Atualizacao pronta para instalacao.';
  static const readyToInstallDetails =
      'O Windows concluira o processo quando o aplicativo for encerrado para aplicar a nova versao.';

  static const updateDownloadedHeadline = 'Atualizacao baixada.';
  static const updateDownloadedDetails =
      'Feche o aplicativo quando o updater solicitar para concluir a substituicao da versao atual.';

  static const upToDateHeadline = 'Este build ja esta atualizado.';
  static const upToDateDetails =
      'Nenhuma release mais nova foi encontrada no appcast oficial neste momento.';

  static const updateNotAvailableErrorHeadline =
      'Nao foi possivel confirmar se ha atualizacoes.';
  static const updateNotAvailableErrorDetails =
      'O verificador nativo nao conseguiu concluir a consulta. Tente novamente.';

  static const feedWithoutReleasesHeadline = 'Feed sem releases publicadas.';
  static const feedWithoutReleasesDetails =
      'O appcast oficial respondeu, mas ainda nao ha itens de release para o Windows. Publique uma release no feed antes de esperar uma atualizacao.';

  static const pendingInitHeadline =
      'Atualizacoes automaticas disponiveis para este build.';
  static const pendingInitDetails =
      'O app esta pronto para usar o feed oficial assim que a inicializacao terminar.';

  static const feedUrlMissingHeadline =
      'Atualizacoes automaticas indisponiveis neste build.';
  static const feedUrlMissingDetails =
      'Este instalador foi gerado sem o feed oficial de atualizacoes. Instale uma versao publicada pelo GitHub Releases ou gere o instalador com o feed configurado.';

  static const feedUrlInvalidHeadline = 'Feed de atualizacao invalido.';
  static const feedUrlInvalidDetails =
      'Este instalador foi gerado com um feed de atualizacoes invalido. Use uma URL HTTPS com appcast .xml valida.';

  static const probeInvalidUrlHeadline = 'Feed de atualizacao invalido.';
  static const probeTimeoutHeadline = 'O feed oficial nao respondeu a tempo.';
  static const probeHttpErrorHeadline =
      'O feed oficial nao esta acessivel no momento.';
  static const probeInvalidPayloadHeadline =
      'O feed oficial respondeu com conteudo inesperado.';
  static const probeNetworkHeadline =
      'Nao foi possivel acessar o feed oficial agora.';
  static const probeGenericHeadline =
      'Nao foi possivel verificar atualizacoes agora.';

  static const genericRetryDetails =
      'Revise a conectividade e tente novamente.';

  static String settingsStatusLabel(WindowsAutoUpdateStatus status) {
    return switch (status) {
      WindowsAutoUpdateStatus.updateAvailable => 'Nova release disponivel',
      WindowsAutoUpdateStatus.upToDate => 'Build atualizado',
      WindowsAutoUpdateStatus.feedWithoutReleases => 'Feed sem releases',
      WindowsAutoUpdateStatus.readyToInstall => 'Pronto para instalar',
      WindowsAutoUpdateStatus.failed => 'Verificacao com falha',
      WindowsAutoUpdateStatus.unavailable => 'Atualizacoes indisponiveis',
      WindowsAutoUpdateStatus.idle => 'Pronto para verificar',
      WindowsAutoUpdateStatus.checking => 'Consultando feed oficial',
    };
  }

  static String lastCheckedLabel({
    required String date,
    required String time,
  }) {
    return 'Ultima checagem em $date, $time.';
  }
}
