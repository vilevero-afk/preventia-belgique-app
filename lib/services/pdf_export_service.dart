import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'document_generator.dart';

class PdfDocumentTexts {
  const PdfDocumentTexts({
    required this.projectStatus,
    required this.preventionDocumentStatus,
    required this.projectStatusUpper,
    required this.documentType,
    required this.generatedAt,
    required this.source,
    required this.localPdfSource,
  });

  static const french = PdfDocumentTexts(
    projectStatus: 'Projet à valider',
    preventionDocumentStatus: 'Document de prévention - Projet à valider',
    projectStatusUpper: 'PROJET À VALIDER',
    documentType: 'Type de document',
    generatedAt: 'Date de génération',
    source: 'Source',
    localPdfSource:
        'Contenu généré dans l’application - PDF généré localement sur l’appareil',
  );

  final String projectStatus;
  final String preventionDocumentStatus;
  final String projectStatusUpper;
  final String documentType;
  final String generatedAt;
  final String source;
  final String localPdfSource;
}

class PdfExportService {
  PdfExportService._();

  static const _missingSectionText =
      'Information à compléter ou à valider sur le terrain.';
  static const Map<String, String> _missingSectionTextsByLanguage = {
    'fr': 'Information à compléter ou à valider sur le terrain.',
    'nl':
        'Informatie aan te vullen of te valideren tijdens het terreinbezoek.',
    'en': 'Information to be completed or validated during the site visit.',
    'de': 'Informationen sind vor Ort zu ergänzen oder zu validieren.',
  };
  static const _actionPlanMissingText =
      'Le plan d’action doit être complété ou régénéré.';
  static const _riskTableMissingText =
      'Le tableau d’analyse détaillée doit être complété après observation de terrain ou relance de la génération IA.';
  static const Map<String, String> _actionPlanMissingTextsByLanguage = {
    'fr': 'Le plan d’action doit être complété ou régénéré.',
    'nl': 'Het actieplan moet worden aangevuld of opnieuw gegenereerd.',
    'en': 'The action plan must be completed or regenerated.',
    'de': 'Der Maßnahmenplan muss ergänzt oder erneut generiert werden.',
  };
  static const Map<String, String> _riskTableMissingTextsByLanguage = {
    'fr':
        'Le tableau d’analyse détaillée doit être complété après observation de terrain ou relance de la génération IA.',
    'nl':
        'De gedetailleerde analysetabel moet worden aangevuld na terreinobservatie of na een nieuwe AI-generatie.',
    'en':
        'The detailed assessment table must be completed after a site observation or by running AI generation again.',
    'de':
        'Die detaillierte Beurteilungstabelle muss nach einer Vor-Ort-Beobachtung oder durch erneute KI-Generierung ergänzt werden.',
  };
  static const _finalNotice =
      'Ce document est un projet à adapter à la situation réelle de l’entreprise et à valider par le conseiller en prévention, l’employeur et, le cas échéant, le service externe, le médecin du travail ou le CPPT. Il ne constitue pas à lui seul une preuve de conformité réglementaire.';

  static const Map<String, String> _finalNoticesByLanguage = {
    'fr':
        'Ce document est un projet à adapter à la situation réelle de l’entreprise et à valider par le conseiller en prévention, l’employeur et, le cas échéant, le service externe, le médecin du travail ou le CPPT. Il ne constitue pas à lui seul une preuve de conformité réglementaire.',
    'nl':
        'Dit document is een ontwerp dat moet worden aangepast aan de werkelijke situatie van de onderneming en gevalideerd door de preventieadviseur, de werkgever en, indien van toepassing, de externe dienst, de arbeidsarts of het CPBW. Het vormt op zichzelf geen bewijs van reglementaire conformiteit.',
    'en':
        'This document is a draft that must be adapted to the actual situation of the organisation and validated by the prevention advisor, the employer and, where applicable, the external service, the occupational physician or the health and safety committee. It does not constitute proof of regulatory compliance on its own.',
    'de':
        'Dieses Dokument ist ein Entwurf, der an die tatsächliche Situation des Unternehmens angepasst und vom Präventionsberater, dem Arbeitgeber sowie gegebenenfalls vom externen Dienst, dem Arbeitsmediziner oder dem Ausschuss für Gefahrenverhütung und Schutz am Arbeitsplatz validiert werden muss. Es stellt für sich allein keinen Nachweis der regulatorischen Konformität dar.',
  };

  static const _brandColor = PdfColor.fromInt(0xff12355b);
  static const _mutedColor = PdfColor.fromInt(0xff5f6b7a);
  static const _borderColor = PdfColor.fromInt(0xffcbd5e1);
  static const _softBackground = PdfColor.fromInt(0xfff8fafc);

  static Future<pw.ThemeData>? _pdfTheme;

  static const Map<String, List<String>> _sectionTitlesByLanguage = {
    'fr': [
      'Identification du document',
      'Contexte et objectif',
      'Références réglementaires belges applicables',
      'Périmètre de l’analyse',
      'Sources d’information utilisées ou à obtenir',
      'Hypothèses et limites',
      'Description des postes, tâches et travailleurs exposés',
      'Identification détaillée des dangers',
      'Tableau principal d’analyse des risques',
      'Analyse des risques résiduels',
      'Priorités d’action',
      'Projet de plan d’action',
      'Lien avec le Plan Global de Prévention et le Plan Annuel d’Action',
      'Documents à créer ou mettre à jour',
      'Acteurs à consulter ou à impliquer',
      'Annexes nécessaires',
      'Conclusion',
      'Mention finale obligatoire',
    ],
    'nl': [
      'Identificatie van het document',
      'Context en doelstelling',
      'Toepasselijke Belgische regelgeving',
      'Afbakening van de analyse',
      'Gebruikte of te verkrijgen informatiebronnen',
      'Hypothesen en beperkingen',
      'Beschrijving van functies, taken en blootgestelde werknemers',
      'Gedetailleerde identificatie van gevaren',
      'Hoofdtabel van de risicoanalyse',
      'Analyse van restrisico’s',
      'Actieprioriteiten',
      'Ontwerp van actieplan',
      'Verband met het Globaal Preventieplan en het Jaaractieplan',
      'Documenten op te stellen of bij te werken',
      'Te raadplegen of te betrekken actoren',
      'Noodzakelijke bijlagen',
      'Conclusie',
      'Validatievermelding',
    ],
    'en': [
      'Document identification',
      'Context and objective',
      'Applicable Belgian regulatory references',
      'Scope of the assessment',
      'Information sources used or to be obtained',
      'Assumptions and limitations',
      'Description of jobs, tasks and exposed workers',
      'Detailed identification of hazards',
      'Main risk assessment table',
      'Residual risk assessment',
      'Action priorities',
      'Draft action plan',
      'Link with the Global Prevention Plan and the Annual Action Plan',
      'Documents to create or update',
      'Stakeholders to consult or involve',
      'Required appendices',
      'Conclusion',
      'Mandatory final statement',
    ],
    'de': [
      'Dokumentidentifikation',
      'Kontext und Zielsetzung',
      'Anwendbare belgische Rechtsvorschriften',
      'Umfang der Beurteilung',
      'Verwendete oder noch einzuholende Informationsquellen',
      'Annahmen und Grenzen',
      'Beschreibung der Arbeitsplätze, Tätigkeiten und exponierten Beschäftigten',
      'Detaillierte Ermittlung der Gefährdungen',
      'Haupttabelle der Gefährdungsbeurteilung',
      'Beurteilung der Restrisiken',
      'Handlungsprioritäten',
      'Entwurf eines Maßnahmenplans',
      'Verbindung mit dem Globalen Präventionsplan und dem Jährlichen Aktionsplan',
      'Zu erstellende oder zu aktualisierende Dokumente',
      'Zu konsultierende oder einzubeziehende Akteure',
      'Erforderliche Anhänge',
      'Schlussfolgerung',
      'Verbindlicher Abschlusshinweis',
    ],
  };

  static const Map<String, List<String>> _riskSummaryHeadersByLanguage = {
    'fr': [
      'Numéro',
      'Activité',
      'Danger',
      'Risque',
      'Personnes exposées',
      'Score initial',
      'Niveau',
      'Priorité',
      'Responsable',
      'Échéance',
      'Score résiduel',
    ],
    'nl': [
      'Nr.',
      'Activiteit',
      'Gevaar',
      'Risico',
      'Blootgestelde personen',
      'Score',
      'Niveau',
      'Prioriteit',
      'Verantwoordelijke',
      'Termijn',
      'Restrisico',
    ],
    'en': [
      'No.',
      'Activity',
      'Hazard',
      'Risk',
      'Exposed persons',
      'Score',
      'Level',
      'Priority',
      'Responsible person',
      'Deadline',
      'Residual risk',
    ],
    'de': [
      'Nr.',
      'Tätigkeit',
      'Gefährdung',
      'Risiko',
      'Exponierte Personen',
      'Punktzahl',
      'Niveau',
      'Priorität',
      'Verantwortliche Person',
      'Frist',
      'Restrisiko',
    ],
  };

