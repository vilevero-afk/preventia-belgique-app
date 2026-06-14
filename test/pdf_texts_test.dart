import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/l10n/generated/app_localizations_de.dart';
import 'package:preventia_belgique_app/l10n/generated/app_localizations_en.dart';
import 'package:preventia_belgique_app/l10n/generated/app_localizations_fr.dart';
import 'package:preventia_belgique_app/l10n/generated/app_localizations_nl.dart';
import 'package:preventia_belgique_app/l10n/pdf_texts.dart';

void main() {
  test('returns exact localized PDF chrome texts', () {
    final fr = pdfDocumentTexts(AppLocalizationsFr());
    expect(fr.preventionDocumentStatus, 'Document - Projet à valider');
    expect(fr.projectStatusUpper, 'PROJET À VALIDER');
    expect(fr.documentType, 'Document');
    expect(fr.generatedAt, 'Date de génération');
    expect(
      fr.localPdfSource,
      'IA backend Render - PDF généré localement sur l’appareil',
    );

    final nl = pdfDocumentTexts(AppLocalizationsNl());
    expect(nl.preventionDocumentStatus, 'Document - Ontwerp te valideren');
    expect(nl.projectStatusUpper, 'ONTWERP TE VALIDEREN');
    expect(nl.generatedAt, 'Generatiedatum');
    expect(
      nl.localPdfSource,
      'IA-backend Render - PDF lokaal gegenereerd op het toestel',
    );

    final en = pdfDocumentTexts(AppLocalizationsEn());
    expect(en.preventionDocumentStatus, 'Document - Draft for validation');
    expect(en.projectStatusUpper, 'DRAFT FOR VALIDATION');
    expect(en.generatedAt, 'Generation date');
    expect(
      en.localPdfSource,
      'AI backend Render - PDF generated locally on the device',
    );

    final de = pdfDocumentTexts(AppLocalizationsDe());
    expect(de.preventionDocumentStatus, 'Dokument - Zu validierender Entwurf');
    expect(de.projectStatusUpper, 'ZU VALIDIERENDER ENTWURF');
    expect(de.documentType, 'Dokument');
    expect(de.generatedAt, 'Generierungsdatum');
    expect(
      de.localPdfSource,
      'KI-Backend Render - PDF lokal auf dem Gerät generiert',
    );
  });

  test('does not leak French PDF chrome into non-French texts', () {
    for (final texts in [
      pdfDocumentTexts(AppLocalizationsNl()),
      pdfDocumentTexts(AppLocalizationsEn()),
      pdfDocumentTexts(AppLocalizationsDe()),
    ]) {
      final values = [
        texts.projectStatus,
        texts.preventionDocumentStatus,
        texts.projectStatusUpper,
        texts.generatedAt,
        texts.localPdfSource,
      ].join('\n');

      expect(values, isNot(contains('Projet à valider')));
      expect(values, isNot(contains('Date de génération')));
      expect(values, isNot(contains('PDF généré localement')));
    }
  });
}
