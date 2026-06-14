import 'document_type.dart';

class PreventionDocumentConfig {
  const PreventionDocumentConfig({
    required this.documentTypeId,
    required this.sections,
  });

  final String documentTypeId;
  final List<PreventionFormSection> sections;
}

class PreventionFormSection {
  const PreventionFormSection({
    required this.key,
    required this.fields,
    this.initiallyExpanded = false,
  });

  final String key;
  final List<PreventionFormField> fields;
  final bool initiallyExpanded;
}

class PreventionFormField {
  const PreventionFormField(this.key, {this.maxLines = 2});

  final String key;
  final int maxLines;
}

const newPreventionDocumentTypeIds = {
  'annual_action_plan',
  'five_year_prevention_plan',
  'safety_visit_report',
  'job_sheet',
  'safety_instruction_sheet',
  'accident_incident_report',
};

bool isNewPreventionDocument(DocumentType type) {
  return newPreventionDocumentTypeIds.contains(type.id);
}

PreventionDocumentConfig? preventionDocumentConfigFor(DocumentType type) {
  return _preventionDocumentConfigs[type.id];
}

String localizedDocumentTypeLabel(DocumentType type, String localeName) {
  final labels = _documentTypeLabels[type.id];
  return labels?[localeName] ?? labels?['fr'] ?? type.label;
}

String localizedPreventionSectionTitle(String key, String localeName) {
  return _sectionLabels[key]?[localeName] ?? _sectionLabels[key]?['fr'] ?? key;
}

String localizedPreventionFieldLabel(String key, String localeName) {
  return _fieldLabels[key]?[localeName] ?? _fieldLabels[key]?['fr'] ?? key;
}

String localizedPreventionFieldHelp(String key, String localeName) {
  final label = localizedPreventionFieldLabel(key, localeName);
  final template = switch (localeName) {
    'nl' =>
      'Beschrijf concreet "$label". Vermeld wat bekend is, wat aanbevolen is en wat nog moet worden gecontroleerd door de preventieadviseur.',
    'en' =>
      'Describe "$label" concretely. Include what is known, what is recommended and what the prevention advisor still needs to verify.',
    'de' =>
      'Beschreiben Sie "$label" konkret. Nennen Sie bekannte Angaben, Empfehlungen und Punkte, die der Präventionsberater noch prüfen muss.',
    _ =>
      'Décrivez concrètement "$label". Indiquez ce qui est connu, ce qui est recommandé et ce que le conseiller en prévention doit encore vérifier.',
  };
  return _fieldHelps[key]?[localeName] ?? _fieldHelps[key]?['fr'] ?? template;
}

Map<String, String> completePreventionExample({
  required DocumentType type,
  required String localeName,
}) {
  final config = preventionDocumentConfigFor(type);
  if (config == null) {
    return const {};
  }

  final base = _baseExamples(localeName);
  return {
    for (final key in _mandatoryExampleFieldKeys)
      if (base.containsKey(key)) key: base[key]!,
    for (final section in config.sections)
      for (final field in section.fields)
        if (!_referenceExampleFieldKeys.contains(field.key))
          field.key: _exampleValue(type.id, field.key, localeName),
  };
}

const _mandatoryExampleFieldKeys = {
  'companyName',
  'site',
  'department',
  'preparedBy',
  'author',
  'version',
  'visitDate',
  'date',
  'serviceConcerned',
  'siteConcerned',
};

const _referenceExampleFieldKeys = {
  'documentReference',
  'reference',
  'analysisNumber',
  'projectNumber',
  'internalReference',
};

const _preventionDocumentConfigs = {
  'annual_action_plan': PreventionDocumentConfig(
    documentTypeId: 'annual_action_plan',
    sections: [
      PreventionFormSection(
        key: 'identification',
        initiallyExpanded: true,
        fields: [
          PreventionFormField('documentReference'),
          PreventionFormField('companyName'),
          PreventionFormField('siteConcerned'),
          PreventionFormField('serviceConcerned'),
          PreventionFormField('planYear'),
          PreventionFormField('preparedBy'),
          PreventionFormField('version'),
        ],
      ),
      PreventionFormSection(
        key: 'sources',
        fields: [
          PreventionFormField('sourcesUsed', maxLines: 4),
          PreventionFormField('preventionObjectives', maxLines: 4),
          PreventionFormField('validationPoints', maxLines: 3),
        ],
      ),
      PreventionFormSection(
        key: 'actionPlan',
        fields: [
          PreventionFormField('plannedActions', maxLines: 6),
          PreventionFormField('responsibles', maxLines: 3),
          PreventionFormField('deadlines', maxLines: 3),
          PreventionFormField('resources', maxLines: 3),
          PreventionFormField('budget', maxLines: 2),
          PreventionFormField('indicators', maxLines: 3),
          PreventionFormField('remarks', maxLines: 3),
        ],
      ),
    ],
  ),
  'five_year_prevention_plan': PreventionDocumentConfig(
    documentTypeId: 'five_year_prevention_plan',
    sections: [
      PreventionFormSection(
        key: 'identification',
        initiallyExpanded: true,
        fields: [
          PreventionFormField('documentReference'),
          PreventionFormField('companyName'),
          PreventionFormField('siteConcerned'),
          PreventionFormField('serviceConcerned'),
          PreventionFormField('coveredPeriod'),
          PreventionFormField('preparedBy'),
          PreventionFormField('version'),
        ],
      ),
      PreventionFormSection(
        key: 'strategy',
        fields: [
          PreventionFormField('mainActivities', maxLines: 4),
          PreventionFormField('riskSynthesis', maxLines: 5),
          PreventionFormField('fiveYearObjectives', maxLines: 5),
          PreventionFormField('priorityAxes', maxLines: 4),
        ],
      ),
      PreventionFormSection(
        key: 'resourcesAndFollowUp',
        fields: [
          PreventionFormField('structuralMeasures', maxLines: 5),
          PreventionFormField('resources', maxLines: 4),
          PreventionFormField('multiYearPlanning', maxLines: 5),
          PreventionFormField('indicators', maxLines: 3),
          PreventionFormField('validations', maxLines: 3),
        ],
      ),
    ],
  ),
  'safety_visit_report': PreventionDocumentConfig(
    documentTypeId: 'safety_visit_report',
    sections: [
      PreventionFormSection(
        key: 'visitIdentification',
        initiallyExpanded: true,
        fields: [
          PreventionFormField('documentReference'),
          PreventionFormField('companyName'),
          PreventionFormField('siteConcerned'),
          PreventionFormField('serviceConcerned'),
          PreventionFormField('visitDateTime'),
          PreventionFormField('visitLocation'),
          PreventionFormField('preparedBy'),
          PreventionFormField('version'),
          PreventionFormField('participants', maxLines: 3),
          PreventionFormField('visitedZone', maxLines: 3),
        ],
      ),
      PreventionFormSection(
        key: 'findings',
        fields: [
          PreventionFormField('positiveFindings', maxLines: 4),
          PreventionFormField('observations', maxLines: 5),
          PreventionFormField('observedRisks', maxLines: 4),
          PreventionFormField('immediateMeasures', maxLines: 4),
        ],
      ),
      PreventionFormSection(
        key: 'followUp',
        fields: [
          PreventionFormField('proposedActions', maxLines: 5),
          PreventionFormField('responsibles', maxLines: 3),
          PreventionFormField('deadlines', maxLines: 3),
          PreventionFormField('evidenceFollowUp', maxLines: 3),
          PreventionFormField('remarks', maxLines: 3),
        ],
      ),
    ],
  ),
  'job_sheet': PreventionDocumentConfig(
    documentTypeId: 'job_sheet',
    sections: [
      PreventionFormSection(
        key: 'jobIdentification',
        initiallyExpanded: true,
        fields: [
          PreventionFormField('documentReference'),
          PreventionFormField('companyName'),
          PreventionFormField('siteConcerned'),
          PreventionFormField('jobTitle'),
          PreventionFormField('serviceConcerned'),
          PreventionFormField('preparedBy'),
          PreventionFormField('version'),
          PreventionFormField('mission', maxLines: 3),
        ],
      ),
      PreventionFormSection(
        key: 'workContent',
        fields: [
          PreventionFormField('mainTasks', maxLines: 5),
          PreventionFormField('workEnvironment', maxLines: 4),
          PreventionFormField('equipmentTools', maxLines: 4),
          PreventionFormField('requiredSkills', maxLines: 4),
        ],
      ),
      PreventionFormSection(
        key: 'prevention',
        fields: [
          PreventionFormField('jobRisks', maxLines: 5),
          PreventionFormField('preventionMeasures', maxLines: 5),
          PreventionFormField('requiredPpe', maxLines: 3),
          PreventionFormField('trainingAuthorizations', maxLines: 3),
          PreventionFormField('specificInstructions', maxLines: 4),
          PreventionFormField('remarks', maxLines: 3),
        ],
      ),
    ],
  ),
  'safety_instruction_sheet': PreventionDocumentConfig(
    documentTypeId: 'safety_instruction_sheet',
    sections: [
      PreventionFormSection(
        key: 'instructionIdentification',
        initiallyExpanded: true,
        fields: [
          PreventionFormField('documentReference'),
          PreventionFormField('companyName'),
          PreventionFormField('siteConcerned'),
          PreventionFormField('serviceConcerned'),
          PreventionFormField('activityMachineTask'),
          PreventionFormField('preparedBy'),
          PreventionFormField('version'),
          PreventionFormField('instructionObjective', maxLines: 3),
        ],
      ),
      PreventionFormSection(
        key: 'safeWork',
        fields: [
          PreventionFormField('hazards', maxLines: 4),
          PreventionFormField('requiredPpe', maxLines: 3),
          PreventionFormField('beforeInstructions', maxLines: 4),
          PreventionFormField('duringInstructions', maxLines: 4),
          PreventionFormField('afterInstructions', maxLines: 4),
          PreventionFormField('forbiddenActions', maxLines: 4),
        ],
      ),
      PreventionFormSection(
        key: 'abnormalEmergency',
        fields: [
          PreventionFormField('anomalyActions', maxLines: 4),
          PreventionFormField('emergencyActions', maxLines: 4),
          PreventionFormField('usefulContacts', maxLines: 3),
          PreventionFormField('diffusionTrainingProof', maxLines: 3),
        ],
      ),
    ],
  ),
  'accident_incident_report': PreventionDocumentConfig(
    documentTypeId: 'accident_incident_report',
    sections: [
      PreventionFormSection(
        key: 'incidentIdentification',
        initiallyExpanded: true,
        fields: [
          PreventionFormField('documentReference'),
          PreventionFormField('companyName'),
          PreventionFormField('siteConcerned'),
          PreventionFormField('serviceConcerned'),
          PreventionFormField('eventDateTime'),
          PreventionFormField('eventLocation'),
          PreventionFormField('preparedBy'),
          PreventionFormField('version'),
          PreventionFormField('personsConcerned', maxLines: 3),
          PreventionFormField('witnesses', maxLines: 3),
        ],
      ),
      PreventionFormSection(
        key: 'factsAndCauses',
        fields: [
          PreventionFormField('factualDescription', maxLines: 5),
          PreventionFormField('consequences', maxLines: 4),
          PreventionFormField('immediateMeasures', maxLines: 4),
          PreventionFormField('probableCauses', maxLines: 4),
          PreventionFormField('immediateCauses', maxLines: 4),
          PreventionFormField('rootCauses', maxLines: 4),
        ],
      ),
      PreventionFormSection(
        key: 'correctiveFollowUp',
        fields: [
          PreventionFormField('correctiveActions', maxLines: 5),
          PreventionFormField('preventiveActions', maxLines: 5),
          PreventionFormField('responsibles', maxLines: 3),
          PreventionFormField('deadlines', maxLines: 3),
          PreventionFormField('evidenceAnnexes', maxLines: 3),
          PreventionFormField('declarationsValidations', maxLines: 3),
        ],
      ),
    ],
  ),
};

