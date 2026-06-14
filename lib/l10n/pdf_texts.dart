import '../services/pdf_export_service.dart';
import 'generated/app_localizations.dart';

PdfDocumentTexts pdfDocumentTexts(AppLocalizations l10n, {String? sourceText}) {
  final texts = switch (l10n.localeName) {
    'nl' => const PdfDocumentTexts(
      projectStatus: 'Ontwerp te valideren',
      preventionDocumentStatus: 'Document - Ontwerp te valideren',
      projectStatusUpper: 'ONTWERP TE VALIDEREN',
      documentType: 'Document',
      generatedAt: 'Generatiedatum',
      source: 'Bron',
      localPdfSource:
          'IA-backend Render - PDF lokaal gegenereerd op het toestel',
    ),
    'en' => const PdfDocumentTexts(
      projectStatus: 'Draft for validation',
      preventionDocumentStatus: 'Document - Draft for validation',
      projectStatusUpper: 'DRAFT FOR VALIDATION',
      documentType: 'Document',
      generatedAt: 'Generation date',
      source: 'Source',
      localPdfSource: 'AI backend Render - PDF generated locally on the device',
    ),
    'de' => const PdfDocumentTexts(
      projectStatus: 'Zu validierender Entwurf',
      preventionDocumentStatus: 'Dokument - Zu validierender Entwurf',
      projectStatusUpper: 'ZU VALIDIERENDER ENTWURF',
      documentType: 'Dokument',
      generatedAt: 'Generierungsdatum',
      source: 'Quelle',
      localPdfSource: 'KI-Backend Render - PDF lokal auf dem Gerät generiert',
    ),
    _ => const PdfDocumentTexts(
      projectStatus: 'Projet à valider',
      preventionDocumentStatus: 'Document - Projet à valider',
      projectStatusUpper: 'PROJET À VALIDER',
      documentType: 'Document',
      generatedAt: 'Date de génération',
      source: 'Source',
      localPdfSource:
          'IA backend Render - PDF généré localement sur l’appareil',
    ),
  };

  if (sourceText == null) {
    return texts;
  }
  return PdfDocumentTexts(
    projectStatus: texts.projectStatus,
    preventionDocumentStatus: texts.preventionDocumentStatus,
    projectStatusUpper: texts.projectStatusUpper,
    documentType: texts.documentType,
    generatedAt: texts.generatedAt,
    source: texts.source,
    localPdfSource: sourceText,
  );
}
