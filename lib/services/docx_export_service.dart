import 'dart:convert';
import 'dart:typed_data';

import '../models/document_family.dart';
import 'pdf_export_service.dart';
import 'risk_advisor_block_service.dart';

class DocxExportService {
  const DocxExportService._();

  static const int _mainRiskFirstPartColumnCount = 16;

  static Uint8List buildRiskAssessmentDocx({
    required String documentType,
    required String content,
    required DateTime generatedAt,
    String? referenceNumber,
    String? languageCode,
  }) {
    final detectedLanguage =
        languageCode ?? PdfExportService.detectDocumentLanguage(content);
    final localized = PdfExportService.normalizePdfContent(
      rawMarkdown: content,
      documentType: documentType,
      languageCode: detectedLanguage,
      documentFamily: DocumentFamily.riskAssessment,
    );
    final exportMarkdown =
        PdfExportService.traceAndRemoveDuplicateLeadingReferenceDateBlock(
          localized.rawMarkdown,
        );
    final language = localized.languageCode;
    final hasBackendHeader = PdfExportService.hasLeadingReferenceDateBlock(
      content,
    );
    final resolvedReference = PdfExportService.resolveDocumentReference(
      metadataDocumentReference: referenceNumber,
      content: exportMarkdown,
    );
    final builder = _DocxDocumentBuilder(
      languageCode: language,
      footerReferenceNumber: resolvedReference,
    );

    if (!hasBackendHeader) {
      builder.addTitle(localized.documentTitle);
      if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
        builder.addLabelValue(
          _referenceLabel(language),
          referenceNumber.trim(),
        );
      }
      builder.addLabelValue(_dateLabel(language), _formatDate(generatedAt));
      builder.addParagraph('');
    }

    _appendRiskAssessmentContent(
      builder,
      exportMarkdown,
      language,
      documentTitle: hasBackendHeader ? '' : localized.documentTitle,
    );

