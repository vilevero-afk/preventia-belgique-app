import '../models/document_form_data.dart';

const mandatoryValidationNotice =
    'Ce document est un projet à adapter à la situation réelle de l’entreprise et à valider par le conseiller en prévention, l’employeur et, le cas échéant, le service externe, le médecin du travail ou le CPPT. Il ne constitue pas à lui seul une preuve de conformité réglementaire.';

class DocumentGenerator {
  String generate(DocumentFormData data) {
    if (data.extraFields['_isPreventionDocument'] == 'true') {
      return _generatePreventionDocument(data);
    }

    final risks = _risksFor(data);

    return '''
PROJET DE DOCUMENT - ${data.documentType.toUpperCase()}

$mandatoryValidationNotice

1. Contexte
Type de document demandé : ${data.documentType}
Référence documentaire : ${_extraValue(data, 'documentReference')}
Entreprise : ${_value(data.companyName)}
Secteur d’activité : ${_value(data.sector)}
Nombre de travailleurs : ${_value(data.workerCount)}
Site ou lieu de travail : ${_value(data.siteConcerned)}
Service concerné : ${_value(data.serviceConcerned)}
Activité ou poste analysé : ${_value(data.activity)}
Rédacteur : ${_value(data.author)}
Version : ${_value(data.version)}
Date de visite ou d’observation : ${_value(data.visitDate)}
Objectif du document : ${_value(data.documentObjective)}

2. Hypothèses utilisées
- Les informations ci-dessous proviennent des éléments saisis localement dans l’application.
- Le projet ne remplace pas une visite de terrain, une concertation interne, ni l’avis des acteurs compétents.
- Les mesures proposées doivent être adaptées aux procédures, équipements, formations et contraintes réelles.
- La hiérarchie de prévention doit être appliquée : suppression du danger, mesures collectives, organisation, équipements de protection individuelle, information et formation.
- Les champs indiqués "${DocumentFormData.unknownValue}" doivent être confirmés avant validation.

2.1. Périmètre de l’analyse
Lieux inclus : ${_value(data.includedLocations)}
Lieux exclus : ${_value(data.excludedLocations)}
Postes concernés : ${_value(data.concernedPositions)}
Tâches concernées : ${_value(data.concernedTasks)}
Situations incluses : ${_value(data.includedSituations)}
Durée d’exposition : ${_value(data.exposureDuration)}
Mode de travail : ${_value(data.workMode)}

2.2. Sources d’information
Visite terrain réalisée : ${_value(data.fieldVisitDone)}
Observation de poste réalisée : ${_value(data.jobObservationDone)}
Travailleurs consultés : ${_value(data.workersConsulted)}
Ligne hiérarchique consultée : ${_value(data.managementConsulted)}
CPPT consulté : ${_value(data.cpptConsulted)}
Registre accidents/incidents disponible : ${_value(data.incidentRegisterAvailable)}
Photos disponibles : ${_value(data.photosAvailable)}
Rapports de contrôle disponibles : ${_value(data.controlReportsAvailable)}
Fiches techniques disponibles : ${_value(data.technicalSheetsAvailable)}
FDS disponibles : ${_value(data.safetyDataSheetsAvailable)}

3. Tableau d’analyse des risques
| Danger ou situation | Personnes exposées | Risques possibles | Mesures existantes | Mesures complémentaires proposées | Priorité |
${risks.map((risk) => '| ${risk.danger} | ${risk.exposed} | ${risk.effects} | ${risk.existingMeasures} | ${risk.actions} | ${risk.priority} |').join('\n')}

4. Priorités d’action
- Priorité 1 : vérifier les risques graves, imminents ou touchant plusieurs travailleurs.
- Priorité 2 : formaliser les consignes, responsabilités, formations et contrôles périodiques.
- Priorité 3 : planifier les améliorations techniques, organisationnelles et documentaires.

5. Projet de plan d’action
- Désigner un responsable interne pour chaque action retenue.
- Définir une échéance réaliste et un indicateur de suivi.
- Consigner les décisions dans le plan annuel d’action ou dans le plan global de prévention lorsque pertinent.
- Présenter le projet aux parties concernées avant validation.

6. Documents à créer ou mettre à jour
- Analyse de risques liée au sujet traité.
- Procédures et instructions de sécurité applicables.
- Fiches de poste, fiches d’instruction ou fiches produits si nécessaire.
- Registre de formation, preuve d’information et suivi des actions.
- Rapports de contrôle, entretien ou inspection des équipements concernés.

7. Points à valider
- Exactitude du contexte, du périmètre et des travailleurs exposés.
- Concordance avec les observations de terrain et les obligations internes.
- Avis du conseiller en prévention et, le cas échéant, du service externe, du médecin du travail ou du CPPT.
- Faisabilité, priorisation et financement des mesures proposées.
- Modalités de communication aux travailleurs concernés.

8. Informations complémentaires
Machines ou équipements utilisés : ${_value(data.equipment)}
Produits dangereux utilisés : ${_value(data.dangerousProducts)}
Travailleurs exposés : ${_value(data.exposedWorkers)}
Accidents ou incidents connus : ${_value(data.knownIncidents)}
Instructions écrites existantes : ${_value(data.writtenInstructions)}
Formations déjà réalisées : ${_value(data.completedTrainings)}
EPI disponibles : ${_value(data.availablePpe)}
Contrôles périodiques réalisés : ${_value(data.periodicControls)}
Preuves disponibles : ${_value(data.availableEvidence)}
Mesures seulement orales ou non documentées : ${_value(data.oralMeasures)}
Mesures à vérifier sur terrain : ${_value(data.measuresToVerify)}
Travail en hauteur : ${_value(data.workAtHeight)}
Machines ou outillage dangereux : ${_value(data.dangerousMachines)}
Produits chimiques : ${_value(data.chemicalProducts)}
Manutention manuelle : ${_value(data.manualHandling)}
Circulation véhicules/piétons : ${_value(data.vehiclePedestrianTraffic)}
Bruit : ${_value(data.noise)}
Incendie : ${_value(data.fireRisk)}
Travail isolé : ${_value(data.loneWork)}
Coactivité avec public/sous-traitants : ${_value(data.coactivity)}
Contraintes météo : ${_value(data.weatherConstraints)}
Nouveaux travailleurs : ${_value(data.newWorkers)}
Intérimaires : ${_value(data.temporaryWorkers)}
Jeunes travailleurs : ${_value(data.youngWorkers)}
Travailleuses enceintes ou allaitantes : ${_value(data.pregnantOrBreastfeedingWorkers)}
Travailleurs avec restrictions médicales : ${_value(data.medicalRestrictionsWorkers)}
Travailleurs isolés : ${_value(data.isolatedWorkers)}
Sous-traitants : ${_value(data.subcontractors)}
Présence d’un CPPT : ${_value(data.cpptPresence)}
Service interne ou externe : ${_value(data.preventionService)}
Alimentation du Plan Annuel d’Action : ${_value(data.feedAnnualActionPlan)}
Alimentation du Plan Global de Prévention : ${_value(data.feedGlobalPreventionPlan)}
Présentation au CPPT : ${_value(data.presentToCppt)}
Validation du service externe : ${_value(data.externalServiceValidation)}
Avis du médecin du travail : ${_value(data.occupationalDoctorAdvice)}
Contraintes particulières : ${_value(data.constraints)}
Informations complémentaires : ${_value(data.additionalInformation)}

$mandatoryValidationNotice
''';
  }