const _documentTypeLabels = {
  'annual_action_plan': {
    'fr': 'Plan annuel d’action',
    'nl': 'Jaaractieplan',
    'en': 'Annual Action Plan',
    'de': 'Jährlicher Aktionsplan',
  },
  'five_year_prevention_plan': {
    'fr': 'Plan global de prévention sur 5 ans',
    'nl': 'Globaal preventieplan over 5 jaar',
    'en': 'Five-Year Global Prevention Plan',
    'de': 'Globaler Präventionsplan über 5 Jahre',
  },
  'safety_visit_report': {
    'fr': 'Rapport de visite sécurité',
    'nl': 'Veiligheidsbezoekverslag',
    'en': 'Safety Visit Report',
    'de': 'Sicherheitsbegehungsbericht',
  },
  'job_sheet': {
    'fr': 'Fiche de poste',
    'nl': 'Functiefiche',
    'en': 'Job Description Sheet',
    'de': 'Stellenbeschreibung',
  },
  'safety_instruction_sheet': {
    'fr': 'Fiche d’instruction sécurité',
    'nl': 'Veiligheidsinstructieblad',
    'en': 'Safety Instruction Sheet',
    'de': 'Sicherheitsanweisungsblatt',
  },
  'accident_incident_report': {
    'fr': 'Rapport d’accident ou d’incident',
    'nl': 'Ongevallen- of incidentenrapport',
    'en': 'Accident or Incident Report',
    'de': 'Unfall- oder Vorfallbericht',
  },
};

const _sectionLabels = {
  'identification': {
    'fr': 'A. Identification du document',
    'nl': 'A. Identificatie van het document',
    'en': 'A. Document identification',
    'de': 'A. Dokumentidentifikation',
  },
  'sources': {
    'fr': 'B. Sources et objectifs',
    'nl': 'B. Bronnen en doelstellingen',
    'en': 'B. Sources and objectives',
    'de': 'B. Quellen und Ziele',
  },
  'actionPlan': {
    'fr': 'C. Actions, moyens et suivi',
    'nl': 'C. Acties, middelen en opvolging',
    'en': 'C. Actions, resources and follow-up',
    'de': 'C. Maßnahmen, Mittel und Nachverfolgung',
  },
  'strategy': {
    'fr': 'B. Analyse stratégique',
    'nl': 'B. Strategische analyse',
    'en': 'B. Strategic analysis',
    'de': 'B. Strategische Analyse',
  },
  'resourcesAndFollowUp': {
    'fr': 'C. Ressources, planning et validation',
    'nl': 'C. Middelen, planning en validatie',
    'en': 'C. Resources, planning and validation',
    'de': 'C. Ressourcen, Planung und Validierung',
  },
  'visitIdentification': {
    'fr': 'A. Identification de la visite',
    'nl': 'A. Identificatie van het bezoek',
    'en': 'A. Visit identification',
    'de': 'A. Identifikation der Begehung',
  },
  'findings': {
    'fr': 'B. Constats et risques observés',
    'nl': 'B. Vaststellingen en geobserveerde risico’s',
    'en': 'B. Findings and observed risks',
    'de': 'B. Feststellungen und beobachtete Risiken',
  },
  'followUp': {
    'fr': 'C. Actions et suivi',
    'nl': 'C. Acties en opvolging',
    'en': 'C. Actions and follow-up',
    'de': 'C. Maßnahmen und Nachverfolgung',
  },
  'jobIdentification': {
    'fr': 'A. Identification du poste',
    'nl': 'A. Identificatie van de functie',
    'en': 'A. Job identification',
    'de': 'A. Stellenidentifikation',
  },
  'workContent': {
    'fr': 'B. Activités, environnement et compétences',
    'nl': 'B. Activiteiten, omgeving en competenties',
    'en': 'B. Activities, environment and skills',
    'de': 'B. Tätigkeiten, Umgebung und Kompetenzen',
  },
  'prevention': {
    'fr': 'C. Risques et prévention',
    'nl': 'C. Risico’s en preventie',
    'en': 'C. Risks and prevention',
    'de': 'C. Risiken und Prävention',
  },
  'instructionIdentification': {
    'fr': 'A. Identification de l’instruction',
    'nl': 'A. Identificatie van de instructie',
    'en': 'A. Instruction identification',
    'de': 'A. Identifikation der Anweisung',
  },
  'safeWork': {
    'fr': 'B. Travail sûr',
    'nl': 'B. Veilig werken',
    'en': 'B. Safe work',
    'de': 'B. Sicheres Arbeiten',
  },
  'abnormalEmergency': {
    'fr': 'C. Anomalie, urgence et diffusion',
    'nl': 'C. Afwijking, noodsituatie en verspreiding',
    'en': 'C. Anomaly, emergency and communication',
    'de': 'C. Abweichung, Notfall und Weitergabe',
  },
  'incidentIdentification': {
    'fr': 'A. Identification de l’événement',
    'nl': 'A. Identificatie van de gebeurtenis',
    'en': 'A. Event identification',
    'de': 'A. Ereignisidentifikation',
  },
  'factsAndCauses': {
    'fr': 'B. Faits, conséquences et causes',
    'nl': 'B. Feiten, gevolgen en oorzaken',
    'en': 'B. Facts, consequences and causes',
    'de': 'B. Fakten, Folgen und Ursachen',
  },
  'correctiveFollowUp': {
    'fr': 'C. Actions correctives et validations',
    'nl': 'C. Corrigerende acties en validaties',
    'en': 'C. Corrective actions and validations',
    'de': 'C. Korrekturmaßnahmen und Validierungen',
  },
};

