enum RiskAdvisorBlockType {
  usable,
  checkOnSite,
  completeBeforeValidation,
  blocking,
  evidence,
  specialistAdvice,
}

class RiskAdvisorBlock {
  const RiskAdvisorBlock({
    required this.type,
    required this.title,
    required this.content,
    required this.languageCode,
  });

  final RiskAdvisorBlockType type;
  final String title;
  final String content;
  final String languageCode;
}

class RiskAdvisorContentSegment {
  const RiskAdvisorContentSegment.text(this.text) : block = null;
  const RiskAdvisorContentSegment.block(this.block) : text = null;

  final String? text;
  final RiskAdvisorBlock? block;

  bool get isBlock => block != null;
}

class RiskAdvisorBlockService {
  const RiskAdvisorBlockService._();

  static List<RiskAdvisorContentSegment> parseSegments(
    String content, {
    required String languageCode,
    bool enableFallbackDetection = true,
  }) {
    final language = _normalizeLanguage(languageCode);
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final segments = <RiskAdvisorContentSegment>[];
    var cursor = 0;

    while (cursor < normalized.length) {
      final tagMatch = _tagPattern.firstMatch(normalized.substring(cursor));
      if (tagMatch == null) {
        _appendPlainSegments(
          segments,
          normalized.substring(cursor),
          language,
          enableFallbackDetection: enableFallbackDetection,
        );
        break;
      }

      final tagStart = cursor + tagMatch.start;
      final tagEnd = cursor + tagMatch.end;
      _appendPlainSegments(
        segments,
        normalized.substring(cursor, tagStart),
        language,
        enableFallbackDetection: enableFallbackDetection,
      );

      final rawTag = tagMatch.group(0)!;
      final definition = _definitionForTag(rawTag);
      if (definition == null) {
        segments.add(RiskAdvisorContentSegment.text(rawTag));
        cursor = tagEnd;
        continue;
      }

      final nextBoundary = _nextBlockBoundary(normalized, tagEnd);
      final rawBlockContent = normalized.substring(tagEnd, nextBoundary.start);
      final blockContent = _cleanBlockContent(rawBlockContent);
      if (blockContent.isNotEmpty) {
        segments.add(
          RiskAdvisorContentSegment.block(
            RiskAdvisorBlock(
              type: definition.type,
              title: definition.title,
              content: blockContent,
              languageCode: definition.languageCode,
            ),
          ),
        );
      }
      cursor = nextBoundary.consumeBoundary
          ? nextBoundary.end
          : nextBoundary.start;
    }

    return _mergeTextSegments(segments);
  }

