class ActionSummaryService {
  ActionSummary build(String documentContent) {
    final language = detectLanguage(documentContent);
    final sections = _extractSections(documentContent);
    final priorities = sections[11] ?? '';
    final actionPlan = sections[12] ?? '';
    final documents = sections[14] ?? '';
    final actors = sections[15] ?? '';
    final annexes = sections[16] ?? '';
    final actionPlanActions = _actionsFromTables(actionPlan, language);
    final priorityActions = actionPlanActions.isNotEmpty
        ? actionPlanActions
        : _actionsFromText(priorities, language);

    return ActionSummary(
      priorityActions: _deduplicateActions(priorityActions).take(12).toList(),
      documents: [
        ..._documentsFromText(documents, language),
        ..._annexesFromText(annexes, language),
      ].take(12).toList(),
      actors: _actorsFromText(actors, language).take(12).toList(),
      fieldChecks: _fieldChecksFromText(documentContent).take(10).toList(),
      expectedProofs: _expectedProofsFromText(
        documentContent,
        language,
      ).take(12).toList(),
    );
  }

  String detectLanguage(String content) {
    final normalized = _normalize(content);
    if (normalized.contains('draft action plan') ||
        normalized.contains('action priorities') ||
        normalized.contains('documents to create or update') ||
        normalized.contains('stakeholders to consult or involve') ||
        normalized.contains('required appendices') ||
        normalized.contains('document identification') ||
        normalized.contains('main risk assessment table')) {
      return 'en';
    }
    if (normalized.contains('entwurf eines massnahmenplans') ||
        normalized.contains('handlungsprioritaten') ||
        normalized.contains(
          'zu erstellende oder zu aktualisierende dokumente',
        ) ||
        normalized.contains('zu konsultierende oder einzubeziehende akteure') ||
        normalized.contains('erforderliche anhange') ||
        normalized.contains('dokumentidentifikation') ||
        normalized.contains('haupttabelle der gefahrdungsbeurteilung')) {
      return 'de';
    }
    if (normalized.contains('ontwerp van actieplan') ||
        normalized.contains('actieprioriteiten') ||
        normalized.contains('documenten op te stellen of bij te werken') ||
        normalized.contains('te raadplegen of te betrekken actoren') ||
        normalized.contains('noodzakelijke bijlagen') ||
        normalized.contains('identificatie van het document') ||
        normalized.contains('hoofdtabel van de risicoanalyse')) {
      return 'nl';
    }
    return 'fr';
  }

  Map<int, String> _extractSections(String content) {
    final sections = <int, StringBuffer>{};
    int? currentSection;

    for (final rawLine in content.split('\n')) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();
      final match = RegExp(r'^##\s+(\d{1,2})\.?\s+').firstMatch(trimmed);

      if (match != null) {
        currentSection = int.tryParse(match.group(1) ?? '');
        if (currentSection != null) {
          sections.putIfAbsent(currentSection, StringBuffer.new);
        }
        continue;
      }

      final titleMatch = RegExp(r'^##\s+(.+)$').firstMatch(trimmed);
      final titleSection = titleMatch == null
          ? null
          : _sectionIndexFromTitle(titleMatch.group(1) ?? '');
      if (titleSection != null) {
        currentSection = titleSection;
        sections.putIfAbsent(currentSection, StringBuffer.new);
        continue;
      }

      if (currentSection != null) {
        sections[currentSection]!.writeln(line);
      }
    }

