import '../services/pdf_export_service.dart';
import 'generated/app_localizations.dart';

PdfDocumentTexts pdfDocumentTexts(AppLocalizations l10n, {String? sourceText}) {
  return PdfDocumentTexts(
    projectStatus: l10n.projectToValidate,
    preventionDocumentStatus: '${l10n.document} - ${l10n.projectToValidate}',
    projectStatusUpper: l10n.projectToValidate.toUpperCase(),
    documentType: l10n.document,
    generatedAt: l10n.generatedAt,
    source: l10n.source,
    localPdfSource: sourceText ?? l10n.generatedLocallyFromAnalysis,
  );
}