  static String stripAdvisorTags(String content) {
    return content
        .replaceAll(_tagPattern, '')
        .replaceAll(_endPattern, '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String localizedTitle(RiskAdvisorBlockType type, String languageCode) {
    final language = _normalizeLanguage(languageCode);
    return _titlesByLanguage[language]?[type] ??
        _titlesByLanguage['fr']![type]!;
  }

  static String localizedCheckNote(String languageCode) {
    return localizedTitle(RiskAdvisorBlockType.checkOnSite, languageCode);
  }

  static _Boundary _nextBlockBoundary(String content, int start) {
    final rest = content.substring(start);
    final candidates = <_Boundary>[];
    final nextTag = _tagPattern.firstMatch(rest);
    if (nextTag != null) {
      candidates.add(_Boundary(start + nextTag.start, start + nextTag.start));
    }
    final endMarker = _endPattern.firstMatch(rest);
    if (endMarker != null) {
      candidates.add(
        _Boundary(start + endMarker.start, start + endMarker.end, true),
      );
    }
    final heading = _headingPattern.firstMatch(rest);
    if (heading != null) {
      candidates.add(_Boundary(start + heading.start, start + heading.start));
    }
    if (candidates.isEmpty) {
      return _Boundary(content.length, content.length);
    }
    candidates.sort((a, b) => a.start.compareTo(b.start));
    return candidates.first;
  }

  static void _appendPlainSegments(
    List<RiskAdvisorContentSegment> segments,
    String text,
    String language, {
    required bool enableFallbackDetection,
  }) {
    if (text.isEmpty) {
      return;
    }
    if (!enableFallbackDetection) {
      segments.add(RiskAdvisorContentSegment.text(text));
      return;
    }

    final lines = text.split('\n');
    final buffer = StringBuffer();
    for (final line in lines) {
      final type = _fallbackTypeForLine(line, language);
      if (type == null || line.trim().isEmpty) {
        buffer.writeln(line);
        continue;
      }
      if (buffer.isNotEmpty) {
        segments.add(RiskAdvisorContentSegment.text(buffer.toString()));
        buffer.clear();
      }
      segments.add(
        RiskAdvisorContentSegment.block(
          RiskAdvisorBlock(
            type: type,
            title: localizedTitle(type, language),
            content: line.trim(),
            languageCode: language,
          ),
        ),
      );
    }
    if (buffer.isNotEmpty) {
      segments.add(RiskAdvisorContentSegment.text(buffer.toString()));
    }
  }

  static List<RiskAdvisorContentSegment> _mergeTextSegments(
    List<RiskAdvisorContentSegment> segments,
  ) {
    final merged = <RiskAdvisorContentSegment>[];
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isNotEmpty) {
        merged.add(RiskAdvisorContentSegment.text(buffer.toString()));
        buffer.clear();
      }
    }