const _fieldLabels = {
  'documentReference': {
    'fr': 'Titre ou référence du document',
    'nl': 'Titel of referentie van het document',
    'en': 'Document title or reference',
    'de': 'Titel oder Referenz des Dokuments',
  },
  'companyName': {
    'fr': 'Entreprise',
    'nl': 'Onderneming',
    'en': 'Company',
    'de': 'Unternehmen',
  },
  'siteConcerned': {'fr': 'Site', 'nl': 'Site', 'en': 'Site', 'de': 'Standort'},
  'serviceConcerned': {
    'fr': 'Service',
    'nl': 'Dienst',
    'en': 'Department',
    'de': 'Dienst',
  },
  'planYear': {
    'fr': 'Année concernée',
    'nl': 'Betrokken jaar',
    'en': 'Year covered',
    'de': 'Betroffenes Jahr',
  },
  'preparedBy': {
    'fr': 'Personne qui prépare le document',
    'nl': 'Persoon die het document voorbereidt',
    'en': 'Prepared by',
    'de': 'Erstellt von',
  },
  'version': {
    'fr': 'Version',
    'nl': 'Versie',
    'en': 'Version',
    'de': 'Version',
  },
  'sourcesUsed': {
    'fr': 'Sources utilisées',
    'nl': 'Gebruikte bronnen',
    'en': 'Sources used',
    'de': 'Verwendete Quellen',
  },
  'preventionObjectives': {
    'fr': 'Objectifs de prévention',
    'nl': 'Preventiedoelstellingen',
    'en': 'Prevention objectives',
    'de': 'Präventionsziele',
  },
  'plannedActions': {
    'fr': 'Actions prévues',
    'nl': 'Geplande acties',
    'en': 'Planned actions',
    'de': 'Geplante Maßnahmen',
  },
  'responsibles': {
    'fr': 'Responsables',
    'nl': 'Verantwoordelijken',
    'en': 'Responsible persons',
    'de': 'Verantwortliche',
  },
  'deadlines': {
    'fr': 'Échéances',
    'nl': 'Termijnen',
    'en': 'Deadlines',
    'de': 'Fristen',
  },
  'resources': {
    'fr': 'Moyens et ressources',
    'nl': 'Middelen en resources',
    'en': 'Means and resources',
    'de': 'Mittel und Ressourcen',
  },
  'budget': {'fr': 'Budget', 'nl': 'Budget', 'en': 'Budget', 'de': 'Budget'},
  'indicators': {
    'fr': 'Indicateurs de suivi',
    'nl': 'Opvolgingsindicatoren',
    'en': 'Follow-up indicators',
    'de': 'Nachverfolgungsindikatoren',
  },
  'remarks': {
    'fr': 'Remarques',
    'nl': 'Opmerkingen',
    'en': 'Remarks',
    'de': 'Bemerkungen',
  },
  'validationPoints': {
    'fr': 'Points à valider',
    'nl': 'Te valideren punten',
    'en': 'Points to validate',
    'de': 'Zu validierende Punkte',
  },
  'coveredPeriod': {
    'fr': 'Période couverte',
    'nl': 'Gedekte periode',
    'en': 'Period covered',
    'de': 'Abgedeckter Zeitraum',
  },
  'mainActivities': {
    'fr': 'Activités principales',
    'nl': 'Belangrijkste activiteiten',
    'en': 'Main activities',
    'de': 'Haupttätigkeiten',
  },
  'riskSynthesis': {
    'fr': 'Synthèse des risques',
    'nl': 'Samenvatting van de risico’s',
    'en': 'Risk synthesis',
    'de': 'Zusammenfassung der Risiken',
  },
  'fiveYearObjectives': {
    'fr': 'Objectifs stratégiques à 5 ans',
    'nl': 'Strategische doelstellingen over 5 jaar',
    'en': 'Five-year strategic objectives',
    'de': 'Strategische Ziele über 5 Jahre',
  },
  'priorityAxes': {
    'fr': 'Axes prioritaires',
    'nl': 'Prioritaire assen',
    'en': 'Priority axes',
    'de': 'Prioritätsachsen',
  },
  'structuralMeasures': {
    'fr': 'Mesures structurelles',
    'nl': 'Structurele maatregelen',
    'en': 'Structural measures',
    'de': 'Strukturelle Maßnahmen',
  },
  'multiYearPlanning': {
    'fr': 'Planning pluriannuel',
    'nl': 'Meerjarenplanning',
    'en': 'Multi-year planning',
    'de': 'Mehrjahresplanung',
  },
  'validations': {
    'fr': 'Validations',
    'nl': 'Validaties',
    'en': 'Validations',
    'de': 'Validierungen',
  },
  'visitDateTime': {
    'fr': 'Date et heure de visite',
    'nl': 'Datum en uur van het bezoek',
    'en': 'Visit date and time',
    'de': 'Datum und Uhrzeit der Begehung',
  },
  'visitLocation': {
    'fr': 'Lieu de visite',
    'nl': 'Plaats van het bezoek',
    'en': 'Visit location',
    'de': 'Ort der Begehung',
  },
  'participants': {
    'fr': 'Participants',
    'nl': 'Deelnemers',
    'en': 'Participants',
    'de': 'Teilnehmende',
  },
  'visitedZone': {
    'fr': 'Objet ou zone visitée',
    'nl': 'Onderwerp of bezochte zone',
    'en': 'Purpose or area visited',
    'de': 'Zweck oder begangener Bereich',
  },
  'positiveFindings': {
    'fr': 'Constats positifs',
    'nl': 'Positieve vaststellingen',
    'en': 'Positive findings',
    'de': 'Positive Feststellungen',
  },
  'observations': {
    'fr': 'Observations ou anomalies',
    'nl': 'Observaties of afwijkingen',
    'en': 'Observations or anomalies',
    'de': 'Beobachtungen oder Abweichungen',
  },
  'observedRisks': {
    'fr': 'Risques observés',
    'nl': 'Geobserveerde risico’s',
    'en': 'Observed risks',
    'de': 'Beobachtete Risiken',
  },
  'immediateMeasures': {
    'fr': 'Mesures immédiates',
    'nl': 'Onmiddellijke maatregelen',
    'en': 'Immediate measures',
    'de': 'Sofortmaßnahmen',
  },
  'proposedActions': {
    'fr': 'Actions proposées',
    'nl': 'Voorgestelde acties',
    'en': 'Proposed actions',
    'de': 'Vorgeschlagene Maßnahmen',
  },
  'evidenceFollowUp': {
    'fr': 'Preuves et suivi',
    'nl': 'Bewijzen en opvolging',
    'en': 'Evidence and follow-up',
    'de': 'Nachweise und Nachverfolgung',
  },
  'jobTitle': {
    'fr': 'Intitulé du poste',
    'nl': 'Functietitel',
    'en': 'Job title',
    'de': 'Stellentitel',
  },
  'mission': {
    'fr': 'Mission',
    'nl': 'Opdracht',
    'en': 'Mission',
    'de': 'Auftrag',
  },
  'mainTasks': {
    'fr': 'Tâches principales',
    'nl': 'Belangrijkste taken',
    'en': 'Main tasks',
    'de': 'Hauptaufgaben',
  },
  'workEnvironment': {
    'fr': 'Environnement de travail',
    'nl': 'Werkomgeving',
    'en': 'Work environment',
    'de': 'Arbeitsumgebung',
  },
  'equipmentTools': {
    'fr': 'Équipements et outils',
    'nl': 'Uitrusting en gereedschap',
    'en': 'Equipment and tools',
    'de': 'Ausrüstung und Werkzeuge',
  },
  'requiredSkills': {
    'fr': 'Compétences requises',
    'nl': 'Vereiste competenties',
    'en': 'Required skills',
    'de': 'Erforderliche Kompetenzen',
  },
  'jobRisks': {
    'fr': 'Risques liés au poste',
    'nl': 'Risico’s verbonden aan de functie',
    'en': 'Job-related risks',
    'de': 'Stellenbezogene Risiken',
  },
  'preventionMeasures': {
    'fr': 'Mesures de prévention',
    'nl': 'Preventiemaatregelen',
    'en': 'Prevention measures',
    'de': 'Präventionsmaßnahmen',
  },
  'requiredPpe': {
    'fr': 'EPI requis',
    'nl': 'Vereiste PBM',
    'en': 'Required PPE',
    'de': 'Erforderliche PSA',
  },
  'trainingAuthorizations': {
    'fr': 'Formations et habilitations',
    'nl': 'Opleidingen en bevoegdheden',
    'en': 'Training and authorizations',
    'de': 'Schulungen und Befähigungen',
  },
  'specificInstructions': {
    'fr': 'Consignes particulières',
    'nl': 'Bijzondere instructies',
    'en': 'Specific instructions',
    'de': 'Besondere Anweisungen',
  },
  'activityMachineTask': {
    'fr': 'Activité, machine ou tâche concernée',
    'nl': 'Betrokken activiteit, machine of taak',
    'en': 'Activity, machine or task concerned',
    'de': 'Betroffene Tätigkeit, Maschine oder Aufgabe',
  },
  'instructionObjective': {
    'fr': 'Objectif de l’instruction',
    'nl': 'Doel van de instructie',
    'en': 'Instruction objective',
    'de': 'Ziel der Anweisung',
  },
  'hazards': {
    'fr': 'Dangers',
    'nl': 'Gevaren',
    'en': 'Hazards',
    'de': 'Gefährdungen',
  },
  'beforeInstructions': {
    'fr': 'Consignes avant le travail',
    'nl': 'Instructies vóór het werk',
    'en': 'Instructions before work',
    'de': 'Anweisungen vor der Arbeit',
  },
  'duringInstructions': {
    'fr': 'Consignes pendant le travail',
    'nl': 'Instructies tijdens het werk',
    'en': 'Instructions during work',
    'de': 'Anweisungen während der Arbeit',
  },
  'afterInstructions': {
    'fr': 'Consignes après le travail',
    'nl': 'Instructies na het werk',
    'en': 'Instructions after work',
    'de': 'Anweisungen nach der Arbeit',
  },
  'forbiddenActions': {
    'fr': 'Actions interdites',
    'nl': 'Verboden handelingen',
    'en': 'Forbidden actions',
    'de': 'Verbotene Handlungen',
  },
  'anomalyActions': {
    'fr': 'Conduite à tenir en cas d’anomalie',
    'nl': 'Wat te doen bij een afwijking',
    'en': 'What to do in case of anomaly',
    'de': 'Vorgehen bei Abweichungen',
  },
  'emergencyActions': {
    'fr': 'Conduite à tenir en cas d’urgence',
    'nl': 'Wat te doen in een noodsituatie',
    'en': 'What to do in an emergency',
    'de': 'Vorgehen im Notfall',
  },
  'usefulContacts': {
    'fr': 'Contacts utiles',
    'nl': 'Nuttige contacten',
    'en': 'Useful contacts',
    'de': 'Nützliche Kontakte',
  },
  'diffusionTrainingProof': {
    'fr': 'Diffusion, formation et preuve',
    'nl': 'Verspreiding, opleiding en bewijs',
    'en': 'Communication, training and proof',
    'de': 'Weitergabe, Schulung und Nachweis',
  },
  'eventDateTime': {
    'fr': 'Date et heure de l’événement',
    'nl': 'Datum en uur van de gebeurtenis',
    'en': 'Event date and time',
    'de': 'Datum und Uhrzeit des Ereignisses',
  },
  'eventLocation': {
    'fr': 'Lieu de l’événement',
    'nl': 'Plaats van de gebeurtenis',
    'en': 'Event location',
    'de': 'Ort des Ereignisses',
  },
  'personsConcerned': {
    'fr': 'Personne(s) concernée(s)',
    'nl': 'Betrokken persoon/personen',
    'en': 'Person(s) concerned',
    'de': 'Betroffene Person(en)',
  },
  'witnesses': {
    'fr': 'Témoins',
    'nl': 'Getuigen',
    'en': 'Witnesses',
    'de': 'Zeugen',
  },
  'factualDescription': {
    'fr': 'Description factuelle',
    'nl': 'Feitelijke beschrijving',
    'en': 'Factual description',
    'de': 'Sachliche Beschreibung',
  },
  'consequences': {
    'fr': 'Conséquences',
    'nl': 'Gevolgen',
    'en': 'Consequences',
    'de': 'Folgen',
  },
  'probableCauses': {
    'fr': 'Causes probables',
    'nl': 'Waarschijnlijke oorzaken',
    'en': 'Probable causes',
    'de': 'Wahrscheinliche Ursachen',
  },
  'immediateCauses': {
    'fr': 'Causes immédiates',
    'nl': 'Directe oorzaken',
    'en': 'Immediate causes',
    'de': 'Unmittelbare Ursachen',
  },
  'rootCauses': {
    'fr': 'Causes profondes',
    'nl': 'Dieperliggende oorzaken',
    'en': 'Root causes',
    'de': 'Grundursachen',
  },
  'correctiveActions': {
    'fr': 'Actions correctives',
    'nl': 'Corrigerende acties',
    'en': 'Corrective actions',
    'de': 'Korrekturmaßnahmen',
  },
  'preventiveActions': {
    'fr': 'Actions préventives',
    'nl': 'Preventieve acties',
    'en': 'Preventive actions',
    'de': 'Präventive Maßnahmen',
  },
  'evidenceAnnexes': {
    'fr': 'Preuves et annexes',
    'nl': 'Bewijzen en bijlagen',
    'en': 'Evidence and annexes',
    'de': 'Nachweise und Anhänge',
  },
  'declarationsValidations': {
    'fr': 'Déclarations et validations à vérifier',
    'nl': 'Te controleren aangiften en validaties',
    'en': 'Declarations and validations to verify',
    'de': 'Zu prüfende Meldungen und Validierungen',
  },
};