  static const Map<String, List<List<String>>> _riskDetailFieldsByLanguage = {
    'fr': [
      ['Situation dangereuse', 'risque ou dommage possible'],
      ['Mesures existantes', 'mesures existantes'],
      ['Preuve des mesures existantes', 'preuve des mesures existantes'],
      ['Justification Gravité', 'motivering gravité'],
      ['Justification Probabilité', 'motivering probabilité'],
      ['Justification Exposition', 'motivering exposition'],
      [
        'Mesures complémentaires proposées',
        'mesures complémentaires proposées',
      ],
      [
        'Type de mesure selon la hiérarchie de prévention',
        'type de mesure selon la hiérarchie de prévention',
      ],
      [
        'Moyen de contrôle ou preuve attendue',
        'moyen de contrôle ou preuve attendue',
      ],
    ],
    'nl': [
      ['Gevaarlijke situatie', 'risque ou dommage possible'],
      ['Bestaande maatregelen', 'mesures existantes'],
      ['Bestaand bewijs', 'preuve des mesures existantes'],
      ['Motivering ernst', 'motivering gravité'],
      ['Motivering waarschijnlijkheid', 'motivering probabilité'],
      ['Motivering blootstelling', 'motivering exposition'],
      ['Aanvullende maatregelen', 'mesures complémentaires proposées'],
      [
        'Type maatregel volgens de preventiehiërarchie',
        'type de mesure selon la hiérarchie de prévention',
      ],
      ['Controle/bewijs', 'moyen de contrôle ou preuve attendue'],
    ],
    'en': [
      ['Hazardous situation', 'risque ou dommage possible'],
      ['Existing measures', 'mesures existantes'],
      ['Existing evidence', 'preuve des mesures existantes'],
      ['Severity justification', 'motivering gravité'],
      ['Probability justification', 'motivering probabilité'],
      ['Exposure justification', 'motivering exposition'],
      ['Additional measures', 'mesures complémentaires proposées'],
      [
        'Type of measure according to the prevention hierarchy',
        'type de mesure selon la hiérarchie de prévention',
      ],
      ['Expected control/evidence', 'moyen de contrôle ou preuve attendue'],
    ],
    'de': [
      ['Gefährliche Situation', 'risque ou dommage possible'],
      ['Bestehende Maßnahmen', 'mesures existantes'],
      ['Vorhandene Nachweise', 'preuve des mesures existantes'],
      ['Begründung Schwere', 'motivering gravité'],
      ['Begründung Wahrscheinlichkeit', 'motivering probabilité'],
      ['Begründung Exposition', 'motivering exposition'],
      ['Zusätzliche Maßnahmen', 'mesures complémentaires proposées'],
      [
        'Art der Maßnahme gemäß Präventionshierarchie',
        'type de mesure selon la hiérarchie de prévention',
      ],
      ['Kontrolle/erwarteter Nachweis', 'moyen de contrôle ou preuve attendue'],
    ],
  };

  static const Map<String, List<String>> _actionSummaryHeadersByLanguage = {
    'fr': [
      'N°',
      'Risque concerné',
      'Mesure proposée',
      'Responsable',
      'Échéance',
      'Statut',
    ],
    'nl': [
      'Nr.',
      'Betrokken risico',
      'Voorgestelde maatregel',
      'Verantwoordelijke',
      'Termijn',
      'Status',
    ],
    'en': [
      'No.',
      'Related risk',
      'Proposed measure',
      'Responsible person',
      'Deadline',
      'Status',
    ],
    'de': [
      'Nr.',
      'Betroffenes Risiko',
      'Vorgeschlagene Maßnahme',
      'Verantwortliche Person',
      'Frist',
      'Status',
    ],
  };

  static const Map<String, List<List<String>>> _actionDetailFieldsByLanguage = {
    'fr': [
      ['Objectif', 'objectif'],
      ['Moyens nécessaires', 'moyens nécessaires'],
      ['Budget estimatif si possible', 'budget estimatif si possible'],
      ['Indicateur de réalisation', 'indicateur de réalisation'],
      ['Preuve attendue', 'preuve attendue'],
    ],
    'nl': [
      ['Doel', 'objectif'],
      ['Benodigde middelen', 'moyens nécessaires'],
      ['Raming van budget indien mogelijk', 'budget estimatif si possible'],
      ['Indicator', 'indicateur de réalisation'],
      ['Verwacht bewijs', 'preuve attendue'],
    ],
    'en': [
      ['Objective', 'objectif'],
      ['Required resources', 'moyens nécessaires'],
      ['Estimated budget if possible', 'budget estimatif si possible'],
      ['Indicator', 'indicateur de réalisation'],
      ['Expected evidence', 'preuve attendue'],
    ],
    'de': [
      ['Ziel', 'objectif'],
      ['Erforderliche Mittel', 'moyens nécessaires'],
      ['Geschätztes Budget falls möglich', 'budget estimatif si possible'],
      ['Indikator', 'indicateur de réalisation'],
      ['Erwarteter Nachweis', 'preuve attendue'],
    ],
  };

