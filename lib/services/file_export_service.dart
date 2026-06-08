import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  static String cleanPdfFileName(String fileName) {
    return sanitizeFileName(fileName);
  }

  static String sanitizeFileName(String value) {
    final trimmed = value.trim();
    final extension = trimmed.toLowerCase().endsWith('.pdf') ? '.pdf' : '';
    final withoutExtension = extension.isEmpty
        ? trimmed
        : trimmed.substring(0, trimmed.length - extension.length);
    final arPrefix = RegExp(
      r'^AR-\d{4}-\d{4}',
      caseSensitive: false,
    ).firstMatch(withoutExtension)?.group(0)?.toUpperCase();
    var normalized = _normalizeForFileName(withoutExtension).toLowerCase();
    normalized = normalized
        .replaceAll(RegExp(r'[\/\\:*?"<>|]'), '-')
        .replaceAll(RegExp(r'[–—]+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^[-._]+|[-._]+$'), '');

    if (arPrefix != null) {
      final normalizedPrefix = arPrefix.toLowerCase();
      normalized = normalized.replaceFirst(
        RegExp('^${RegExp.escape(normalizedPrefix)}'),
        arPrefix,
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

  static String riskAnalysisFileName({
    String? referenceNumber,
    String? projectTitle,
    Locale? locale,
    String? languageCode,
  }) {
    final title = projectTitle?.trim();
    final resolvedLanguageCode = languageCode ?? locale?.languageCode;
    if (title == null || title.isEmpty || resolvedLanguageCode == null) {
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

  static String _ensurePdfExtension(String path) {
    if (path.toLowerCase().endsWith('.pdf')) {
      return path;
    }
    return '$path.pdf';
  }

  static String _documentKindSuffix(String documentKind, String languageCode) {
    final normalizedLanguageCode = languageCode.toLowerCase();
    final suffixes = switch (normalizedLanguageCode) {
      'nl' => {'analysis': 'risicoanalyse', 'actionSummary': 'actieoverzicht'},
      'en' => {
        'analysis': 'risk-assessment',
        'actionSummary': 'action-summary',
      },
      'de' => {
        'analysis': 'gefaehrdungsbeurteilung',
        'actionSummary': 'massnahmenuebersicht',
      },
      _ => {
        'analysis': 'analyse-de-risques',
        'actionSummary': 'recapitulatif-actions',
      },
    };

    return suffixes[documentKind] ?? suffixes['analysis']!;
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
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return null;
    }
    if (cleaned.length > 70 ||
        cleaned.split(RegExp(r'\s+')).length > 8 ||
        cleaned.contains(',')) {
      return null;
    }
    return cleaned;
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