    return _OpenXmlPackage(
      documentXml: builder.build(),
      footerXml: builder.buildFooter(),
      languageCode: language,
    ).toBytes();
  }

  static void _appendRiskAssessmentContent(
    _DocxDocumentBuilder builder,
    String content,
    String language, {
    required String documentTitle,
  }) {
    final parsed = _parseRiskAssessment(content, language, documentTitle);

    if (parsed.introLines.isNotEmpty) {
      _appendMarkdownContent(
        builder,
        parsed.introLines.join('\n'),
        language,
        documentTitle: documentTitle,
        appendValidationNotice: false,
      );
    }

    for (final section in parsed.sections) {
      if (_isValidationSection(section.title)) {
        continue;
      }
      final isLandscape = _sectionNeedsLandscape(section);
      builder.ensureOrientation(
        isLandscape
            ? _DocxPageOrientation.landscape
            : _DocxPageOrientation.portrait,
      );
      builder.addHeading('${section.index}. ${section.title}', 2);
      if (section.blocks.where((block) => block.tableRows != null).length > 1) {
        for (final block in section.blocks) {
          final text = block.text;
          final tableRows = block.tableRows;
          if (text != null) {
            _appendMarkdownContent(
              builder,
              text,
              language,
              documentTitle: documentTitle,
              appendValidationNotice: false,
            );
          } else if (tableRows != null && tableRows.isNotEmpty) {
            builder.addTable(tableRows, forceWide: isLandscape);
          }
        }
      } else {
        if (section.bodyLines.isNotEmpty) {
          _appendMarkdownContent(
            builder,
            section.bodyLines.join('\n'),
            language,
            documentTitle: documentTitle,
            appendValidationNotice: false,
          );
        }
        if (section.tableRows.isNotEmpty) {
          if (_isMainRiskTableSection(section) &&
              _tableColumnCount(section.tableRows) >
                  _mainRiskFirstPartColumnCount) {
            final parts = _splitMainRiskTable(section.tableRows, language);
            builder.addHeading(parts.firstTitle, 3);
            builder.addTable(parts.firstRows, forceWide: true);
            builder.addHeading(parts.secondTitle, 3);
            builder.addTable(parts.secondRows, forceWide: true);
          } else {
            builder.addTable(section.tableRows, forceWide: isLandscape);
          }
        }
      }
    }

    builder.ensureOrientation(_DocxPageOrientation.portrait);
    builder.addValidationNotice(
      PdfExportService.localizedValidationHeading(language),
      PdfExportService.localizedValidationText(language),
    );
  }

  static _ParsedRiskAssessment _parseRiskAssessment(
    String content,
    String language,
    String documentTitle,
  ) {
    final titles =
        _riskSectionTitlesByLanguage[language] ??
        _riskSectionTitlesByLanguage['fr']!;
    final builders = {
      for (var index = 1; index <= titles.length; index++)
        index: _RiskSectionBuilder(index: index, title: titles[index - 1]),
    };
    final introLines = <String>[];
    var currentIndex = 0;

    for (final rawLine in content.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (currentIndex == 0) {
          if (introLines.isNotEmpty) introLines.add('');
        } else {
          builders[currentIndex]!.addLine('');
        }
        continue;
      }

      final cleaned = _cleanMarkdownText(trimmed);
      if (cleaned.isEmpty) {
        if (currentIndex == 0) {
          introLines.add(line);
        } else if (!_isValidationSection(builders[currentIndex]!.title)) {
          builders[currentIndex]!.addLine(line);
        }
        continue;
      }
      if (_sameText(cleaned, documentTitle) || _isValidationNotice(cleaned)) {
        continue;
      }

      final section = _parseRiskSectionTitle(cleaned, language);
      if (section != null) {
        currentIndex = section.index;
        builders[currentIndex]!.title = section.title;
        continue;
      }

      if (currentIndex != 0 &&
          _isValidationSection(builders[currentIndex]!.title)) {
        continue;
      }

      if (currentIndex == 0) {
        introLines.add(line);
      } else {
        builders[currentIndex]!.addLine(line);
      }
    }

    return _ParsedRiskAssessment(
      introLines: _trimEmptyLines(introLines),
      sections: List.generate(
        titles.length,
        (index) => builders[index + 1]!.build(),
      ),
    );
  }

  static _RiskSectionInfo? _parseRiskSectionTitle(
    String line,
    String language,
  ) {
    final titles =
        _riskSectionTitlesByLanguage[language] ??
        _riskSectionTitlesByLanguage['fr']!;
    final numbered = RegExp(r'^(\d{1,2})[\.)]\s+(.+)$').firstMatch(line);
    if (numbered != null) {
      final index = int.tryParse(numbered.group(1)!);
      if (index != null && index >= 1 && index <= titles.length) {
        final title = _cleanSectionTitle(numbered.group(2) ?? '');
        return _RiskSectionInfo(index, title);
      }
    }

    final title = _cleanSectionTitle(line);
    final index = titles.indexWhere((known) => _sameText(known, title)) + 1;
    if (index > 0) {
      return _RiskSectionInfo(index, titles[index - 1]);
    }
    for (final localizedTitles in _riskSectionTitlesByLanguage.values) {
      final otherIndex =
          localizedTitles.indexWhere((known) => _sameText(known, title)) + 1;
      if (otherIndex > 0 && otherIndex <= titles.length) {
        return _RiskSectionInfo(otherIndex, titles[otherIndex - 1]);
      }
    }
    return null;
  }

  static bool _isValidationSection(String title) {
    return [
      'Mention de validation',
      'Mention finale obligatoire',
      'Validatievermelding',
      'Validation Statement',
      'Validation notice',
      'Validation statement',
      'Mandatory final statement',
      'Validierungshinweis',
      'Verbindlicher Abschlusshinweis',
    ].any((knownTitle) => _sameText(knownTitle, title));
  }

  static bool _isMainRiskTableSection(_RiskSection section) {
    final normalizedTitle = _normalizeForComparison(section.title);
    return section.index == 9 ||
        section.index == 12 ||
        [
          'tableau principal d analyse des risques',
          'main risk assessment table',
          'hoofdtabel van de risicoanalyse',
          'haupttabelle der gefahrdungsbeurteilung',
        ].contains(normalizedTitle);
  }

  static bool _sectionNeedsLandscape(_RiskSection section) {
    if (section.index == 9 || _isMainRiskTableSection(section)) {
      return true;
    }
    if (section.tableRows.isEmpty) {
      return false;
    }
    final columnCount = section.tableRows.fold<int>(
      0,
      (max, row) => row.length > max ? row.length : max,
    );
    if (columnCount > 6) {
      return true;
    }
    final normalizedTitle = _normalizeForComparison(section.title);
    return [
      'tableau principal d analyse des risques',
      'analyse des risques residuels',
      'projet de plan d action',
      'evaluation de completude',
      'main risk assessment table',
      'residual risk assessment',
      'draft action plan',
      'completeness assessment',
      'hoofdtabel van de risicoanalyse',
      'analyse van restrisicos',
      'ontwerp van actieplan',
      'hulptabel volledigheid',
      'haupttabelle der gefahrdungsbeurteilung',
      'beurteilung der restrisiken',
      'entwurf eines massnahmenplans',
    ].contains(normalizedTitle);
  }

  static int _tableColumnCount(List<List<String>> rows) {
    return rows.fold<int>(0, (max, row) => row.length > max ? row.length : max);
  }

  static _SplitRiskTable _splitMainRiskTable(
    List<List<String>> rows,
    String language,
  ) {
    final columnCount = _tableColumnCount(rows);
    final splitIndex = _mainRiskFirstPartColumnCount;
    return _SplitRiskTable(
      firstTitle: _mainRiskSplitTitle(language, firstPart: true),
      firstRows: _projectTableColumns(rows, [
        for (var index = 0; index < splitIndex; index++) index,
      ]),
      secondTitle: _mainRiskSplitTitle(language, firstPart: false),
      secondRows: _projectTableColumns(rows, [
        0,
        for (var index = splitIndex; index < columnCount; index++) index,
      ]),
    );
  }

  static List<List<String>> _projectTableColumns(
    List<List<String>> rows,
    List<int> indexes,
  ) {
    return rows
        .map(
          (row) => indexes
              .map((index) => index < row.length ? row[index] : '')
              .toList(),
        )
        .toList();
  }

  static String _mainRiskSplitTitle(
    String language, {
    required bool firstPart,
  }) {
    if (firstPart) {
      return switch (language) {
        'nl' => 'Hoofdtabel A - Risicobeoordeling',
        'en' => 'Main table A - Risk evaluation',
        'de' => 'Haupttabelle A - Risikobewertung',
        _ => 'Tableau principal A - Évaluation du risque',
      };
    }
    return switch (language) {
      'nl' => 'Hoofdtabel B - Maatregelen en opvolging',
      'en' => 'Main table B - Measures and follow-up',
      'de' => 'Haupttabelle B - Maßnahmen und Nachverfolgung',
      _ => 'Tableau principal B - Mesures, suivi et validation',
    };
  }

  static void _appendMarkdownContent(
    _DocxDocumentBuilder builder,
    String content,
    String language, {
    required String documentTitle,
    bool enableAdvisorParsing = true,
    bool appendValidationNotice = true,
  }) {
    if (enableAdvisorParsing) {
      final segments = RiskAdvisorBlockService.parseSegments(
        content,
        languageCode: language,
      );
      if (segments.any((segment) => segment.block != null)) {
        for (final segment in segments) {
          final block = segment.block;
          if (block != null) {
            builder.addAdvisorBlock(block);
            continue;
          }
          final text = segment.text;
          if (text == null || text.trim().isEmpty) {
            continue;
          }
          _appendMarkdownContent(
            builder,
            text,
            language,
            documentTitle: documentTitle,
            enableAdvisorParsing: false,
            appendValidationNotice: false,
          );
        }
        return;
      }
    }

    final tableRows = <List<String>>[];

    void flushTable() {
      if (tableRows.isEmpty) {
        return;
      }
      builder.addTable(tableRows);
      tableRows.clear();
    }

    for (final rawLine in content.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();
      final tableCells = _parseRawTableLine(trimmed);
      if (tableCells != null) {
        tableRows.add(tableCells);
        continue;
      }
      flushTable();

      if (trimmed.isEmpty) {
        builder.addParagraph('');
        continue;
      }
      final cleanedLine = _cleanMarkdownText(trimmed);
      if (_isValidationNotice(cleanedLine)) {
        continue;
      }
      if (RegExp(
        r'^\|\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|$',
      ).hasMatch(trimmed)) {
        continue;
      }

      final heading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
      if (heading != null) {
        final headingText = _cleanMarkdownText(heading.group(2) ?? '');
        if (!appendValidationNotice && _isValidationHeading(headingText)) {
          continue;
        }
        if (_sameText(headingText, documentTitle)) {
          continue;
        }
        builder.addHeading(headingText, heading.group(1)!.length);
        continue;
      }

      final numberedHeading = RegExp(
        r'^(\d{1,2})[\.)]\s+(.+)$',
      ).firstMatch(trimmed);
      if (numberedHeading != null) {
        builder.addHeading(
          '${numberedHeading.group(1)}. '
          '${_cleanMarkdownText(numberedHeading.group(2) ?? '')}',
          2,
        );
        continue;
      }

      final segments = RiskAdvisorBlockService.parseSegments(
        line,
        languageCode: language,
      );
      for (final segment in segments) {
        final block = segment.block;
        if (block != null) {
          builder.addAdvisorBlock(block);
        } else {
          for (final part in (segment.text ?? '').split('\n')) {
            final cleaned = _cleanMarkdownText(part);
            if (cleaned.isEmpty) {
              continue;
            }
            final bullet = RegExp(r'^[-*]\s+(.+)$').firstMatch(cleaned);
            if (bullet != null) {
              builder.addBullet(_cleanMarkdownText(bullet.group(1) ?? ''));
            } else {
              builder.addParagraph(cleaned);
            }
          }
        }
      }
    }
    flushTable();

    if (appendValidationNotice &&
        !_containsValidationHeading(content, language)) {
      builder.addValidationNotice(
        PdfExportService.localizedValidationHeading(language),
        PdfExportService.localizedValidationText(language),
      );
    }
  }

  static bool _containsValidationHeading(String content, String language) {
    final heading = PdfExportService.localizedValidationHeading(
      language,
    ).toLowerCase();
    return content.toLowerCase().contains(heading);
  }

  static List<String>? _parseRawTableLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('|') || !trimmed.endsWith('|')) {
      return null;
    }
    final cells = trimmed
        .substring(1, trimmed.length - 1)
        .split('|')
        .map((cell) => _cleanMarkdownText(cell))
        .toList();
    if (cells.every((cell) {
      final value = cell.trim();
      return value.isEmpty || RegExp(r'^:?-{3,}:?$').hasMatch(value);
    })) {
      return null;
    }
    return cells;
  }

  static String _cleanMarkdownText(String text) {
    return RiskAdvisorBlockService.stripAdvisorTags(text)
        .replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match[1]!)
        .replaceAllMapped(RegExp(r'__([^_]+)__'), (match) => match[1]!)
        .replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match[1]!)
        .replaceFirst(RegExp(r'^\s*#{1,6}\s*'), '')
        .trim();
  }

  static bool _isValidationNotice(String text) {
    final normalized = _normalizeForComparison(text);
    if (_isValidationHeading(text)) {
      return true;
    }
    return [
      'ce document est un projet a adapter',
      'dit document is een ontwerp dat moet worden aangepast',
      'this document is a draft that must be adapted',
      'dieses dokument ist ein entwurf',
    ].any((start) => normalized.contains(_normalizeForComparison(start)));
  }

  static bool _isValidationHeading(String text) {
    final cleaned = text.replaceFirst(RegExp(r'^\d+\s*[.)-]?\s*'), '');
    final normalized = _normalizeForComparison(cleaned);
    return [
      'mention de validation',
      'mention finale obligatoire',
      'validatievermelding',
      'validation statement',
      'mandatory final statement',
      'validierungshinweis',
      'verbindlicher abschlusshinweis',
    ].contains(normalized);
  }

  static String _cleanSectionTitle(String text) {
    return _cleanMarkdownText(text).replaceAll(RegExp(r':$'), '').trim();
  }

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

  static bool _sameText(String left, String right) {
    return _normalizeForComparison(left) == _normalizeForComparison(right);
  }

  static String _normalizeForComparison(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('û', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('œ', 'oe')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static String _referenceLabel(String language) {
    return switch (language) {
      'nl' => 'Referentie',
      'en' => 'Reference',
      'de' => 'Referenz',
      _ => 'Référence',
    };
  }

  static String _dateLabel(String language) {
    return switch (language) {
      'nl' => 'Datum',
      'en' => 'Date',
      'de' => 'Datum',
      _ => 'Date',
    };
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static const Map<String, List<String>> _riskSectionTitlesByLanguage = {
    'fr': [
      'Identification du document',
      'Contexte et objectif',
      'Références réglementaires belges applicables',
      'Glossaire des abréviations utilisées',
      'Périmètre de l’analyse',
      'Sources d’information utilisées ou à obtenir',
      'Hypothèses et limites',
      'Description des postes, tâches et travailleurs exposés',
      'Plan photos',
      'Identification détaillée des dangers',
      'Méthode de cotation',
      'Tableau principal d’analyse des risques',
      'Analyse des risques résiduels',
      'Priorités d’action',
      'Projet de plan d’action',
      'Lien avec le Plan Annuel d’Action et le Plan Global de Prévention',
      'Documents à créer ou à mettre à jour',
      'Acteurs à consulter ou à impliquer',
      'Annexes nécessaires',
      'Limites d’intervention du conseiller en prévention niveau 3',
      'Points bloquants avant validation',
      'Conclusion',
      'Mention de validation',
    ],
    'nl': [
      'Identificatie van het document',
      'Context en doelstelling',
      'Toepasselijke Belgische regelgevende referenties',
      'Glossarium van gebruikte afkortingen',
      'Afbakening van de analyse',
      'Gebruikte of nog te verkrijgen informatiebronnen',
      'Hypothesen en beperkingen',
      'Beschrijving van functies, taken en blootgestelde werknemers',
      'Fotoplan',
      'Gedetailleerde identificatie van de gevaren',
      'Beoordelingsmethode',
      'Hoofdtabel van de risicoanalyse',
      'Analyse van de restrisico’s',
      'Prioritaire acties',
      'Ontwerpactieplan',
      'Verband met het Jaaractieplan en het Globaal Preventieplan',
      'Documenten die moeten worden opgesteld of bijgewerkt',
      'Te raadplegen of te betrekken actoren',
      'Noodzakelijke bijlagen',
      'Grenzen van de tussenkomst van de preventieadviseur niveau 3',
      'Blokkerende punten vóór validatie',
      'Conclusie',
      'Validatievermelding',
    ],
    'en': [
      'Document identification',
      'Context and objective',
      'Applicable Belgian regulatory references',
      'Glossary of abbreviations used',
      'Scope of the assessment',
      'Information sources used or to be obtained',
      'Assumptions and limitations',
      'Description of jobs, tasks and exposed workers',
      'Photo plan',
      'Detailed identification of hazards',
      'Scoring method',
      'Main risk assessment table',
      'Residual risk analysis',
      'Action priorities',
      'Draft action plan',
      'Link with the Annual Action Plan and the Global Prevention Plan',
      'Documents to create or update',
      'Actors to consult or involve',
      'Required annexes',
      'Limits of intervention of the level 3 prevention advisor',
      'Blocking points before validation',
      'Conclusion',
      'Validation statement',
    ],
    'de': [
      'Dokumentidentifikation',
      'Kontext und Zielsetzung',
      'Anwendbare belgische regulatorische Referenzen',
      'Glossar der verwendeten Abkürzungen',
      'Umfang der Beurteilung',
      'Verwendete oder noch zu beschaffende Informationsquellen',
      'Annahmen und Einschränkungen',
      'Beschreibung der Arbeitsplätze, Tätigkeiten und exponierten Beschäftigten',
      'Fotoplan',
      'Detaillierte Identifikation der Gefährdungen',
      'Bewertungsmethode',
      'Haupttabelle der Gefährdungsbeurteilung',
      'Analyse der Restrisiken',
      'Handlungsprioritäten',
      'Entwurf des Maßnahmenplans',
      'Verbindung mit dem Jährlichen Aktionsplan und dem Globalen Präventionsplan',
      'Zu erstellende oder zu aktualisierende Dokumente',
      'Zu konsultierende oder einzubeziehende Akteure',
      'Erforderliche Anhänge',
      'Grenzen der Mitwirkung des Präventionsberaters Niveau 3',
      'Blockierende Punkte vor der Validierung',
      'Schlussfolgerung',
      'Validierungshinweis',
    ],
  };
}

class _ParsedRiskAssessment {
  const _ParsedRiskAssessment({
    required this.introLines,
    required this.sections,
  });

  final List<String> introLines;
  final List<_RiskSection> sections;
}

class _SplitRiskTable {
  const _SplitRiskTable({
    required this.firstTitle,
    required this.firstRows,
    required this.secondTitle,
    required this.secondRows,
  });

  final String firstTitle;
  final List<List<String>> firstRows;
  final String secondTitle;
  final List<List<String>> secondRows;
}

class _RiskSection {
  const _RiskSection({
    required this.index,
    required this.title,
    required this.bodyLines,
    required this.tableRows,
    required this.blocks,
  });

  final int index;
  final String title;
  final List<String> bodyLines;
  final List<List<String>> tableRows;
  final List<_RiskContentBlock> blocks;
}

class _RiskSectionBuilder {
  _RiskSectionBuilder({required this.index, required this.title});

  final int index;
  String title;
  final List<String> bodyLines = [];
  final List<List<String>> tableRows = [];
  final List<_RiskContentBlock> blocks = [];

  void addLine(String line) {
    final trimmed = line.trim();
    if (RegExp(
      r'^\|\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|$',
    ).hasMatch(trimmed)) {
      return;
    }
    final tableCells = DocxExportService._parseRawTableLine(trimmed);
    if (tableCells != null) {
      tableRows.add(tableCells);
      if (blocks.isNotEmpty && blocks.last.tableRows != null) {
        blocks.last.tableRows!.add(List<String>.of(tableCells));
      } else {
        blocks.add(_RiskContentBlock.table([List<String>.of(tableCells)]));
      }
      return;
    }
    bodyLines.add(line);
    blocks.add(_RiskContentBlock.text(line));
  }

  _RiskSection build() {
    return _RiskSection(
      index: index,
      title: title,
      bodyLines: DocxExportService._trimEmptyLines(bodyLines),
      tableRows: tableRows,
      blocks: _trimBlocks(blocks),
    );
  }

  List<_RiskContentBlock> _trimBlocks(List<_RiskContentBlock> value) {
    var start = 0;
    var end = value.length;
    while (start < end && (value[start].text?.trim().isEmpty ?? false)) {
      start++;
    }
    while (end > start && (value[end - 1].text?.trim().isEmpty ?? false)) {
      end--;
    }
    return value.sublist(start, end);
  }
}

class _RiskContentBlock {
  const _RiskContentBlock._({this.text, this.tableRows});

  factory _RiskContentBlock.text(String text) {
    return _RiskContentBlock._(text: text);
  }

  factory _RiskContentBlock.table(List<List<String>> rows) {
    return _RiskContentBlock._(tableRows: rows);
  }

  final String? text;
  final List<List<String>>? tableRows;
}

class _RiskSectionInfo {
  const _RiskSectionInfo(this.index, this.title);

  final int index;
  final String title;
}

enum _DocxPageOrientation { portrait, landscape }

class _DocxDocumentBuilder {
  _DocxDocumentBuilder({
    required this.languageCode,
    required this.footerReferenceNumber,
  });

  final String languageCode;
  final String? footerReferenceNumber;
  final StringBuffer _body = StringBuffer();
  _DocxPageOrientation _orientation = _DocxPageOrientation.portrait;

  String build() {
    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
$_body
    ${_sectionProperties(_orientation)}
  </w:body>
</w:document>
''';
  }

  String buildFooter() {
    final referencePart = footerReferenceNumber == null
        ? null
        : '${PdfExportService.documentReferenceLabel(languageCode)} $footerReferenceNumber — ';
    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p>
    <w:pPr><w:jc w:val="right"/></w:pPr>
    <w:r><w:rPr><w:color w:val="374151"/><w:sz w:val="15"/></w:rPr><w:t xml:space="preserve">${_escapeXml(referencePart ?? '')}${_escapeXml(PdfExportService.documentPageLabel(languageCode))} </w:t></w:r>
    ${_fieldRun('PAGE')}
    <w:r><w:rPr><w:color w:val="374151"/><w:sz w:val="15"/></w:rPr><w:t xml:space="preserve"> / </w:t></w:r>
    ${_fieldRun('NUMPAGES')}
  </w:p>
</w:ftr>
''';
  }

  void ensureOrientation(_DocxPageOrientation orientation) {
    if (_orientation == orientation) {
      return;
    }
    _body.writeln(
      '<w:p><w:pPr>${_sectionProperties(_orientation)}</w:pPr></w:p>',
    );
    _orientation = orientation;
  }

  void addTitle(String text) {
    _body.writeln(_paragraph(text, style: 'Title'));
  }

  void addHeading(String text, int level) {
    final style = level <= 1 ? 'Heading1' : 'Heading2';
    _body.writeln(_paragraph(text, style: style));
  }

  void addLabelValue(String label, String value) {
    _body.writeln(
      _paragraph('$label : $value', boldPrefixLength: '$label :'.length),
    );
  }

  void addParagraph(String text) {
    _body.writeln(_paragraph(text));
  }

  void addBullet(String text) {
    _body.writeln(_paragraph('• $text'));
  }

  void addAdvisorBlock(RiskAdvisorBlock block) {
    final colors = _blockColors(block.type);
    final title = RiskAdvisorBlockService.localizedTitle(
      block.type,
      languageCode,
    );
    _body.writeln('''
    <w:tbl>
      <w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="8" w:color="${colors.border}"/><w:left w:val="single" w:sz="8" w:color="${colors.border}"/><w:bottom w:val="single" w:sz="8" w:color="${colors.border}"/><w:right w:val="single" w:sz="8" w:color="${colors.border}"/></w:tblBorders></w:tblPr>
      <w:tr><w:tc><w:tcPr><w:tcW w:w="0" w:type="auto"/><w:shd w:val="clear" w:color="auto" w:fill="${colors.fill}"/></w:tcPr>
        ${_paragraph(title, bold: true)}
        ${block.content.split('\n').where((line) => line.trim().isNotEmpty).map((line) => _paragraph(line.trim())).join('\n')}
      </w:tc></w:tr>
    </w:tbl>
''');
  }

  void addValidationNotice(String title, String text) {
    _body.writeln('''
    <w:tbl>
      <w:tblPr><w:tblW w:w="5000" w:type="pct"/><w:tblBorders><w:top w:val="single" w:sz="8" w:color="12355B"/><w:left w:val="single" w:sz="8" w:color="12355B"/><w:bottom w:val="single" w:sz="8" w:color="12355B"/><w:right w:val="single" w:sz="8" w:color="12355B"/></w:tblBorders></w:tblPr>
      <w:tr><w:tc><w:tcPr><w:tcW w:w="5000" w:type="pct"/><w:shd w:val="clear" w:color="auto" w:fill="EEF6FF"/></w:tcPr>
        ${_paragraph(title, bold: true)}
        ${_paragraph(text)}
      </w:tc></w:tr>
    </w:tbl>
''');
  }

  void addTable(List<List<String>> rows, {bool forceWide = false}) {
    final visibleRows = rows
        .where(
          (row) =>
              row.any((cell) => cell.trim().isNotEmpty) && !_isSeparator(row),
        )
        .toList();
    if (visibleRows.isEmpty) {
      return;
    }
    final maxColumns = visibleRows.fold<int>(
      0,
      (max, row) => row.length > max ? row.length : max,
    );
    final isWide = forceWide || maxColumns > 6;
    final isVeryWide = maxColumns > 12;
    final fontSize = isWide
        ? (maxColumns > 20 ? 13 : (isVeryWide ? 14 : 15))
        : 19;
    final cellMargin = isVeryWide ? 18 : (isWide ? 28 : 72);
    final columnWidths = _columnWidths(visibleRows.first, compact: isVeryWide);
    _body.writeln(
      '<w:tbl><w:tblPr><w:tblStyle w:val="TableGrid"/><w:tblW w:w="5000" w:type="pct"/><w:tblLayout w:type="autofit"/><w:tblCellMar><w:top w:w="$cellMargin" w:type="dxa"/><w:left w:w="$cellMargin" w:type="dxa"/><w:bottom w:w="$cellMargin" w:type="dxa"/><w:right w:w="$cellMargin" w:type="dxa"/></w:tblCellMar><w:tblBorders><w:top w:val="single" w:sz="4" w:color="CBD5E1"/><w:left w:val="single" w:sz="4" w:color="CBD5E1"/><w:bottom w:val="single" w:sz="4" w:color="CBD5E1"/><w:right w:val="single" w:sz="4" w:color="CBD5E1"/><w:insideH w:val="single" w:sz="4" w:color="CBD5E1"/><w:insideV w:val="single" w:sz="4" w:color="CBD5E1"/></w:tblBorders></w:tblPr><w:tblGrid>${columnWidths.map((width) => '<w:gridCol w:w="$width"/>').join()} </w:tblGrid>',
    );
    for (var rowIndex = 0; rowIndex < visibleRows.length; rowIndex++) {
      final row = visibleRows[rowIndex];
      final rowPr = rowIndex == 0
          ? '<w:trPr><w:tblHeader/><w:cantSplit/></w:trPr>'
          : rowIndex == 1
          ? '<w:trPr><w:cantSplit/></w:trPr>'
          : '';
      _body.writeln('<w:tr>$rowPr');
      for (var index = 0; index < maxColumns; index++) {
        final rawCell = index < row.length ? row[index] : '';
        final cell = rowIndex == 0 && isVeryWide
            ? _shortHeader(rawCell)
            : rawCell;
        final gridWidth = index < columnWidths.length
            ? columnWidths[index]
            : columnWidths.last;
        final tcPr = rowIndex == 0
            ? '<w:tcPr><w:tcW w:w="$gridWidth" w:type="dxa"/><w:shd w:val="clear" w:fill="12355B"/></w:tcPr>'
            : '<w:tcPr><w:tcW w:w="$gridWidth" w:type="dxa"/></w:tcPr>';
        _body.writeln(
          '<w:tc>$tcPr${_paragraph(cell, bold: rowIndex == 0, color: rowIndex == 0 ? 'FFFFFF' : null, fontSize: fontSize, keepNext: rowIndex == 0, keepLines: rowIndex <= 1)}</w:tc>',
        );
      }
      _body.writeln('</w:tr>');
    }
    _body.writeln('</w:tbl>');
  }

  static bool _isSeparator(List<String> row) {
    return row.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell.trim()));
  }

  static List<int> _columnWidths(
    List<String> headers, {
    required bool compact,
  }) {
    final weights = headers
        .map(
          (header) => _columnWeight(
            DocxExportService._normalizeForComparison(header),
            compact,
          ),
        )
        .toList();
    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);
    final totalWidth = compact ? 15400 : 14800;
    return weights
        .map((weight) => (totalWidth * weight / totalWeight).round())
        .toList();
  }

  static double _columnWeight(String normalizedHeader, bool compact) {
    if ([
      'n',
      'no',
      'nr',
      'g',
      'p',
      'e',
      'score',
      'score initial',
      'niveau',
      'niveau initial',
      'priorite',
      'priority',
      'deadline',
      'echeance',
    ].contains(normalizedHeader)) {
      return compact ? 0.35 : 0.45;
    }
    if ([
      'justification',
      'mesure',
      'measure',
      'preuve',
      'evidence',
      'situation',
    ].any(normalizedHeader.contains)) {
      return compact ? 1.35 : 1.5;
    }
    if ([
      'activite',
      'activity',
      'danger',
      'hazard',
      'risque',
      'risk',
      'responsable',
      'responsible',
    ].any(normalizedHeader.contains)) {
      return compact ? 0.95 : 1.15;
    }
    return compact ? 0.7 : 1;
  }

  static String _shortHeader(String value) {
    final normalized = DocxExportService._normalizeForComparison(value);
    return {
          'numero': 'N°',
          'activity or task': 'Task',
          'activite ou tache': 'Tâche',
          'situation dangereuse': 'Situation',
          'personnes exposees': 'Exposés',
          'exposed persons': 'Exposed',
          'mesures existantes': 'Mesures exist.',
          'existing measures': 'Existing',
          'preuves existantes': 'Preuves',
          'existing evidence': 'Evidence',
          'score initial': 'Score init.',
          'niveau initial': 'Niveau init.',
          'niveau de risque initial': 'Niveau init.',
          'mesure complementaire': 'Mesure',
          'mesures complementaires proposees': 'Mesure',
          'score residuel': 'Score rés.',
          'score residuel estime': 'Score rés.',
          'justification du score residuel': 'Justif. rés.',
          'preuve attendue': 'Preuve',
          'photo a inserer': 'Photo',
          'annexe a joindre': 'Annexe',
          'point bloquant': 'Blocage',
          'avis externe': 'Avis ext.',
          'responsible person': 'Owner',
          'deadline': 'Due',
          'priority': 'Prio.',
        }[normalized] ??
        value;
  }

  static String _paragraph(
    String text, {
    String? style,
    bool bold = false,
    int? boldPrefixLength,
    String? color,
    int? fontSize,
    bool keepNext = false,
    bool keepLines = false,
  }) {
    final escaped = _escapeXml(text);
    final keepNextXml = keepNext || style == 'Heading1' || style == 'Heading2'
        ? '<w:keepNext/>'
        : '';
    final keepLinesXml = keepLines ? '<w:keepLines/>' : '';
    final pPr =
        '$keepNextXml$keepLinesXml'
        '${style == null ? '' : '<w:pStyle w:val="$style"/>'}';
    final pStyle = pPr.isEmpty ? '' : '<w:pPr>$pPr</w:pPr>';
    final runProperties = _runProperties(
      bold: bold,
      color: color,
      fontSize: fontSize,
    );
    if (boldPrefixLength != null &&
        boldPrefixLength > 0 &&
        boldPrefixLength < text.length) {
      final prefix = _escapeXml(text.substring(0, boldPrefixLength));
      final suffix = _escapeXml(text.substring(boldPrefixLength));
      return '<w:p>$pStyle<w:r>${_runProperties(bold: true, color: color, fontSize: fontSize)}<w:t xml:space="preserve">$prefix</w:t></w:r><w:r>$runProperties<w:t xml:space="preserve">$suffix</w:t></w:r></w:p>';
    }
    return '<w:p>$pStyle<w:r>$runProperties<w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
  }

  static String _runProperties({
    bool bold = false,
    String? color,
    int? fontSize,
  }) {
    final values = [
      if (bold) '<w:b/>',
      if (color != null) '<w:color w:val="$color"/>',
      if (fontSize != null) '<w:sz w:val="$fontSize"/>',
    ].join();
    return values.isEmpty ? '' : '<w:rPr>$values</w:rPr>';
  }

  static String _sectionProperties(_DocxPageOrientation orientation) {
    return switch (orientation) {
      _DocxPageOrientation.landscape =>
        '<w:sectPr><w:footerReference w:type="default" r:id="rIdFooter1"/><w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/><w:pgMar w:top="567" w:right="567" w:bottom="720" w:left="567" w:header="567" w:footer="360" w:gutter="0"/></w:sectPr>',
      _ =>
        '<w:sectPr><w:footerReference w:type="default" r:id="rIdFooter1"/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="708" w:footer="567" w:gutter="0"/></w:sectPr>',
    };
  }

  static String _fieldRun(String instruction) {
    return '<w:fldSimple w:instr="$instruction"><w:r><w:rPr><w:color w:val="374151"/><w:sz w:val="15"/></w:rPr><w:t>1</w:t></w:r></w:fldSimple>';
  }

  static _DocxBlockColors _blockColors(RiskAdvisorBlockType type) {
    return switch (type) {
      RiskAdvisorBlockType.usable => const _DocxBlockColors('ECFDF5', '16A34A'),
      RiskAdvisorBlockType.checkOnSite => const _DocxBlockColors(
        'EFF6FF',
        '2563EB',
      ),
      RiskAdvisorBlockType.completeBeforeValidation => const _DocxBlockColors(
        'FFF7ED',
        'F97316',
      ),
      RiskAdvisorBlockType.blocking => const _DocxBlockColors(
        'FEF2F2',
        'DC2626',
      ),
      RiskAdvisorBlockType.evidence => const _DocxBlockColors(
        'F9FAFB',
        '6B7280',
      ),
      RiskAdvisorBlockType.specialistAdvice => const _DocxBlockColors(
        'F5F3FF',
        '7C3AED',
      ),
    };
  }
}

