/// Test data used to prefill risk-assessment questionnaires.
///
/// The returned map is a new instance and can safely be adapted by callers.
Map<String, dynamic> getRiskAssessmentTestPreset(String documentType) {
  return RiskAssessmentTestPresets.forDocumentType(documentType);
}

abstract final class RiskAssessmentTestPresets {
  static const Map<String, dynamic> _common = {
    'companyName': 'SPGE',
    'siteName': 'Site administratif de Verviers',
    'buildingName': 'Site administratif de Verviers',
    'address': 'Rue des Écoles 12',
    'postalCode': '4800',
    'city': 'Verviers',
    'country': 'Belgique',
    'activityDescription':
        'Bureaux administratifs, accueil du public, réunions, locaux techniques et archives',
    'riskProfile': 'modéré',
    'numberOfWorkers': '85',
    'visitors': 'Environ 20 visiteurs par jour',
    'visitorsPresence': 'Environ 20 visiteurs par jour',
    'externalCompaniesPresence':
        'Nettoyage, maintenance, contrôles techniques, entreprises extérieures ponctuelles',
    'workingHours': 'Horaires administratifs à confirmer',
    'preventionAdvisor': 'Vincent Legrand',
    'siteContact': 'Sophie Martin',
    'siteManager': 'Marc Delvaux',
    'technicalServiceContact': 'Jean Peeters',
    'generalPhone': '[à compléter]',
    'generalEmail': '[à compléter]',
    'language': 'fr',
  };

  static Map<String, dynamic> forDocumentType(String documentType) {
    final normalized = _normalize(documentType);
    final (scenarioName, specific) = switch (normalized) {
      final value when value.contains('ascenseur') => ('ASCENSEUR', _elevator),
      final value
          when value.contains('electrique') ||
              value.contains('bt/ht') ||
              value.contains('basse tension') =>
        ('INSTALLATIONS ÉLECTRIQUES BT/HT', _electrical),
      final value when value.contains('incendie') => ('INCENDIE', _fire),
      final value
          when value.contains('ergonomie') || value.contains('poste ecran') =>
        ('ERGONOMIE / POSTES ÉCRAN', _ergonomics),
      final value
          when value.contains('manutention') || value.contains('archive') =>
        ('MANUTENTION / ARCHIVES', _manualHandling),
      final value
          when value.contains('nettoyage') ||
              value.contains('produits chimiques') =>
        ('NETTOYAGE / PRODUITS CHIMIQUES', _cleaning),
      final value
          when value.contains('entreprise') && value.contains('exterieure') =>
        ('ENTREPRISES EXTÉRIEURES', _externalCompanies),
      final value
          when value.contains('circulation') || value.contains('chute') =>
        ('CIRCULATION INTERNE / CHUTES', _internalTraffic),
      final value when value.contains('psychosoc') => (
        'PSYCHOSOCIAUX / ACCUEIL PUBLIC',
        _psychosocial,
      ),
      final value when value.contains('poste de travail') => (
        'POSTE DE TRAVAIL / ACCUEIL ADMINISTRATIF',
        _job,
      ),
      final value
          when value.contains('machine') || value.contains('equipement') =>
        ('MACHINES ET ÉQUIPEMENTS', _machines),
      final value when value.contains('travail en hauteur') => (
        'TRAVAIL EN HAUTEUR',
        _workAtHeight,
      ),
      final value when value.contains('travail isole') => (
        'TRAVAIL ISOLÉ',
        _loneWork,
      ),
      _ => ('ANALYSE GÉNÉRALE', _general),
    };
    final preset = <String, dynamic>{..._common, ...specific};
    _completeGenericQuestionnaire(preset, normalized);
    preset['additionalContext'] = _buildAdditionalContext(
      scenarioName: scenarioName,
      documentType: documentType,
      preset: preset,
    );
    preset['additionalInformation'] = preset['additionalContext'];
    return preset;
  }