const _fieldHelps = {
  'sourcesUsed': {
    'fr':
        'Listez les analyses, accidents, visites, remarques CPPT, rapports de contrôle ou obligations qui justifient les actions.',
    'nl':
        'Vermeld analyses, ongevallen, bezoeken, CPBW-opmerkingen, keuringsverslagen of verplichtingen die de acties onderbouwen.',
    'en':
        'List risk assessments, accidents, visits, committee remarks, inspection reports or legal drivers that support the actions.',
    'de':
        'Nennen Sie Beurteilungen, Unfälle, Begehungen, Ausschussbemerkungen, Prüfberichte oder Pflichten, die die Maßnahmen begründen.',
  },
  'plannedActions': {
    'fr':
        'Formulez des actions concrètes, attribuables et vérifiables, pas seulement des intentions générales.',
    'nl':
        'Formuleer concrete, toewijsbare en controleerbare acties, niet alleen algemene intenties.',
    'en':
        'Write concrete, assignable and verifiable actions, not only general intentions.',
    'de':
        'Formulieren Sie konkrete, zuweisbare und prüfbare Maßnahmen, nicht nur allgemeine Absichten.',
  },
  'riskSynthesis': {
    'fr':
        'Résumez les risques majeurs, les tendances et les thèmes qui nécessitent une approche pluriannuelle.',
    'nl':
        'Vat de belangrijkste risico’s, trends en thema’s samen die een meerjarige aanpak vragen.',
    'en':
        'Summarize major risks, trends and themes that require a multi-year approach.',
    'de':
        'Fassen Sie wesentliche Risiken, Trends und Themen zusammen, die einen mehrjährigen Ansatz erfordern.',
  },
  'observations': {
    'fr':
        'Décrivez les anomalies observées de façon factuelle: lieu, situation, fréquence et preuve éventuelle.',
    'nl':
        'Beschrijf afwijkingen feitelijk: plaats, situatie, frequentie en eventueel bewijs.',
    'en':
        'Describe anomalies factually: location, situation, frequency and possible evidence.',
    'de':
        'Beschreiben Sie Abweichungen sachlich: Ort, Situation, Häufigkeit und mögliche Nachweise.',
  },
  'factualDescription': {
    'fr':
        'Restez factuel: ce qui s’est passé, avant/pendant/après, sans conclure trop vite sur les responsabilités.',
    'nl':
        'Blijf feitelijk: wat gebeurde vóór/tijdens/na het voorval, zonder te snel conclusies over verantwoordelijkheid te trekken.',
    'en':
        'Stay factual: what happened before/during/after, without jumping to conclusions about responsibility.',
    'de':
        'Bleiben Sie sachlich: was vor/während/nach dem Ereignis geschah, ohne vorschnell Verantwortlichkeiten festzulegen.',
  },
};

String _exampleValue(
  String documentTypeId,
  String fieldKey,
  String localeName,
) {
  final base = _baseExamples(localeName);
  if (base.containsKey(fieldKey)) {
    return base[fieldKey]!;
  }
  final concrete = _concreteFieldExamples(localeName);
  if (concrete.containsKey(fieldKey)) {
    return concrete[fieldKey]!;
  }

  final label = localizedPreventionFieldLabel(fieldKey, localeName);
  return switch (localeName) {
    'nl' =>
      '$label: gemeentelijke technische dienst Verviers; situatie te controleren in werkplaats, garage voertuigen, opslagzones, wegenisploeg en groendienst.',
    'en' =>
      '$label: Verviers municipal technical department; situation to check in the workshop, vehicle garage, storage areas, road crew and green spaces team.',
    'de' =>
      '$label: Technischer Dienst der Stadt Verviers; Situation in Werkstatt, Fahrzeuggarage, Lagerbereichen, Straßenkolonne und Grünflächendienst zu prüfen.',
    _ =>
      '$label : service technique communal de Verviers; situation à vérifier dans l’atelier, le garage véhicules, les zones de stockage, la voirie et les espaces verts.',
  };
}

