/// Derives a `{page}` / `{pages}` template from a localized label builder.
String? pageLabelTemplateFromBuilder(String Function(int page, int pages)? builder) {
  if (builder == null) {
    return null;
  }
  const sentinelPage = 42;
  const sentinelPages = 99;
  return builder(sentinelPage, sentinelPages)
      .replaceFirst('$sentinelPage', '{page}')
      .replaceFirst('$sentinelPages', '{pages}');
}

String formatPdfPageLabel(String template, int page, int pages) {
  return template
      .replaceAll('{page}', '$page')
      .replaceAll('{pages}', '$pages');
}