  static void _completeGenericQuestionnaire(
    Map<String, dynamic> preset,
    String normalizedDocumentType,
  ) {
    String value(List<String> keys, String fallback) {
      for (final key in keys) {
        final candidate = preset[key]?.toString().trim() ?? '';
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
      return fallback;
    }

    void set(String key, String value) => preset.putIfAbsent(key, () => value);

    final areas = value(const [
      'concernedAreas',
      'workplaceDescription',
      'buildingDescription',
      'elevatorLocation',
    ], 'Site administratif de Verviers et zones liées à l’activité analysée.');
    final persons = value(
      const ['exposedPersons', 'occupants'],
      'Travailleurs, visiteurs, entreprises extérieures et personnel de nettoyage.',
    );
    final activity = value(const [
      'activityType',
      'concernedActivities',
      'scenario',
    ], preset['activityDescription'].toString());
    final equipment = value(
      const [
        'connectedWorkEquipment',
        'workstations',
        'handledLoads',
        'externalCompanies',
      ],
      'Postes informatiques, mobilier de bureau et équipements présents dans les zones analysées.',
    );
    final products = value(
      const ['productsUsed'],
      'Produits d’entretien courants présents sur le site ; inventaire et FDS à vérifier.',
    );
    final risks = value(
      const ['mainRisks', 'fireRisks'],
      'Risques à confirmer par une visite et par la consultation des travailleurs.',
    );

    set('siteConcerned', preset['siteName'].toString());
    set('serviceConcerned', 'Services administratifs et techniques concernés');
    set('author', preset['preventionAdvisor'].toString());
    set('version', 'Version test SPGE 1.0');
    set('visitDate', 'Visite à planifier et date à confirmer');
    set('documentObjective', preset['scenario'].toString());
    set('includedLocations', areas);
    set(
      'excludedLocations',
      'Autres sites SPGE et zones non visitées ; périmètre à confirmer avant validation.',
    );
    set('concernedPositions', persons);
    set('concernedTasks', activity);
    set(
      'includedSituations',
      'Fonctionnement normal, entretien, incident, urgence, coactivité et intervention d’entreprises extérieures.',
    );
    set(
      'exposureDuration',
      'Variable selon la tâche ; fréquence et durée à confirmer avec les travailleurs.',
    );
    set(
      'workMode',
      'Principalement sur site, avec télétravail partiel pour certains agents.',
    );
    set(
      'fieldVisitDone',
      'À réaliser avec le gestionnaire du site et le service technique.',
    );
    set(
      'jobObservationDone',
      'Observation ciblée à planifier dans les zones concernées.',
    );
    set(
      'workersConsulted',
      'À organiser avec un échantillon de travailleurs exposés.',
    );
    set(
      'managementConsulted',
      'Marc Delvaux et les responsables concernés à consulter.',
    );
    set(
      'cpptConsulted',
      'Projet à présenter au CPPT selon les règles internes SPGE.',
    );
    set(
      'incidentRegisterAvailable',
      'Registre incidents et accidents à demander.',
    );
    set(
      'photosAvailable',
      'Photos à prendre lors de la visite, avec accord du gestionnaire.',
    );
    set(
      'controlReportsAvailable',
      'Rapports applicables à demander au gestionnaire.',
    );
    set(
      'technicalSheetsAvailable',
      'Notices et fiches techniques à centraliser.',
    );
    set(
      'safetyDataSheetsAvailable',
      'FDS des produits présents à obtenir et vérifier.',
    );
    set(
      'sector',
      'Administration et gestion du service public de l’eau en Wallonie.',
    );
    set('workerCount', preset['numberOfWorkers'].toString());
    set('activity', activity);
    set('equipment', equipment);
    set('dangerousProducts', products);
    set('exposedWorkers', persons);
    set(
      'knownIncidents',
      'Aucun incident spécifique confirmé lors du préremplissage ; registre à consulter.',
    );
    set(
      'constraints',
      '${preset['priority']} Délai proposé : ${preset['deadline']}',
    );
    set('writtenInstructions', preset['existingMeasures'].toString());
    set(
      'completedTrainings',
      'Formations et sensibilisations existantes à inventorier auprès des RH et du service technique.',
    );
    set(
      'availablePpe',
      'EPI adaptés à confirmer selon les tâches et les entreprises intervenantes.',
    );
    set('periodicControls', preset['pointsToCheck'].toString());
    set('availableEvidence', preset['evidenceToCollect'].toString());
    set(
      'oralMeasures',
      'Certaines pratiques sont connues oralement ; leur formalisation doit être vérifiée.',
    );
    set('measuresToVerify', preset['plannedMeasures'].toString());
    set(
      'workAtHeight',
      normalizedDocumentType.contains('hauteur')
          ? 'Oui, situation centrale de cette analyse ; accès, matériel et protections à vérifier.'
          : 'Ponctuel pour maintenance ou accès aux stockages ; à encadrer.',
    );
    set(
      'dangerousMachines',
      normalizedDocumentType.contains('machine')
          ? 'Oui, équipements et petit outillage décrits dans le scénario.'
          : 'Petit outillage du service technique uniquement ; inventaire à vérifier.',
    );
    set(
      'chemicalProducts',
      normalizedDocumentType.contains('nettoyage') ||
              normalizedDocumentType.contains('produits chimiques')
          ? 'Oui, détergents et désinfectants utilisés pour le nettoyage.'
          : 'Produits de nettoyage présents ; exposition indirecte possible.',
    );
    set(
      'manualHandling',
      normalizedDocumentType.contains('manutention') ||
              normalizedDocumentType.contains('archive')
          ? 'Oui, boîtes d’archives, fournitures et matériel léger.'
          : 'Ponctuelle pour dossiers, colis et fournitures.',
    );
    set(
      'vehiclePedestrianTraffic',
      normalizedDocumentType.contains('circulation')
          ? 'Oui, accès parking, livraisons, visiteurs et cheminements piétons.'
          : 'Présente au parking et lors des livraisons ; à vérifier.',
    );
    set(
      'noise',
      'Niveau de bureau généralement faible ; nuisances ponctuelles à confirmer.',
    );
    set(
      'fireRisk',
      'Oui, charge combustible, installations électriques et évacuation à considérer.',
    );
    set(
      'loneWork',
      normalizedDocumentType.contains('travail isole')
          ? 'Oui, nettoyage hors horaires et présence ponctuelle seul sur site.'
          : 'Possible en début ou fin de journée et lors du nettoyage.',
    );
    set(
      'coactivity',
      'Oui, travailleurs, visiteurs, nettoyage, maintenance et entreprises extérieures.',
    );
    set(
      'weatherConstraints',
      'Faibles en intérieur ; pluie et gel possibles aux accès et au parking.',
    );
    set(
      'newWorkers',
      'Accueil sécurité et information sur les consignes du site à formaliser.',
    );
    set(
      'temporaryWorkers',
      'Même accueil sécurité et mêmes restrictions que le personnel SPGE.',
    );
    set(
      'youngWorkers',
      'Aucun connu ; affectation et restrictions à vérifier le cas échéant.',
    );
    set(
      'pregnantOrBreastfeedingWorkers',
      'Analyse individuelle à prévoir si nécessaire, dans le respect de la confidentialité.',
    );
    set(
      'medicalRestrictionsWorkers',
      'Restrictions individuelles à gérer avec le médecin du travail, sans donnée médicale dans ce document.',
    );
    set(
      'isolatedWorkers',
      'Nettoyage hors horaires et agents présents ponctuellement seuls.',
    );
    set(
      'subcontractors',
      'Maintenance, nettoyage, contrôles périodiques et petits travaux.',
    );
    set(
      'cpptPresence',
      'À confirmer ; présentation prévue pour les actions importantes.',
    );
    set('preventionService', preset['responsible'].toString());
    set('feedAnnualActionPlan', 'Oui : ${preset['paaPgpLinks']}');
    set(
      'feedGlobalPreventionPlan',
      'Oui pour les actions structurelles et pluriannuelles.',
    );
    set('presentToCppt', 'Oui pour avis et suivi des priorités retenues.');
    set(
      'externalServiceValidation',
      'À prévoir selon le risque et les compétences requises.',
    );
    set(
      'occupationalDoctorAdvice',
      'À solliciter si l’exposition ou la santé au travail le justifie.',
    );

    // Keep the complete risk description available to callers even when the
    // generic questionnaire has no dedicated risk-summary field.
    preset['mainRiskSummary'] = risks;
  }

  static String _buildAdditionalContext({
    required String scenarioName,
    required String documentType,
    required Map<String, dynamic> preset,
  }) {
    String value(String key, [String fallback = 'À vérifier sur site']) =>
        preset[key]?.toString().trim().isNotEmpty == true
        ? preset[key].toString().trim()
        : fallback;

    final exposedPersons = value('exposedPersons', value('occupants'));
    final concernedAreas = value(
      'concernedAreas',
      value(
        'workplaceDescription',
        value('buildingDescription', value('elevatorLocation')),
      ),
    );
    final risks = value('mainRisks', value('fireRisks'));
    final specificDetails = preset.entries
        .where(
          (entry) =>
              !_commonKeys.contains(entry.key) &&
              !_contextSectionKeys.contains(entry.key) &&
              _readableLabels.containsKey(entry.key),
        )
        .map((entry) => '- ${_readableLabels[entry.key]} : ${entry.value}')
        .join('\n');

    return '''SCÉNARIO TEST SPGE
Document : $documentType
${value('scenario')}

DONNÉES SPÉCIFIQUES $scenarioName
${specificDetails.isEmpty ? '- Données à confirmer lors de la visite du site.' : specificDetails}

PERSONNES EXPOSÉES
$exposedPersons

ZONES CONCERNÉES
$concernedAreas

RISQUES IDENTIFIÉS
$risks

MESURES EXISTANTES
${value('existingMeasures')}

POINTS À VÉRIFIER
${value('pointsToCheck')}

MESURES À PRÉVOIR
${value('plannedMeasures')}

PRIORITÉS
${value('priority')}

RESPONSABLES
${value('responsible')}

DÉLAIS
${value('deadline')}

PREUVES À OBTENIR
${value('evidenceToCollect')}

LIENS PAA / PGP
${value('paaPgpLinks')}

LIENS DIU
${value('diuLinks')}

LIENS PIU
${value('piuLinks')}''';
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static const _commonKeys = {
    'companyName',
    'siteName',
    'buildingName',
    'address',
    'postalCode',
    'city',
    'country',
    'activityDescription',
    'numberOfWorkers',
    'visitors',
    'preventionAdvisor',
    'siteContact',
    'siteManager',
    'technicalServiceContact',
    'generalPhone',
    'generalEmail',
    'language',
    'visitorsPresence',
    'externalCompaniesPresence',
    'workingHours',
  };

  static const _contextSectionKeys = {
    'scenario',
    'exposedPersons',
    'occupants',
    'concernedAreas',
    'workplaceDescription',
    'buildingDescription',
    'mainRisks',
    'fireRisks',
    'existingMeasures',
    'pointsToCheck',
    'plannedMeasures',
    'priority',
    'responsible',
    'deadline',
    'evidenceToCollect',
    'paaPgpLinks',
    'diuLinks',
    'piuLinks',
  };

  static const _readableLabels = <String, String>{
    'owner': 'Propriétaire',
    'manager': 'Gestionnaire',
    'contactPerson': 'Personne de contact',
    'sect': 'SECT',
    'maintenanceCompany': 'Entreprise de maintenance',
    'elevatorAddress': 'Adresse de l’ascenseur',
    'elevatorLocation': 'Localisation de l’ascenseur',
    'brand': 'Marque',
    'serialNumber': 'Numéro de série',
    'constructionYear': 'Année de construction',
    'commissioningDate': 'Date de mise en service',
    'elevatorType': 'Type d’ascenseur',
    'ratedLoad': 'Charge nominale',
    'personsCapacity': 'Capacité',
    'speed': 'Vitesse',
    'numberOfStops': 'Nombre d’arrêts',
    'environment': 'Environnement',
    'usageIntensity': 'Intensité d’utilisation',
    'vulnerableUsers': 'Utilisateurs vulnérables',
    'historicalValue': 'Valeur historique',
    'sectReportAvailable': 'Rapport SECT',
    'lastPeriodicInspectionAvailable': 'Dernier contrôle périodique',
    'regularizationCertificateAvailable': 'Attestation de régularisation',
    'openSectRemarks': 'Remarques SECT ouvertes',
    'modernizationWorksDone': 'Travaux de modernisation',
    'openWorks': 'Travaux ouverts',
    'installationType': 'Type d’installation',
    'installationStatus': 'État de l’installation',
    'analysisStage': 'Stade de l’analyse',
    'hasLowVoltageCabinet': 'Armoires basse tension',
    'hasHighVoltageCabin': 'Cabine haute tension',
    'hasTransformer': 'Transformateur',
    'hasMainLowVoltagePanel': 'TGBT',
    'rgieReportAvailable': 'PV RGIE',
    'periodicInspectionAvailable': 'Contrôle périodique',
    'ba4Ba5ListAvailable': 'Liste BA4/BA5',
    'lockoutProcedureAvailable': 'Procédure de consignation',
    'thermographyReportAvailable': 'Rapport de thermographie',
    'openInspectionRemarks': 'Remarques de contrôle ouvertes',
    'connectedWorkEquipment': 'Équipements raccordés',
    'activityType': 'Type d’activité',
    'workstations': 'Postes de travail',
    'exposureDuration': 'Durée d’exposition',
    'handledLoads': 'Charges manipulées',
    'productsUsed': 'Produits utilisés',
    'concernedActivities': 'Activités concernées',
    'externalCompanies': 'Entreprises extérieures',
  };

  static const Map<String, dynamic> _general = {
    'scenario':
        'Analyse globale du site administratif afin d’identifier les risques transversaux et de préparer les actions à intégrer au plan d’action.',
    'activityType': 'Administration, bureaux, accueil du public et réunions.',
    'workplaceDescription':
        'Bâtiment administratif de trois niveaux avec accueil, open spaces, bureaux individuels, salles de réunion, sanitaires, local nettoyage, archives et locaux techniques.',
    'concernedAreas':
        'Accueil, open spaces, bureaux individuels, salles de réunion, sanitaires, local nettoyage, archives, circulations et locaux techniques.',
    'exposedPersons':
        'Travailleurs administratifs, visiteurs, entreprises extérieures, personnel de nettoyage, service technique, personnes à mobilité réduite.',
    'mainRisks':
        'Circulation interne, chutes de plain-pied, ergonomie postes écran, manutention ponctuelle d’archives, risques incendie, risques électriques, coactivité avec entreprises extérieures, stress lié à l’accueil du public.',
    'existingMeasures':
        'Plans d’évacuation affichés, extincteurs présents, éclairage de secours, registre visiteurs, consignes générales, service de nettoyage, premiers secours disponibles.',
    'pointsToCheck':
        'Mise à jour plans, registre exercices, liste secouristes, accueil entreprises extérieures, état circulations, câbles au sol, ergonomie postes écran.',
    'plannedMeasures':
        'Vérifier les plans d’évacuation, mettre à jour la liste des secouristes, vérifier les extincteurs, formaliser l’accueil des entreprises extérieures, contrôler les câbles au sol, compléter l’analyse ergonomique des postes écran.',
    'priority': 'Moyenne à élevée selon les zones.',
    'responsible':
        'Direction du site, conseiller en prévention, service technique.',
    'deadline':
        '3 mois pour les actions prioritaires, 12 mois pour les améliorations générales.',
    'evidenceToCollect':
        'Photos des zones, rapports de contrôle, liste secouristes, registre exercices, plan d’action mis à jour.',
    'paaPgpLinks':
        'Actions transversales prévention, contrôles, formation, accueil entreprises.',
    'diuLinks': 'Locaux techniques, circulations, contraintes interventions.',
    'piuLinks': 'Organisation urgence, contacts, évacuation.',
  };

  static const Map<String, dynamic> _fire = {
    'scenario':
        'Le bâtiment administratif comporte des archives papier, des bureaux, un accueil public, des locaux techniques et un local nettoyage. L’objectif est d’identifier les risques incendie, vérifier les moyens d’évacuation et alimenter le PIU.',
    'buildingDescription':
        'Bâtiment administratif de trois niveaux avec accueil, bureaux, salles de réunion, archives, local nettoyage, local technique et armoires électriques.',
    'concernedAreas':
        'Accueil, bureaux, salles de réunion, archives, local nettoyage, local technique, circulations, escaliers et issues de secours.',
    'occupants':
        '85 travailleurs, visiteurs ponctuels, entreprises extérieures et personnel de nettoyage hors heures.',
    'exposedPersons':
        '85 travailleurs, visiteurs ponctuels, entreprises extérieures, personnel de nettoyage hors heures et services de secours.',
    'fireRisks':
        'Archives papier, multiprises dans certains bureaux, armoires électriques, local nettoyage avec produits, charge combustible dans les locaux de stockage, portes coupe-feu à vérifier.',
    'existingMeasures':
        'Extincteurs, éclairage de secours, signalisation d’évacuation, plans affichés, alarme incendie, exercices d’évacuation occasionnels.',
    'pointsToCheck':
        'Accessibilité des extincteurs, validité des contrôles, dégagement des issues, fermeture des portes coupe-feu, conformité du local archives, présence du dossier pompiers, mise à jour du plan d’évacuation.',
    'plannedMeasures':
        'Mettre à jour le dossier intervention pompiers, vérifier le point de rassemblement, formaliser l’accueil des secours, contrôler les stockages, sensibiliser le personnel, planifier un exercice d’évacuation annuel.',
    'priority': 'Élevée pour issues, alarme, extincteurs et portes coupe-feu.',
    'responsible':
        'Service technique, conseiller en prévention, direction du site.',
    'deadline': '1 à 3 mois.',
    'evidenceToCollect':
        'Rapport extincteurs, rapport éclairage secours, photos issues, plan d’évacuation, registre exercice incendie.',
    'paaPgpLinks':
        'Exercice évacuation, contrôle stockage, levée remarques incendie.',
    'diuLinks': 'Compartimentage, accès secours, locaux techniques, archives.',
    'piuLinks':
        'Alarme, évacuation, point rassemblement, accueil secours, dossier pompiers.',
  };

  static const Map<String, dynamic> _electrical = {
    'installationType':
        'Mixte basse tension avec armoires électriques principales, tableaux divisionnaires et local technique. Pas de cabine haute tension connue sur site.',
    'installationStatus':
        'Installation existante avec modifications ponctuelles lors de rénovations.',
    'analysisStage': 'Exploitation',
    'hasLowVoltageCabinet':
        'Oui, TGBT au local technique et tableaux divisionnaires par étage',
    'hasHighVoltageCabin': 'Non connue / à vérifier',
    'hasTransformer': 'Non connu / à vérifier',
    'hasMainLowVoltagePanel': 'Oui',
    'rgieReportAvailable': 'À demander',
    'periodicInspectionAvailable': 'À demander au gestionnaire',
    'ba4Ba5ListAvailable': 'Non disponible lors de l’analyse, à vérifier',
    'lockoutProcedureAvailable':
        'Non formalisée sur site, à vérifier avec le service technique',
    'thermographyReportAvailable': 'Non disponible, à demander',
    'openInspectionRemarks':
        'Inconnues, à vérifier dans le dernier rapport de contrôle',
    'connectedWorkEquipment':
        'Postes informatiques, imprimantes, serveurs locaux, matériel audiovisuel, machine à café, appareils de nettoyage, petit outillage service technique',
    'scenario':
        'Le site dispose de plusieurs armoires électriques accessibles au service technique. Le conseiller en prévention veut vérifier les preuves RGIE, les accès, les habilitations BA4/BA5, la consignation et les risques liés aux interventions d’entreprises extérieures.',
    'exposedPersons':
        'Service technique, entreprises extérieures, personnel de nettoyage, travailleurs proches des armoires, visiteurs en cas d’accès non contrôlé',
    'concernedAreas':
        'Local technique, TGBT, tableaux divisionnaires par étage, zones de bureaux avec multiprises, local serveur',
    'mainRisks':
        'Contact direct ou indirect, accès non autorisé aux armoires, absence de preuve BA4/BA5, défaut de signalisation, surcharge multiprises, absence de procédure claire de consignation, remarques RGIE inconnues, risque d’incendie d’origine électrique.',
    'existingMeasures':
        'Armoires électriques fermées, local technique réservé au service technique, signalisation partielle, disjoncteurs différentiels présents à vérifier.',
    'pointsToCheck':
        'PV RGIE, schémas unifilaires, verrouillage armoires, signalisation tension, liste BA4/BA5, procédure consignation, test différentiels, thermographie, surcharge multiprises.',
    'plannedMeasures':
        'Demander PV RGIE, vérifier verrouillage des armoires, identifier les personnes BA4/BA5, formaliser la consignation, prévoir thermographie, vérifier les multiprises, mettre à jour les schémas unifilaires.',
    'priority':
        'Élevée pour accès armoires, PV RGIE, consignation et remarques ouvertes.',
    'responsible': 'Service technique et conseiller en prévention',
    'deadline': '1 à 3 mois',
    'evidenceToCollect':
        'PV RGIE, schémas unifilaires, liste BA4/BA5, photos des armoires, preuve contrôle différentiel, rapport thermographie',
    'paaPgpLinks':
        'Mise à jour schémas, thermographie, formation BA4/BA5, consignation, levée remarques RGIE',
    'diuLinks':
        'Localisation TGBT, coupures électriques, accès technique, contraintes pour entreprises extérieures',
    'piuLinks':
        'Coupure générale, accès local technique, contact service technique, risque incendie électrique',
  };

  static const Map<String, dynamic> _elevator = {
    'owner': 'SPGE',
    'manager': 'Marc Delvaux',
    'contactPerson': 'Sophie Martin',
    'preventionAdvisor': 'Vincent Legrand',
    'sect': 'À confirmer auprès du gestionnaire',
    'maintenanceCompany': 'LiftControl Belgium',
    'elevatorAddress': 'Rue des Écoles 12, 4800 Verviers',
    'elevatorLocation':
        'Hall principal, desserte rez-de-chaussée, étage 1 et étage 2',
    'brand': 'Kone, à confirmer sur plaque signalétique',
    'serialNumber': 'À relever sur site',
    'constructionYear': '2008, à confirmer',
    'commissioningDate': '2009, à confirmer',
    'elevatorType': 'Électrique',
    'ratedLoad': '630 kg',
    'personsCapacity': '8 personnes',
    'speed': '1 m/s, à confirmer',
    'numberOfStops': '3',
    'environment': 'Immeuble de bureaux avec accueil visiteurs',
    'usageIntensity': 'Normale à intensive en journée',
    'vulnerableUsers':
        'Visiteurs, personnes âgées occasionnelles, personnes à mobilité réduite',
    'historicalValue': 'Non',
    'sectReportAvailable': 'À demander',
    'lastPeriodicInspectionAvailable': 'À demander',
    'regularizationCertificateAvailable': 'À vérifier',
    'openSectRemarks': 'Inconnues, à vérifier dans le dernier rapport SECT',
    'modernizationWorksDone': 'Inconnus',
    'openWorks': 'À vérifier',
    'scenario':
        'L’ascenseur est utilisé quotidiennement par le personnel administratif, les visiteurs et occasionnellement des personnes à mobilité réduite. Le conseiller en prévention souhaite préparer le suivi des obligations, vérifier les documents disponibles et identifier les mesures à intégrer au plan d’action.',
    'exposedPersons':
        'Travailleurs, visiteurs, PMR, personnes âgées occasionnelles, personnel de nettoyage, entreprise de maintenance, secours',
    'concernedAreas':
        'Cabine, portes palières, hall, paliers, gaine, cuvette, local technique ou salle machines',
    'mainRisks':
        'Personne bloquée en cabine, défaut de communication bidirectionnelle, défaut d’éclairage de secours, précision d’arrêt insuffisante, risque de trébuchement au seuil, défaut de verrouillage des portes palières, accès technique non sécurisé, remarques SECT ouvertes, maintenance insuffisamment documentée.',
    'existingMeasures':
        'Contrat de maintenance supposé, bouton d’alarme en cabine, affichage de la charge nominale, éclairage cabine, portes automatiques, usage normal par le personnel et les visiteurs.',
    'pointsToCheck':
        'Rapport SECT, dernier contrôle périodique, test communication bidirectionnelle, test éclairage secours, précision d’arrêt, affichage charge, état portes palières, accès local technique, procédure personne bloquée, contacts urgence.',
    'plannedMeasures':
        'Obtenir le dernier rapport SECT, vérifier les remarques ouvertes, tester la communication bidirectionnelle, tester l’éclairage de secours, vérifier la précision d’arrêt, formaliser la procédure personne bloquée, intégrer les contacts maintenance au PIU, vérifier l’accès au local technique.',
    'priority':
        'Élevée pour communication bidirectionnelle, éclairage secours, remarques SECT et procédure personne bloquée.',
    'responsible':
        'Gestionnaire du site, conseiller en prévention, entreprise de maintenance ascenseur',
    'deadline': '1 mois pour les documents et vérifications prioritaires',
    'evidenceToCollect':
        'Rapport SECT, contrat maintenance, photos cabine, photo plaque signalétique, preuve test téléphone cabine, preuve éclairage secours, dernier rapport d’entretien',
    'paaPgpLinks':
        'Levée des remarques SECT, suivi maintenance, tests périodiques, procédure personne bloquée',
    'diuLinks':
        'Localisation ascenseur, accès local technique, contraintes d’intervention, schémas et dossier technique',
    'piuLinks':
        'Procédure personne bloquée, contact maintenance, contact secours, interdiction de désincarcération par personnel non formé',
  };

  static const Map<String, dynamic> _ergonomics = {
    'scenario':
        'Plusieurs travailleurs occupent des postes écran pendant la majorité de la journée. Certains postes sont installés en open space, d’autres à l’accueil ou en bureaux individuels.',
    'activityType':
        'Travail administratif sur écran, accueil téléphonique, encodage, réunions et traitement de dossiers.',
    'workstations':
        'Open space, bureaux individuels, accueil, salle de réunion utilisée ponctuellement comme poste temporaire.',
    'concernedAreas':
        'Open space, bureaux individuels, accueil, salle de réunion et postes de télétravail.',
    'exposedPersons':
        'Personnel administratif, accueil, direction, agents en télétravail partiel.',
    'exposureDuration':
        '6 à 7 heures par jour sur écran pour la majorité des travailleurs.',
    'mainRisks':
        'Fatigue visuelle, douleurs cervicales, douleurs dorsales, troubles musculosquelettiques, mauvaise hauteur écran, éclairage inadapté, câbles au sol, postes temporaires non adaptés.',
    'existingMeasures':
        'Chaises réglables, écrans externes pour une partie du personnel, pauses informelles, télétravail partiel.',
    'pointsToCheck':
        'Hauteur écran, réglage chaise, position clavier/souris, éclairage, reflets, câbles, postes accueil, postes télétravail.',
    'plannedMeasures':
        'Vérifier l’ergonomie des postes, fournir supports écrans, vérifier éclairage, sensibiliser aux pauses, prévoir analyse postes écran, adapter les postes accueil et télétravail.',
    'priority': 'Moyenne.',
    'responsible': 'Conseiller en prévention, RH, direction du site.',
    'deadline': '6 mois.',
    'evidenceToCollect':
        'Photos postes, checklist ergonomie, inventaire matériel, registre demandes adaptation.',
    'paaPgpLinks': 'Campagne ergonomie, adaptation postes, achat matériel.',
    'diuLinks': 'Non prioritaire sauf aménagement structurel.',
    'piuLinks': 'Non applicable sauf information PMR/occupation.',
  };

  static const Map<String, dynamic> _manualHandling = {
    'scenario':
        'Les travailleurs manipulent ponctuellement des boîtes d’archives et fournitures. Le local archives est utilisé par plusieurs services et certains stockages sont en hauteur.',
    'activityType':
        'Manipulation ponctuelle de boîtes d’archives, dossiers papier, fournitures, matériel de réunion et colis.',
    'concernedAreas':
        'Local archives, réserve fournitures, accueil, salles de réunion.',
    'exposedPersons':
        'Personnel administratif, accueil, service technique, nettoyage.',
    'handledLoads':
        'Boîtes d’archives de 5 à 15 kg, cartons de fournitures, matériel audiovisuel léger.',
    'mainRisks':
        'Douleurs dorsales, chute de charge, stockage en hauteur, encombrement, accès difficile aux archives, escabeau inadapté, circulation avec charge.',
    'existingMeasures': 'Rayonnages, chariots ponctuels, aide entre collègues.',
    'pointsToCheck':
        'Poids boîtes, état rayonnages, stockage lourd en hauteur, disponibilité chariot, accès au local, escabeau conforme.',
    'plannedMeasures':
        'Limiter les charges, utiliser chariot adapté, organiser les archives, éviter stockage lourd en hauteur, former aux gestes de manutention, vérifier stabilité rayonnages.',
    'priority': 'Moyenne.',
    'responsible': 'Service technique, direction, conseiller en prévention.',
    'deadline': '3 à 6 mois.',
    'evidenceToCollect':
        'Photos archives, inventaire charges, vérification rayonnages, preuve mise à disposition chariot.',
    'paaPgpLinks':
        'Réorganisation archives, achat chariot, contrôle rayonnages.',
    'diuLinks': 'Local archives, charges admissibles, rayonnages.',
    'piuLinks': 'Charge combustible archives utile pour incendie.',
  };

  static const Map<String, dynamic> _cleaning = {
    'scenario':
        'Le nettoyage est réalisé hors heures de bureau avec stockage de produits dans un local dédié. Les FDS ne sont pas toutes disponibles lors de la visite.',
    'activityType':
        'Nettoyage des bureaux, sanitaires, sols, vitres intérieures et zones communes.',
    'productsUsed':
        'Détergents, désinfectants sanitaires, produits vitres, produits sol.',
    'exposedPersons':
        'Personnel de nettoyage, travailleurs présents hors horaires, visiteurs indirectement.',
    'concernedAreas':
        'Local nettoyage, sanitaires, couloirs, bureaux, accueil.',
    'mainRisks':
        'Contact cutané, inhalation, mélange incompatible de produits, stockage non conforme, glissade sur sol humide, absence de FDS, étiquetage insuffisant.',
    'existingMeasures':
        'Local nettoyage dédié, certains produits étiquetés, panneaux sol humide disponibles.',
    'pointsToCheck':
        'FDS, étiquetage, stockage, ventilation local, transvasements, EPI, procédure sol humide, compatibilité produits.',
    'plannedMeasures':
        'Obtenir les fiches de données de sécurité, vérifier stockage, interdire transvasements non étiquetés, sensibiliser nettoyage, vérifier ventilation local, prévoir gants adaptés.',
    'priority': 'Moyenne à élevée selon produits.',
    'responsible':
        'Entreprise de nettoyage, gestionnaire du site, conseiller en prévention.',
    'deadline': '1 à 3 mois.',
    'evidenceToCollect':
        'FDS, photos stockage, inventaire produits, procédure nettoyage, preuve formation.',
    'paaPgpLinks': 'Inventaire produits, FDS, formation nettoyage.',
    'diuLinks': 'Local nettoyage, produits stockés, ventilation.',
    'piuLinks': 'Produit chimique, déversement, contact urgence.',
  };

  static const Map<String, dynamic> _externalCompanies = {
    'scenario':
        'Plusieurs entreprises interviennent sur site pour l’ascenseur, l’électricité, le nettoyage, le HVAC et les contrôles périodiques. L’accueil sécurité n’est pas formalisé.',
    'concernedActivities':
        'Maintenance ascenseur, maintenance électrique, nettoyage, interventions HVAC, petits travaux bâtiment, contrôle extincteurs.',
    'externalCompanies':
        'LiftControl Belgium, société de nettoyage, organisme agréé, maintenance technique.',
    'exposedPersons':
        'Travailleurs, visiteurs, entreprises extérieures, service technique, accueil.',
    'concernedAreas':
        'Accueil, circulations, ascenseur, locaux techniques, toiture, zones HVAC et bureaux occupés.',
    'mainRisks':
        'Coactivité, absence d’accueil sécurité, travaux sans information préalable, accès locaux techniques, consignation électrique, travaux en hauteur ponctuels, circulation visiteurs.',
    'existingMeasures':
        'Accueil par réception, registre visiteurs, accompagnement ponctuel par service technique.',
    'pointsToCheck':
        'Procédure accueil, consignes transmises, registre visiteurs, permis de travail, consignation, attestations, planification interventions.',
    'plannedMeasures':
        'Créer procédure accueil entreprises extérieures, transmettre consignes sécurité, vérifier attestations, planifier interventions, formaliser permis de travail si nécessaire, intégrer consignation électrique.',
    'priority': 'Élevée pour interventions techniques.',
    'responsible':
        'Direction du site, service technique, conseiller en prévention.',
    'deadline': '3 mois.',
    'evidenceToCollect':
        'Registre visiteurs, procédure accueil, bons d’intervention, attestations entreprises, permis de travail.',
    'paaPgpLinks':
        'Procédure entreprises extérieures, permis de travail, coordination.',
    'diuLinks': 'Contraintes techniques pour interventions futures.',
    'piuLinks': 'Présence entreprises en cas d’évacuation, recensement.',
  };

  static const Map<String, dynamic> _internalTraffic = {
    'scenario':
        'Le site accueille des travailleurs et visiteurs. Des zones de circulation peuvent être encombrées lors de réunions ou livraisons. Des câbles et tapis doivent être vérifiés.',
    'concernedAreas':
        'Accueil, couloirs, escaliers, sanitaires, parking, accès visiteurs, salles de réunion.',
    'exposedPersons':
        'Travailleurs, visiteurs, PMR, nettoyage, entreprises extérieures.',
    'mainRisks':
        'Chutes de plain-pied, glissade sol humide, encombrement couloirs, câbles au sol, tapis d’entrée, éclairage insuffisant, escaliers.',
    'existingMeasures':
        'Éclairage général, nettoyage régulier, panneaux sol humide, mains courantes escaliers.',
    'pointsToCheck':
        'Tapis entrée, câbles, éclairage, état marches, signalisation sol humide, dégagement circulations, accès PMR.',
    'plannedMeasures':
        'Vérifier tapis d’entrée, supprimer câbles au sol, vérifier éclairage, dégager circulations, contrôler état marches, prévoir signalement défauts.',
    'priority': 'Moyenne.',
    'responsible': 'Gestionnaire du site, service technique, nettoyage.',
    'deadline': '1 à 3 mois.',
    'evidenceToCollect':
        'Photos zones, registre incidents, checklist circulation, actions correctives.',
    'paaPgpLinks': 'Plan de correction circulations, signalement défauts.',
    'diuLinks': 'Circulations, accès PMR, contraintes bâtiment.',
    'piuLinks': 'Cheminements évacuation, issues, PMR.',
  };

  static const Map<String, dynamic> _psychosocial = {
    'scenario':
        'Le personnel d’accueil reçoit des visiteurs et traite des appels. Des tensions peuvent survenir lors de demandes administratives complexes.',
    'activityType':
        'Accueil du public, appels téléphoniques, gestion de dossiers administratifs, réunions avec usagers.',
    'exposedPersons':
        'Personnel accueil, agents administratifs, responsables d’équipe.',
    'concernedAreas':
        'Accueil du public, bureaux administratifs, zones d’attente, salles de réunion et postes téléphoniques.',
    'mainRisks':
        'Charge mentale, agressivité verbale, interruptions fréquentes, pression délais, isolement ponctuel, manque de procédure en cas d’incident.',
    'existingMeasures':
        'Présence de collègues, encadrement hiérarchique, possibilité de signalement oral.',
    'pointsToCheck':
        'Procédure agression, registre incidents, moyens d’appel interne, formation accueil difficile, organisation pauses, soutien après incident.',
    'plannedMeasures':
        'Formaliser procédure agression, former accueil difficile, clarifier signalement incident, prévoir bouton ou moyen d’appel interne, organiser débriefing après incident.',
    'priority': 'Moyenne à élevée pour accueil.',
    'responsible':
        'Direction, RH, conseiller en prévention aspects psychosociaux.',
    'deadline': '3 à 6 mois.',
    'evidenceToCollect':
        'Procédure agression, registre incidents, preuve information personnel, plan d’action psychosocial.',
    'paaPgpLinks': 'Plan psychosocial, formation accueil, procédure incident.',
    'diuLinks': 'Non applicable sauf aménagement accueil.',
    'piuLinks': 'Intrusion, agression, appel interne, mise à l’abri.',
  };

  static const Map<String, dynamic> _job = {
    'scenario':
        'Le poste d’agent d’accueil combine réception des visiteurs, appels téléphoniques, encodage sur écran, gestion de courrier et déplacements ponctuels dans le bâtiment.',
    'activityType':
        'Accueil du public, téléphone, encodage administratif, gestion du courrier et orientation des visiteurs.',
    'concernedAreas':
        'Banque d’accueil, zone d’attente, poste écran, local courrier, circulations et salles de réunion.',
    'exposedPersons':
        'Agents d’accueil, remplaçants, visiteurs, livreurs et responsables d’équipe.',
    'mainRisks':
        'Posture statique, fatigue visuelle, agressivité verbale, interruptions fréquentes, manutention de colis, chute de plain-pied et travail ponctuel isolé.',
    'existingMeasures':
        'Chaise réglable, écran externe, présence de collègues en journée, téléphone interne et registre visiteurs.',
    'pointsToCheck':
        'Réglage du poste, organisation des pauses, moyen d’appel interne, procédure agression, poids des colis, câbles et dégagement de l’accueil.',
    'plannedMeasures':
        'Réaliser une observation du poste, adapter l’écran et le siège, formaliser la procédure agression, organiser les pauses et prévoir un chariot pour les colis.',
    'priority': 'Moyenne à élevée pour l’accueil public et l’ergonomie.',
    'responsible':
        'Responsable accueil, RH, conseiller en prévention et service technique.',
    'deadline': '3 à 6 mois.',
    'evidenceToCollect':
        'Photos du poste, checklist ergonomie, procédure agression, registre incidents et preuve information du personnel.',
    'paaPgpLinks':
        'Adaptation du poste, formation accueil difficile et organisation des pauses.',
    'diuLinks': 'Aménagement fixe de la banque d’accueil et accès PMR.',
    'piuLinks':
        'Alerte interne, intrusion, accueil secours et évacuation visiteurs.',
  };

  static const Map<String, dynamic> _machines = {
    'scenario':
        'Le site administratif utilise plusieurs équipements de bureau et du petit outillage dans le local technique. Leur inventaire, leur état et les consignes ne sont pas centralisés.',
    'activityType':
        'Utilisation de destructeurs de documents, massicot, appareils de cuisine, escabeaux et petit outillage du service technique.',
    'concernedAreas':
        'Bureaux, local reprographie, cafétéria, archives et local technique.',
    'exposedPersons':
        'Personnel administratif, service technique, nettoyage et entreprises extérieures.',
    'mainRisks':
        'Coupure au massicot, entraînement au destructeur, brûlure, choc électrique, projection lors de l’usage d’outillage et utilisation d’un équipement défectueux.',
    'existingMeasures':
        'Protecteurs d’origine sur certains équipements, prises avec terre, rangement du petit outillage et interventions réservées au service technique.',
    'pointsToCheck':
        'Inventaire, notices, marquage CE, état câbles et protecteurs, contrôles, retrait du matériel défectueux et consignes d’utilisation.',
    'plannedMeasures':
        'Créer l’inventaire, identifier les équipements à contrôler, retirer le matériel défectueux, afficher les consignes et formaliser le signalement des anomalies.',
    'priority': 'Élevée pour tout équipement défectueux ou sans protecteur.',
    'responsible':
        'Service technique, gestionnaire du site et conseiller en prévention.',
    'deadline':
        '1 mois pour les anomalies critiques, 6 mois pour l’inventaire.',
    'evidenceToCollect':
        'Inventaire, photos, notices, rapports de contrôle, registre de maintenance et preuves de retrait.',
    'paaPgpLinks':
        'Inventaire équipements, maintenance préventive et information des utilisateurs.',
    'diuLinks':
        'Équipements fixes, alimentations et contraintes de maintenance.',
    'piuLinks':
        'Coupure électrique, incendie d’équipement et premiers secours.',
  };

  static const Map<String, dynamic> _workAtHeight = {
    'scenario':
        'Des accès ponctuels en hauteur sont nécessaires pour les archives, le remplacement d’éléments en hauteur et certaines interventions techniques confiées à des entreprises extérieures.',
    'activityType':
        'Accès ponctuel à des rayonnages, remplacement de consommables en hauteur et maintenance technique.',
    'concernedAreas':
        'Archives, réserves, halls, cages d’escalier, locaux techniques et toiture technique.',
    'exposedPersons':
        'Service technique, personnel administratif, nettoyage et entreprises extérieures.',
    'mainRisks':
        'Chute depuis escabeau, perte d’équilibre, matériel d’accès inadapté, chute d’objet, travail seul et intervention en toiture non préparée.',
    'existingMeasures':
        'Escabeaux disponibles, interventions techniques généralement confiées à des entreprises spécialisées et accès toiture limité.',
    'pointsToCheck':
        'Inventaire et état des escabeaux, stockage en hauteur, accès toiture, protections collectives, permis de travail et compétences des intervenants.',
    'plannedMeasures':
        'Contrôler les escabeaux, interdire les moyens improvisés, limiter le stockage en hauteur, formaliser les interventions toiture et privilégier les protections collectives.',
    'priority':
        'Élevée pour l’accès toiture et tout matériel d’accès défectueux.',
    'responsible':
        'Service technique, conseiller en prévention et entreprises extérieures.',
    'deadline':
        '1 mois pour le contrôle du matériel, avant toute intervention toiture.',
    'evidenceToCollect':
        'Registre escabeaux, photos, procédure travail en hauteur, permis de travail et attestations des entreprises.',
    'paaPgpLinks':
        'Contrôle escabeaux, procédure hauteur et organisation des interventions.',
    'diuLinks':
        'Accès toiture, points d’ancrage, protections collectives et contraintes d’entretien.',
    'piuLinks': 'Accident en hauteur, accès secours et localisation toiture.',
  };

  static const Map<String, dynamic> _loneWork = {
    'scenario':
        'Le personnel de nettoyage travaille hors heures et certains agents administratifs ou techniques restent ponctuellement seuls en début ou fin de journée.',
    'activityType':
        'Nettoyage hors horaires, fermeture du bâtiment, travail administratif tardif et intervention technique ponctuelle.',
    'concernedAreas':
        'Bureaux, sanitaires, circulations, parking, archives et locaux techniques.',
    'exposedPersons':
        'Personnel de nettoyage, agents administratifs, gardiennage éventuel et service technique.',
    'mainRisks':
        'Malaise sans assistance, chute, agression, incident technique, absence de détection et difficulté à donner une localisation précise.',
    'existingMeasures':
        'Téléphone mobile pour certains intervenants, fermeture organisée et contacts hiérarchiques connus oralement.',
    'pointsToCheck':
        'Liste des travailleurs isolés, horaires, moyen d’alerte, procédure de prise de nouvelles, couverture téléphonique et accès des secours.',
    'plannedMeasures':
        'Formaliser le travail isolé, définir les prises de contact, fournir un moyen d’alerte fiable, interdire certaines tâches seul et informer les responsables.',
    'priority':
        'Élevée pour les interventions techniques et le nettoyage isolé.',
    'responsible':
        'Direction du site, entreprise de nettoyage, service technique et conseiller en prévention.',
    'deadline': '3 mois, avant toute tâche technique isolée à risque.',
    'evidenceToCollect':
        'Procédure, planning, liste contacts, preuve test du moyen d’alerte et information des travailleurs.',
    'paaPgpLinks':
        'Procédure travail isolé, moyens d’alerte et organisation des contrôles.',
    'diuLinks': 'Zones sans couverture, accès techniques et accès secours.',
    'piuLinks':
        'Alerte travailleur isolé, contacts, localisation et accueil des secours.',
  };
}