  String _generatePreventionDocument(DocumentFormData data) {
    final localeName = data.extraFields['_localeName'] ?? 'fr';
    final texts = _localPreventionTexts(localeName);
    final fields = data.extraFields.entries
        .where((entry) => !entry.key.startsWith('_'))
        .map(
          (entry) =>
              '- ${_humanizeKey(entry.key)} : ${_value(entry.value, texts.missingValue)}',
        )
        .join('\n');
    final actions = _actionLines(data.extraFields, texts.defaultActionLine);

    return '''
${texts.draftDocument} - ${data.documentType.toUpperCase()}

${texts.validationNotice}

## 1. ${texts.identification}
${texts.documentType} : ${data.documentType}
${texts.company} : ${_extraValue(data, 'companyName', texts.missingValue)}
${texts.site} : ${_extraValue(data, 'siteConcerned', texts.missingValue)}
${texts.service} : ${_extraValue(data, 'serviceConcerned', texts.missingValue)}
${texts.reference} : ${_extraValue(data, 'documentReference', texts.missingValue)}
${texts.author} : ${_extraValue(data, 'preparedBy', texts.missingValue)}

## 2. ${texts.structuredInformation}
$fields

## 3. ${texts.draftContent}
${texts.draftContentBody}

## 4. ${texts.followUpActions}
$actions

## 5. ${texts.validationPoints}
${texts.validationBullets}

${texts.validationNotice}
''';
  }