  static Future<Uint8List> buildDocumentPdf({
    required String documentType,
    required String content,
    required DateTime generatedAt,
    PdfDocumentTexts texts = PdfDocumentTexts.french,
  }) async {
    final theme = await _theme();
    final document = pw.Document(
      title: 'PreventIA Belgique - $documentType',
      author: 'PreventIA Belgique',
      creator: 'PreventIA Belgique',
      subject: 'Projet de document de prévention',
    );
    final language = detectDocumentLanguage(content);
    final parsed = _splitDocumentIntoSections(content, language: language);
    final sections = parsed.sections;
    final riskRows = _buildRiskRows(
      _parseMarkdownTable(sections[8].tableRows, language: language),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 48, 44, 46),
        theme: theme,
        header: (context) => _buildHeader(
          context,
          documentType: documentType,
          generatedAt: generatedAt,
        ),
        footer: (context) => _buildFooter(context, generatedAt, texts),
        build: (context) => [
          _buildTitleBlock(
            documentType: documentType,
            generatedAt: generatedAt,
            texts: texts,
          ),
          if (parsed.introLines.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            ..._buildParagraphs(parsed.introLines, language),
          ],
          pw.SizedBox(height: 18),
          ...sections
              .where((section) => section.index < 9)
              .expand((section) => _buildSection(section, language: language)),
        ],
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 34, 28, 34),
        theme: theme,
        header: (context) => _buildHeader(
          context,
          documentType: documentType,
          generatedAt: generatedAt,
        ),
        footer: (context) => _buildFooter(context, generatedAt, texts),
        build: (context) => _buildRiskSection(sections[8], riskRows, language),
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 46, 44, 46),
        theme: theme,
        header: (context) => _buildHeader(
          context,
          documentType: documentType,
          generatedAt: generatedAt,
        ),
        footer: (context) => _buildFooter(context, generatedAt, texts),
        build: (context) => [
          ...sections
              .where((section) => section.index > 9 && section.index < 18)
              .expand(
                (section) => _buildSection(
                  section,
                  riskRows: riskRows,
                  language: language,
                ),
              ),
          _buildValidationNoticeSection(language),
        ],
      ),
    );

    return document.save();
  }

  static List<pw.Widget> _buildSection(
    _DocumentSection section, {
    List<_RiskRow> riskRows = const [],
    String language = 'fr',
  }) {
    final widgets = <pw.Widget>[
      _buildSectionTitle('${section.index}. ${section.title}'),
    ];
    final contentWidgets = <pw.Widget>[];

    contentWidgets.addAll(_buildParagraphs(section.bodyLines, language));
    if (section.tableRows.isNotEmpty) {
      if (section.index == 12) {
        contentWidgets.addAll(_buildActionPlan(section.tableRows, language));
      } else {
        final table = _buildGenericTable(section.tableRows, language);
        if (table != null) {
          contentWidgets.add(table);
        }
      }
    }
    if (section.index == 11 &&
        _shouldGeneratePriorities(section, contentWidgets, language)) {
      contentWidgets
        ..clear()
        ..addAll(_buildGeneratedPriorities(riskRows, language));
    }

    if (contentWidgets.isEmpty) {
      widgets.add(_buildParagraph(_missingSectionTextForLanguage(language)));
    } else {
      widgets.addAll(contentWidgets);
    }

    widgets.add(pw.SizedBox(height: 14));
    return widgets;
  }

  static List<pw.Widget> _buildRiskSection(
    _DocumentSection section,
    List<_RiskRow> riskRows,
    String language,
  ) {
    if (riskRows.isEmpty ||
        _isPlaceholderRiskTable(riskRows) ||
        riskRows.every((risk) => _riskConcern(risk).trim().isEmpty)) {
      final rawTable = _buildGenericTable(section.tableRows, language);
      return [
        _buildSectionTitle('${section.index}. ${section.title}'),
        if (rawTable != null)
          rawTable
        else
          _buildParagraph(_riskTableMissingTextForLanguage(language)),
      ];
    }

    return [
      _buildSectionTitle('${section.index}. ${section.title}'),
      _buildRiskSummaryTable(riskRows, language),
      pw.SizedBox(height: 12),
      ...riskRows.expand((risk) => _buildRiskDetailCard(risk, language)),
    ];
  }

  static pw.Widget _buildRiskSummaryTable(
    List<_RiskRow> risks,
    String language,
  ) {
    return pw.TableHelper.fromTextArray(
      headers:
          _riskSummaryHeadersByLanguage[language] ??
          _riskSummaryHeadersByLanguage['fr']!,
      data: risks
          .map(
            (risk) => [
              risk.value('numéro'),
              _displayCell(risk.value('activité ou tâche'), language),
              _displayCell(risk.value('danger'), language),
              _displayCell(
                risk.value('risque ou dommage possible', fallback: 'risque'),
                language,
              ),
              _displayCell(risk.value('personnes exposées'), language),
              _displayCell(risk.value('score initial'), language),
              _displayCell(
                risk.value('niveau de risque initial', fallback: 'niveau'),
                language,
              ),
              _displayCell(risk.value('priorité'), language),
              _displayCell(risk.value('responsable'), language),
              _displayCell(risk.value('échéance'), language),
              _displayCell(
                risk.value(
                  'score résiduel estimé',
                  fallback: 'score résiduel',
                ),
                language,
              ),
            ],
          )
          .toList(),
      border: pw.TableBorder.all(color: _borderColor, width: 0.45),
      headerDecoration: const pw.BoxDecoration(color: _brandColor),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 6,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        color: PdfColor.fromInt(0xff1f2937),
        fontSize: 5.7,
        lineSpacing: 1.1,
      ),
      cellAlignment: pw.Alignment.topLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2.6, vertical: 3),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.45),
        1: pw.FlexColumnWidth(1.05),
        2: pw.FlexColumnWidth(0.95),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(0.55),
        6: pw.FlexColumnWidth(0.62),
        7: pw.FlexColumnWidth(0.62),
        8: pw.FlexColumnWidth(0.85),
        9: pw.FlexColumnWidth(0.72),
        10: pw.FlexColumnWidth(0.72),
      },
    );
  }

  static List<pw.Widget> _buildRiskDetailCard(_RiskRow risk, String language) {
    final riskLabel = switch (language) {
      'nl' => 'Risico',
      'en' => 'Risk',
      'de' => 'Risiko',
      _ => 'Risque',
    };
    final title =
        '$riskLabel ${risk.value('numéro')} - ${risk.value('danger', fallback: riskLabel)}';
    final detailFields =
        _riskDetailFieldsByLanguage[language] ??
        _riskDetailFieldsByLanguage['fr']!;
    return [
      pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 7),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: _softBackground,
          border: pw.Border.all(color: _borderColor, width: 0.6),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: _brandColor,
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            ...detailFields.map(
              (field) =>
                  _buildSmallRichLine(field[0], risk.value(field[1]), language),
            ),
          ],
        ),
      ),
    ];
  }

  static List<pw.Widget> _buildActionPlan(
    List<List<String>> rawRows,
    String language,
  ) {
    final rows = _parseMarkdownTable(rawRows, language: language);
    final actions = _buildActionRows(rows).where((action) => action.isValid);

    if (actions.isEmpty) {
      final rawTable = _buildGenericTable(rawRows, language);
      return [
        if (rawTable != null)
          rawTable
        else
          _buildParagraph(_actionPlanMissingTextForLanguage(language)),
      ];
    }

    final validActions = actions.toList();
    return [
      _buildActionSummaryTable(validActions, language),
      pw.SizedBox(height: 10),
      ...validActions.expand(
        (action) => _buildActionDetailCard(action, language),
      ),
    ];
  }

  static pw.Widget _buildActionSummaryTable(
    List<_ActionRow> actions,
    String language,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.TableHelper.fromTextArray(
        headers:
            _actionSummaryHeadersByLanguage[language] ??
            _actionSummaryHeadersByLanguage['fr']!,
        data: actions
            .map(
              (action) => [
                action.value('numéro d’action', fallback: 'n°'),
                _displayCell(action.value('risque concerné'), language),
                _displayCell(action.value('mesure proposée'), language),
                _displayCell(action.value('responsable'), language),
                _displayCell(action.value('échéance'), language),
                _displayCell(action.value('statut'), language),
              ],
            )
            .toList(),
        border: pw.TableBorder.all(color: _borderColor, width: 0.45),
        headerDecoration: const pw.BoxDecoration(color: _brandColor),
        headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: const pw.TextStyle(
          color: PdfColor.fromInt(0xff1f2937),
          fontSize: 6.8,
          lineSpacing: 1.15,
        ),
        cellAlignment: pw.Alignment.topLeft,
        headerAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(3.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(0.42),
          1: pw.FlexColumnWidth(1.05),
          2: pw.FlexColumnWidth(1.35),
          3: pw.FlexColumnWidth(0.85),
          4: pw.FlexColumnWidth(0.75),
          5: pw.FlexColumnWidth(0.7),
        },
      ),
    );
  }

  static List<pw.Widget> _buildActionDetailCard(
    _ActionRow action,
    String language,
  ) {
    final number = action.value('numéro d’action', fallback: 'n°');
    final measure = action.value('mesure proposée');
    final title = switch (language) {
      'nl' => 'Actie $number - $measure',
      'en' => 'Action $number - $measure',
      'de' => 'Maßnahme $number - $measure',
      _ => 'Action $number - $measure',
    };
    final detailFields =
        _actionDetailFieldsByLanguage[language] ??
        _actionDetailFieldsByLanguage['fr']!;
    return [
      pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 7),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: _softBackground,
          border: pw.Border.all(color: _borderColor, width: 0.6),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: _brandColor,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            ...detailFields.map(
              (field) => _buildSmallRichLine(
                field[0],
                action.value(field[1]),
                language,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  static pw.Widget? _buildGenericTable(
    List<List<String>> rawRows, [
    String language = 'fr',
  ]) {
    final rows = _parseMarkdownTable(rawRows, language: language);
    if (rows.length < 2 || _isPlaceholderTable(rows.skip(1).toList())) {
      return null;
    }
    final dataRows = rows
        .skip(1)
        .map((row) => row.map((cell) => _displayCell(cell, language)).toList())
        .toList();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.TableHelper.fromTextArray(
        headers: rows.first,
        data: dataRows,
        border: pw.TableBorder.all(color: _borderColor, width: 0.45),
        headerDecoration: const pw.BoxDecoration(color: _brandColor),
        headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7.4,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: const pw.TextStyle(
          color: PdfColor.fromInt(0xff1f2937),
          fontSize: 7.2,
          lineSpacing: 1.2,
        ),
        cellAlignment: pw.Alignment.topLeft,
        headerAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(4),
      ),
    );
  }

  static Future<pw.ThemeData> _theme() {
    return _pdfTheme ??= _loadPdfTheme();
  }

  static Future<pw.ThemeData> _loadPdfTheme() async {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();
    final boldItalic = await PdfGoogleFonts.notoSansBoldItalic();
    final fallback = await PdfGoogleFonts.notoSerifRegular();
    final emoji = await PdfGoogleFonts.notoColorEmoji();

    return pw.ThemeData.withFont(
      base: base,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
      fontFallback: [fallback, emoji, base],
    );
  }

  static String suggestedFileName(String documentType, DateTime generatedAt) {
    final date =
        '${generatedAt.year}${_twoDigits(generatedAt.month)}${_twoDigits(generatedAt.day)}';
    final type = documentType
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'preventia-belgique-$type-$date.pdf';
  }

  static String _cleanMarkdownText(String text, {String language = 'fr'}) {
    var cleaned = text.replaceAll('\r', '');
    if (_isMarkdownSeparatorLine(cleaned.trim())) {
      return '';
    }
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'__([^_]+)__'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned
        .replaceAll(RegExp(r'^\s*#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\|\s*$'), '')
        .replaceAll(r'$1', '');
    return normalizePdfText(cleaned, language: language).trim();
  }

  static String normalizePdfText(String input, {String language = 'fr'}) {
    final withoutBadEnglishApostrophes = _fixAnomalousEnglishApostrophes(input);
    final translatedFallbacks = _translatePdfFallbacks(
      withoutBadEnglishApostrophes,
      language,
    );
    return normalizeFrenchText(translatedFallbacks);
  }

  static String normalizeFrenchText(String input) {
    final replacements = <String, String>{
      'l entreprise': 'l’entreprise',
      'l employeur': 'l’employeur',
      'l utilisation': 'l’utilisation',
      'l exécution': 'l’exécution',
      'l Administration': 'l’Administration',
      'l exercice': 'l’exercice',
      'd Action': 'd’Action',
      'd action': 'd’action',
      'd analyse': 'd’analyse',
      'd information': 'd’information',
      'd intervention': 'd’intervention',
      'd intégration': 'd’intégration',
      'd évaluation': 'd’évaluation',
      'd équipe': 'd’équipe',
      'd utilisation': 'd’utilisation',
      'l analyse': 'l’analyse',
      'l information': 'l’information',
      'l intervention': 'l’intervention',
      'c est': 'c’est',
      'Company: Municipal’Administration': 'Company: Municipal Administration',
      'Company : Municipal’Administration': 'Company: Municipal Administration',
      'road’intervention': 'road intervention',
      'possible’intervention': 'possible intervention',
      'chef d équipe': 'chef d’équipe',
      'chefs d équipe': 'chefs d’équipe',
      'Plan Annuel d Action': 'Plan Annuel d’Action',
      'mise en uvre': 'mise en œuvre',
      'man uvre': 'manœuvre',
      'man uvres': 'manœuvres',
      'en uvre': 'en œuvre',
      'Cet analyse': 'Cette analyse',
      'annue de prévention': 'annuel de prévention',
    };

    var fixed = input
        .replaceAll('\u2018', '’')
        .replaceAll('\u2019', '’')
        .replaceAll('\u201B', '’')
        .replaceAll('\u2032', '’')
        .replaceAll('\u00B4', '’')
        .replaceAll('´', '’');

    for (final entry in replacements.entries) {
      fixed = fixed.replaceAll(entry.key, entry.value);
    }
    fixed = fixed.replaceAllMapped(
      RegExp(r'(?<![A-Za-zÀ-ÿŒœ])oeuvre(?![A-Za-zÀ-ÿŒœ])'),
      (_) => 'œuvre',
    );
    return fixed;
  }

  static String _translatePdfFallbacks(String input, String language) {
    final fallback = _missingSectionTextForLanguage(language);
    return input.replaceAll(_missingSectionText, fallback);
  }

  static String _fixAnomalousEnglishApostrophes(String input) {
    const contractionSuffixes = {'re', 've', 'll'};
    return input
        .replaceAllMapped(RegExp(r'\b([A-Za-z]{2,})[’\']([A-Za-z]{2,})\b'), (
      match,
    ) {
      final suffix = match.group(2)!.toLowerCase();
      if (contractionSuffixes.contains(suffix)) {
        return match.group(0)!;
      }
      return '${match.group(1)} ${match.group(2)}';
    });
  }

  static bool _isMarkdownSeparatorLine(String line) {
    if (!line.startsWith('|') || !line.endsWith('|')) {
      return false;
    }
    return RegExp(r'^\|\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|$').hasMatch(line);
  }

  static String detectDocumentLanguage(String content) {
    final normalized = _normalizeTitle(content);
    if (normalized.contains(
          _normalizeTitle('Risk assessment – Draft for validation'),
        ) ||
        normalized.contains(_normalizeTitle('Document identification')) ||
        normalized.contains(_normalizeTitle('Draft action plan'))) {
      return 'en';
    }
    if (normalized.contains(
          _normalizeTitle('Risicoanalyse – Ontwerp te valideren'),
        ) ||
        normalized.contains(
          _normalizeTitle('Identificatie van het document'),
        ) ||
        normalized.contains(_normalizeTitle('Ontwerp van actieplan'))) {
      return 'nl';
    }
    if (normalized.contains(
          _normalizeTitle('Gefährdungsbeurteilung – Entwurf zur Validierung'),
        ) ||
        normalized.contains(_normalizeTitle('Dokumentidentifikation')) ||
        normalized.contains(_normalizeTitle('Entwurf eines Maßnahmenplans'))) {
      return 'de';
    }
    return 'fr';
  }

  static _ParsedDocument _splitDocumentIntoSections(
    String content, {
    required String language,
  }) {
    final sectionTitles =
        _sectionTitlesByLanguage[language] ?? _sectionTitlesByLanguage['fr']!;
    final builders = {
      for (var index = 1; index <= sectionTitles.length; index++)
        index: _DocumentSectionBuilder(
          index: index,
          title: sectionTitles[index - 1],
        ),
    };
    final introLines = <String>[];
    var currentIndex = 0;

    for (final rawLine in content.replaceAll('\r\n', '\n').split('\n')) {
      final cleanedLine = _cleanMarkdownText(rawLine).trimRight();
      final trimmed = cleanedLine.trim();

      if (_isValidationNotice(trimmed)) {
        continue;
      }
      if (_isDocumentChromeLine(trimmed)) {
        continue;
      }
      if (trimmed.isEmpty) {
        if (currentIndex == 0) {
          if (introLines.isNotEmpty) {
            introLines.add('');
          }
        } else {
          builders[currentIndex]!.addLine('');
        }
        continue;
      }

      final sectionInfo = _parseSectionTitle(trimmed, language: language);
      if (sectionInfo != null) {
        currentIndex = sectionInfo.index;
        builders[currentIndex]!.setTitle(sectionInfo.title);
        continue;
      }

      if (currentIndex == 0) {
        introLines.add(cleanedLine);
      } else if (currentIndex != 18) {
        builders[currentIndex]!.addLine(cleanedLine);
      }
    }

    return _ParsedDocument(
      introLines: _trimEmptyLines(introLines),
      sections: List.generate(
        sectionTitles.length,
        (index) => builders[index + 1]!.build(),
      ),
    );
  }

  static bool _isDocumentChromeLine(String text) {
    if (text.isEmpty) {
      return false;
    }
    return RegExp(
          r'^projet\s+de\s+document\b',
          caseSensitive: false,
        ).hasMatch(text) ||
        RegExp(
          r'^projet\s+à\s+valider$',
          caseSensitive: false,
        ).hasMatch(text) ||
        RegExp(
          r'^analyse de risques\s*[–-]\s*projet à valider$',
          caseSensitive: false,
        ).hasMatch(text);
  }

  static bool _isValidationNotice(String text) {
    final normalized = _normalizeTitle(text);
    return normalized == _normalizeTitle(mandatoryValidationNotice) ||
        normalized == _normalizeTitle(_finalNotice) ||
        normalized.contains(
          _normalizeTitle(
            'Ce document est un projet à adapter à la situation réelle de l’entreprise',
          ),
        );
  }

  static _SectionInfo? _parseSectionTitle(
    String line, {
    required String language,
  }) {
    final sectionTitles =
        _sectionTitlesByLanguage[language] ?? _sectionTitlesByLanguage['fr']!;
    final numbered = RegExp(
      r'^(\d+)[\.)]\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (numbered != null) {
      final index = int.tryParse(numbered.group(1)!);
      if (index != null && index >= 1 && index <= 18) {
        final rawTitle = numbered.group(2) ?? '';
        final title = _displaySectionTitleForIndex(rawTitle, index, language);
        return _SectionInfo(index: index, title: title);
      }
    }

    final title = _canonicalSectionTitle(line);
    var index =
        sectionTitles.indexWhere(
          (knownTitle) => _normalizeTitle(knownTitle) == _normalizeTitle(title),
        ) +
        1;
    if (index == 0) {
      index =
          _sectionTitlesByLanguage['fr']!.indexWhere(
            (knownTitle) =>
                _normalizeTitle(knownTitle) == _normalizeTitle(title),
          ) +
          1;
    }
    if (index > 0) {
      return _SectionInfo(index: index, title: sectionTitles[index - 1]);
    }
    return null;
  }

  static String _displaySectionTitleForIndex(
    String title,
    int index,
    String language,
  ) {
    final sectionTitles =
        _sectionTitlesByLanguage[language] ?? _sectionTitlesByLanguage['fr']!;
    final canonicalTitle = _canonicalSectionTitle(title);
    final canonicalIndex =
        sectionTitles.indexWhere(
          (knownTitle) =>
              _normalizeTitle(knownTitle) == _normalizeTitle(canonicalTitle),
        ) +
        1;
    if (canonicalIndex == index) {
      return _cleanSectionDisplayTitle(title);
    }
    return sectionTitles[index - 1];
  }

  static String _cleanSectionDisplayTitle(String title) {
    final cleaned = _cleanMarkdownText(title).replaceAll(RegExp(r':$'), '');
    return cleaned.trim();
  }

  static String _canonicalSectionTitle(String title) {
    final normalized = _normalizeTitle(title);
    final aliases = <String, int>{
      _normalizeTitle('Contexte'): 2,
      _normalizeTitle('Hypothèses utilisées'): 6,
      _normalizeTitle('Tableau d’analyse des risques'): 9,
      _normalizeTitle('Priorités d’action'): 11,
      _normalizeTitle('Documents à créer ou mettre à jour'): 14,
      _normalizeTitle('Documents à créer ou à mettre à jour'): 14,
      _normalizeTitle('Points à valider'): 6,
      _normalizeTitle('Mention de validation'): 18,
      _normalizeTitle('Mention finale obligatoire'): 18,
      _normalizeTitle('Identificatie van het document'): 1,
      _normalizeTitle('Context en doelstelling'): 2,
      _normalizeTitle('Toepasselijke Belgische regelgeving'): 3,
      _normalizeTitle('Afbakening van de analyse'): 4,
      _normalizeTitle('Gebruikte of te verkrijgen informatiebronnen'): 5,
      _normalizeTitle('Hypothesen en beperkingen'): 6,
      _normalizeTitle(
        'Beschrijving van functies, taken en blootgestelde werknemers',
      ): 7,
      _normalizeTitle('Gedetailleerde identificatie van gevaren'): 8,
      _normalizeTitle('Hoofdtabel van de risicoanalyse'): 9,
      _normalizeTitle('Analyse van restrisico’s'): 10,
      _normalizeTitle('Actieprioriteiten'): 11,
      _normalizeTitle('Ontwerp van actieplan'): 12,
      _normalizeTitle(
        'Verband met het Globaal Preventieplan en het Jaaractieplan',
      ): 13,
      _normalizeTitle('Documenten op te stellen of bij te werken'): 14,
      _normalizeTitle('Te raadplegen of te betrekken actoren'): 15,
      _normalizeTitle('Noodzakelijke bijlagen'): 16,
      _normalizeTitle('Conclusie'): 17,
      _normalizeTitle('Validatievermelding'): 18,
      _normalizeTitle('Document identification'): 1,
      _normalizeTitle('Context and objective'): 2,
      _normalizeTitle('Applicable Belgian regulatory references'): 3,
      _normalizeTitle('Scope of the assessment'): 4,
      _normalizeTitle('Information sources used or to be obtained'): 5,
      _normalizeTitle('Assumptions and limitations'): 6,
      _normalizeTitle('Description of jobs, tasks and exposed workers'): 7,
      _normalizeTitle('Detailed identification of hazards'): 8,
      _normalizeTitle('Main risk assessment table'): 9,
      _normalizeTitle('Residual risk assessment'): 10,
      _normalizeTitle('Action priorities'): 11,
      _normalizeTitle('Draft action plan'): 12,
      _normalizeTitle(
        'Link with the Global Prevention Plan and the Annual Action Plan',
      ): 13,
      _normalizeTitle('Documents to create or update'): 14,
      _normalizeTitle('Stakeholders to consult or involve'): 15,
      _normalizeTitle('Required appendices'): 16,
      _normalizeTitle('Mandatory final statement'): 18,
      _normalizeTitle('Dokumentidentifikation'): 1,
      _normalizeTitle('Anwendbare belgische Rechtsvorschriften'): 3,
      _normalizeTitle('Umfang der Beurteilung'): 4,
      _normalizeTitle('Verwendete oder noch einzuholende Informationsquellen'):
          5,
      _normalizeTitle('Annahmen und Grenzen'): 6,
      _normalizeTitle(
        'Beschreibung der Arbeitsplätze, Tätigkeiten und exponierten Beschäftigten',
      ): 7,
      _normalizeTitle('Detaillierte Ermittlung der Gefährdungen'): 8,
      _normalizeTitle('Haupttabelle der Gefährdungsbeurteilung'): 9,
      _normalizeTitle('Beurteilung der Restrisiken'): 10,
      _normalizeTitle('Handlungsprioritäten'): 11,
      _normalizeTitle('Entwurf eines Maßnahmenplans'): 12,
      _normalizeTitle(
        'Verbindung mit dem Globalen Präventionsplan und dem Jährlichen Aktionsplan',
      ): 13,
      _normalizeTitle('Zu erstellende oder zu aktualisierende Dokumente'): 14,
      _normalizeTitle('Zu konsultierende oder einzubeziehende Akteure'): 15,
      _normalizeTitle('Erforderliche Anhänge'): 16,
      _normalizeTitle('Schlussfolgerung'): 17,
      _normalizeTitle('Verbindlicher Abschlusshinweis'): 18,
    };
    final aliasIndex = aliases[normalized];
    if (aliasIndex != null) {
      return _sectionTitlesByLanguage['fr']![aliasIndex - 1];
    }
    return _cleanMarkdownText(title).replaceAll(RegExp(r':$'), '').trim();
  }

  static String _normalizeTitle(String title) {
    return _cleanMarkdownText(title)
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll('œ', 'oe')
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-zàâçéèêëîïôûùüÿñæ0-9]+'), ' ')
        .trim();
  }

  static List<pw.Widget> _buildParagraphs(
    List<String> lines, [
    String language = 'fr',
  ]) {
    final widgets = <pw.Widget>[];
    for (final line in lines) {
      final trimmed = _cleanMarkdownText(line, language: language).trim();
      if (trimmed.isEmpty) {
        if (widgets.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 5));
        }
        continue;
      }

      final bullet = RegExp(r'^[-*]\s+(.+)$').firstMatch(trimmed);
      if (bullet != null) {
        widgets.add(_buildBullet(bullet.group(1)!, language));
      } else {
        widgets.add(_buildParagraph(trimmed, language));
      }
    }
    if (widgets.isEmpty) {
      return const [];
    }
    return widgets;
  }

  static pw.Widget _buildParagraph(String text, [String language = 'fr']) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        _cleanMarkdownText(text, language: language),
        style: const pw.TextStyle(
          color: PdfColor.fromInt(0xff1f2937),
          fontSize: 10.2,
          lineSpacing: 2.2,
        ),
      ),
    );
  }

  static pw.Widget _buildBullet(String text, [String language = 'fr']) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 6, right: 8),
            decoration: const pw.BoxDecoration(
              color: _brandColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(child: _buildParagraph(text, language)),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 9),
      padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _borderColor, width: 0.8),
        ),
      ),
      child: pw.Text(
        _cleanMarkdownText(title),
        style: pw.TextStyle(
          color: _brandColor,
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildValidationNoticeSection(String language) {
    final titles =
        _sectionTitlesByLanguage[language] ?? _sectionTitlesByLanguage['fr']!;
    final notice =
        _finalNoticesByLanguage[language] ?? _finalNoticesByLanguage['fr']!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('18. ${titles[17]}'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(13),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xffeef6ff),
            border: pw.Border.all(color: _brandColor, width: 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            notice,
            style: pw.TextStyle(
              color: _brandColor,
              fontSize: 9.5,
              lineSpacing: 2,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static List<List<String>> _parseMarkdownTable(
    List<List<String>> rows, {
    String language = 'fr',
  }) {
    return rows
        .where((row) {
          if (row.isEmpty) {
            return false;
          }
          return !_isMarkdownSeparatorRow(row);
        })
        .map(
          (row) =>
              row.map((cell) => _cleanMarkdownText(cell, language: language)).toList(),
        )
        .toList();
  }

  static bool _isMarkdownSeparatorRow(List<String> row) {
    return row.every((cell) {
      final trimmed = cell.trim();
      return trimmed.isEmpty ||
          RegExp(r'^:?-{3,}:?$').hasMatch(trimmed) ||
          RegExp(r'^[-:\s]+$').hasMatch(trimmed);
    });
  }

  static List<_RiskRow> _buildRiskRows(List<List<String>> rows) {
    if (rows.length < 2) {
      return const [];
    }

    final header = rows.first.map((value) {
      return _canonicalRiskHeader(_normalizeTitle(value));
    }).toList();
    final language = _riskTableLanguage(rows.first);
    return rows
        .skip(1)
        .map((row) {
          final values = <String, String>{};
          for (
            var index = 0;
            index < header.length && index < row.length;
            index++
          ) {
            values[header[index]] = _cleanMarkdownText(row[index]);
          }
          final score = _readRiskScore(values);
          if (score != null) {
            // Le niveau de risque est recalculé localement pour garantir la cohérence de la méthode G x P x E.
            values[_normalizeTitle('niveau de risque initial')] =
                getRiskLevelFromScore(score, language: language);
            values[_normalizeTitle('niveau')] = getRiskLevelFromScore(
              score,
              language: language,
            );
          }
          return _RiskRow(values);
        })
        .where((risk) => !risk.isEmpty)
        .toList();
  }

  static String getRiskLevelFromScore(int score, {String language = 'fr'}) {
    final levels = switch (language) {
      'nl' => ['Laag', 'Gemiddeld', 'Hoog', 'Kritiek', 'Te controleren'],
      'en' => ['Low', 'Medium', 'High', 'Critical', 'To be checked'],
      'de' => ['Niedrig', 'Mittel', 'Hoch', 'Kritisch', 'Zu prüfen'],
      _ => ['Faible', 'Moyen', 'Élevé', 'Critique', 'À vérifier'],
    };
    if (score >= 1 && score <= 20) {
      return levels[0];
    }
    if (score >= 21 && score <= 50) {
      return levels[1];
    }
    if (score >= 51 && score <= 100) {
      return levels[2];
    }
    if (score >= 101 && score <= 125) {
      return levels[3];
    }
    return levels[4];
  }

  static int? _readRiskScore(Map<String, String> values) {
    final scoreText =
        values[_normalizeTitle('score initial')] ??
        values[_normalizeTitle('score')] ??
        values[_normalizeTitle('punktzahl')];
    if (scoreText == null) {
      return null;
    }
    final match = RegExp(r'\d+').firstMatch(scoreText);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static bool _isPlaceholderRiskTable(List<_RiskRow> risks) {
    if (risks.isEmpty) {
      return true;
    }
    return risks.every((risk) => risk.values.values.every(_isPlaceholderCell));
  }

  static List<_ActionRow> _buildActionRows(List<List<String>> rows) {
    if (rows.length < 2) {
      return const [];
    }

    final header = rows.first.map((value) {
      return _canonicalActionHeader(_normalizeTitle(value));
    }).toList();
    return rows
        .skip(1)
        .map((row) {
          final normalizedRow = _normalizeActionRowWidth(row, header.length);
          final values = <String, String>{};
          for (
            var index = 0;
            index < header.length && index < normalizedRow.length;
            index++
          ) {
            values[header[index]] = _cleanMarkdownText(normalizedRow[index]);
          }
          return _ActionRow(values);
        })
        .where((action) => !action.isEmpty)
        .toList();
  }

  static List<String> _normalizeActionRowWidth(
    List<String> row,
    int headerLength,
  ) {
    if (headerLength < 4 || row.length <= headerLength) {
      return row;
    }
    final trailingCellCount = headerLength - 3;
    final trailingStart = row.length - trailingCellCount;
    return [
      row[0],
      row[1],
      row.sublist(2, trailingStart).join(' | '),
      ...row.sublist(trailingStart),
    ];
  }

  static String _canonicalActionHeader(String normalizedHeader) {
    final aliases = <String, String>{
      _normalizeTitle('N°'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Nr.'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Nr'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('No.'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('No'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Numéro'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Action'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Risque'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Risque concerné'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Betrokken risico'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Related risk'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Betroffenes Risiko'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Mesure'): _normalizeTitle('mesure proposée'),
      _normalizeTitle('Action proposée'): _normalizeTitle('mesure proposée'),
      _normalizeTitle('Mesure proposée'): _normalizeTitle('mesure proposée'),
      _normalizeTitle('Voorgestelde maatregel'): _normalizeTitle(
        'mesure proposée',
      ),
      _normalizeTitle('Proposed measure'): _normalizeTitle('mesure proposée'),
      _normalizeTitle('Vorgeschlagene Maßnahme'): _normalizeTitle(
        'mesure proposée',
      ),
      _normalizeTitle('Doel'): _normalizeTitle('objectif'),
      _normalizeTitle('Objective'): _normalizeTitle('objectif'),
      _normalizeTitle('Ziel'): _normalizeTitle('objectif'),
      _normalizeTitle('Responsable'): _normalizeTitle('responsable'),
      _normalizeTitle('Verantwoordelijke'): _normalizeTitle('responsable'),
      _normalizeTitle('Responsible person'): _normalizeTitle('responsable'),
      _normalizeTitle('Verantwortliche Person'): _normalizeTitle('responsable'),
      _normalizeTitle('Échéance'): _normalizeTitle('échéance'),
      _normalizeTitle('Termijn'): _normalizeTitle('échéance'),
      _normalizeTitle('Deadline'): _normalizeTitle('échéance'),
      _normalizeTitle('Frist'): _normalizeTitle('échéance'),
      _normalizeTitle('Benodigde middelen'): _normalizeTitle(
        'moyens nécessaires',
      ),
      _normalizeTitle('Required resources'): _normalizeTitle(
        'moyens nécessaires',
      ),
      _normalizeTitle('Erforderliche Mittel'): _normalizeTitle(
        'moyens nécessaires',
      ),
      _normalizeTitle('Indicator'): _normalizeTitle(
        'indicateur de réalisation',
      ),
      _normalizeTitle('Verwacht bewijs'): _normalizeTitle('preuve attendue'),
      _normalizeTitle('Expected evidence'): _normalizeTitle('preuve attendue'),
      _normalizeTitle('Erwarteter Nachweis'): _normalizeTitle(
        'preuve attendue',
      ),
      _normalizeTitle('Statut'): _normalizeTitle('statut'),
      _normalizeTitle('Status'): _normalizeTitle('statut'),
      _normalizeTitle('Link AAP/GPP'): _normalizeTitle(
        'lien avec plan annuel d’action / plan global de prévention',
      ),
      _normalizeTitle('Bezug JAP/GPP'): _normalizeTitle(
        'lien avec plan annuel d’action / plan global de prévention',
      ),
      _normalizeTitle('Link JAP/GPP'): _normalizeTitle(
        'lien avec plan annuel d’action / plan global de prévention',
      ),
    };
    return aliases[normalizedHeader] ?? normalizedHeader;
  }

  static String _canonicalRiskHeader(String normalizedHeader) {
    final aliases = <String, String>{
      _normalizeTitle('N°'): _normalizeTitle('numéro'),
      _normalizeTitle('Nr.'): _normalizeTitle('numéro'),
      _normalizeTitle('Nr'): _normalizeTitle('numéro'),
      _normalizeTitle('No.'): _normalizeTitle('numéro'),
      _normalizeTitle('No'): _normalizeTitle('numéro'),
      _normalizeTitle('Activité ou tâche'): _normalizeTitle(
        'activité ou tâche',
      ),
      _normalizeTitle('Activiteit'): _normalizeTitle('activité ou tâche'),
      _normalizeTitle('Activity or task'): _normalizeTitle('activité ou tâche'),
      _normalizeTitle('Tätigkeit oder Aufgabe'): _normalizeTitle(
        'activité ou tâche',
      ),
      _normalizeTitle('Danger'): _normalizeTitle('danger'),
      _normalizeTitle('Gevaar'): _normalizeTitle('danger'),
      _normalizeTitle('Hazard'): _normalizeTitle('danger'),
      _normalizeTitle('Gefährdung'): _normalizeTitle('danger'),
      _normalizeTitle('Risque'): _normalizeTitle('risque'),
      _normalizeTitle('Risico'): _normalizeTitle('risque'),
      _normalizeTitle('Risk'): _normalizeTitle('risque'),
      _normalizeTitle('Risiko'): _normalizeTitle('risque'),
      _normalizeTitle('Personnes exposées'): _normalizeTitle(
        'personnes exposées',
      ),
      _normalizeTitle('Blootgestelde personen'): _normalizeTitle(
        'personnes exposées',
      ),
      _normalizeTitle('Exposed persons'): _normalizeTitle('personnes exposées'),
      _normalizeTitle('Exponierte Personen'): _normalizeTitle(
        'personnes exposées',
      ),
      _normalizeTitle('Mesures existantes'): _normalizeTitle(
        'mesures existantes',
      ),
      _normalizeTitle('Bestaande maatregelen'): _normalizeTitle(
        'mesures existantes',
      ),
      _normalizeTitle('Existing measures'): _normalizeTitle(
        'mesures existantes',
      ),
      _normalizeTitle('Bestehende Maßnahmen'): _normalizeTitle(
        'mesures existantes',
      ),
      _normalizeTitle('Preuves existantes'): _normalizeTitle(
        'preuve des mesures existantes',
      ),
      _normalizeTitle('Bestaand bewijs'): _normalizeTitle(
        'preuve des mesures existantes',
      ),
      _normalizeTitle('Existing evidence'): _normalizeTitle(
        'preuve des mesures existantes',
      ),
      _normalizeTitle('Vorhandene Nachweise'): _normalizeTitle(
        'preuve des mesures existantes',
      ),
      _normalizeTitle('Justification Gravité'): _normalizeTitle(
        'motivering gravité',
      ),
      _normalizeTitle('Motivering ernst'): _normalizeTitle(
        'motivering gravité',
      ),
      _normalizeTitle('Severity justification'): _normalizeTitle(
        'motivering gravité',
      ),
      _normalizeTitle('Begründung Schwere'): _normalizeTitle(
        'motivering gravité',
      ),
      _normalizeTitle('Justification Probabilité'): _normalizeTitle(
        'motivering probabilité',
      ),
      _normalizeTitle('Motivering waarschijnlijkheid'): _normalizeTitle(
        'motivering probabilité',
      ),
      _normalizeTitle('Probability justification'): _normalizeTitle(
        'motivering probabilité',
      ),
      _normalizeTitle('Begründung Wahrscheinlichkeit'): _normalizeTitle(
        'motivering probabilité',
      ),
      _normalizeTitle('Justification Exposition'): _normalizeTitle(
        'motivering exposition',
      ),
      _normalizeTitle('Motivering blootstelling'): _normalizeTitle(
        'motivering exposition',
      ),
      _normalizeTitle('Exposure justification'): _normalizeTitle(
        'motivering exposition',
      ),
      _normalizeTitle('Begründung Exposition'): _normalizeTitle(
        'motivering exposition',
      ),
      _normalizeTitle('Gravité'): _normalizeTitle('gravité'),
      _normalizeTitle('Ernst'): _normalizeTitle('gravité'),
      _normalizeTitle('Severity'): _normalizeTitle('gravité'),
      _normalizeTitle('Schwere'): _normalizeTitle('gravité'),
      _normalizeTitle('Probabilité'): _normalizeTitle('probabilité'),
      _normalizeTitle('Waarschijnlijkheid'): _normalizeTitle('probabilité'),
      _normalizeTitle('Probability'): _normalizeTitle('probabilité'),
      _normalizeTitle('Wahrscheinlichkeit'): _normalizeTitle('probabilité'),
      _normalizeTitle('Exposition'): _normalizeTitle('exposition'),
      _normalizeTitle('Blootstelling'): _normalizeTitle('exposition'),
      _normalizeTitle('Exposure'): _normalizeTitle('exposition'),
      _normalizeTitle('Score'): _normalizeTitle('score initial'),
      _normalizeTitle('Punktzahl'): _normalizeTitle('score initial'),
      _normalizeTitle('Niveau'): _normalizeTitle('niveau de risque initial'),
      _normalizeTitle('Level'): _normalizeTitle('niveau de risque initial'),
      _normalizeTitle('Mesures complémentaires'): _normalizeTitle(
        'mesures complémentaires proposées',
      ),
      _normalizeTitle('Aanvullende maatregelen'): _normalizeTitle(
        'mesures complémentaires proposées',
      ),
      _normalizeTitle('Additional measures'): _normalizeTitle(
        'mesures complémentaires proposées',
      ),
      _normalizeTitle('Zusätzliche Maßnahmen'): _normalizeTitle(
        'mesures complémentaires proposées',
      ),
      _normalizeTitle('Type de mesure'): _normalizeTitle(
        'type de mesure selon la hiérarchie de prévention',
      ),
      _normalizeTitle('Type maatregel'): _normalizeTitle(
        'type de mesure selon la hiérarchie de prévention',
      ),
      _normalizeTitle('Type of measure'): _normalizeTitle(
        'type de mesure selon la hiérarchie de prévention',
      ),
      _normalizeTitle('Art der Maßnahme'): _normalizeTitle(
        'type de mesure selon la hiérarchie de prévention',
      ),
      _normalizeTitle('Responsable'): _normalizeTitle('responsable'),
      _normalizeTitle('Verantwoordelijke'): _normalizeTitle('responsable'),
      _normalizeTitle('Responsible person'): _normalizeTitle('responsable'),
      _normalizeTitle('Verantwortliche Person'): _normalizeTitle('responsable'),
      _normalizeTitle('Échéance'): _normalizeTitle('échéance'),
      _normalizeTitle('Termijn'): _normalizeTitle('échéance'),
      _normalizeTitle('Deadline'): _normalizeTitle('échéance'),
      _normalizeTitle('Frist'): _normalizeTitle('échéance'),
      _normalizeTitle('Risque résiduel'): _normalizeTitle(
        'score résiduel estimé',
      ),
      _normalizeTitle('Restrisico'): _normalizeTitle('score résiduel estimé'),
      _normalizeTitle('Restrisiko'): _normalizeTitle('score résiduel estimé'),
      _normalizeTitle('Residual risk'): _normalizeTitle(
        'score résiduel estimé',
      ),
      _normalizeTitle('Kontrolle/erwarteter Nachweis'): _normalizeTitle(
        'moyen de contrôle ou preuve attendue',
      ),
      _normalizeTitle('Contrôle/preuve attendue'): _normalizeTitle(
        'moyen de contrôle ou preuve attendue',
      ),
      _normalizeTitle('Controle/bewijs'): _normalizeTitle(
        'moyen de contrôle ou preuve attendue',
      ),
      _normalizeTitle('Expected control/evidence'): _normalizeTitle(
        'moyen de contrôle ou preuve attendue',
      ),
      _normalizeTitle('Prioriteit'): _normalizeTitle('priorité'),
      _normalizeTitle('Priority'): _normalizeTitle('priorité'),
      _normalizeTitle('Priorität'): _normalizeTitle('priorité'),
    };
    return aliases[normalizedHeader] ?? normalizedHeader;
  }

  static String _riskTableLanguage(List<String> headers) {
    final normalized = headers.map(_normalizeTitle).join(' | ');
    if (normalized.contains(_normalizeTitle('Activity or task')) ||
        normalized.contains(_normalizeTitle('Exposed persons'))) {
      return 'en';
    }
    if (normalized.contains(_normalizeTitle('Tätigkeit oder Aufgabe')) ||
        normalized.contains(_normalizeTitle('Punktzahl')) ||
        normalized.contains(_normalizeTitle('Exponierte Personen'))) {
      return 'de';
    }
    if (normalized.contains(_normalizeTitle('Activiteit')) ||
        normalized.contains(_normalizeTitle('Blootgestelde personen'))) {
      return 'nl';
    }
    return 'fr';
  }

  static List<String> _riskHeaderCandidates(String normalizedHeader) {
    final aliases = <String, List<String>>{
      _normalizeTitle('numéro'): ['Nr.', 'Nr', 'N°', 'No.', 'No'],
      _normalizeTitle('activité ou tâche'): [
        'Activiteit',
        'Activity or task',
        'Tätigkeit oder Aufgabe',
      ],
      _normalizeTitle('activité'): ['Activiteit', 'Activity', 'Tätigkeit'],
      _normalizeTitle('danger'): ['Gevaar', 'Hazard', 'Gefährdung'],
      _normalizeTitle('risque ou dommage possible'): [
        'Risico',
        'Risk',
        'Risiko',
      ],
      _normalizeTitle('risque'): ['Risico', 'Risk', 'Risiko'],
      _normalizeTitle('personnes exposées'): [
        'Blootgestelde personen',
        'Exposed persons',
        'Exponierte Personen',
      ],
      _normalizeTitle('mesures existantes'): [
        'Bestaande maatregelen',
        'Existing measures',
        'Bestehende Maßnahmen',
      ],
      _normalizeTitle('preuve des mesures existantes'): [
        'Bestaand bewijs',
        'Existing evidence',
        'Vorhandene Nachweise',
      ],
      _normalizeTitle('motivering gravité'): [
        'Justification Gravité',
        'Motivering ernst',
        'Severity justification',
        'Begründung Schwere',
      ],
      _normalizeTitle('motivering probabilité'): [
        'Justification Probabilité',
        'Motivering waarschijnlijkheid',
        'Probability justification',
        'Begründung Wahrscheinlichkeit',
      ],
      _normalizeTitle('motivering exposition'): [
        'Justification Exposition',
        'Motivering blootstelling',
        'Exposure justification',
        'Begründung Exposition',
      ],
      _normalizeTitle('gravité'): ['Ernst', 'Severity', 'Schwere'],
      _normalizeTitle('probabilité'): [
        'Waarschijnlijkheid',
        'Probability',
        'Wahrscheinlichkeit',
      ],
      _normalizeTitle('exposition'): ['Blootstelling', 'Exposure'],
      _normalizeTitle('score initial'): ['Score'],
      _normalizeTitle('niveau de risque initial'): ['Niveau', 'Level'],
      _normalizeTitle('niveau'): ['Niveau', 'Level'],
      _normalizeTitle('mesures complémentaires proposées'): [
        'Aanvullende maatregelen',
        'Additional measures',
        'Zusätzliche Maßnahmen',
      ],
      _normalizeTitle('type de mesure selon la hiérarchie de prévention'): [
        'Type maatregel',
        'Type of measure',
        'Art der Maßnahme',
      ],
      _normalizeTitle('responsable'): [
        'Verantwoordelijke',
        'Responsible person',
        'Verantwortliche Person',
      ],
      _normalizeTitle('échéance'): ['Termijn', 'Deadline', 'Frist'],
      _normalizeTitle('score résiduel estimé'): [
        'Restrisico',
        'Residual risk',
        'Restrisiko',
      ],
      _normalizeTitle('score résiduel'): [
        'Restrisico',
        'Residual risk',
        'Restrisiko',
      ],
      _normalizeTitle('moyen de contrôle ou preuve attendue'): [
        'Controle/bewijs',
        'Expected control/evidence',
        'Kontrolle/erwarteter Nachweis',
      ],
      _normalizeTitle('priorité'): ['Prioriteit', 'Priority', 'Priorität'],
    };
    return aliases[normalizedHeader]
            ?.map((alias) => _normalizeTitle(alias))
            .toList() ??
        const [];
  }

  static List<String> _actionHeaderCandidates(String normalizedHeader) {
    final aliases = <String, List<String>>{
      _normalizeTitle('numéro d’action'): ['Nr.', 'Nr', 'N°', 'No.', 'No'],
      _normalizeTitle('n°'): ['Nr.', 'Nr', 'No.', 'No'],
      _normalizeTitle('risque concerné'): [
        'Betrokken risico',
        'Related risk',
        'Betroffenes Risiko',
      ],
      _normalizeTitle('mesure proposée'): [
        'Voorgestelde maatregel',
        'Proposed measure',
        'Vorgeschlagene Maßnahme',
      ],
      _normalizeTitle('objectif'): ['Doel', 'Objective', 'Ziel'],
      _normalizeTitle('responsable'): [
        'Verantwoordelijke',
        'Responsible person',
        'Verantwortliche Person',
      ],
      _normalizeTitle('échéance'): ['Termijn', 'Deadline', 'Frist'],
      _normalizeTitle('moyens nécessaires'): [
        'Benodigde middelen',
        'Required resources',
        'Erforderliche Mittel',
      ],
      _normalizeTitle('indicateur de réalisation'): ['Indicator'],
      _normalizeTitle('preuve attendue'): [
        'Verwacht bewijs',
        'Expected evidence',
        'Erwarteter Nachweis',
      ],
      _normalizeTitle('statut'): ['Status'],
    };
    return aliases[normalizedHeader]
            ?.map((alias) => _normalizeTitle(alias))
            .toList() ??
        const [];
  }

  static bool _isPlaceholderTable(List<List<String>> rows) {
    if (rows.isEmpty) {
      return true;
    }
    return rows.every((row) => row.every(_isPlaceholderCell));
  }

  static bool _isPlaceholderCell(String value) {
    final normalized = _normalizeTitle(value);
    return normalized.isEmpty ||
        _missingSectionTextsByLanguage.values.any(
          (text) => normalized == _normalizeTitle(text),
        ) ||
        normalized == _normalizeTitle('À compléter') ||
        normalized == _normalizeTitle('Non renseigné / à vérifier') ||
        normalized == _normalizeTitle('À vérifier');
  }

  static String _displayCell(String value, String language) {
    final cleaned = _cleanMarkdownText(value, language: language).trim();
    if (_isPlaceholderCell(cleaned)) {
      return _missingSectionTextForLanguage(language);
    }
    return cleaned;
  }

  static String _missingSectionTextForLanguage(String language) {
    return _missingSectionTextsByLanguage[language] ??
        _missingSectionTextsByLanguage['fr']!;
  }

  static String _actionPlanMissingTextForLanguage(String language) {
    return _actionPlanMissingTextsByLanguage[language] ??
        _actionPlanMissingTextsByLanguage['fr']!;
  }

  static String _riskTableMissingTextForLanguage(String language) {
    return _riskTableMissingTextsByLanguage[language] ??
        _riskTableMissingTextsByLanguage['fr']!;
  }

  static bool _shouldGeneratePriorities(
    _DocumentSection section,
    List<pw.Widget> contentWidgets,
    String language,
  ) {
    if (section.tableRows.isNotEmpty) {
      return false;
    }
    if (contentWidgets.isEmpty) {
      return true;
    }
    final usefulLines = section.bodyLines
        .map((line) => _cleanMarkdownText(line, language: language).trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return usefulLines.isEmpty ||
        usefulLines.every(
          (line) => _missingSectionTextsByLanguage.values.any(
            (text) => _normalizeTitle(line) == _normalizeTitle(text),
          ),
        );
  }

  static List<pw.Widget> _buildGeneratedPriorities(
    List<_RiskRow> risks,
    String language,
  ) {
    final usefulRisks = risks.where((risk) => !risk.isEmpty).toList();
    if (usefulRisks.isEmpty) {
      return const [];
    }

    usefulRisks.sort((left, right) {
      return _prioritySortRank(
        left.value('priorité'),
      ).compareTo(_prioritySortRank(right.value('priorité')));
    });

    return [
      for (var index = 0; index < usefulRisks.length; index++)
        _buildBullet(_generatedPriorityText(index, usefulRisks[index], language), language),
    ];
  }

  static String _generatedPriorityText(
    int index,
    _RiskRow risk,
    String language,
  ) {
    final number = index + 1;
    final concern = _riskConcern(risk);
    return switch (language) {
      'nl' =>
        'Prioriteit $number: $concern - actie te bepalen - verantwoordelijke - termijn - verwacht bewijs.',
      'en' =>
        'Priority $number: $concern - action to define - responsible person - deadline - expected evidence.',
      'de' =>
        'Priorität $number: $concern - Maßnahme festzulegen - verantwortliche Person - Frist - erwarteter Nachweis.',
      _ =>
        'Priorité $number : $concern - action à définir - responsable - échéance - preuve attendue.',
    };
  }

  static int _prioritySortRank(String priority) {
    final normalized = _normalizeTitle(priority);
    if (normalized.contains('haute') ||
        normalized.contains('élevée') ||
        normalized.contains('elevee')) {
      return 0;
    }
    if (normalized.contains('moyenne')) {
      return 1;
    }
    if (normalized.contains('basse') || normalized.contains('faible')) {
      return 2;
    }
    return 3;
  }

  static String _riskConcern(_RiskRow risk) {
    final riskText = risk.value(
      'risque ou dommage possible',
      fallback: 'risque',
    );
    if (riskText.isNotEmpty) {
      return riskText;
    }
    final danger = risk.value('danger');
    if (danger.isNotEmpty) {
      return danger;
    }
    return risk.value('activité ou tâche');
  }

  static pw.Widget _buildSmallRichLine(
    String label,
    String value, [
    String language = 'fr',
  ]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label : ',
              style: pw.TextStyle(
                color: _brandColor,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: _displayCell(value, language),
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xff1f2937),
                fontSize: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildHeader(
    pw.Context context, {
    required String documentType,
    required DateTime generatedAt,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xffd6dce3)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'PreventIA Belgique',
            style: pw.TextStyle(
              color: _brandColor,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9.5,
            ),
          ),
          pw.Text(
            '$documentType - ${_formatDate(generatedAt)}',
            style: const pw.TextStyle(color: _mutedColor, fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    pw.Context context,
    DateTime generatedAt,
    PdfDocumentTexts texts,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xffd6dce3)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _formatDate(generatedAt),
            style: const pw.TextStyle(color: _mutedColor, fontSize: 8),
          ),
          pw.Text(
            texts.projectStatus,
            style: pw.TextStyle(
              color: _brandColor,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(color: _mutedColor, fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitleBlock({
    required String documentType,
    required DateTime generatedAt,
    required PdfDocumentTexts texts,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PreventIA Belgique',
          style: pw.TextStyle(
            color: _brandColor,
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          texts.preventionDocumentStatus,
          style: const pw.TextStyle(
            color: PdfColor.fromInt(0xff374151),
            fontSize: 13,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xfffff7ed),
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border.all(color: const PdfColor.fromInt(0xfff59e0b)),
          ),
          child: pw.Center(
            child: pw.Text(
              texts.projectStatusUpper,
              style: pw.TextStyle(
                color: const PdfColor.fromInt(0xff92400e),
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _softBackground,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _borderColor),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSmallRichLine(texts.documentType, documentType),
              _buildSmallRichLine(texts.generatedAt, _formatDate(generatedAt)),
              _buildSmallRichLine(texts.source, texts.localPdfSource),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static List<String> _trimEmptyLines(List<String> lines) {
    var start = 0;
    var end = lines.length;
    while (start < end && lines[start].trim().isEmpty) {
      start++;
    }
    while (end > start && lines[end - 1].trim().isEmpty) {
      end--;
    }
    return lines.sublist(start, end);
  }
}

class _DocumentSectionBuilder {
  _DocumentSectionBuilder({required this.index, required this.title});

  final int index;
  String title;
  final List<String> _bodyLines = [];
  final List<List<String>> _tableRows = [];

  void setTitle(String value) {
    if (value.trim().isNotEmpty) {
      title = value.trim();
    }
  }

  void addLine(String line) {
    final cells = _parseTableLine(line);
    if (cells != null) {
      _tableRows.add(cells);
      return;
    }
    if (index == 12 && _appendActionTableContinuation(line)) {
      return;
    }
    _bodyLines.add(line);
  }

  bool _appendActionTableContinuation(String line) {
    final cleaned = PdfExportService._cleanMarkdownText(line).trim();
    if (cleaned.isEmpty || _tableRows.length < 2) {
      return false;
    }
    final lastRow = _tableRows.last;
    if (lastRow.isEmpty) {
      return false;
    }
    final targetIndex = lastRow.length > 2 ? 2 : lastRow.length - 1;
    lastRow[targetIndex] = '${lastRow[targetIndex]}\n$cleaned'.trim();
    return true;
  }

  _DocumentSection build() {
    return _DocumentSection(
      index: index,
      title: title,
      bodyLines: PdfExportService._trimEmptyLines(_bodyLines),
      tableRows: _tableRows,
    );
  }

  List<String>? _parseTableLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('|') || !trimmed.endsWith('|')) {
      return null;
    }
    if (PdfExportService._isMarkdownSeparatorLine(trimmed)) {
      return null;
    }
    final cells = trimmed
        .substring(1, trimmed.length - 1)
        .split('|')
        .map((cell) => PdfExportService._cleanMarkdownText(cell))
        .toList();
    if (cells.every((cell) => cell.trim().isEmpty)) {
      return null;
    }
    return cells;
  }
}

class _ParsedDocument {
  const _ParsedDocument({required this.introLines, required this.sections});

  final List<String> introLines;
  final List<_DocumentSection> sections;
}

class _DocumentSection {
  const _DocumentSection({
    required this.index,
    required this.title,
    required this.bodyLines,
    required this.tableRows,
  });

  final int index;
  final String title;
  final List<String> bodyLines;
  final List<List<String>> tableRows;
}

class _SectionInfo {
  const _SectionInfo({required this.index, required this.title});

  final int index;
  final String title;
}

class _RiskRow {
  const _RiskRow(this.values);

  final Map<String, String> values;

  bool get isEmpty => values.values.every((value) => value.trim().isEmpty);

  String value(String key, {String? fallback}) {
    final normalized = PdfExportService._normalizeTitle(key);
    final fallbackNormalized = fallback == null
        ? null
        : PdfExportService._normalizeTitle(fallback);
    final fallbackAliases = fallbackNormalized == null
        ? null
        : PdfExportService._riskHeaderCandidates(fallbackNormalized);
    final candidates = [
      normalized,
      ...PdfExportService._riskHeaderCandidates(normalized),
      ?fallbackNormalized,
      ...?fallbackAliases,
    ];
    for (final candidate in candidates) {
      final value = values[candidate];
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}

class _ActionRow {
  const _ActionRow(this.values);

  final Map<String, String> values;

  bool get isEmpty => values.values.every((value) => value.trim().isEmpty);

  bool get isValid {
    final number = value('numéro d’action', fallback: 'n°');
    final measure = value('mesure proposée');
    final responsible = value('responsable');
    final deadline = value('échéance');
    return number.isNotEmpty &&
        measure.isNotEmpty &&
        (responsible.isNotEmpty || deadline.isNotEmpty);
  }

  String value(String key, {String? fallback}) {
    final normalized = PdfExportService._normalizeTitle(key);
    final fallbackNormalized = fallback == null
        ? null
        : PdfExportService._normalizeTitle(fallback);
    final fallbackAliases = fallbackNormalized == null
        ? null
        : PdfExportService._actionHeaderCandidates(fallbackNormalized);
    final candidates = [
      normalized,
      ...PdfExportService._actionHeaderCandidates(normalized),
      ?fallbackNormalized,
      ...?fallbackAliases,
    ];
    for (final candidate in candidates) {
      final value = values[candidate];
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}
