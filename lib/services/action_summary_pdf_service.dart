import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/generated/app_localizations.dart';
import 'action_summary_service.dart';
import 'pdf_export_service.dart';

class ActionSummaryPdfTexts {
  factory ActionSummaryPdfTexts.fromLocalizations(AppLocalizations l10n) {
    return ActionSummaryPdfTexts(
      languageCode: l10n.localeName,
      title: l10n.actionSummary,
      status: l10n.projectToValidate,
      statusLabel: l10n.status(''),
      linkedAnalysis: l10n.completeAnalysis,
      generatedAt: l10n.generatedAt,
      source: l10n.source,
      generatedLocallyFromAnalysis: l10n.generatedLocallyFromAnalysis,
      summaryObjectiveTitle: l10n.summaryObjectiveTitle,
      summaryObjectiveText: l10n.summaryObjectiveText,
      priorityActions: l10n.priorityActions,
      documentsToPrepare: l10n.documentsToPrepare,
      actorsToConsult: l10n.actorsToConsult,
      fieldChecks: l10n.fieldChecks,
      expectedProofs: l10n.expectedProofs,
      usefulExplanations: l10n.usefulExplanations,
      validationNoticeTitle: l10n.validationNoticeTitle,
      localValidationNotice: l10n.localValidationNotice,
      noPriorityActions: l10n.noPriorityActions,
      noDocumentsDetected: l10n.noDocumentsDetected,
      noActorsDetected: l10n.noActorsDetected,
      noFieldChecks: l10n.noFieldChecks,
      noProofsDetected: l10n.noProofsDetected,
      actionToPerform: l10n.actionToPerform,
      riskConcerned: l10n.riskConcerned,
      responsible: l10n.responsible,
      deadline: l10n.deadline,
      expectedProof: l10n.expectedProof,
      whyImportant: l10n.whyImportant,
      advisorExpectedShort: l10n.advisorExpectedShort,
      advisorMustCheck: l10n.advisorMustCheck,
      document: l10n.document,
      objective: l10n.objective,
      documentsNecessityExplanation: l10n.documentsNecessityExplanation,
      expectedResult: l10n.expectedResult,
      actor: l10n.actor,
      whyConsult: l10n.whyConsult,
      expectedTrace: l10n.expectedTrace,
      unverifiedInfoImportance: l10n.unverifiedInfoImportance,
      verifyBy: l10n.verifyBy,
      proofConcreteExamples: l10n.proofConcreteExamples,
    );
  }

  const ActionSummaryPdfTexts({
    required this.languageCode,
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.linkedAnalysis,
    required this.generatedAt,
    required this.source,
    required this.generatedLocallyFromAnalysis,
    required this.summaryObjectiveTitle,
    required this.summaryObjectiveText,
    required this.priorityActions,
    required this.documentsToPrepare,
    required this.actorsToConsult,
    required this.fieldChecks,
    required this.expectedProofs,
    required this.usefulExplanations,
    required this.validationNoticeTitle,
    required this.localValidationNotice,
    required this.noPriorityActions,
    required this.noDocumentsDetected,
    required this.noActorsDetected,
    required this.noFieldChecks,
    required this.noProofsDetected,
    required this.actionToPerform,
    required this.riskConcerned,
    required this.responsible,
    required this.deadline,
    required this.expectedProof,
    required this.whyImportant,
    required this.advisorExpectedShort,
    required this.advisorMustCheck,
    required this.document,
    required this.objective,
    required this.documentsNecessityExplanation,
    required this.expectedResult,
    required this.actor,
    required this.whyConsult,
    required this.expectedTrace,
    required this.unverifiedInfoImportance,
    required this.verifyBy,
    required this.proofConcreteExamples,
  });