  List<_RiskLine> _risksFor(DocumentFormData data) {
    final exposed = _value(data.exposedWorkers);
    final existing = _value(data.existingMeasures);
    final risks = <_RiskLine>[
      _RiskLine(
        danger: 'Organisation du travail et environnement général',
        exposed: exposed,
        effects:
            'Accident, surcharge, erreur opérationnelle ou exposition non maîtrisée',
        existingMeasures: existing,
        actions:
            'Vérifier les procédures, responsabilités, formations et contrôles',
        priority: 'À évaluer',
      ),
    ];

    if (data.equipment.trim().isNotEmpty) {
      risks.add(
        _RiskLine(
          danger: 'Machines ou équipements : ${data.equipment.trim()}',
          exposed: exposed,
          effects:
              'Contact mécanique, coincement, coupure, projection, bruit ou énergie dangereuse',
          existingMeasures: existing,
          actions:
              'Contrôler la conformité, les protections, l’entretien et les consignes d’utilisation',
          priority: 'Élevée si protection absente',
        ),
      );
    }

    if (data.dangerousProducts.trim().isNotEmpty) {
      risks.add(
        _RiskLine(
          danger: 'Produits dangereux : ${data.dangerousProducts.trim()}',
          exposed: exposed,
          effects:
              'Inhalation, contact cutané, incendie, réaction chimique ou pollution',
          existingMeasures: existing,
          actions:
              'Vérifier les FDS, l’étiquetage, le stockage, la ventilation et les EPI',
          priority: 'Élevée si exposition directe',
        ),
      );
    }

    if (data.knownIncidents.trim().isNotEmpty) {
      risks.add(
        _RiskLine(
          danger: 'Accidents ou incidents connus',
          exposed: exposed,
          effects: data.knownIncidents.trim(),
          existingMeasures: existing,
          actions:
              'Analyser les causes, documenter les actions correctives et suivre leur efficacité',
          priority: 'Prioritaire',
        ),
      );
    }

    risks.add(
      _RiskLine(
        danger: 'Contraintes particulières',
        exposed: exposed,
        effects: _value(data.constraints),
        existingMeasures: existing,
        actions:
            'Valider les contraintes avec le terrain et adapter le plan d’action',
        priority: 'À confirmer',
      ),
    );

    return risks;
  }

  String _value(String value, [String missingValue = 'À compléter']) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? missingValue : trimmed;
  }

  String _extraValue(
    DocumentFormData data,
    String key, [
    String missingValue = 'À compléter',
  ]) {
    return _value(data.extraFields[key] ?? '', missingValue);
  }

  String _humanizeKey(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _actionLines(Map<String, String> fields, String defaultActionLine) {
    final candidates = [
      fields['plannedActions'],
      fields['proposedActions'],
      fields['correctiveActions'],
      fields['preventiveActions'],
      fields['preventionMeasures'],
      fields['beforeInstructions'],
      fields['duringInstructions'],
    ].where((value) => value != null && value.trim().isNotEmpty).toList();
    if (candidates.isEmpty) {
      return '- $defaultActionLine';
    }
    return candidates.map((value) => '- ${value!.trim()}').join('\n');
  }
}