Map<String, String> _concreteFieldExamples(String localeName) {
  return switch (localeName) {
    'nl' => const {
      'sourcesUsed':
          'Risicoanalyse van de technische dienst 2025, bezoekverslag terreinbezoek van 07/06/2026, incidentmeldingen over struikelen en snijwonden, VIB voor chemische producten, keuringsverslagen hefbruggen en arbeidsmiddelen, opmerkingen van het CPBW.',
      'preventionObjectives':
          'Het aantal kleine ongevallen in werkplaats en garage met 25% verminderen, opslagzones vrijmaken van doorgangen, opleiding veilig gebruik slijpmachine en bosmaaier organiseren, keuringen en PBM-draging opvolgen.',
      'plannedActions':
          '| Nr. | Thema | Maatregel | Verantwoordelijke | Termijn | Bewijs |\n| 1 | Opslag | Rekken B3-B5 herindelen en draaglasten afficheren | Ploegbaas onderhoud | 30/09/2026 | Foto’s en controlelijst |\n| 2 | Machines | Toolbox slijpmachine en afscherming vonken | Preventieadviseur | 31/10/2026 | Aanwezigheidslijst |\n| 3 | Verkeer | Voetgangerszone aan garagepoort markeren | Diensthoofd | 31/12/2026 | Werkbon en foto |',
      'resources':
          'Signalisatieverf, reklabels, PBM-voorraad, twee uur toolbox per ploeg, ondersteuning magazijnier en onderhoudsploeg.',
      'mainActivities':
          'Onderhoud gemeentelijke gebouwen, kleine herstellingen aan voertuigen, opslag en verdeling van materialen, interventies op wegenis, onderhoud van groenzones en winterdienst.',
      'fiveYearObjectives':
          'Tegen 2030: gescheiden verkeersstromen in garage en opslag, opvolging via het jaaractieplan, prioriteiten uit het globaal preventieplan, jaarlijks opleidingsplan voor technische ploegen, gestandaardiseerde veiligheidsinstructies voor machines, digitaal opvolgregister voor acties.',
      'priorityAxes':
          '1. Orde en netheid in opslagzones. 2. Machineveiligheid. 3. Verkeer voertuigen/voetgangers. 4. Ergonomie bij laden en lossen. 5. Chemische producten in garage en groenonderhoud.',
      'structuralMeasures':
          'Herinrichting rekken, aankoop afsluitbare kast voor gevaarlijke producten, markering loopzones, jaarlijkse keuring arbeidsmiddelen, standaard onthaalfiche voor nieuwe medewerkers.',
      'multiYearPlanning':
          '2026 opslag en signalisatie; 2027 machine-instructies; 2028 ergonomische hulpmiddelen; 2029 verkeersplan technische site; 2030 audit en actualisatie.',
      'validations':
          'Valideren door gemeentesecretaris, diensthoofd technische dienst, preventieadviseur en CPBW; nagaan of budgetlijnen 2026-2030 zijn voorzien.',
      'participants':
          'Diensthoofd technische dienst, ploegbaas onderhoud, magazijnier, preventieadviseur en twee werknemers van wegenis/groen.',
      'visitedZone':
          'Werkplaats met slijpbank, garage voertuigen, opslagrekken B1-B6, buitenopslag zout en materialen, zone groenonderhoud.',
      'positiveFindings':
          'Brandblussers zijn bereikbaar, EHBO-koffer is aanwezig, afvalolie wordt in afgesloten recipiënt bewaard, hefbrug heeft geldig keuringsverslag.',
      'observations':
          'Doorgang aan rek B3 gedeeltelijk geblokkeerd door signalisatiepanelen; verlengkabel op vloer bij werkbank; PBM-kast niet aangevuld met snijbestendige handschoenen maat 9.',
      'observedRisks':
          'Struikelen, vallende materialen, snijwonden bij slijpen, aanrijding bij achteruitrijden bestelwagen, blootstelling aan lawaai en stof.',
      'immediateMeasures':
          'Losse kabel verwijderd, doorgang vrijgemaakt, defecte veiligheidsbril uit dienst genomen, medewerkers herinnerd aan gehoorbescherming.',
      'proposedActions':
          '| Actie | Verantwoordelijke | Termijn | Bewijs |\n| Markering doorgangen opslag | Ploegbaas | 30/09/2026 | Foto |\n| PBM-kast aanvullen | Magazijnier | 15/07/2026 | Bestelbon |\n| Toolbox achteruitrijden | Preventieadviseur | 31/10/2026 | Presentielijst |',
      'evidenceFollowUp':
          'Foto’s voor/na, werkbonnen technische dienst, bestelbonnen PBM, aanwezigheidslijsten toolbox, verslag CPBW.',
      'mission':
          'Uitvoeren van onderhouds- en herstellingswerken voor gemeentelijke gebouwen, wegenis en groenzones met aandacht voor veiligheid van collega’s en burgers.',
      'mainTasks':
          'Materialen laden en lossen, kleine herstellingen uitvoeren, signalisatie plaatsen, groenzones onderhouden, voertuigen reinigen, werkplaats ordelijk houden.',
      'workEnvironment':
          'Binnenwerk in atelier en garage, buitenwerk op gemeentewegen en groenzones, wisselende weersomstandigheden, aanwezigheid van voertuigen en publiek.',
      'equipmentTools':
          'Bestelwagen, handgereedschap, slijpmachine, boormachine, hogedrukreiniger, bosmaaier, ladders, rekken en hefmiddelen.',
      'requiredSkills':
          'Rijbewijs B, basiskennis veilig werken met handmachines, lezen van werkbonnen, communicatie met ploegbaas, fysieke geschiktheid voor buitenwerk.',
      'jobRisks':
          'Snijwonden, projecties, lawaai, trillingen, manueel hanteren van lasten, vallen op gelijke hoogte, verkeer op openbare weg.',
      'preventionMeasures':
          'Werkzone afbakenen, machines controleren voor gebruik, PBM dragen, lasten met twee personen verplaatsen, defect materiaal melden.',
      'requiredPpe':
          'Veiligheidsschoenen S3, werkhandschoenen, veiligheidsbril, gehoorbescherming, fluohesje, stofmasker FFP2 bij stofvorming.',
      'trainingAuthorizations':
          'Onthaalveiligheid, toolbox slijpmachine, signalisatie op openbare weg, gebruik kleine arbeidsmiddelen, EHBO-contactprocedure.',
      'specificInstructions':
          'Niet alleen slijpen in afgesloten ruimte; vonken weg richten van brandbare materialen; incidenten onmiddellijk melden aan ploegbaas.',
      'instructionObjective':
          'Veilig gebruik van de haakse slijper bij kleine herstellingen in de gemeentelijke werkplaats.',
      'hazards':
          'Projecties van metaal, snijwonden, vonken, lawaai, stof, brandrisico bij opslag van brandbare materialen.',
      'beforeInstructions':
          'Controleer schijf, beschermkap, kabel en dodemansknop; verwijder brandbare materialen binnen twee meter; draag PBM.',
      'duringInstructions':
          'Werkstuk klemmen, twee handen op machine houden, niet boven schouderhoogte slijpen, collega’s buiten projectiezone houden.',
      'afterInstructions':
          'Machine laten stoppen voor neerleggen, stekker uittrekken, stof verwijderen, beschadigde schijven apart leggen en melden.',
      'forbiddenActions':
          'Beschermkap verwijderen, versleten schijf gebruiken, slijpen naast brandbare vloeistoffen, machine doorgeven terwijl ze draait.',
      'anomalyActions':
          'Stop het werk, koppel de machine los, verwittig ploegbaas, label defect materiaal en registreer de melding.',
      'emergencyActions':
          'Bij snijwonde EHBO oproepen; bij brand blusser gebruiken indien veilig en 112 bellen; incident melden aan preventieadviseur.',
      'usefulContacts':
          'Ploegbaas onderhoud 087/xx.xx.xx; preventieadviseur; onthaal gemeentehuis; noodnummer 112.',
      'diffusionTrainingProof':
          'Instructie ophangen bij werkbank, bespreken in toolbox van september 2026, werknemers laten tekenen op aanwezigheidslijst.',
      'personsConcerned':
          'Ouvrier polyvalent van technische dienst, geen externe werknemer betrokken.',
      'witnesses': 'Ploegbaas onderhoud en magazijnier aanwezig in opslagzone.',
      'factualDescription':
          'Tijdens het verplaatsen van signalisatiepanelen struikelde de werknemer over een losliggende verlengkabel aan rek B3 en viel op de linkerknie.',
      'consequences':
          'Lichte kneuzing knie, werk onderbroken voor verzorging, geen materiële schade.',
      'probableCauses':
          'Kabel over doorgang, tijdelijke opslag buiten aangeduide zone, onvoldoende controle orde en netheid aan begin shift.',
      'immediateCauses': 'Losliggende kabel en geblokkeerde doorgang.',
      'rootCauses':
          'Geen vaste kabelhaspel aan werkbank, onduidelijke opslagregels voor tijdelijke signalisatiepanelen.',
      'correctiveActions':
          'Kabelhaspel monteren, doorgangen markeren, opslagplaats voor signalisatiepanelen vastleggen.',
      'preventiveActions':
          'Maandelijkse 5S-rondgang, toolbox struikelgevaar, controle door ploegbaas op vrijdag.',
      'evidenceAnnexes':
          'Foto plaats incident, EHBO-register, getuigenverklaring, werkbon kabelhaspel, foto markering doorgang.',
      'declarationsValidations':
          'Nagaan of aangifte arbeidsongeval nodig is; validatie door werkgever en preventieadviseur; bespreking CPBW.',
    },
    'en' => const {
      'sourcesUsed':
          '2025 risk assessment for the technical department, site visit report of 07/06/2026, incident reports on trips and cuts, SDS for chemical products, inspection reports for lifts and work equipment, health and safety committee remarks.',
      'preventionObjectives':
          'Reduce minor accidents in the workshop and garage by 25%, clear storage walkways, train workers on angle grinder and brush cutter use, follow up inspections and PPE use.',
      'plannedActions':
          '| No. | Theme | Measure | Owner | Deadline | Evidence |\n| 1 | Storage | Reorganise racks B3-B5 and display load limits | Maintenance team leader | 30/09/2026 | Photos and checklist |\n| 2 | Machines | Toolbox on angle grinder and spark shielding | Prevention advisor | 31/10/2026 | Attendance sheet |\n| 3 | Traffic | Mark pedestrian zone at garage door | Department manager | 31/12/2026 | Work order and photo |',
      'resources':
          'Signage paint, rack labels, PPE stock, two-hour toolbox per team, support from the storekeeper and maintenance crew.',
      'mainActivities':
          'Maintenance of municipal buildings, minor vehicle repairs, storage and distribution of materials, road interventions, green space maintenance and winter service.',
      'fiveYearObjectives':
          'By 2030: separated vehicle and pedestrian flows, Annual Action Plan follow-up, Global Prevention Plan priorities, annual training plan, standard safety instructions for machines, digital action tracking register.',
      'priorityAxes':
          '1. Housekeeping in storage areas. 2. Machine safety. 3. Vehicle and pedestrian traffic. 4. Ergonomics during loading. 5. Chemical products in garage and green work.',
      'structuralMeasures':
          'Reorganise racks, buy lockable hazardous products cabinet, mark walkways, annual work equipment inspections, standard induction sheet.',
      'multiYearPlanning':
          '2026 storage and signage; 2027 machine instructions; 2028 ergonomic aids; 2029 traffic plan for the technical site; 2030 audit and update.',
      'validations':
          'Validate with municipal secretary, technical department manager, prevention advisor and committee; check budget lines for 2026-2030.',
      'participants':
          'Technical department manager, maintenance team leader, storekeeper, prevention advisor and two road/green space workers.',
      'visitedZone':
          'Workshop with grinding bench, vehicle garage, racks B1-B6, outdoor salt and material storage, green space area.',
      'positiveFindings':
          'Extinguishers are accessible, first-aid kit is present, waste oil is stored in a closed container, vehicle lift inspection is valid.',
      'observations':
          'Walkway at rack B3 partly blocked by road signs; extension cable on floor near workbench; PPE cabinet missing cut-resistant gloves size 9.',
      'observedRisks':
          'Trips, falling materials, cuts during grinding, collision during reversing van, exposure to noise and dust.',
      'immediateMeasures':
          'Loose cable removed, walkway cleared, defective goggles withdrawn, workers reminded to use hearing protection.',
      'proposedActions':
          '| Action | Owner | Deadline | Evidence |\n| Mark storage walkways | Team leader | 30/09/2026 | Photo |\n| Refill PPE cabinet | Storekeeper | 15/07/2026 | Purchase order |\n| Toolbox on reversing | Prevention advisor | 31/10/2026 | Attendance sheet |',
      'evidenceFollowUp':
          'Before/after photos, technical department work orders, PPE purchase orders, toolbox attendance sheets, committee minutes.',
      'mission':
          'Carry out maintenance and repair work for municipal buildings, roads and green spaces while protecting colleagues and citizens.',
      'mainTasks':
          'Load and unload materials, perform minor repairs, install signage, maintain green spaces, clean vehicles, keep the workshop tidy.',
      'workEnvironment':
          'Indoor work in workshop and garage, outdoor work on municipal roads and green spaces, changing weather, vehicles and public nearby.',
      'equipmentTools':
          'Van, hand tools, angle grinder, drill, pressure washer, brush cutter, ladders, racks and lifting aids.',
      'requiredSkills':
          'Driving licence B, basic safe use of hand machines, reading work orders, communication with team leader, physical fitness for outdoor work.',
      'jobRisks':
          'Cuts, projections, noise, vibration, manual handling, slips and trips, traffic on public roads.',
      'preventionMeasures':
          'Mark work area, check machines before use, wear PPE, move heavy loads with two people, report defective equipment.',
      'requiredPpe':
          'S3 safety shoes, work gloves, safety goggles, hearing protection, high-visibility vest, FFP2 mask when dust is produced.',
      'trainingAuthorizations':
          'Safety induction, angle grinder toolbox, public road signage, small work equipment use, first-aid contact procedure.',
      'specificInstructions':
          'Do not grind alone in an enclosed room; direct sparks away from combustible materials; report incidents immediately.',
      'instructionObjective':
          'Safe use of the angle grinder for minor repairs in the municipal workshop.',
      'hazards':
          'Metal projections, cuts, sparks, noise, dust, fire risk near combustible storage.',
      'beforeInstructions':
          'Check disc, guard, cable and dead-man switch; remove combustible materials within two metres; wear PPE.',
      'duringInstructions':
          'Clamp the workpiece, keep two hands on the machine, do not grind above shoulder height, keep colleagues outside projection zone.',
      'afterInstructions':
          'Let machine stop before putting it down, unplug it, remove dust, set damaged discs aside and report them.',
      'forbiddenActions':
          'Remove guard, use worn disc, grind near flammable liquids, hand over machine while running.',
      'anomalyActions':
          'Stop work, unplug machine, inform team leader, label defective equipment and record report.',
      'emergencyActions':
          'For cuts call first aid; for fire use extinguisher if safe and call 112; report incident to prevention advisor.',
      'usefulContacts':
          'Maintenance team leader 087/xx.xx.xx; prevention advisor; municipal reception; emergency number 112.',
      'diffusionTrainingProof':
          'Post instruction at workbench, discuss in September 2026 toolbox, workers sign attendance sheet.',
      'personsConcerned':
          'Multi-skilled worker from the technical department, no external worker involved.',
      'witnesses':
          'Maintenance team leader and storekeeper present in storage area.',
      'factualDescription':
          'While moving road signs, the worker tripped over a loose extension cable at rack B3 and fell on the left knee.',
      'consequences':
          'Minor knee bruise, work interrupted for first aid, no material damage.',
      'probableCauses':
          'Cable across walkway, temporary storage outside marked area, insufficient housekeeping check at start of shift.',
      'immediateCauses': 'Loose cable and blocked walkway.',
      'rootCauses':
          'No fixed cable reel at workbench, unclear storage rules for temporary road signs.',
      'correctiveActions':
          'Install cable reel, mark walkways, define storage location for road signs.',
      'preventiveActions':
          'Monthly 5S walk, toolbox on trip hazards, Friday check by team leader.',
      'evidenceAnnexes':
          'Incident location photo, first-aid register, witness statement, cable reel work order, walkway marking photo.',
      'declarationsValidations':
          'Check whether occupational accident declaration is required; validation by employer and prevention advisor; committee discussion.',
    },
    'de' => const {
      'sourcesUsed':
          'Gefährdungsbeurteilung technischer Dienst 2025, Bericht der Vor-Ort-Besichtigung vom 07.06.2026, Meldungen zu Stolpern und Schnittverletzungen, Sicherheitsdatenblätter für chemische Produkte, Prüfberichte Hebebühnen und Arbeitsmittel, Bemerkungen des Ausschusses für Gefahrenverhütung und Schutz am Arbeitsplatz.',
      'preventionObjectives':
          'Kleine Unfälle in Werkstatt und Garage um 25 % senken, Lagergänge freihalten, Schulung für Winkelschleifer und Freischneider organisieren, Prüfungen und PSA-Nutzung verfolgen.',
      'plannedActions':
          '| Nr. | Thema | Maßnahme | Verantwortlich | Frist | Nachweis |\n| 1 | Lager | Regale B3-B5 neu ordnen und Traglasten anzeigen | Teamleitung Instandhaltung | 30.09.2026 | Fotos und Checkliste |\n| 2 | Maschinen | Toolbox Winkelschleifer und Funkenschutz | Präventionsberater | 31.10.2026 | Anwesenheitsliste |\n| 3 | Verkehr | Fußgängerzone am Garagentor markieren | Dienstleitung | 31.12.2026 | Arbeitsauftrag und Foto |',
      'resources':
          'Markierungsfarbe, Regaletiketten, PSA-Bestand, zwei Stunden Toolbox je Team, Unterstützung durch Lagerverwalter und Instandhaltung.',
      'mainActivities':
          'Unterhalt kommunaler Gebäude, kleinere Fahrzeugreparaturen, Lagerung und Verteilung von Material, Straßeneinsätze, Grünflächenpflege und Winterdienst.',
      'fiveYearObjectives':
          'Bis 2030: getrennte Fahrzeug- und Fußgängerwege, Nachverfolgung im Jährlichen Aktionsplan, Prioritäten des Globalen Präventionsplans, jährlicher Schulungsplan, standardisierte Maschinenanweisungen, digitales Maßnahmenregister.',
      'priorityAxes':
          '1. Ordnung in Lagerbereichen. 2. Maschinensicherheit. 3. Fahrzeug- und Fußgängerverkehr. 4. Ergonomie beim Laden. 5. Chemische Produkte in Garage und Grünpflege.',
      'structuralMeasures':
          'Regale neu organisieren, abschließbaren Gefahrstoffschrank kaufen, Gehwege markieren, jährliche Prüfungen, Standard-Unterweisungsblatt.',
      'multiYearPlanning':
          '2026 Lager und Beschilderung; 2027 Maschinenanweisungen; 2028 ergonomische Hilfsmittel; 2029 Verkehrsplan; 2030 Audit und Aktualisierung.',
      'validations':
          'Validierung durch Gemeindesekretär, Dienstleitung, Präventionsberater und Ausschuss für Gefahrenverhütung und Schutz am Arbeitsplatz; Budgetlinien 2026-2030 prüfen.',
      'participants':
          'Dienstleitung technischer Dienst, Teamleitung Instandhaltung, Lagerverwalter, Präventionsberater und zwei Beschäftigte Straßen/Grünflächen.',
      'visitedZone':
          'Werkstatt mit Schleifbank, Fahrzeuggarage, Regale B1-B6, Außenlager Salz und Material, Grünflächenbereich.',
      'positiveFindings':
          'Feuerlöscher zugänglich, Erste-Hilfe-Kasten vorhanden, Altöl in geschlossenem Behälter, gültige Prüfung der Hebebühne.',
      'observations':
          'Durchgang bei Regal B3 teilweise durch Verkehrsschilder blockiert; Verlängerungskabel am Boden; PSA-Schrank ohne schnittfeste Handschuhe Größe 9.',
      'observedRisks':
          'Stolpern, fallendes Material, Schnittverletzungen beim Schleifen, Kollision beim Rückwärtsfahren, Lärm- und Staubexposition.',
      'immediateMeasures':
          'Loses Kabel entfernt, Durchgang freigemacht, defekte Schutzbrille ausgesondert, Beschäftigte an Gehörschutz erinnert.',
      'proposedActions':
          '| Maßnahme | Verantwortlich | Frist | Nachweis |\n| Lagergänge markieren | Teamleitung | 30.09.2026 | Foto |\n| PSA-Schrank auffüllen | Lagerverwalter | 15.07.2026 | Bestellung |\n| Toolbox Rückwärtsfahren | Präventionsberater | 31.10.2026 | Anwesenheitsliste |',
      'evidenceFollowUp':
          'Vorher-nachher-Fotos, Arbeitsaufträge, PSA-Bestellungen, Anwesenheitslisten, Ausschussprotokoll.',
      'mission':
          'Wartungs- und Reparaturarbeiten für kommunale Gebäude, Straßen und Grünflächen durchführen und Kollegen sowie Bürger schützen.',
      'mainTasks':
          'Material laden und entladen, kleine Reparaturen durchführen, Beschilderung aufstellen, Grünflächen pflegen, Fahrzeuge reinigen, Werkstatt ordentlich halten.',
      'workEnvironment':
          'Innenarbeit in Werkstatt und Garage, Außenarbeit auf Gemeindestraßen und Grünflächen, wechselndes Wetter, Fahrzeuge und Öffentlichkeit in der Nähe.',
      'equipmentTools':
          'Transporter, Handwerkzeuge, Winkelschleifer, Bohrmaschine, Hochdruckreiniger, Freischneider, Leitern, Regale und Hebehilfen.',
      'requiredSkills':
          'Führerschein B, Grundkenntnisse sicherer Umgang mit Handmaschinen, Arbeitsaufträge lesen, Kommunikation mit Teamleitung, Eignung für Außenarbeit.',
      'jobRisks':
          'Schnittverletzungen, Projektionen, Lärm, Vibrationen, manuelles Heben, Ausrutschen und Stolpern, Verkehr auf öffentlicher Straße.',
      'preventionMeasures':
          'Arbeitsbereich abgrenzen, Maschinen vor Nutzung prüfen, PSA tragen, schwere Lasten zu zweit bewegen, defekte Geräte melden.',
      'requiredPpe':
          'S3-Sicherheitsschuhe, Arbeitshandschuhe, Schutzbrille, Gehörschutz, Warnweste, FFP2-Maske bei Staub.',
      'trainingAuthorizations':
          'Sicherheitsunterweisung, Toolbox Winkelschleifer, Beschilderung öffentlicher Straßen, kleine Arbeitsmittel, Erste-Hilfe-Kontaktverfahren.',
      'specificInstructions':
          'Nicht allein in geschlossenem Raum schleifen; Funken von brennbaren Materialien weg richten; Ereignisse sofort melden.',
      'instructionObjective':
          'Sichere Verwendung des Winkelschleifers für kleine Reparaturen in der kommunalen Werkstatt.',
      'hazards':
          'Metallprojektionen, Schnittverletzungen, Funken, Lärm, Staub, Brandgefahr bei brennbarer Lagerung.',
      'beforeInstructions':
          'Scheibe, Schutzhaube, Kabel und Totmannschalter prüfen; brennbare Materialien in zwei Metern entfernen; PSA tragen.',
      'duringInstructions':
          'Werkstück einspannen, Maschine mit zwei Händen halten, nicht über Schulterhöhe schleifen, Kollegen außerhalb der Projektionszone halten.',
      'afterInstructions':
          'Maschine vor Ablegen auslaufen lassen, Stecker ziehen, Staub entfernen, beschädigte Scheiben aussortieren und melden.',
      'forbiddenActions':
          'Schutzhaube entfernen, abgenutzte Scheibe verwenden, neben brennbaren Flüssigkeiten schleifen, laufende Maschine weitergeben.',
      'anomalyActions':
          'Arbeit stoppen, Maschine trennen, Teamleitung informieren, defektes Gerät kennzeichnen und Meldung erfassen.',
      'emergencyActions':
          'Bei Schnittverletzung Erste Hilfe rufen; bei Brand löschen wenn sicher und 112 rufen; Ereignis dem Präventionsberater melden.',
      'usefulContacts':
          'Teamleitung Instandhaltung 087/xx.xx.xx; Präventionsberater; Empfang Rathaus; Notruf 112.',
      'diffusionTrainingProof':
          'Anweisung an Werkbank aushängen, in Toolbox September 2026 besprechen, Beschäftigte unterschreiben Anwesenheitsliste.',
      'personsConcerned':
          'Mehrzweck-Technikmitarbeiter des technischen Dienstes, kein externer Beschäftigter beteiligt.',
      'witnesses':
          'Teamleitung Instandhaltung und Lagerverwalter im Lagerbereich anwesend.',
      'factualDescription':
          'Beim Bewegen von Verkehrsschildern stolperte der Beschäftigte über ein loses Verlängerungskabel bei Regal B3 und fiel auf das linke Knie.',
      'consequences':
          'Leichte Knieprellung, Arbeit für Erste Hilfe unterbrochen, kein Sachschaden.',
      'probableCauses':
          'Kabel im Durchgang, temporäre Lagerung außerhalb markierter Zone, unzureichende Ordnungskontrolle zu Schichtbeginn.',
      'immediateCauses': 'Loses Kabel und blockierter Durchgang.',
      'rootCauses':
          'Keine feste Kabeltrommel an Werkbank, unklare Lagerregeln für temporäre Verkehrsschilder.',
      'correctiveActions':
          'Kabeltrommel montieren, Durchgänge markieren, Lagerplatz für Verkehrsschilder festlegen.',
      'preventiveActions':
          'Monatlicher 5S-Rundgang, Toolbox Stolpergefahr, Freitagskontrolle durch Teamleitung.',
      'evidenceAnnexes':
          'Foto Ereignisort, Erste-Hilfe-Register, Zeugenaussage, Arbeitsauftrag Kabeltrommel, Foto Durchgangsmarkierung.',
      'declarationsValidations':
          'Prüfen, ob Unfallmeldung nötig ist; Validierung durch Arbeitgeber und Präventionsberater; Besprechung im Ausschuss.',
    },
    _ => const {
      'sourcesUsed':
          'Analyse de risques 2025 du service technique, rapport de visite du 07/06/2026, déclarations d’incidents liés aux chutes de plain-pied et coupures, rapports de contrôle des ponts et outils électriques, remarques CPPT.',
      'preventionObjectives':
          'Réduire de 25 % les petits accidents dans l’atelier et le garage, dégager les circulations de stockage, former à la meuleuse et à la débroussailleuse, suivre les contrôles et le port des EPI.',
      'plannedActions':
          '| N° | Thème | Mesure | Responsable | Échéance | Preuve |\n| 1 | Stockage | Réorganiser les rayonnages B3-B5 et afficher les charges | Chef d’équipe maintenance | 30/09/2026 | Photos et check-list |\n| 2 | Machines | Toolbox meuleuse et protection contre projections | Conseiller en prévention | 31/10/2026 | Liste de présence |\n| 3 | Circulation | Marquer la zone piétonne à la porte du garage | Responsable service | 31/12/2026 | Bon de travail et photo |',
      'resources':
          'Peinture de signalisation, étiquettes de rayonnage, stock EPI, deux heures de toolbox par équipe, appui magasinier et maintenance.',
      'mainActivities':
          'Entretien des bâtiments communaux, petites réparations véhicules, stockage et distribution de matériel, interventions voirie, espaces verts et service hiver.',
      'fiveYearObjectives':
          'D’ici 2030 : séparer véhicules/piétons, plan annuel de formation, consignes standard pour machines, registre numérique de suivi des actions.',
      'priorityAxes':
          '1. Ordre et propreté des stockages. 2. Sécurité machines. 3. Circulation véhicules/piétons. 4. Ergonomie manutention. 5. Produits chimiques garage et espaces verts.',
      'structuralMeasures':
          'Réorganisation des rayonnages, armoire fermée pour produits dangereux, marquage des circulations, contrôles annuels des équipements, fiche d’accueil standard.',
      'multiYearPlanning':
          '2026 stockage et signalisation; 2027 consignes machines; 2028 aides ergonomiques; 2029 plan de circulation du site technique; 2030 audit et mise à jour.',
      'validations':
          'Validation par secrétaire communal, responsable du service technique, conseiller en prévention et CPPT; vérifier les lignes budgétaires 2026-2030.',
      'participants':
          'Responsable du service technique, chef d’équipe maintenance, magasinier, conseiller en prévention et deux ouvriers voirie/espaces verts.',
      'visitedZone':
          'Atelier avec poste de meulage, garage véhicules, rayonnages B1-B6, stockage extérieur sel et matériaux, zone espaces verts.',
      'positiveFindings':
          'Extincteurs accessibles, trousse de secours présente, huile usagée stockée en récipient fermé, contrôle du pont élévateur valide.',
      'observations':
          'Passage au rayonnage B3 partiellement bloqué par panneaux de signalisation; rallonge au sol près de l’établi; armoire EPI sans gants anticoupure taille 9.',
      'observedRisks':
          'Chute de plain-pied, chute d’objets, coupures au meulage, heurt lors de marche arrière, exposition au bruit et poussières.',
      'immediateMeasures':
          'Rallonge retirée, passage dégagé, lunettes défectueuses écartées, rappel du port de protections auditives.',
      'proposedActions':
          '| Action | Responsable | Échéance | Preuve |\n| Marquer les passages de stockage | Chef d’équipe | 30/09/2026 | Photo |\n| Réassortir l’armoire EPI | Magasinier | 15/07/2026 | Bon de commande |\n| Toolbox marche arrière | Conseiller prévention | 31/10/2026 | Liste de présence |',
      'evidenceFollowUp':
          'Photos avant/après, bons de travail, commandes EPI, listes de présence toolbox, procès-verbal CPPT.',
      'mission':
          'Assurer les travaux d’entretien et de réparation des bâtiments communaux, de la voirie et des espaces verts en protégeant collègues et citoyens.',
      'mainTasks':
          'Charger et décharger du matériel, réaliser de petites réparations, poser la signalisation, entretenir les espaces verts, nettoyer les véhicules, maintenir l’atelier en ordre.',
      'workEnvironment':
          'Travail intérieur en atelier et garage, travail extérieur sur voirie communale et espaces verts, météo variable, présence de véhicules et du public.',
      'equipmentTools':
          'Camionnette, outillage manuel, meuleuse, foreuse, nettoyeur haute pression, débroussailleuse, échelles, rayonnages et aides de levage.',
      'requiredSkills':
          'Permis B, bases d’utilisation sûre des machines portatives, lecture des bons de travail, communication avec chef d’équipe, aptitude au travail extérieur.',
      'jobRisks':
          'Coupures, projections, bruit, vibrations, manutention manuelle, glissades et chutes de plain-pied, circulation sur voie publique.',
      'preventionMeasures':
          'Baliser la zone, contrôler les machines avant usage, porter les EPI, déplacer les charges lourdes à deux, signaler le matériel défectueux.',
      'requiredPpe':
          'Chaussures S3, gants de travail, lunettes, protections auditives, gilet haute visibilité, masque FFP2 en cas de poussières.',
      'trainingAuthorizations':
          'Accueil sécurité, toolbox meuleuse, signalisation sur voie publique, utilisation de petits équipements, procédure contacts premiers secours.',
      'specificInstructions':
          'Ne pas meuler seul en local fermé; orienter les étincelles loin des matières combustibles; signaler immédiatement tout incident.',
      'instructionObjective':
          'Utiliser la meuleuse d’angle en sécurité lors de petites réparations dans l’atelier communal.',
      'hazards':
          'Projections métalliques, coupures, étincelles, bruit, poussières, risque d’incendie près des stockages combustibles.',
      'beforeInstructions':
          'Contrôler disque, carter, câble et homme mort; retirer les matières combustibles dans un rayon de deux mètres; porter les EPI.',
      'duringInstructions':
          'Brider la pièce, tenir la machine à deux mains, ne pas meuler au-dessus des épaules, éloigner les collègues de la zone de projection.',
      'afterInstructions':
          'Laisser la machine s’arrêter avant de la poser, débrancher, nettoyer les poussières, isoler et signaler les disques abîmés.',
      'forbiddenActions':
          'Retirer le carter, utiliser un disque usé, meuler près de liquides inflammables, passer la machine en fonctionnement.',
      'anomalyActions':
          'Arrêter le travail, débrancher la machine, prévenir le chef d’équipe, étiqueter le matériel défectueux et enregistrer la remarque.',
      'emergencyActions':
          'En cas de coupure appeler les premiers secours; en cas d’incendie utiliser l’extincteur si possible et appeler le 112; prévenir le conseiller en prévention.',
      'usefulContacts':
          'Chef d’équipe maintenance 087/xx.xx.xx; conseiller en prévention; accueil communal; urgence 112.',
      'diffusionTrainingProof':
          'Afficher la consigne près de l’établi, la présenter en toolbox de septembre 2026, faire signer la liste de présence.',
      'personsConcerned':
          'Ouvrier polyvalent du service technique, aucun travailleur externe impliqué.',
      'witnesses':
          'Chef d’équipe maintenance et magasinier présents en zone de stockage.',
      'factualDescription':
          'Lors du déplacement de panneaux de signalisation, le travailleur a trébuché sur une rallonge au sol au rayonnage B3 et est tombé sur le genou gauche.',
      'consequences':
          'Contusion légère au genou, arrêt temporaire pour soins, pas de dégât matériel.',
      'probableCauses':
          'Câble dans le passage, stockage temporaire hors zone prévue, contrôle ordre/propreté insuffisant au début de poste.',
      'immediateCauses': 'Rallonge au sol et passage encombré.',
      'rootCauses':
          'Absence d’enrouleur fixe à l’établi, règles de stockage temporaire des panneaux insuffisamment définies.',
      'correctiveActions':
          'Installer un enrouleur, marquer les circulations, définir l’emplacement des panneaux.',
      'preventiveActions':
          'Ronde 5S mensuelle, toolbox chute de plain-pied, contrôle du chef d’équipe le vendredi.',
      'evidenceAnnexes':
          'Photo du lieu, registre premiers secours, témoignage, bon de travail enrouleur, photo du marquage.',
      'declarationsValidations':
          'Vérifier si déclaration accident du travail requise; validation employeur et conseiller en prévention; discussion CPPT.',
    },
  };
}

