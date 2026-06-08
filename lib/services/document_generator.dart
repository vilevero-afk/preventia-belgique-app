import '../models/document_form_data.dart';

const mandatoryValidationNotice =
    'Ce document est un projet à adapter à la situation réelle de l’entreprise et à valider par le conseiller en prévention, l’employeur et, le cas échéant, le service externe, le médecin du travail ou le CPPT.';

class DocumentGenerator {
  String generate(DocumentFormData data) {
    final risks = _risksFor(data);

    return '''
PROJET DE DOCUMENT - ${data.documentType.toUpperCase()}

$mandatoryValidationNotice

1. Contexte
Type de document demandé : ${data.documentType}
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

  String _value(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'À compléter' : trimmed;
  }
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