_LocalPreventionTexts _localPreventionTexts(String localeName) {
  return switch (localeName) {
    'nl' => const _LocalPreventionTexts(
      draftDocument: 'ONTWERPDOCUMENT',
      validationNotice:
          'Dit document is een ontwerp dat moet worden aangepast aan de werkelijke situatie van de onderneming en gevalideerd door de preventieadviseur, de werkgever en, indien van toepassing, de externe dienst, de arbeidsarts of het CPBW. Het vormt op zichzelf geen bewijs van reglementaire conformiteit.',
      missingValue:
          'Informatie aan te vullen of te valideren tijdens het terreinbezoek.',
      defaultActionLine:
          'Definieer acties, verantwoordelijken, termijnen en verwachte bewijzen vóór validatie.',
      identification: 'Identificatie',
      documentType: 'Gevraagd documenttype',
      company: 'Onderneming',
      site: 'Site of werkplek',
      service: 'Betrokken dienst',
      reference: 'Referentie',
      author: 'Opsteller',
      structuredInformation: 'Ingevoerde gestructureerde informatie',
      draftContent: 'Ontwerpinhoud',
      draftContentBody:
          'Het document moet worden gevalideerd met de werkelijke terreininformatie. De ingevoerde gegevens helpen de preventieadviseur een bruikbaar ontwerp op te stellen met verantwoordelijkheden, termijnen, middelen, bewijzen en validaties.',
      followUpActions: 'Op te volgen acties',
      validationPoints: 'Te valideren punten',
      validationBullets:
          '- Bevestig ontbrekende of te controleren informatie.\n- Valideer verantwoordelijkheden, termijnen en beschikbare middelen.\n- Controleer de samenhang met risicoanalyses, bezoeken, incidenten of CPBW-beslissingen.\n- Bewaar nuttige bewijzen: foto’s, verslagen, aanwezigheidslijsten, validaties en communicatie aan werknemers.',
    ),
    'en' => const _LocalPreventionTexts(
      draftDocument: 'DRAFT DOCUMENT',
      validationNotice:
          'This document is a draft that must be adapted to the actual situation of the organisation and validated by the prevention advisor, the employer and, where applicable, the external service, the occupational physician or the health and safety committee. It does not constitute proof of regulatory compliance on its own.',
      missingValue:
          'Information to be completed or validated during the site visit.',
      defaultActionLine:
          'Define actions, responsible persons, deadlines and expected evidence before validation.',
      identification: 'Identification',
      documentType: 'Requested document type',
      company: 'Company',
      site: 'Site or workplace',
      service: 'Department concerned',
      reference: 'Reference',
      author: 'Author',
      structuredInformation: 'Structured information entered',
      draftContent: 'Draft content',
      draftContentBody:
          'The document must be validated against real field information. The entered data prepares a usable draft for the prevention advisor, with responsibilities, deadlines, resources, evidence and validations.',
      followUpActions: 'Follow-up actions',
      validationPoints: 'Points to validate',
      validationBullets:
          '- Confirm incomplete information or items marked for verification.\n- Validate responsibilities, deadlines and available resources.\n- Check consistency with risk assessments, visits, incidents or prevention committee decisions.\n- Keep useful evidence: photos, reports, attendance lists, validations and worker communications.',
    ),
    'de' => const _LocalPreventionTexts(
      draftDocument: 'DOKUMENTENTWURF',
      validationNotice:
          'Dieses Dokument ist ein Entwurf, der an die tatsächliche Situation des Unternehmens angepasst und vom Präventionsberater, dem Arbeitgeber sowie gegebenenfalls vom externen Dienst, dem Arbeitsmediziner oder dem Ausschuss für Gefahrenverhütung und Schutz am Arbeitsplatz validiert werden muss. Es stellt für sich allein keinen Nachweis der regulatorischen Konformität dar.',
      missingValue:
          'Informationen sind vor Ort zu ergänzen oder zu validieren.',
      defaultActionLine:
          'Maßnahmen, verantwortliche Personen, Fristen und erwartete Nachweise vor der Validierung festlegen.',
      identification: 'Identifikation',
      documentType: 'Angeforderter Dokumenttyp',
      company: 'Unternehmen',
      site: 'Standort oder Arbeitsplatz',
      service: 'Betroffener Dienst',
      reference: 'Referenz',
      author: 'Verfasser',
      structuredInformation: 'Erfasste strukturierte Informationen',
      draftContent: 'Entwurfsinhalt',
      draftContentBody:
          'Das Dokument muss anhand der tatsächlichen Angaben vor Ort validiert werden. Die erfassten Daten bereiten einen nutzbaren Entwurf für den Präventionsberater mit Verantwortlichkeiten, Fristen, Mitteln, Nachweisen und Validierungen vor.',
      followUpActions: 'Nachzuverfolgende Maßnahmen',
      validationPoints: 'Zu validierende Punkte',
      validationBullets:
          '- Unvollständige oder zu prüfende Informationen bestätigen.\n- Verantwortlichkeiten, Fristen und verfügbare Mittel validieren.\n- Übereinstimmung mit Gefährdungsbeurteilungen, Begehungen, Ereignissen oder Ausschussentscheidungen prüfen.\n- Nützliche Nachweise aufbewahren: Fotos, Berichte, Anwesenheitslisten, Validierungen und Mitteilungen an Beschäftigte.',
    ),
    _ => const _LocalPreventionTexts(
      draftDocument: 'PROJET DE DOCUMENT',
      validationNotice: mandatoryValidationNotice,
      missingValue: 'Information à compléter ou à valider sur le terrain.',
      defaultActionLine:
          'Définir les actions, responsables, échéances et preuves attendues avant validation.',
      identification: 'Identification',
      documentType: 'Type de document demandé',
      company: 'Entreprise',
      site: 'Site ou lieu de travail',
      service: 'Service concerné',
      reference: 'Référence',
      author: 'Rédacteur',
      structuredInformation: 'Informations structurées saisies',
      draftContent: 'Projet de contenu',
      draftContentBody:
          'Le document doit être validé avec les informations réelles du terrain. Les éléments saisis permettent de préparer une version exploitable par le conseiller en prévention, avec les responsabilités, échéances, moyens, preuves et validations nécessaires.',
      followUpActions: 'Actions à suivre',
      validationPoints: 'Points à valider',
      validationBullets:
          '- Confirmer les informations incomplètes ou indiquées comme à vérifier.\n- Valider les responsabilités, les délais et les moyens disponibles.\n- Vérifier la cohérence avec les analyses de risques, visites terrain, accidents ou décisions CPPT.\n- Conserver les preuves utiles : photos, rapports, listes de présence, validations et communications aux travailleurs.',
    ),
  };
}

class _LocalPreventionTexts {
  const _LocalPreventionTexts({
    required this.draftDocument,
    required this.validationNotice,
    required this.missingValue,
    required this.defaultActionLine,
    required this.identification,
    required this.documentType,
    required this.company,
    required this.site,
    required this.service,
    required this.reference,
    required this.author,
    required this.structuredInformation,
    required this.draftContent,
    required this.draftContentBody,
    required this.followUpActions,
    required this.validationPoints,
    required this.validationBullets,
  });

  final String draftDocument;
  final String validationNotice;
  final String missingValue;
  final String defaultActionLine;
  final String identification;
  final String documentType;
  final String company;
  final String site;
  final String service;
  final String reference;
  final String author;
  final String structuredInformation;
  final String draftContent;
  final String draftContentBody;
  final String followUpActions;
  final String validationPoints;
  final String validationBullets;
}

class _RiskLine {
  const _RiskLine({
    required this.danger,
    required this.exposed,
    required this.effects,
    required this.existingMeasures,
    required this.actions,
    required this.priority,
  });

  final String danger;
  final String exposed;
  final String effects;
  final String existingMeasures;
  final String actions;
  final String priority;
}
