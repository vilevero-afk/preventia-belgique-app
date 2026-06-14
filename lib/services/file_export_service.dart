import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

import '../models/document_family.dart';

class FileExportService {
  const FileExportService._();

  static bool get usesSaveDialog {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => false,
    };
  }

  static Future<void> savePdfBytes({
    required Uint8List bytes,
    required String suggestedFileName,
    required BuildContext context,
  }) async {
    if (!usesSaveDialog) {
      return;
    }

    try {
      final cleanName = cleanPdfFileName(suggestedFileName);
      final location = await getSaveLocation(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
        suggestedName: cleanName,
        confirmButtonText: 'Enregistrer',
        canCreateDirectories: true,
      );

      if (location == null) {
        return;
      }

      final file = XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: cleanName,
      );
      await file.saveTo(_ensurePdfExtension(location.path));

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document enregistré.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’enregistrer le document.')),
      );
    }
  }

  static Future<void> saveDocxBytes({
    required Uint8List bytes,
    required String suggestedFileName,
    required BuildContext context,
    required String successMessage,
    required String errorMessage,
  }) async {
    if (!usesSaveDialog) {
      try {
        final cleanName = cleanDocxFileName(suggestedFileName);
        final box = context.findRenderObject() as RenderBox?;
        await share_plus.SharePlus.instance.share(
          share_plus.ShareParams(
            files: [
              share_plus.XFile.fromData(
                bytes,
                name: cleanName,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
              ),
            ],
            fileNameOverrides: [cleanName],
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
            downloadFallbackEnabled: true,
          ),
        );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return;
    }

    try {
      final cleanName = cleanDocxFileName(suggestedFileName);
      final location = await getSaveLocation(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Word',
            extensions: ['docx'],
            mimeTypes: [
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            ],
          ),
        ],
        suggestedName: cleanName,
        confirmButtonText: 'Enregistrer',
        canCreateDirectories: true,
      );

      if (location == null) {
        return;
      }

      final file = XFile.fromData(
        bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        name: cleanName,
      );
      await file.saveTo(_ensureDocxExtension(location.path));

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  static String cleanPdfFileName(String fileName) {
    return sanitizeFileName(fileName);
  }

  static String cleanDocxFileName(String fileName) {
    return _withExtension(
      sanitizeFileName(_withExtension(fileName, 'pdf')),
      'docx',
    );
  }

  static String sanitizeFileName(String value) {
    final trimmed = value.trim();
    final extension = trimmed.toLowerCase().endsWith('.pdf') ? '.pdf' : '';
    final withoutExtension = extension.isEmpty
        ? trimmed
        : trimmed.substring(0, trimmed.length - extension.length);
    final documentPrefix = RegExp(
      r'^(AR|PAA|PGP|RVS|FP|FIS|RAI)-\d{4}-\d{4}',
      caseSensitive: false,
    ).firstMatch(withoutExtension)?.group(0)?.toUpperCase();
    var normalized = _normalizeForFileName(withoutExtension).toLowerCase();
    normalized = normalized
        .replaceAll(RegExp(r'[\/\\:*?"<>|]'), '-')
        .replaceAll(RegExp(r'[–—]+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^[-._]+|[-._]+$'), '');

    if (documentPrefix != null) {
      final normalizedPrefix = documentPrefix.toLowerCase();
      normalized = normalized.replaceFirst(
        RegExp('^${RegExp.escape(normalizedPrefix)}'),
        documentPrefix,
      );
    }

    final baseName = _trimFileNameBase(
      normalized.isEmpty ? 'document' : normalized,
    );
    return '$baseName.pdf';
  }

  static String buildExportFileName({
    required String projectTitle,
    required String documentKind,
    required String languageCode,
    String? referenceNumber,
  }) {
    final suffix = _documentKindSuffix(documentKind, languageCode);
    final title = _safeProjectTitle(projectTitle);
    if (title.isEmpty) {
      final reference = referenceNumber?.trim();
      if (reference != null && reference.isNotEmpty) {
        return sanitizeFileName('$reference-$suffix.pdf');
      }
      return '$suffix.pdf';
    }

    final reference = referenceNumber?.trim();
    final rawName =
        reference != null &&
            reference.isNotEmpty &&
            !title.toLowerCase().startsWith(reference.toLowerCase())
        ? '$reference-$title-$suffix.pdf'
        : '$title-$suffix.pdf';

    return sanitizeFileName(rawName);
  }

  static String? projectTitleFromContent(String content) {
    final company = _valueFromContent(content, const [
      'Nom de l’entreprise',
      'Entreprise',
      'Administration',
      'Naam van de onderneming',
      'Onderneming',
      'Company name',
      'Company',
      'Name des Unternehmens',
      'Unternehmen',
    ]);
    final service = _valueFromContent(content, const [
      'Service concerné',
      'Service',
      'Betrokken dienst',
      'Dienst',
      'Service concerned',
      'Department concerned',
      'Department',
      'Betroffener Dienst',
    ]);
    final parts = [company, _shortServiceName(service)]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList();
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' – ');
  }

  static String? preferredProjectTitle({
    required String? projectTitle,
    required String? content,
  }) {
    final title = projectTitle?.trim();
    final contentTitle = content == null
        ? null
        : projectTitleFromContent(content);
    if (title == null || title.isEmpty || _safeProjectTitle(title).isEmpty) {
      return contentTitle;
    }
    if (_looksLikeLongFormTitle(title) && contentTitle != null) {
      return contentTitle;
    }
    return title;
  }

  static String riskAnalysisFileName({
    String? referenceNumber,
    String? projectTitle,
    Locale? locale,
    String? languageCode,
  }) {
    final title = projectTitle?.trim();
    final resolvedLanguageCode = languageCode ?? locale?.languageCode;
    if (title == null || title.isEmpty || resolvedLanguageCode == null) {
      final reference = referenceNumber?.trim();
      if (reference != null && reference.isNotEmpty) {
        return sanitizeFileName('$reference-analyse-de-risques.pdf');
      }
      return 'analyse-de-risques.pdf';
    }
    return buildExportFileName(
      projectTitle: title,
      documentKind: 'analysis',
      languageCode: resolvedLanguageCode,
      referenceNumber: referenceNumber,
    );
  }

  static String actionSummaryFileName({
    String? referenceNumber,
    String? projectTitle,
    Locale? locale,
    String? languageCode,
  }) {
    final title = projectTitle?.trim();
    final resolvedLanguageCode = languageCode ?? locale?.languageCode;
    if (title == null || title.isEmpty || resolvedLanguageCode == null) {
      return 'recapitulatif-actions.pdf';
    }
    return buildExportFileName(
      projectTitle: title,
      documentKind: 'actionSummary',
      languageCode: resolvedLanguageCode,
      referenceNumber: referenceNumber,
    );
  }

  static String documentFileName({
    String? referenceNumber,
    String? projectTitle,
    required String documentType,
    required String languageCode,
  }) {
    final title = projectTitle?.trim();
    final family = resolveDocumentFamily(documentType);
    final suffixBase = family == DocumentFamily.riskAssessment
        ? _slug(documentType)
        : _documentKindSuffix(_documentKindForFamily(family), languageCode);
    if (title == null || title.isEmpty) {
      final reference = referenceNumber?.trim();
      if (reference != null && reference.isNotEmpty) {
        return sanitizeFileName('$reference-$suffixBase.pdf');
      }
      return sanitizeFileName('$suffixBase.pdf');
    }
    if (family != DocumentFamily.riskAssessment) {
      final reference = referenceNumber?.trim();
      final rawName =
          reference != null &&
              reference.isNotEmpty &&
              !title.toLowerCase().startsWith(reference.toLowerCase())
          ? '$reference-$title.pdf'
          : '$title.pdf';
      return sanitizeFileName(rawName);
    }
    final reference = referenceNumber?.trim();
    if (reference != null && reference.isNotEmpty) {
      return sanitizeFileName('$reference-$suffixBase.pdf');
    }
    return sanitizeFileName('$suffixBase.pdf');
  }

  static String documentWordFileName({
    String? referenceNumber,
    String? projectTitle,
    required String documentType,
    required String languageCode,
  }) {
    return _withExtension(
      documentFileName(
        referenceNumber: referenceNumber,
        projectTitle: projectTitle,
        documentType: documentType,
        languageCode: languageCode,
      ),
      'docx',
    );
  }

  static String riskAnalysisWordFileName({
    String? referenceNumber,
    String? projectTitle,
    Locale? locale,
    String? languageCode,
  }) {
    return _withExtension(
      riskAnalysisFileName(
        referenceNumber: referenceNumber,
        projectTitle: projectTitle,
        locale: locale,
        languageCode: languageCode,
      ),
      'docx',
    );
  }

  static String _ensurePdfExtension(String path) {
    if (path.toLowerCase().endsWith('.pdf')) {
      return path;
    }
    return '$path.pdf';
  }

  static String _ensureDocxExtension(String path) {
    if (path.toLowerCase().endsWith('.docx')) {
      return path;
    }
    return '$path.docx';
  }

  static String _withExtension(String fileName, String extension) {
    final cleanExtension = extension.replaceFirst(RegExp(r'^\.'), '');
    return fileName.replaceFirst(RegExp(r'\.[^.]+$'), '.$cleanExtension');
  }

  static String _documentKindSuffix(String documentKind, String languageCode) {
    final normalizedLanguageCode = languageCode.toLowerCase();
    final suffixes = switch (normalizedLanguageCode) {
      'nl' => {
        'analysis': 'risicoanalyse',
        'actionSummary': 'actieoverzicht',
        'annualActionPlan': 'jaaractieplan',
        'globalPreventionPlan': 'globaal-preventieplan',
        'safetyVisitReport': 'veiligheidsbezoekverslag',
        'jobDescriptionSheet': 'functiefiche',
        'safetyInstructionSheet': 'veiligheidsinstructieblad',
        'accidentIncidentReport': 'ongevallen-incidentenrapport',
      },
      'en' => {
        'analysis': 'risk-assessment',
        'actionSummary': 'action-summary',
        'annualActionPlan': 'annual-action-plan',
        'globalPreventionPlan': 'five-year-global-prevention-plan',
        'safetyVisitReport': 'safety-visit-report',
        'jobDescriptionSheet': 'job-description-sheet',
        'safetyInstructionSheet': 'safety-instruction-sheet',
        'accidentIncidentReport': 'accident-incident-report',
      },
      'de' => {
        'analysis': 'gefaehrdungsbeurteilung',
        'actionSummary': 'massnahmenuebersicht',
        'annualActionPlan': 'jaehrlicher-aktionsplan',
        'globalPreventionPlan': 'globaler-praeventionsplan',
        'safetyVisitReport': 'sicherheitsbegehungsbericht',
        'jobDescriptionSheet': 'stellenbeschreibung',
        'safetyInstructionSheet': 'sicherheitsanweisungsblatt',
        'accidentIncidentReport': 'unfall-vorfallbericht',
      },
      _ => {
        'analysis': 'analyse-de-risques',
        'actionSummary': 'recapitulatif-actions',
        'annualActionPlan': 'plan-annuel-d-action',
        'globalPreventionPlan': 'plan-global-de-prevention',
        'safetyVisitReport': 'rapport-visite-securite',
        'jobDescriptionSheet': 'fiche-de-poste',
        'safetyInstructionSheet': 'fiche-instruction-securite',
        'accidentIncidentReport': 'rapport-accident-incident',
      },
    };

    return suffixes[documentKind] ?? documentKind;
  }

  static String _documentKindForFamily(DocumentFamily family) {
    return switch (family) {
      DocumentFamily.riskAssessment => 'analysis',
      DocumentFamily.annualActionPlan => 'annualActionPlan',
      DocumentFamily.globalPreventionPlan => 'globalPreventionPlan',
      DocumentFamily.safetyVisitReport => 'safetyVisitReport',
      DocumentFamily.jobDescriptionSheet => 'jobDescriptionSheet',
      DocumentFamily.safetyInstructionSheet => 'safetyInstructionSheet',
      DocumentFamily.accidentIncidentReport => 'accidentIncidentReport',
      DocumentFamily.unknown => 'document',
    };
  }

  static String _safeProjectTitle(String value) {
    final title = value.trim();
    if (title.isEmpty) {
      return '';
    }
    final sanitized = sanitizeFileName('$title.pdf');
    final base = sanitized.substring(0, sanitized.length - 4).toLowerCase();
    const bannedPrefixes = ['of-', 'concerned-', 'site-', 'service-concerned-'];
    if (bannedPrefixes.any(base.startsWith)) {
      return '';
    }
    return title;
  }

  static String? _valueFromContent(String content, List<String> labels) {
    for (final rawLine in content.split('\n')) {
      final line = rawLine
          .replaceAll('*', '')
          .replaceAll('|', ' ')
          .replaceAll('#', '')
          .trim();
      final lowerLine = line.toLowerCase();
      for (final label in labels) {
        final lowerLabel = label.toLowerCase();
        if (!lowerLine.startsWith(lowerLabel)) {
          continue;
        }
        final afterLabel = line.substring(label.length).trim();
        if (!RegExp(r'^[:\-–]').hasMatch(afterLabel)) {
          continue;
        }
        final value = line
            .substring(label.length)
            .trim()
            .replaceFirst(RegExp(r'^[:\-–]\s*'), '')
            .split(RegExp(r'\s{2,}'))
            .first
            .trim();
        if (value.isNotEmpty && value.length <= 120) {
          return value;
        }
      }
    }
    return null;
  }

  static String? _shortServiceName(String? value) {
    if (value == null) {
      return null;
    }
    var cleaned = value.trim();
    if (cleaned.isEmpty) {
      return null;
    }
    cleaned = cleaned.split(RegExp(r'\s+[\/|]\s+|\s+[–—-]\s+')).first.trim();
    if (cleaned.length > 70 ||
        cleaned.split(RegExp(r'\s+')).length > 8 ||
        cleaned.contains(',')) {
      return null;
    }
    return cleaned;
  }

  static bool _looksLikeLongFormTitle(String value) {
    final sanitized = sanitizeFileName('$value.pdf');
    final base = sanitized.substring(0, sanitized.length - 4).toLowerCase();
    if (base.length > 90 || base.split('-').length > 10) {
      return true;
    }
    const longFragments = [
      'instandhaltung-von-gebaeuden',
      'oeffentlichen-bereichen',
      'maintenance-of-buildings',
      'public-areas',
      'site-concerned',
      'service-concerned',
      'department-concerned',
    ];
    return longFragments.any(base.contains);
  }

  static String _normalizeForFileName(String value) {
    const replacements = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'ae',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'oe',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'ue',
      'ý': 'y',
      'ÿ': 'y',
      'æ': 'ae',
      'œ': 'oe',
      'ß': 'ss',
    };

    return value.runes.map((rune) {
      final character = String.fromCharCode(rune);
      final lower = character.toLowerCase();
      return replacements[lower] ?? character;
    }).join();
  }

  static String _slug(String value) {
    final normalized = _normalizeForFileName(value).toLowerCase();
    final slug = normalized
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'document' : slug;
  }

  static String _trimFileNameBase(String value) {
    const maxBaseLength = 140;
    if (value.length <= maxBaseLength) {
      return value;
    }

    return value
        .substring(0, maxBaseLength)
        .replaceAll(RegExp(r'-[^-]*$'), '')
        .replaceAll(RegExp(r'^[-._]+|[-._]+$'), '');
  }
}