    for (final segment in segments) {
      if (segment.isBlock) {
        flush();
        merged.add(segment);
      } else {
        buffer.write(segment.text);
      }
    }
    flush();
    return merged;
  }

  static String _cleanBlockContent(String value) {
    return value.split('\n').map((line) => line.trimRight()).join('\n').trim();
  }

  static _AdvisorTagDefinition? _definitionForTag(String tag) {
    final normalized = _normalizeTag(tag);
    return _tagDefinitions[normalized];
  }

  static RiskAdvisorBlockType? _fallbackTypeForLine(
    String line,
    String language,
  ) {
    final normalized = _normalizeSearchText(line);
    if (normalized.isEmpty) {
      return null;
    }
    final terms =
        _fallbackTermsByLanguage[language] ?? _fallbackTermsByLanguage['fr']!;
    for (final entry in terms.entries) {
      if (entry.value.any((term) => normalized.contains(term))) {
        return entry.key;
      }
    }
    return null;
  }

  static String _normalizeLanguage(String languageCode) {
    final language = languageCode.toLowerCase();
    if (language.startsWith('nl')) return 'nl';
    if (language.startsWith('en')) return 'en';
    if (language.startsWith('de')) return 'de';
    return 'fr';
  }

  static String _normalizeTag(String tag) {
    return tag
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim()
        .toUpperCase()
        .replaceAll('À', 'A')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ë', 'E')
        .replaceAll('Ä', 'A')
        .replaceAll('Ö', 'O')
        .replaceAll('Ü', 'U')
        .replaceAll('ß', 'SS');
  }

  static String _normalizeSearchText(String text) {
    return text
        .toLowerCase()
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ï', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static final RegExp _tagPattern = RegExp(
    r'\[(EXPLOITABLE|À VÉRIFIER SUR LE TERRAIN|A VÉRIFIER SUR LE TERRAIN|À COMPLÉTER AVANT VALIDATION|A COMPLÉTER AVANT VALIDATION|POINT BLOQUANT AVANT VALIDATION|PREUVE ATTENDUE|AVIS SPÉCIALISÉ REQUIS|BRUIKBAAR|TER PLAATSE TE CONTROLEREN|AAN TE VULLEN VÓÓR VALIDATIE|AAN TE VULLEN VOOR VALIDATIE|BLOKKEREND PUNT VÓÓR VALIDATIE|BLOKKEREND PUNT VOOR VALIDATIE|VERWACHT BEWIJS|SPECIALISTISCH ADVIES VEREIST|USABLE NOW|TO BE CHECKED ON SITE|TO BE COMPLETED BEFORE VALIDATION|BLOCKING POINT BEFORE VALIDATION|EXPECTED EVIDENCE|SPECIALIST ADVICE REQUIRED|JETZT NUTZBAR|VOR ORT ZU PRÜFEN|VOR ORT ZU PRUFEN|VOR DER VALIDIERUNG ZU ERGÄNZEN|VOR DER VALIDIERUNG ZU ERGANZEN|BLOCKIERENDER PUNKT VOR DER VALIDIERUNG|ERWARTETER NACHWEIS|FACHLICHE STELLUNGNAHME ERFORDERLICH)\]',
    caseSensitive: false,
  );

  static final RegExp _endPattern = RegExp(
    r'^\s*(FIN DU BLOC|END OF BLOCK|EINDE BLOK|ENDE DES BLOCKS)\s*$',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _headingPattern = RegExp(
    r'^\s*(#{1,6}\s+.+|\d{1,2}[\.)]\s+.+)\s*$',
    multiLine: true,
  );

  static final Map<String, _AdvisorTagDefinition> _tagDefinitions = {
    for (final definition in _allDefinitions)
      _normalizeTag(definition.tag): definition,
  };

  static const Map<String, Map<RiskAdvisorBlockType, String>>
  _titlesByLanguage = {
    'fr': {
      RiskAdvisorBlockType.usable: 'Exploitable',
      RiskAdvisorBlockType.checkOnSite: 'À vérifier sur le terrain',
      RiskAdvisorBlockType.completeBeforeValidation:
          'À compléter avant validation',
      RiskAdvisorBlockType.blocking: 'Point bloquant avant validation',
      RiskAdvisorBlockType.evidence: 'Preuve attendue',
      RiskAdvisorBlockType.specialistAdvice: 'Avis spécialisé requis',
    },
    'nl': {
      RiskAdvisorBlockType.usable: 'Bruikbaar',
      RiskAdvisorBlockType.checkOnSite: 'Ter plaatse te controleren',
      RiskAdvisorBlockType.completeBeforeValidation:
          'Aan te vullen vóór validatie',
      RiskAdvisorBlockType.blocking: 'Blokkerend punt vóór validatie',
      RiskAdvisorBlockType.evidence: 'Verwacht bewijs',
      RiskAdvisorBlockType.specialistAdvice: 'Specialistisch advies vereist',
    },
    'en': {
      RiskAdvisorBlockType.usable: 'Usable now',
      RiskAdvisorBlockType.checkOnSite: 'To be checked on site',
      RiskAdvisorBlockType.completeBeforeValidation:
          'To be completed before validation',
      RiskAdvisorBlockType.blocking: 'Blocking point before validation',
      RiskAdvisorBlockType.evidence: 'Expected evidence',
      RiskAdvisorBlockType.specialistAdvice: 'Specialist advice required',
    },
    'de': {
      RiskAdvisorBlockType.usable: 'Jetzt nutzbar',
      RiskAdvisorBlockType.checkOnSite: 'Vor Ort zu prüfen',
      RiskAdvisorBlockType.completeBeforeValidation:
          'Vor der Validierung zu ergänzen',
      RiskAdvisorBlockType.blocking: 'Blockierender Punkt vor der Validierung',
      RiskAdvisorBlockType.evidence: 'Erwarteter Nachweis',
      RiskAdvisorBlockType.specialistAdvice:
          'Fachliche Stellungnahme erforderlich',
    },
  };

  static final Map<String, Map<RiskAdvisorBlockType, List<String>>>
  _fallbackTermsByLanguage = {
    'fr': {
      RiskAdvisorBlockType.checkOnSite: [
        'information a completer ou a valider sur le terrain',
        'a verifier',
        'a confirmer',
        'visite terrain a confirmer',
      ],
      RiskAdvisorBlockType.evidence: ['preuve attendue'],
      RiskAdvisorBlockType.blocking: ['point bloquant'],
      RiskAdvisorBlockType.specialistAdvice: [
        'avis du service externe',
        'avis du medecin du travail',
      ],
    },
    'en': {
      RiskAdvisorBlockType.checkOnSite: [
        'to be checked',
        'to be confirmed',
        'field verification',
      ],
      RiskAdvisorBlockType.evidence: ['expected evidence'],
      RiskAdvisorBlockType.blocking: ['blocking point'],
      RiskAdvisorBlockType.specialistAdvice: ['specialist advice'],
    },
    'nl': {
      RiskAdvisorBlockType.checkOnSite: [
        'te controleren',
        'te bevestigen',
        'terreincontrole',
      ],
      RiskAdvisorBlockType.evidence: ['verwacht bewijs'],
      RiskAdvisorBlockType.blocking: ['blokkerend punt'],
      RiskAdvisorBlockType.specialistAdvice: ['advies externe dienst'],
    },
    'de': {
      RiskAdvisorBlockType.checkOnSite: [
        'zu prufen',
        'zu bestatigen',
        'vor-ort-prufung',
        'vor ort prufung',
      ],
      RiskAdvisorBlockType.evidence: ['erwarteter nachweis'],
      RiskAdvisorBlockType.blocking: ['blockierender punkt'],
      RiskAdvisorBlockType.specialistAdvice: ['fachliche stellungnahme'],
    },
  };

  static const List<_AdvisorTagDefinition> _allDefinitions = [
    _AdvisorTagDefinition(
      tag: 'EXPLOITABLE',
      type: RiskAdvisorBlockType.usable,
      title: 'Exploitable',
      languageCode: 'fr',
    ),
    _AdvisorTagDefinition(
      tag: 'À VÉRIFIER SUR LE TERRAIN',
      type: RiskAdvisorBlockType.checkOnSite,
      title: 'À vérifier sur le terrain',
      languageCode: 'fr',
    ),
    _AdvisorTagDefinition(
      tag: 'À COMPLÉTER AVANT VALIDATION',
      type: RiskAdvisorBlockType.completeBeforeValidation,
      title: 'À compléter avant validation',
      languageCode: 'fr',
    ),
    _AdvisorTagDefinition(
      tag: 'POINT BLOQUANT AVANT VALIDATION',
      type: RiskAdvisorBlockType.blocking,
      title: 'Point bloquant avant validation',
      languageCode: 'fr',
    ),
    _AdvisorTagDefinition(
      tag: 'PREUVE ATTENDUE',
      type: RiskAdvisorBlockType.evidence,
      title: 'Preuve attendue',
      languageCode: 'fr',
    ),
    _AdvisorTagDefinition(
      tag: 'AVIS SPÉCIALISÉ REQUIS',
      type: RiskAdvisorBlockType.specialistAdvice,
      title: 'Avis spécialisé requis',
      languageCode: 'fr',
    ),
    _AdvisorTagDefinition(
      tag: 'BRUIKBAAR',
      type: RiskAdvisorBlockType.usable,
      title: 'Bruikbaar',
      languageCode: 'nl',
    ),
    _AdvisorTagDefinition(
      tag: 'TER PLAATSE TE CONTROLEREN',
      type: RiskAdvisorBlockType.checkOnSite,
      title: 'Ter plaatse te controleren',
      languageCode: 'nl',
    ),
    _AdvisorTagDefinition(
      tag: 'AAN TE VULLEN VÓÓR VALIDATIE',
      type: RiskAdvisorBlockType.completeBeforeValidation,
      title: 'Aan te vullen vóór validatie',
      languageCode: 'nl',
    ),
    _AdvisorTagDefinition(
      tag: 'BLOKKEREND PUNT VÓÓR VALIDATIE',
      type: RiskAdvisorBlockType.blocking,
      title: 'Blokkerend punt vóór validatie',
      languageCode: 'nl',
    ),
    _AdvisorTagDefinition(
      tag: 'VERWACHT BEWIJS',
      type: RiskAdvisorBlockType.evidence,
      title: 'Verwacht bewijs',
      languageCode: 'nl',
    ),
    _AdvisorTagDefinition(
      tag: 'SPECIALISTISCH ADVIES VEREIST',
      type: RiskAdvisorBlockType.specialistAdvice,
      title: 'Specialistisch advies vereist',
      languageCode: 'nl',
    ),
    _AdvisorTagDefinition(
      tag: 'USABLE NOW',
      type: RiskAdvisorBlockType.usable,
      title: 'Usable now',
      languageCode: 'en',
    ),
    _AdvisorTagDefinition(
      tag: 'TO BE CHECKED ON SITE',
      type: RiskAdvisorBlockType.checkOnSite,
      title: 'To be checked on site',
      languageCode: 'en',
    ),
    _AdvisorTagDefinition(
      tag: 'TO BE COMPLETED BEFORE VALIDATION',
      type: RiskAdvisorBlockType.completeBeforeValidation,
      title: 'To be completed before validation',
      languageCode: 'en',
    ),
    _AdvisorTagDefinition(
      tag: 'BLOCKING POINT BEFORE VALIDATION',
      type: RiskAdvisorBlockType.blocking,
      title: 'Blocking point before validation',
      languageCode: 'en',
    ),
    _AdvisorTagDefinition(
      tag: 'EXPECTED EVIDENCE',
      type: RiskAdvisorBlockType.evidence,
      title: 'Expected evidence',
      languageCode: 'en',
    ),
    _AdvisorTagDefinition(
      tag: 'SPECIALIST ADVICE REQUIRED',
      type: RiskAdvisorBlockType.specialistAdvice,
      title: 'Specialist advice required',
      languageCode: 'en',
    ),
    _AdvisorTagDefinition(
      tag: 'JETZT NUTZBAR',
      type: RiskAdvisorBlockType.usable,
      title: 'Jetzt nutzbar',
      languageCode: 'de',
    ),
    _AdvisorTagDefinition(
      tag: 'VOR ORT ZU PRÜFEN',
      type: RiskAdvisorBlockType.checkOnSite,
      title: 'Vor Ort zu prüfen',
      languageCode: 'de',
    ),
    _AdvisorTagDefinition(
      tag: 'VOR DER VALIDIERUNG ZU ERGÄNZEN',
      type: RiskAdvisorBlockType.completeBeforeValidation,
      title: 'Vor der Validierung zu ergänzen',
      languageCode: 'de',
    ),
    _AdvisorTagDefinition(
      tag: 'BLOCKIERENDER PUNKT VOR DER VALIDIERUNG',
      type: RiskAdvisorBlockType.blocking,
      title: 'Blockierender Punkt vor der Validierung',
      languageCode: 'de',
    ),
    _AdvisorTagDefinition(
      tag: 'ERWARTETER NACHWEIS',
      type: RiskAdvisorBlockType.evidence,
      title: 'Erwarteter Nachweis',
      languageCode: 'de',
    ),
    _AdvisorTagDefinition(
      tag: 'FACHLICHE STELLUNGNAHME ERFORDERLICH',
      type: RiskAdvisorBlockType.specialistAdvice,
      title: 'Fachliche Stellungnahme erforderlich',
      languageCode: 'de',
    ),
  ];
}

class _AdvisorTagDefinition {
  const _AdvisorTagDefinition({
    required this.tag,
    required this.type,
    required this.title,
    required this.languageCode,
  });

  final String tag;
  final RiskAdvisorBlockType type;
  final String title;
  final String languageCode;
}

class _Boundary {
  const _Boundary(this.start, this.end, [this.consumeBoundary = false]);

  final int start;
  final int end;
  final bool consumeBoundary;
}