class _DocxBlockColors {
  const _DocxBlockColors(this.fill, this.border);

  final String fill;
  final String border;
}

class _OpenXmlPackage {
  const _OpenXmlPackage({
    required this.documentXml,
    required this.footerXml,
    required this.languageCode,
  });

  final String documentXml;
  final String footerXml;
  final String languageCode;

  Uint8List toBytes() {
    final files = <String, List<int>>{
      '[Content_Types].xml': utf8.encode(_contentTypesXml),
      '_rels/.rels': utf8.encode(_relsXml),
      'word/_rels/document.xml.rels': utf8.encode(_documentRelsXml),
      'word/document.xml': utf8.encode(documentXml),
      'word/footer1.xml': utf8.encode(footerXml),
      'word/styles.xml': utf8.encode(_stylesXml),
      'docProps/core.xml': utf8.encode(_coreXml),
      'docProps/app.xml': utf8.encode(_appXml),
    };
    return _ZipStoreEncoder.encode(files);
  }
}

class _ZipStoreEncoder {
  const _ZipStoreEncoder._();

  static Uint8List encode(Map<String, List<int>> files) {
    final output = BytesBuilder();
    final central = BytesBuilder();
    var offset = 0;

    for (final entry in files.entries) {
      final nameBytes = utf8.encode(entry.key);
      final data = entry.value;
      final crc = _crc32(data);

      final local = BytesBuilder()
        ..add(_u32(0x04034b50))
        ..add(_u16(20))
        ..add(_u16(0x0800))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(crc))
        ..add(_u32(data.length))
        ..add(_u32(data.length))
        ..add(_u16(nameBytes.length))
        ..add(_u16(0))
        ..add(nameBytes)
        ..add(data);
      final localBytes = local.toBytes();
      output.add(localBytes);

      central
        ..add(_u32(0x02014b50))
        ..add(_u16(20))
        ..add(_u16(20))
        ..add(_u16(0x0800))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(crc))
        ..add(_u32(data.length))
        ..add(_u32(data.length))
        ..add(_u16(nameBytes.length))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(0))
        ..add(_u32(offset))
        ..add(nameBytes);

      offset += localBytes.length;
    }

    final centralBytes = central.toBytes();
    output
      ..add(centralBytes)
      ..add(_u32(0x06054b50))
      ..add(_u16(0))
      ..add(_u16(0))
      ..add(_u16(files.length))
      ..add(_u16(files.length))
      ..add(_u32(centralBytes.length))
      ..add(_u32(offset))
      ..add(_u16(0));

    return output.toBytes();
  }

  static int _crc32(List<int> bytes) {
    var crc = 0xffffffff;
    for (final byte in bytes) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  static List<int> _u16(int value) => [value & 0xff, (value >> 8) & 0xff];

  static List<int> _u32(int value) => [
    value & 0xff,
    (value >> 8) & 0xff,
    (value >> 16) & 0xff,
    (value >> 24) & 0xff,
  ];
}

String _escapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

const _contentTypesXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
''';

const _relsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
''';

const _documentRelsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rIdFooter1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
</Relationships>
''';

const _stylesXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:sz w:val="22"/><w:color w:val="111827"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="34"/><w:color w:val="0F766E"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="28"/><w:color w:val="0F766E"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="134E4A"/></w:rPr></w:style>
</w:styles>
''';

const _coreXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>PreventIA Belgique</dc:title>
  <dc:creator>PreventIA Belgique</dc:creator>
  <cp:lastModifiedBy>PreventIA Belgique</cp:lastModifiedBy>
</cp:coreProperties>
''';

const _appXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>PreventIA Belgique</Application>
</Properties>
''';
