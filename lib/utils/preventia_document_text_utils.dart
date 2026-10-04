String normalizePreventiaDocumentType(String value) {
  final normalized = value
      .trim()
      .replaceAll(RegExp(r'[\u2013\u2014]'), '—')
      .replaceAll(RegExp(r'\s+'), ' ');
  return normalized;
}

String sanitizePreventiaExportText(String input) {
  return input
      .replaceAll(
        RegExp(
          r'^\s*R[ée]f[ée]rence\s+AR-[A-Za-z0-9-]+\s*[—–-]\s*Page\s+1\s*/\s*1\s*$',
          caseSensitive: false,
          multiLine: true,
        ),
        '',
      )
      .replaceAll(
        RegExp(
          r'^\s*Page\s+1\s*/\s*1\s*$',
          caseSensitive: false,
          multiLine: true,
        ),
        '',
      )
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