  final String languageCode;
  final String title;
  final String status;
  final String statusLabel;
  final String linkedAnalysis;
  final String generatedAt;
  final String source;
  final String generatedLocallyFromAnalysis;
  final String summaryObjectiveTitle;
  final String summaryObjectiveText;
  final String priorityActions;
  final String documentsToPrepare;
  final String actorsToConsult;
  final String fieldChecks;
  final String expectedProofs;
  final String usefulExplanations;
  final String validationNoticeTitle;
  final String localValidationNotice;
  final String noPriorityActions;
  final String noDocumentsDetected;
  final String noActorsDetected;
  final String noFieldChecks;
  final String noProofsDetected;
  final String actionToPerform;
  final String riskConcerned;
  final String responsible;
  final String deadline;
  final String expectedProof;
  final String whyImportant;
  final String advisorExpectedShort;
  final String advisorMustCheck;
  final String document;
  final String objective;
  final String documentsNecessityExplanation;
  final String expectedResult;
  final String actor;
  final String whyConsult;
  final String expectedTrace;
  final String unverifiedInfoImportance;
  final String verifyBy;
  final String proofConcreteExamples;
}

class ActionSummaryPdfService {
  static Future<Uint8List> buildPdf({
    required ActionSummary summary,
    required String sourceAnalysisTitle,
    required DateTime generatedAt,
    required ActionSummaryPdfTexts texts,
    String? referenceNumber,
  }) async {
    final footerReference = PdfExportService.resolveDocumentReference(
      metadataDocumentReference: referenceNumber,
      content: sourceAnalysisTitle,
    );
    final document = pw.Document(
      title: texts.title,
      author: 'PreventIA Belgique',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        footer: (context) =>
            _footer(context, texts.languageCode, footerReference),
        build: (context) => [
          _title('PreventIA Belgique'),
          _subtitle(texts.title),
          _status(texts.status, texts.languageCode),
          pw.SizedBox(height: 12),
          _info(texts.linkedAnalysis, sourceAnalysisTitle, texts.languageCode),
          _info(
            texts.generatedAt,
            _formatDate(generatedAt),
            texts.languageCode,
          ),
          _info(
            texts.source,
            texts.generatedLocallyFromAnalysis,
            texts.languageCode,
          ),
          _info(
            texts.statusLabel.replaceAll(':', '').trim(),
            texts.status,
            texts.languageCode,
          ),
          pw.SizedBox(height: 18),
          _section('1. ${texts.summaryObjectiveTitle}', [
            texts.summaryObjectiveText,
          ], texts.languageCode),
          _actionsSection(summary.priorityActions, texts),
          _documentsSection(summary.documents, texts),
          _actorsSection(summary.actors, texts),
          _listSection(
            '5. ${texts.fieldChecks}',
            summary.fieldChecks,
            texts.noFieldChecks,
            texts.languageCode,
          ),
          _listSection(
            '6. ${texts.expectedProofs}',
            summary.expectedProofs,
            texts.noProofsDetected,
            texts.languageCode,
          ),
          _section('7. ${texts.usefulExplanations}', [
            texts.advisorMustCheck,
            texts.unverifiedInfoImportance,
            texts.proofConcreteExamples,
          ], texts.languageCode),
          _section('8. ${texts.validationNoticeTitle}', [
            texts.localValidationNotice,
          ], texts.languageCode),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _footer(
    pw.Context context,
    String languageCode,
    String? referenceNumber,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xffd6dce3)),
        ),
      ),
      child: pw.Text(
        PdfExportService.documentFooterText(
          languageCode: languageCode,
          referenceNumber: referenceNumber,
          pageNumber: context.pageNumber.toString(),
          pagesCount: context.pagesCount.toString(),
        ),
        style: const pw.TextStyle(
          color: PdfColor.fromInt(0xff374151),
          fontSize: 7.5,
        ),
      ),
    );
  }

  static String suggestedFileName(DateTime generatedAt) {
    final year = generatedAt.year.toString();
    final month = generatedAt.month.toString().padLeft(2, '0');
    final day = generatedAt.day.toString().padLeft(2, '0');
    return 'preventia-belgique-recapitulatif-actions-$year$month$day.pdf';
  }

  static pw.Widget _title(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _subtitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _status(String text, String languageCode) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Text(
        _normalizeFrenchText(text, languageCode),
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
  }

  static pw.Widget _info(String label, String value, String languageCode) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _normalizeFrenchText('$label : $value', languageCode),
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _actionsSection(
    List<PriorityActionSummary> actions,
    ActionSummaryPdfTexts texts,
  ) {
    if (actions.isEmpty) {
      return _section('2. ${texts.priorityActions}', [
        texts.noPriorityActions,
      ], texts.languageCode);
    }

    return _cardsSection(
      '2. ${texts.priorityActions}',
      actions.map(
        (action) => [
          '${texts.actionToPerform} : ${action.action}',
          '${texts.riskConcerned} : ${action.risk}',
          '${texts.responsible} : ${action.responsible}',
          '${texts.deadline} : ${action.deadline}',
          '${texts.expectedProof} : ${action.expectedProof}',
          '${texts.whyImportant} : ${action.importance}',
          '${texts.advisorExpectedShort} : ${texts.advisorMustCheck}',
        ],
      ),
      languageCode: texts.languageCode,
    );
  }

  static pw.Widget _documentsSection(
    List<DocumentSummaryItem> documents,
    ActionSummaryPdfTexts texts,
  ) {
    return _cardsSection(
      '3. ${texts.documentsToPrepare}',
      documents.map(
        (document) => [
          '${texts.document} : ${document.document}',
          '${texts.objective} : ${document.objective}',
          '${texts.whyImportant} : ${texts.documentsNecessityExplanation}',
          '${texts.expectedResult} : ${document.expectedResult}',
        ],
      ),
      emptyText: texts.noDocumentsDetected,
      languageCode: texts.languageCode,
    );
  }

  static pw.Widget _actorsSection(
    List<ActorSummaryItem> actors,
    ActionSummaryPdfTexts texts,
  ) {
    return _cardsSection(
      '4. ${texts.actorsToConsult}',
      actors.map(
        (actor) => [
          '${texts.actor} : ${actor.actor}',
          '${texts.whyConsult} : ${actor.reason}',
          '${texts.expectedTrace} : ${actor.expectedTrace}',
        ],
      ),
      emptyText: texts.noActorsDetected,
      languageCode: texts.languageCode,
    );
  }

  static pw.Widget _listSection(
    String title,
    List<String> items,
    String emptyText,
    String languageCode,
  ) {
    return _section(title, items.isEmpty ? [emptyText] : items, languageCode);
  }

  static pw.Widget _section(
    String title,
    List<String> lines,
    String languageCode,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                _normalizeFrenchText(line, languageCode),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cardsSection(
    String title,
    Iterable<List<String>> cards, {
    String emptyText = 'Aucun élément détecté automatiquement.',
    String languageCode = 'fr',
  }) {
    final materialized = cards.toList();
    if (materialized.isEmpty) {
      return _section(title, [emptyText], languageCode);
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...materialized.map(
            (lines) => pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: lines
                    .map(
                      (line) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          _normalizeFrenchText(line, languageCode),
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String _normalizeFrenchText(
    String text, [
    String languageCode = 'fr',
  ]) {
    return PdfExportService.normalizePdfText(
      text
          .replaceAll('l analyse', 'l’analyse')
          .replaceAll('L analyse', 'L’analyse')
          .replaceAll('d analyse', 'd’analyse')
          .replaceAll('D analyse', 'D’analyse')
          .replaceAll('d intervention', 'd’intervention')
          .replaceAll('D intervention', 'D’intervention')
          .replaceAll('c est', 'c’est')
          .replaceAll('C est', 'C’est')
          .replaceAll('d aide', 'd’aide')
          .replaceAll('D aide', 'D’aide')
          .replaceAll('d expérience', 'd’expérience')
          .replaceAll('D expérience', 'D’expérience')
          .replaceAll('l état', 'l’état')
          .replaceAll('L état', 'L’état')
          .replaceAll('l entretien', 'l’entretien')
          .replaceAll('L entretien', 'L’entretien')
          .replaceAll('Chef d équipe', 'Chef d’équipe')
          .replaceAll(
            'Company: Municipal’Administration',
            'Company: Municipal Administration',
          )
          .replaceAll(
            'Company : Municipal’Administration',
            'Company: Municipal Administration',
          )
          .replaceAll('road’intervention', 'road intervention')
          .replaceAll('possible’intervention', 'possible intervention')
          .replaceAll('mise en uvre', 'mise en œuvre')
          .replaceAll('retour d expérience', 'retour d’expérience')
          .replaceAll('Plan Annuel d Action', 'Plan Annuel d’Action'),
      language: languageCode,
    );
  }
}