Map<String, String> _baseExamples(String localeName) {
  return switch (localeName) {
    'nl' => const {
      'companyName': 'Gemeentebestuur van Verviers',
      'siteConcerned':
          'Gemeentelijke werkplaats van Verviers, voertuiggarage, opslagzones, technische lokalen, interventies op de openbare weg en in groenzones',
      'serviceConcerned': 'Gemeentelijke technische dienst',
      'department': 'Gemeentelijke technische dienst',
      'site': 'Gemeentelijke werkplaats van Verviers',
      'author': 'Interne preventieadviseur',
      'version': '1.0',
      'date': '07/06/2026',
      'visitDate': '07/06/2026',
      'planYear': '2026',
      'coveredPeriod': '2026-2030',
      'preparedBy': 'Interne preventieadviseur',
      'visitDateTime': '07/06/2026 om 09:00',
      'visitLocation': 'Gemeentelijke werkplaats en opslagzone',
      'eventDateTime': '04/06/2026 om 10:20',
      'eventLocation': 'Opslagzone materialen, rek B3',
      'jobTitle': 'Polyvalent technisch medewerker',
      'activityMachineTask':
          'Gebruik van slijpmachine voor kleine herstellingen',
      'responsibles':
          'Diensthoofd technische dienst; ploegbaas onderhoud; preventieadviseur voor opvolging.',
      'deadlines':
          'Prioriteit 1 tegen 30/09/2026; structurele acties tegen 31/12/2026.',
      'budget':
          'Raming 8.500 EUR voor PBM, opleiding, signalisatie en opslagverbeteringen.',
      'indicators':
          'Aantal afgesloten acties, geregistreerde opleidingen, keuringsverslagen, incidentmeldingen en CPBW-opvolging.',
      'remarks':
          'Te valideren op het terrein en te bespreken op het volgende CPBW.',
    },
    'en' => const {
      'companyName': 'City Administration of Verviers',
      'siteConcerned':
          'Verviers municipal workshop, vehicle garage, storage areas, technical rooms, road and green space interventions',
      'serviceConcerned': 'Municipal technical department',
      'department': 'Municipal technical department',
      'site': 'Verviers municipal workshop',
      'author': 'Internal prevention advisor',
      'version': '1.0',
      'date': '07/06/2026',
      'visitDate': '07/06/2026',
      'planYear': '2026',
      'coveredPeriod': '2026-2030',
      'preparedBy': 'Internal prevention advisor',
      'visitDateTime': '07/06/2026 at 09:00',
      'visitLocation': 'Municipal workshop and storage area',
      'eventDateTime': '04/06/2026 at 10:20',
      'eventLocation': 'Material storage area, rack B3',
      'jobTitle': 'Multi-skilled technical worker',
      'activityMachineTask': 'Use of angle grinder for minor repairs',
      'responsibles':
          'Technical department manager; maintenance team leader; prevention advisor for follow-up.',
      'deadlines':
          'Priority 1 by 30/09/2026; structural actions by 31/12/2026.',
      'budget':
          'Estimated EUR 8,500 for PPE, training, signage and storage improvements.',
      'indicators':
          'Closed actions, completed training records, inspection reports, incident reports and committee follow-up.',
      'remarks':
          'To be validated on site and discussed at the next prevention committee.',
    },
    'de' => const {
      'companyName': 'Stadtverwaltung Verviers',
      'siteConcerned':
          'Kommunale Werkstatt Verviers, Fahrzeuggarage, Lagerbereiche, Technikräume, Einsätze im Straßenraum und in Grünflächen',
      'serviceConcerned': 'Kommunaler technischer Dienst',
      'department': 'Kommunaler technischer Dienst',
      'site': 'Kommunale Werkstatt Verviers',
      'author': 'Interner Präventionsberater',
      'version': '1.0',
      'date': '07.06.2026',
      'visitDate': '07.06.2026',
      'planYear': '2026',
      'coveredPeriod': '2026-2030',
      'preparedBy': 'Interner Präventionsberater',
      'visitDateTime': '07.06.2026 um 09:00 Uhr',
      'visitLocation': 'Kommunale Werkstatt und Lagerbereich',
      'eventDateTime': '04.06.2026 um 10:20 Uhr',
      'eventLocation': 'Materiallager, Regal B3',
      'jobTitle': 'Mehrzweck-Technikmitarbeiter',
      'activityMachineTask':
          'Verwendung eines Winkelschleifers für kleinere Reparaturen',
      'responsibles':
          'Leitung technischer Dienst; Teamleitung Instandhaltung; Präventionsberater für Nachverfolgung.',
      'deadlines':
          'Priorität 1 bis 30.09.2026; strukturelle Maßnahmen bis 31.12.2026.',
      'budget':
          'Schätzung 8.500 EUR für PSA, Schulung, Beschilderung und Lagerverbesserungen.',
      'indicators':
          'Abgeschlossene Maßnahmen, Schulungsnachweise, Prüfberichte, Ereignismeldungen und Ausschussverfolgung.',
      'remarks':
          'Vor Ort zu validieren und im nächsten Präventionsausschuss zu besprechen.',
    },
    _ => const {
      'companyName': 'Administration communale de Verviers',
      'siteConcerned':
          'Atelier communal de Verviers, garage véhicules, zones de stockage, locaux techniques, interventions sur voirie et espaces verts',
      'serviceConcerned': 'Service technique communal',
      'department': 'Service technique communal',
      'site': 'Atelier communal de Verviers',
      'author': 'Conseiller en prévention interne',
      'version': '1.0',
      'date': '07/06/2026',
      'visitDate': '07/06/2026',
      'planYear': '2026',
      'coveredPeriod': '2026-2030',
      'preparedBy': 'Conseiller en prévention interne',
      'visitDateTime': '07/06/2026 à 09:00',
      'visitLocation': 'Atelier communal et zone de stockage',
      'eventDateTime': '04/06/2026 à 10:20',
      'eventLocation': 'Zone de stockage matériel, rayonnage B3',
      'jobTitle': 'Ouvrier technique polyvalent',
      'activityMachineTask':
          'Utilisation d’une meuleuse pour petites réparations',
      'responsibles':
          'Responsable du service technique; chef d’équipe maintenance; conseiller en prévention pour le suivi.',
      'deadlines':
          'Priorité 1 pour le 30/09/2026; actions structurelles pour le 31/12/2026.',
      'budget':
          'Estimation 8.500 EUR pour EPI, formations, signalisation et amélioration du stockage.',
      'indicators':
          'Actions clôturées, registres de formation, rapports de contrôle, déclarations d’incidents et suivi CPPT.',
      'remarks': 'À valider sur le terrain et à présenter au prochain CPPT.',
    },
  };
}