    return sections.map((key, value) => MapEntry(key, value.toString()));
  }

  int? _sectionIndexFromTitle(String title) {
    final aliases = <String, int>{
      'priorites d action': 11,
      'projet de plan d action': 12,
      'documents a creer ou mettre a jour': 14,
      'documents a creer ou a mettre a jour': 14,
      'acteurs a consulter ou a impliquer': 15,
      'annexes necessaires': 16,
      'actieprioriteiten': 11,
      'ontwerp van actieplan': 12,
      'documenten op te stellen of bij te werken': 14,
      'te raadplegen of te betrekken actoren': 15,
      'noodzakelijke bijlagen': 16,
      'action priorities': 11,
      'draft action plan': 12,
      'documents to create or update': 14,
      'stakeholders to consult or involve': 15,
      'required appendices': 16,
      'handlungsprioritaten': 11,
      'entwurf eines massnahmenplans': 12,
      'zu erstellende oder zu aktualisierende dokumente': 14,
      'zu konsultierende oder einzubeziehende akteure': 15,
      'erforderliche anhange': 16,
    };
    return aliases[_normalize(title).replaceFirst(RegExp(r'^\d{1,2}\s+'), '')];
  }

  List<PriorityActionSummary> _actionsFromTables(String text, String language) {
    final tables = _extractTables(text);
    final actions = <PriorityActionSummary>[];
    final texts = _summaryTexts(language);

    for (final table in tables) {
      if (table.length < 2) {
        continue;
      }

      final headers = table.first.map(_normalize).toList();
      for (final row in table.skip(1)) {
        String cell(List<String> names) => _findCell(headers, row, names);
        final action = cell([
          'action a realiser',
          'mesure proposee',
          'action',
          'objectif',
          'voorgestelde maatregel',
          'actie',
          'doel',
          'proposed measure',
          'related risk',
          'objective',
          'vorgeschlagene massnahme',
          'betroffenes risiko',
          'ziel',
        ]);
        final risk = cell([
          'risque concerne',
          'risque',
          'danger',
          'betrokken risico',
          'risico',
          'gevaar',
          'related risk',
          'risk',
          'hazard',
          'betroffenes risiko',
          'risiko',
          'gefahrdung',
        ]);

        if (action.isEmpty && risk.isEmpty) {
          continue;
        }

        final proof = cell([
          'preuve attendue',
          'moyen de controle ou preuve attendue',
          'verwacht bewijs',
          'controle bewijs',
          'expected evidence',
          'expected control evidence',
          'erwarteter nachweis',
          'kontrolle erwarteter nachweis',
          'indicateur de realisation',
          'indicator',
        ]);

        actions.add(
          PriorityActionSummary(
            action: _fallback(action, risk),
            risk: _fallback(risk, texts.riskToClarify),
            responsible: _fallback(
              cell([
                'responsable',
                'verantwoordelijke',
                'responsible person',
                'verantwortliche person',
              ]),
              texts.responsibleToConfirm,
            ),
            deadline: _fallback(
              cell(['echeance', 'termijn', 'deadline', 'frist']),
              texts.deadlineToConfirm,
            ),
            expectedProof: _fallback(proof, texts.proofToClarify),
            importance: _importanceFor(risk, action, language),
          ),
        );
      }
    }

    return actions;
  }

  List<PriorityActionSummary> _actionsFromText(String text, String language) {
    final texts = _summaryTexts(language);
    return _cleanLines(text).where((line) => _isPriorityLine(line)).map((line) {
      final action = _valueAfterLabel(line, [
        'action',
        'mesure',
        'actie',
        'maatregel',
        'proposed measure',
        'vorgeschlagene massnahme',
      ]);
      final risk = _valueAfterLabel(line, [
        'risque concerné',
        'risque',
        'betrokken risico',
        'risico',
        'related risk',
        'betroffenes risiko',
      ]);
      final responsible = _valueAfterLabel(line, [
        'responsable',
        'verantwoordelijke',
        'responsible person',
        'verantwortliche person',
      ]);
      final deadline = _valueAfterLabel(line, [
        'échéance',
        'echeance',
        'termijn',
        'deadline',
        'frist',
      ]);
      final proof = _valueAfterLabel(line, [
        'preuve attendue',
        'preuve',
        'verwacht bewijs',
        'bewijs',
        'expected evidence',
        'erwarteter nachweis',
      ]);

      return PriorityActionSummary(
        action: _fallback(action, line),
        risk: _fallback(risk, texts.riskToClarify),
        responsible: _fallback(responsible, texts.responsibleToConfirm),
        deadline: _fallback(deadline, texts.deadlineToConfirm),
        expectedProof: _fallback(proof, texts.proofToClarify),
        importance: _importanceFor(risk, action, language),
      );
    }).toList();
  }

  List<PriorityActionSummary> _deduplicateActions(
    List<PriorityActionSummary> actions,
  ) {
    final seen = <String>{};
    final deduplicated = <PriorityActionSummary>[];

    for (final action in actions) {
      final key = _normalize(
        '${action.action} ${action.risk} ${action.responsible}',
      );
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }
      deduplicated.add(action);
    }

    return deduplicated;
  }

  List<DocumentSummaryItem> _documentsFromText(String text, String language) {
    final tableItems = <DocumentSummaryItem>[];
    final texts = _summaryTexts(language);
    for (final table in _extractTables(text)) {
      if (table.length < 2) {
        continue;
      }

      final headers = table.first.map(_normalize).toList();
      for (final row in table.skip(1)) {
        String cell(List<String> names) => _findCell(headers, row, names);
        final document = cell([
          'document',
          'documents',
          'intitule',
          'documenten',
          'dokument',
          'dokumente',
        ]);
        final objective = cell([
          'objectif',
          'pourquoi',
          'usage',
          'doel',
          'objective',
          'ziel',
          'warum',
        ]);
        final proof = cell([
          'preuve attendue',
          'resultat attendu',
          'trace',
          'verwacht bewijs',
          'verwacht resultaat',
          'expected evidence',
          'expected result',
          'erwarteter nachweis',
          'erwartetes ergebnis',
        ]);

        if (document.isNotEmpty || objective.isNotEmpty) {
          tableItems.add(
            DocumentSummaryItem(
              document: _fallback(document, objective),
              objective: _fallback(objective, texts.documentObjective),
              expectedResult: _fallback(proof, texts.documentExpectedResult),
            ),
          );
        }
      }
    }

    if (tableItems.isNotEmpty) {
      return tableItems;
    }

    return _cleanLines(text)
        .map(
          (line) => DocumentSummaryItem(
            document: line,
            objective: texts.documentObjective,
            expectedResult: texts.documentExpectedResult,
          ),
        )
        .toList();
  }

  List<ActorSummaryItem> _actorsFromText(String text, String language) {
    final tableItems = <ActorSummaryItem>[];
    final texts = _summaryTexts(language);
    for (final table in _extractTables(text)) {
      if (table.length < 2) {
        continue;
      }

      final headers = table.first.map(_normalize).toList();
      for (final row in table.skip(1)) {
        String cell(List<String> names) => _findCell(headers, row, names);
        final actor = cell([
          'acteur',
          'acteurs',
          'personne',
          'service',
          'actor',
          'actoren',
          'dienst',
          'stakeholder',
          'akteur',
          'akteure',
        ]);
        final why = cell([
          'pourquoi',
          'role',
          'motif',
          'reden',
          'waarom',
          'why',
          'reason',
          'rolle',
          'warum',
        ]);
        final trace = cell([
          'trace attendue',
          'trace',
          'preuve attendue',
          'verwacht bewijs',
          'verwachte trace',
          'expected trace',
          'expected evidence',
          'erwartete spur',
          'erwarteter nachweis',
        ]);

        if (actor.isNotEmpty || why.isNotEmpty) {
          tableItems.add(
            ActorSummaryItem(
              actor: _fallback(actor, why),
              reason: _fallback(why, texts.actorReason),
              expectedTrace: _fallback(trace, texts.actorTrace),
            ),
          );
        }
      }
    }

    if (tableItems.isNotEmpty) {
      return tableItems;
    }

    return _cleanLines(text)
        .map(
          (line) => ActorSummaryItem(
            actor: line,
            reason: texts.actorReason,
            expectedTrace: texts.actorTrace,
          ),
        )
        .toList();
  }

  List<DocumentSummaryItem> _annexesFromText(String text, String language) {
    final texts = _summaryTexts(language);
    return _cleanLines(text)
        .map(
          (line) => DocumentSummaryItem(
            document: line,
            objective: texts.annexObjective,
            expectedResult: texts.annexExpectedResult,
          ),
        )
        .toList();
  }

  List<String> _fieldChecksFromText(String text) {
    final keywords = [
      'à vérifier',
      'non renseigné',
      'à confirmer',
      'à compléter',
      'visite terrain',
      'observation terrain',
      'te controleren',
      'niet meegedeeld',
      'te bevestigen',
      'aan te vullen',
      'terreinbezoek',
      'terreinobservatie',
      'to be checked',
      'not communicated',
      'to be confirmed',
      'to be completed',
      'site visit',
      'field observation',
      'zu prüfen',
      'nicht mitgeteilt',
      'zu bestätigen',
      'zu vervollständigen',
      'vor ort',
      'beobachtung vor ort',
    ];
    final checks = <String>[];
    final seen = <String>{};

    for (final line in _cleanLines(text)) {
      if (_isLongRawTableLine(line)) {
        continue;
      }
      final lower = line.toLowerCase();
      if (!keywords.any(lower.contains)) {
        continue;
      }

      final normalized = _normalize(line);
      if (seen.add(normalized)) {
        checks.add(line);
      }
    }

    return checks;
  }

  List<String> _expectedProofsFromText(String text, String language) {
    final proofLanguage = language;
    final proofPatterns = <String, List<String>>{
      _localizedProof('controlReport', proofLanguage): [
        'rapport de controle',
        'rapport de contrôle',
        'controlerapport',
        'controleverslag',
        'inspection report',
        'control report',
        'prufbericht',
        'prüfbericht',
      ],
      _localizedProof('trainingRegister', proofLanguage): [
        'registre des formations',
        'registre de formation',
        'opleidingsregister',
        'training register',
        'schulungslisten',
        'schulungsregister',
      ],
      _localizedProof('attendanceList', proofLanguage): [
        'liste de presence',
        'liste de présence',
        'aanwezigheidslijst',
        'attendance list',
        'anwesenheitsliste',
      ],
      'Photos': ['photos', 'photo', 'foto', 'foto s'],
      _localizedProof('updatedInventory', proofLanguage): [
        'inventaire mis a jour',
        'inventaire mis à jour',
        'bijgewerkte inventaris',
        'inventaris bijwerken',
        'updated inventory',
        'inventar aktualisieren',
        'aktualisiertes inventar',
      ],
      _localizedProof('sds', proofLanguage): [
        'fds centralisees',
        'fds centralisées',
        'veiligheidsinformatiebladen',
        'vib',
        'vib s',
        'sds',
        'safety data sheets',
        'sicherheitsdatenblatter',
        'sicherheitsdatenblätter',
      ],
      _localizedProof('committeeMinutes', proofLanguage): [
        'pv cppt',
        'pv ou avis cppt',
        'avis cppt',
        'pv cpbw',
        'advies cpbw',
        'minutes',
        'committee',
        'protokoll',
        'stellungnahme',
      ],
      _localizedProof('signedProcedure', proofLanguage): [
        'procedure signee',
        'procédure signée',
        'procedure validee',
        'procédure validée',
        'ondertekende procedure',
        'gevalideerde procedure',
        'signed procedure',
        'validated procedure',
        'unterzeichnetes verfahren',
        'validiertes verfahren',
      ],
      _localizedProof('signedChecklist', proofLanguage): [
        'check list signee',
        'check-list signee',
        'check-list signée',
        'ondertekende checklist',
        'signed checklist',
        'unterzeichnete checklist',
      ],
      _localizedProof('ppeRegister', proofLanguage): [
        'registre epi',
        'registre des epi',
        'registre des épi',
        'pbm register',
        'pbm-register',
        'ppe register',
        'psa register',
        'psa-register',
      ],
    };
    final proofs = <String>[];
    final seen = <String>{};

    for (final line in _cleanLines(text)) {
      if (_isLongRawTableLine(line)) {
        continue;
      }

      final normalized = _normalize(line);
      for (final entry in proofPatterns.entries) {
        if (!entry.value.any(
          (keyword) => normalized.contains(_normalize(keyword)),
        )) {
          continue;
        }

        final proofKey = _normalize(entry.key);
        if (seen.add(proofKey)) {
          proofs.add(entry.key);
        }
      }
    }

    return proofs;
  }

  String buildCopyText(ActionSummary summary, {String language = 'fr'}) {
    if (language != 'fr') {
      return _buildLocalizedCopyText(summary, language);
    }
    final buffer = StringBuffer()
      ..writeln('Récapitulatif des actions à réaliser')
      ..writeln()
      ..writeln(
        'Ce récapitulatif aide le conseiller en prévention à transformer l’analyse en tâches concrètes. Il ne remplace pas la validation du document par les acteurs compétents.',
      )
      ..writeln();

    void writeSection(String title, Iterable<String> lines) {
      buffer.writeln(title);
      final materialized = lines
          .where((line) => line.trim().isNotEmpty)
          .toList();
      if (materialized.isEmpty) {
        buffer.writeln('- Aucun élément détecté.');
      } else {
        for (final line in materialized) {
          buffer.writeln('- $line');
        }
      }
      buffer.writeln();
    }

    writeSection(
      'A. Actions prioritaires',
      summary.priorityActions.map(
        (action) =>
            'Action à réaliser : ${action.action} | Risque concerné : ${action.risk} | Responsable : ${action.responsible} | Échéance : ${action.deadline} | Preuve attendue : ${action.expectedProof} | Pourquoi c’est important : ${action.importance} | Attendu du conseiller en prévention : vérifier que l’action est réaliste, attribuée à un responsable, planifiée dans un délai cohérent et suivie par une preuve concrète.',
      ),
    );
    writeSection(
      'B. Documents à préparer ou mettre à jour',
      summary.documents.map(
        (document) =>
            'Document : ${document.document} | Objectif : ${document.objective} | Pourquoi c’est nécessaire : ces documents permettent de démontrer que les mesures de prévention sont organisées, connues et traçables. | Résultat attendu : ${document.expectedResult}',
      ),
    );
    writeSection(
      'C. Acteurs à consulter',
      summary.actors.map(
        (actor) =>
            'Acteur : ${actor.actor} | Pourquoi le consulter : ${actor.reason} | Trace attendue : ${actor.expectedTrace} | Explication : la consultation permet de valider la réalité du terrain, d’impliquer les travailleurs et de documenter les décisions.',
      ),
    );
    writeSection(
      'D. Informations à vérifier sur le terrain',
      summary.fieldChecks.map(
        (check) =>
            'Élément à vérifier : $check | Pourquoi c’est important : une information non vérifiée ne doit pas être considérée comme acquise. | Comment vérifier : confirmer par observation, entretien, document ou contrôle. | Preuve possible : photo, rapport, note de visite, registre ou compte rendu.',
      ),
    );
    writeSection(
      'E. Preuves attendues',
      summary.expectedProofs.map(
        (proof) =>
            'Preuve : $proof | À quoi elle sert : démontrer concrètement qu’une action a été réalisée ou suivie. | Exemple concret : rapport, photo, registre, liste de présence, procédure signée ou PV CPPT.',
      ),
    );

    return buffer.toString().trim();
  }

  String _buildLocalizedCopyText(ActionSummary summary, String language) {
    final labels = switch (language) {
      'nl' => (
        title: 'Actieoverzicht',
        intro:
            'Dit overzicht helpt de preventieadviseur om de analyse om te zetten in concrete taken. Het vervangt de validatie door de bevoegde actoren niet.',
        actions: 'A. Prioritaire acties',
        documents: 'B. Documenten voor te bereiden of bij te werken',
        actors: 'C. Te raadplegen actoren',
        checks: 'D. Informatie te controleren op het terrein',
        proofs: 'E. Verwachte bewijzen',
        none: 'Geen element gedetecteerd.',
        action: 'Uit te voeren actie',
        risk: 'Betrokken risico',
        responsible: 'Verantwoordelijke',
        deadline: 'Termijn',
        proof: 'Verwacht bewijs',
        why: 'Waarom belangrijk',
        advisor:
            'Verwachting voor de preventieadviseur: controleren dat de actie realistisch is, toegewezen is aan een verantwoordelijke, gepland is binnen een coherente termijn en opgevolgd wordt met een concreet bewijs.',
        document: 'Document',
        objective: 'Doel',
        necessary:
            'Waarom nodig: deze documenten tonen aan dat preventiemaatregelen georganiseerd, gekend en traceerbaar zijn.',
        result: 'Verwacht resultaat',
        actor: 'Actor',
        consult: 'Waarom raadplegen',
        trace: 'Verwacht spoor',
        explanation:
            'Uitleg: de raadpleging maakt het mogelijk de realiteit op het terrein te valideren, werknemers te betrekken en beslissingen te documenteren.',
        check: 'Te controleren element',
        checkWhy:
            'Waarom belangrijk: niet-gecontroleerde informatie mag niet als verworven worden beschouwd.',
        verify:
            'Hoe controleren: bevestigen door observatie, gesprek, document of controle.',
        possibleProof:
            'Mogelijk bewijs: foto, rapport, bezoeknota, register of verslag.',
        proofPurpose:
            'Waarvoor dient het: concreet aantonen dat een actie werd uitgevoerd of opgevolgd.',
        proofExample:
            'Concreet voorbeeld: rapport, foto, register, aanwezigheidslijst, ondertekende procedure of PV CPBW.',
      ),
      'en' => (
        title: 'Action summary',
        intro:
            'This summary helps the prevention advisor turn the assessment into concrete tasks. It does not replace validation of the document by the competent stakeholders.',
        actions: 'A. Priority actions',
        documents: 'B. Documents to prepare or update',
        actors: 'C. Stakeholders to consult',
        checks: 'D. Information to check in the field',
        proofs: 'E. Expected evidence',
        none: 'No item detected.',
        action: 'Action to perform',
        risk: 'Related risk',
        responsible: 'Responsible person',
        deadline: 'Deadline',
        proof: 'Expected evidence',
        why: 'Why it is important',
        advisor:
            'Expected from the prevention advisor: check that the action is realistic, assigned to a responsible person, planned within a coherent deadline and followed up with concrete evidence.',
        document: 'Document',
        objective: 'Objective',
        necessary:
            'Why it is necessary: these documents show that prevention measures are organised, known and traceable.',
        result: 'Expected result',
        actor: 'Stakeholder',
        consult: 'Why consult them',
        trace: 'Expected trace',
        explanation:
            'Explanation: consultation helps validate field reality, involve workers and document decisions.',
        check: 'Item to check',
        checkWhy:
            'Why it is important: unverified information must not be considered established.',
        verify:
            'How to check: confirm by observation, interview, document or inspection.',
        possibleProof:
            'Possible evidence: photo, report, visit note, register or minutes.',
        proofPurpose:
            'What it is used for: concretely show that an action has been completed or followed up.',
        proofExample:
            'Concrete example: report, photo, register, attendance list, signed procedure or committee minutes.',
      ),
      _ => (
        title: 'Maßnahmenübersicht',
        intro:
            'Diese Übersicht hilft dem Präventionsberater, die Beurteilung in konkrete Aufgaben umzusetzen. Sie ersetzt nicht die Validierung des Dokuments durch die zuständigen Akteure.',
        actions: 'A. Prioritäre Maßnahmen',
        documents: 'B. Vorzubereitende oder zu aktualisierende Dokumente',
        actors: 'C. Zu konsultierende Akteure',
        checks: 'D. Vor Ort zu prüfende Informationen',
        proofs: 'E. Erwartete Nachweise',
        none: 'Kein Element erkannt.',
        action: 'Auszuführende Maßnahme',
        risk: 'Betroffenes Risiko',
        responsible: 'Verantwortliche Person',
        deadline: 'Frist',
        proof: 'Erwarteter Nachweis',
        why: 'Warum wichtig',
        advisor:
            'Erwartung an den Präventionsberater: prüfen, dass die Maßnahme realistisch, einer verantwortlichen Person zugeordnet, innerhalb einer kohärenten Frist geplant und mit einem konkreten Nachweis verfolgt wird.',
        document: 'Dokument',
        objective: 'Ziel',
        necessary:
            'Warum notwendig: diese Dokumente zeigen, dass Präventionsmaßnahmen organisiert, bekannt und nachvollziehbar sind.',
        result: 'Erwartetes Ergebnis',
        actor: 'Akteur',
        consult: 'Warum konsultieren',
        trace: 'Erwartete Spur',
        explanation:
            'Erläuterung: die Konsultation ermöglicht es, die Realität vor Ort zu validieren, Beschäftigte einzubeziehen und Entscheidungen zu dokumentieren.',
        check: 'Zu prüfendes Element',
        checkWhy:
            'Warum wichtig: nicht geprüfte Informationen dürfen nicht als gesichert betrachtet werden.',
        verify:
            'Wie prüfen: durch Beobachtung, Gespräch, Dokument oder Kontrolle bestätigen.',
        possibleProof:
            'Möglicher Nachweis: Foto, Bericht, Besuchsnotiz, Register oder Protokoll.',
        proofPurpose:
            'Wozu es dient: konkret nachweisen, dass eine Maßnahme umgesetzt oder verfolgt wurde.',
        proofExample:
            'Konkretes Beispiel: Bericht, Foto, Register, Anwesenheitsliste, unterzeichnetes Verfahren oder Ausschussprotokoll.',
      ),
    };
    final buffer = StringBuffer()
      ..writeln(labels.title)
      ..writeln()
      ..writeln(labels.intro)
      ..writeln();

    void writeSection(String title, Iterable<String> lines) {
      buffer.writeln(title);
      final materialized = lines
          .where((line) => line.trim().isNotEmpty)
          .toList();
      if (materialized.isEmpty) {
        buffer.writeln('- ${labels.none}');
      } else {
        for (final line in materialized) {
          buffer.writeln('- $line');
        }
      }
      buffer.writeln();
    }

    writeSection(
      labels.actions,
      summary.priorityActions.map(
        (action) =>
            '${labels.action}: ${action.action} | ${labels.risk}: ${action.risk} | ${labels.responsible}: ${action.responsible} | ${labels.deadline}: ${action.deadline} | ${labels.proof}: ${action.expectedProof} | ${labels.why}: ${action.importance} | ${labels.advisor}',
      ),
    );
    writeSection(
      labels.documents,
      summary.documents.map(
        (document) =>
            '${labels.document}: ${document.document} | ${labels.objective}: ${document.objective} | ${labels.necessary} | ${labels.result}: ${document.expectedResult}',
      ),
    );
    writeSection(
      labels.actors,
      summary.actors.map(
        (actor) =>
            '${labels.actor}: ${actor.actor} | ${labels.consult}: ${actor.reason} | ${labels.trace}: ${actor.expectedTrace} | ${labels.explanation}',
      ),
    );
    writeSection(
      labels.checks,
      summary.fieldChecks.map(
        (check) =>
            '${labels.check}: $check | ${labels.checkWhy} | ${labels.verify} | ${labels.possibleProof}',
      ),
    );
    writeSection(
      labels.proofs,
      summary.expectedProofs.map(
        (proof) =>
            '${labels.proof}: $proof | ${labels.proofPurpose} | ${labels.proofExample}',
      ),
    );

    return buffer.toString().trim();
  }

  List<List<List<String>>> _extractTables(String text) {
    final tables = <List<List<String>>>[];
    var current = <List<String>>[];

    void flush() {
      if (current.isNotEmpty) {
        tables.add(current);
        current = <List<String>>[];
      }
    }

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (!_isTableLine(line)) {
        flush();
        continue;
      }

      if (_isSeparatorLine(line)) {
        continue;
      }

      current.add(_tableCells(line));
    }

    flush();
    return tables;
  }

  List<String> _cleanLines(String text) {
    return text
        .split('\n')
        .map(_cleanMarkdown)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _findCell(List<String> headers, List<String> row, List<String> names) {
    for (final name in names.map(_normalize)) {
      final index = headers.indexWhere((header) => header.contains(name));
      if (index >= 0 && index < row.length) {
        return row[index].trim();
      }
    }
    return '';
  }

  String _valueAfterLabel(String line, List<String> labels) {
    final parts = line.split(RegExp(r'\s+-\s+|;\s*'));
    for (final part in parts) {
      final normalized = _normalize(part);
      for (final label in labels.map(_normalize)) {
        if (normalized.startsWith(label)) {
          final separatorIndex = part.indexOf(':');
          if (separatorIndex >= 0 && separatorIndex < part.length - 1) {
            return part.substring(separatorIndex + 1).trim();
          }
        }
      }
    }
    return '';
  }

  String _importanceFor(String risk, String action, String language) {
    final texts = _summaryTexts(language);
    final context = [
      risk,
      action,
    ].where((text) => text.trim().isNotEmpty).join(' ');
    if (context.isEmpty) {
      return texts.emptyImportance;
    }
    return texts.importance;
  }

  bool _isTableLine(String line) {
    return line.contains('|') && line.replaceAll('|', '').trim().isNotEmpty;
  }

  bool _isPriorityLine(String line) {
    return RegExp(
          r'^(priorité|prioriteit|priority|priorität)\s+[1-9]\s*:',
          caseSensitive: false,
        ).hasMatch(line) ||
        line.toLowerCase().contains('priorité') ||
        line.toLowerCase().contains('prioriteit') ||
        line.toLowerCase().contains('priority') ||
        line.toLowerCase().contains('priorität');
  }

  bool _isLongRawTableLine(String line) {
    final normalized = _normalize(line);
    return line.length > 160 ||
        (normalized.contains('numero') &&
            normalized.contains('activite') &&
            normalized.contains('danger') &&
            normalized.contains('risque')) ||
        normalized.contains('score initial') ||
        normalized.contains('niveau de risque') ||
        normalized.contains('hoofdtabel van de risicoanalyse') ||
        normalized.contains('blootgestelde personen') ||
        normalized.contains('waarschijnlijkheid') ||
        normalized.contains('main risk assessment table') ||
        normalized.contains('exposed persons') ||
        normalized.contains('probability') ||
        normalized.contains('haupttabelle der gefahrdungsbeurteilung') ||
        normalized.contains('exponierte personen') ||
        normalized.contains('wahrscheinlichkeit') ||
        (normalized.contains('responsable') &&
            normalized.contains('echeance')) ||
        (normalized.contains('verantwoordelijke') &&
            normalized.contains('termijn')) ||
        (normalized.contains('responsible person') &&
            normalized.contains('deadline')) ||
        (normalized.contains('verantwortliche person') &&
            normalized.contains('frist')) ||
        normalized.contains('plan annuel d action');
  }

  bool _isSeparatorLine(String line) {
    final cleaned = line.replaceAll('|', '').replaceAll(':', '').trim();
    return cleaned.isNotEmpty && RegExp(r'^-+$').hasMatch(cleaned);
  }

  List<String> _tableCells(String line) {
    return line
        .split('|')
        .map(_cleanMarkdown)
        .where((cell) => cell.isNotEmpty)
        .toList();
  }

  String _cleanMarkdown(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('|', ' ')
        .replaceAll('---', '')
        .replaceFirst(RegExp(r'^[-*]\s+'), '')
        .trim();
  }

  String _fallback(String value, String fallback) {
    return value.trim().isEmpty ? fallback : value.trim();
  }

  String _localizedProof(String key, String language) {
    final proofs = <String, Map<String, String>>{
      'controlReport': {
        'fr': 'Rapport de contrôle',
        'nl': 'Controlerapport',
        'en': 'Inspection report',
        'de': 'Prüfbericht',
      },
      'trainingRegister': {
        'fr': 'Registre des formations',
        'nl': 'Opleidingsregister',
        'en': 'Training register',
        'de': 'Schulungsregister',
      },
      'attendanceList': {
        'fr': 'Liste de présence',
        'nl': 'Aanwezigheidslijst',
        'en': 'Attendance list',
        'de': 'Anwesenheitsliste',
      },
      'updatedInventory': {
        'fr': 'Inventaire mis à jour',
        'nl': 'Bijgewerkte inventaris',
        'en': 'Updated inventory',
        'de': 'Aktualisiertes Inventar',
      },
      'sds': {
        'fr': 'FDS centralisées',
        'nl': 'Veiligheidsinformatiebladen',
        'en': 'Centralised safety data sheets',
        'de': 'Zentralisierte Sicherheitsdatenblätter',
      },
      'committeeMinutes': {
        'fr': 'PV CPPT',
        'nl': 'PV CPBW',
        'en': 'Committee minutes',
        'de': 'Ausschussprotokoll',
      },
      'signedProcedure': {
        'fr': 'Procédure signée',
        'nl': 'Ondertekende procedure',
        'en': 'Signed procedure',
        'de': 'Unterzeichnetes Verfahren',
      },
      'signedChecklist': {
        'fr': 'Check-list signée',
        'nl': 'Ondertekende checklist',
        'en': 'Signed checklist',
        'de': 'Unterzeichnete Checkliste',
      },
      'ppeRegister': {
        'fr': 'Registre EPI',
        'nl': 'PBM-register',
        'en': 'PPE register',
        'de': 'PSA-Register',
      },
    };
    return proofs[key]?[language] ?? proofs[key]?['fr'] ?? key;
  }

  _SummaryTexts _summaryTexts(String language) {
    return switch (language) {
      'nl' => const _SummaryTexts(
        riskToClarify: 'Risico te verduidelijken in het document.',
        responsibleToConfirm: 'Verantwoordelijke te bevestigen.',
        deadlineToConfirm: 'Termijn te bevestigen.',
        proofToClarify: 'Verwacht bewijs te verduidelijken.',
        documentObjective:
            'Een preventiebewijs verduidelijken, formaliseren of bijwerken.',
        documentExpectedResult:
            'Gedateerd, toegankelijk en indien nodig gevalideerd document.',
        actorReason:
            'Vaststellingen bevestigen, acties prioriteren of valideren.',
        actorTrace: 'Advies, verslag, notulen of gedocumenteerde uitwisseling.',
        annexObjective:
            'Bijlage voorbereiden om de validatie van de analyse te vervolledigen.',
        annexExpectedResult:
            'Beschikbaar, indien mogelijk gedateerd stuk dat aan het preventiedossier is gekoppeld.',
        emptyImportance:
            'Deze actie zet de analyse om in een opgevolgde en traceerbare maatregel.',
        importance:
            'Deze actie vermindert of beheerst het geïdentificeerde risico en maakt de opvolging van de analyse aantoonbaar.',
      ),
      'en' => const _SummaryTexts(
        riskToClarify: 'Risk to clarify in the document.',
        responsibleToConfirm: 'Responsible person to be confirmed.',
        deadlineToConfirm: 'Deadline to be confirmed.',
        proofToClarify: 'Expected evidence to be clarified.',
        documentObjective: 'Clarify, formalise or update prevention evidence.',
        documentExpectedResult:
            'Dated, accessible and, if necessary, validated document.',
        actorReason: 'Confirm findings, prioritise actions or validate.',
        actorTrace: 'Opinion, minutes, report or documented exchange.',
        annexObjective:
            'Appendix to prepare in order to complete validation of the assessment.',
        annexExpectedResult:
            'Available document, dated if possible, and attached to the prevention file.',
        emptyImportance:
            'This action turns the assessment into a tracked and traceable measure.',
        importance:
            'This action reduces or controls the identified risk and makes follow-up of the assessment demonstrable.',
      ),
      'de' => const _SummaryTexts(
        riskToClarify: 'Risiko im Dokument zu klären.',
        responsibleToConfirm: 'Verantwortliche Person zu bestätigen.',
        deadlineToConfirm: 'Frist zu bestätigen.',
        proofToClarify: 'Erwarteter Nachweis zu klären.',
        documentObjective:
            'Einen Präventionsnachweis klären, formalisieren oder aktualisieren.',
        documentExpectedResult:
            'Datiertes, zugängliches und gegebenenfalls validiertes Dokument.',
        actorReason:
            'Feststellungen bestätigen, Maßnahmen priorisieren oder validieren.',
        actorTrace:
            'Stellungnahme, Protokoll, Bericht oder dokumentierter Austausch.',
        annexObjective:
            'Anhang zur Vorbereitung, um die Validierung der Beurteilung zu vervollständigen.',
        annexExpectedResult:
            'Verfügbares Dokument, wenn möglich datiert und der Präventionsakte zugeordnet.',
        emptyImportance:
            'Diese Maßnahme überführt die Beurteilung in eine nachverfolgte und nachvollziehbare Maßnahme.',
        importance:
            'Diese Maßnahme verringert oder beherrscht das erkannte Risiko und macht die Nachverfolgung der Beurteilung nachweisbar.',
      ),
      _ => const _SummaryTexts(
        riskToClarify: 'Risque à préciser dans le document.',
        responsibleToConfirm: 'Responsable à confirmer.',
        deadlineToConfirm: 'Échéance à confirmer.',
        proofToClarify: 'Preuve attendue à préciser.',
        documentObjective:
            'Clarifier, formaliser ou mettre à jour une preuve de prévention.',
        documentExpectedResult:
            'Document daté, accessible et validé si nécessaire.',
        actorReason:
            'Confirmer les constats, prioriser les actions ou valider.',
        actorTrace: 'Avis, PV, compte rendu ou échange documenté.',
        annexObjective:
            'Annexe à préparer pour compléter la validation de l’analyse.',
        annexExpectedResult:
            'Pièce disponible, datée si possible, et associée au dossier de prévention.',
        emptyImportance:
            'Cette action permet de transformer l’analyse en mesure suivie et traçable.',
        importance:
            'Cette action réduit ou maîtrise le risque identifié et permet de démontrer le suivi de l’analyse.',
      ),
    };
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class ActionSummary {
  const ActionSummary({
    required this.priorityActions,
    required this.documents,
    required this.actors,
    required this.fieldChecks,
    required this.expectedProofs,
  });

  final List<PriorityActionSummary> priorityActions;
  final List<DocumentSummaryItem> documents;
  final List<ActorSummaryItem> actors;
  final List<String> fieldChecks;
  final List<String> expectedProofs;
}

class PriorityActionSummary {
  const PriorityActionSummary({
    required this.action,
    required this.risk,
    required this.responsible,
    required this.deadline,
    required this.expectedProof,
    required this.importance,
  });

  final String action;
  final String risk;
  final String responsible;
  final String deadline;
  final String expectedProof;
  final String importance;
}

class DocumentSummaryItem {
  const DocumentSummaryItem({
    required this.document,
    required this.objective,
    required this.expectedResult,
  });

  final String document;
  final String objective;
  final String expectedResult;
}

class ActorSummaryItem {
  const ActorSummaryItem({
    required this.actor,
    required this.reason,
    required this.expectedTrace,
  });

  final String actor;
  final String reason;
  final String expectedTrace;
}

class _SummaryTexts {
  const _SummaryTexts({
    required this.riskToClarify,
    required this.responsibleToConfirm,
    required this.deadlineToConfirm,
    required this.proofToClarify,
    required this.documentObjective,
    required this.documentExpectedResult,
    required this.actorReason,
    required this.actorTrace,
    required this.annexObjective,
    required this.annexExpectedResult,
    required this.emptyImportance,
    required this.importance,
  });

  final String riskToClarify;
  final String responsibleToConfirm;
  final String deadlineToConfirm;
  final String proofToClarify;
  final String documentObjective;
  final String documentExpectedResult;
  final String actorReason;
  final String actorTrace;
  final String annexObjective;
  final String annexExpectedResult;
  final String emptyImportance;
  final String importance;
}
