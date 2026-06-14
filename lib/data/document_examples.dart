import '../models/document_type.dart';
import '../models/prevention_document_config.dart';

Map<String, dynamic> getCompleteExampleForDocument({
  required String documentType,
  required String languageCode,
}) {
  final normalizedLanguageCode = _normalizeLanguageCode(languageCode);
  if (normalizedLanguageCode == null) {
    return const {};
  }
  final canonicalTypeId = _documentTypeIdFromLabel(documentType);
  if (canonicalTypeId == null) {
    return const {};
  }

  final specificExample =
      _documentSpecificCompleteExamples[canonicalTypeId]?[normalizedLanguageCode];
  if (specificExample != null) {
    return Map<String, dynamic>.from(specificExample);
  }

  final documentTypeModel = documentTypes.firstWhere(
    (type) => type.id == canonicalTypeId,
    orElse: () => documentTypes.first,
  );
  final example = completePreventionExample(
    type: documentTypeModel,
    localeName: normalizedLanguageCode,
  );
  return Map<String, dynamic>.from(example);
}

String? _normalizeLanguageCode(String languageCode) {
  final normalized = languageCode.trim().toLowerCase();
  return switch (normalized) {
    'fr' || 'nl' || 'en' || 'de' => normalized,
    _ => null,
  };
}

String? _documentTypeIdFromLabel(String documentType) {
  final normalized = _normalizeText(documentType);
  if (normalized.isEmpty) {
    return null;
  }

  for (final entry in _documentTypeAliases.entries) {
    if (entry.value.any((alias) => _normalizeText(alias) == normalized)) {
      return entry.key;
    }
  }

  return null;
}

String _normalizeText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r"[’']"), "'")
      .replaceAll(RegExp(r'[–—-]'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9\u00c0-\u024f]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

const _documentTypeAliases = {
  'general_risk_analysis': {
    'Analyse de risques générale',
    'General risk analysis',
    'Allgemeine Risikoanalyse',
    'Algemene risicoanalyse',
  },
  'job_risk_analysis': {
    'Analyse de risques par poste de travail',
    'Job risk analysis',
    'Risikoanalyse Arbeitsplatz',
    'Risicoanalyse per werkpost',
  },
  'machine_risk_analysis': {
    'Analyse de risques machines et équipements',
    'Machine and equipment risk analysis',
    'Risikoanalyse Maschinen und Arbeitsmittel',
    'Risicoanalyse machines en arbeidsmiddelen',
  },
  'chemical_risk_analysis': {
    'Analyse de risques produits chimiques',
    'Chemical risk analysis',
    'Risikoanalyse chemische Stoffe',
    'Risicoanalyse chemische producten',
  },
  'fire_risk_analysis': {
    'Analyse de risques incendie et évacuation',
    'Fire and evacuation risk analysis',
    'Risikoanalyse Brand und Evakuierung',
    'Risicoanalyse brand en evacuatie',
  },
  'ergonomics_risk_analysis': {
    'Analyse de risques ergonomie',
    'Ergonomics risk analysis',
    'Risikoanalyse Ergonomie',
    'Ergonomische risicoanalyse',
  },
  'manual_handling_risk_analysis': {
    'Analyse de risques manutention manuelle',
    'Manual handling risk analysis',
    'Risikoanalyse manuelle Handhabung',
    'Risicoanalyse manueel hanteren',
  },
  'height_work_risk_analysis': {
    'Analyse de risques travail en hauteur',
    'Work at height risk analysis',
    'Risikoanalyse Arbeiten in der Höhe',
    'Risicoanalyse werken op hoogte',
  },
  'lone_work_risk_analysis': {
    'Analyse de risques travail isolé',
    'Lone work risk analysis',
    'Risikoanalyse Alleinarbeit',
    'Risicoanalyse alleenwerk',
  },
  'psychosocial_risk_analysis': {
    'Analyse de risques psychosociaux',
    'Psychosocial risk analysis',
    'Risikoanalyse psychosoziale Risiken',
    'Risicoanalyse psychosociale risico’s',
  },
  'annual_action_plan': {
    'Plan annuel d’action',
    'Jaaractieplan',
    'Annual Action Plan',
    'Jährlicher Aktionsplan',
  },
  'five_year_prevention_plan': {
    'Plan global de prévention sur 5 ans',
    'Globaal preventieplan over 5 jaar',
    'Five-Year Global Prevention Plan',
    'Globaler Präventionsplan über 5 Jahre',
  },
  'safety_visit_report': {
    'Rapport de visite sécurité',
    'Veiligheidsbezoekverslag',
    'Safety Visit Report',
    'Sicherheitsbegehungsbericht',
  },
  'job_sheet': {
    'Fiche de poste',
    'Functiefiche',
    'Job Description Sheet',
    'Stellenbeschreibung',
  },
  'safety_instruction_sheet': {
    'Fiche d’instruction sécurité',
    'Veiligheidsinstructieblad',
    'Safety Instruction Sheet',
    'Sicherheitsanweisungsblatt',
  },
  'accident_incident_report': {
    'Rapport d’accident ou d’incident',
    'Ongevallen- of incidentenrapport',
    'Accident or Incident Report',
    'Unfall- oder Vorfallbericht',
  },
};

const _documentSpecificCompleteExamples = {
  'fire_risk_analysis': {'fr': _frenchFireDangerousProductsExample},
};

const _frenchFireDangerousProductsExample = <String, String>{
  'companyName': 'Chemipro Logistics Belgium SRL',
  'siteConcerned':
      'Entrepôt logistique et atelier de maintenance – Zone industrielle de Liège, bâtiment A, bâtiment B, local produits dangereux, local charge batteries, quai de chargement, zone déchets et parking poids lourds',
  'serviceConcerned':
      'Logistique, magasin, maintenance interne, réception marchandises, expédition, nettoyage industriel et encadrement opérationnel',
  'author':
      'Conseiller en prévention interne – projet à compléter après visite terrain',
  'version': '1.0',
  'visitDate':
      '11/06/2026 – visite terrain à confirmer avec le service interne, le service externe et le service incendie si nécessaire',
  'documentObjective':
      'Réaliser une analyse de risques incendie et évacuation pour un site logistique stockant et manipulant des produits dangereux, afin d’identifier les risques d’incendie, d’explosion, de propagation, d’exposition des travailleurs, de difficultés d’évacuation et d’intervention des secours. Le document doit alimenter le plan global de prévention, le plan annuel d’action, le dossier de prévention incendie, les consignes d’urgence et les actions de mise en conformité.',
  'includedLocations':
      'Entrepôt principal de stockage, zone de picking, racks de stockage grande hauteur, local produits inflammables, local produits corrosifs, zone de stockage aérosols, local charge batteries lithium-ion et batteries plomb, atelier de maintenance, chaufferie, local électrique, quais de chargement, zone déchets, zone de stockage palettes, bureaux attenants, vestiaires, réfectoire, voies d’évacuation, sorties de secours, accès pompiers et point de rassemblement.',
  'excludedLocations':
      'Installations techniques non accessibles sans accompagnement spécialisé, interventions de sociétés externes sur installations haute tension, travaux par points chauds déjà soumis à permis spécifique, transport ADR sur voie publique hors site, installations Seveso si non applicables à confirmer.',
  'concernedPositions':
      'Magasiniers, caristes, préparateurs de commandes, opérateurs réception/expédition, techniciens de maintenance, agents de nettoyage, responsables d’équipe, personnel administratif présent dans les bureaux attenants, visiteurs, chauffeurs externes, sous-traitants maintenance, intérimaires et nouveaux travailleurs.',
  'concernedTasks':
      'Réception de produits chimiques, contrôle des emballages, mise en rack, picking, préparation de commandes, filmage palettes, chargement et déchargement camions, circulation chariots élévateurs, charge de batteries, maintenance de premier niveau, nettoyage de déversements mineurs, gestion des déchets dangereux, stockage temporaire de palettes, ouverture ponctuelle d’emballages endommagés, utilisation de produits de nettoyage inflammables, intervention en cas d’alarme incendie ou évacuation.',
  'includedSituations':
      'Activité normale, pic d’activité, réception simultanée de plusieurs camions, stockage temporaire non planifié, fuite ou emballage endommagé, déversement de produit inflammable, départ de feu sur batterie, court-circuit électrique, obstruction d’une voie d’évacuation, alarme incendie, évacuation de travailleurs et visiteurs, intervention de première ligne par équipiers d’intervention, arrivée des secours externes, coactivité avec chauffeurs et sous-traitants.',
  'exposureDuration':
      'Activité logistique 5 jours par semaine, 2 pauses, présence moyenne de 38 travailleurs par jour. Présence ponctuelle de 10 à 20 chauffeurs externes par jour. Charge batteries en fin de poste et parfois pendant la nuit. Stockage de produits dangereux permanent.',
  'workMode':
      'Principalement travail sur site. Personnel administratif partiellement présent dans bureaux attenants à l’entrepôt.',
  'fieldVisitDone':
      'Non finalisée. Visite terrain complète à organiser avec le conseiller en prévention, le responsable logistique, la maintenance, un représentant des travailleurs et, si nécessaire, le service externe.',
  'jobObservationDone':
      'Partielle. Observation recommandée pendant réception marchandises, charge batteries, picking, pause de fin de poste et période de chargement camion.',
  'workersConsulted':
      'À compléter. Consultation recommandée avec caristes, préparateurs, techniciens maintenance, agents nettoyage, intérimaires et chefs d’équipe.',
  'managementConsulted':
      'Partiellement. Responsable logistique et chef maintenance à consulter formellement.',
  'cpptConsulted':
      'Oui, CPPT présent. Le projet doit être présenté pour avis, priorisation et suivi.',
  'incidentRegisterAvailable':
      'Partiellement disponible. Incidents incendie, déversements, alarmes, presque-accidents et exercices d’évacuation à consolider.',
  'photosAvailable':
      'Oui, photos à intégrer au document : local produits inflammables, racks aérosols, local charge batteries, issue de secours quai B, extincteur masqué, porte coupe-feu maintenue ouverte, accès pompiers encombré, zone déchets, plan d’évacuation affiché, point de rassemblement.',
  'controlReportsAvailable':
      'À vérifier : extincteurs, dévidoirs, éclairage de secours, détection incendie, portes coupe-feu, installation électrique, ventilation, sprinklage si présent, racks, chargeurs batteries, moyens de rétention.',
  'technicalSheetsAvailable':
      'Partiellement. Notices chargeurs batteries, racks, armoires de sécurité, détection incendie et ventilation à centraliser.',
  'safetyDataSheetsAvailable':
      'Partiellement. FDS disponibles pour certains solvants et peintures, mais inventaire complet à mettre à jour. FDS manquantes pour certains aérosols, colles et produits de nettoyage.',
  'sector':
      'Logistique industrielle, stockage et distribution de produits chimiques conditionnés, produits d’entretien, aérosols, peintures, solvants, huiles, colles, résines, batteries et consommables techniques.',
  'workerCount':
      '52 travailleurs : 30 magasiniers/caristes/préparateurs, 5 techniciens maintenance, 4 agents nettoyage, 6 chefs d’équipe, 5 employés administratifs, 2 conseillers internes ou support HSE. Présence régulière d’intérimaires et de chauffeurs externes.',
  'activity':
      'Stockage et manutention de produits dangereux dans un entrepôt logistique, avec risque incendie, explosion, propagation de fumées, évacuation complexe et intervention des secours.',
  'equipment':
      'Chariots élévateurs électriques, transpalettes électriques, filmeuse palette, convoyeur court, racks métalliques grande hauteur, armoires de sécurité pour produits inflammables, bacs de rétention, chargeurs de batteries, compresseur, outillage électroportatif, portes sectionnelles, éclairage de secours, extincteurs, dévidoirs muraux, centrale de détection incendie, sirènes, boutons poussoirs d’alarme, sprinklage partiel à vérifier, ventilation mécanique, armoires électriques, palettiers, douches oculaires, kits anti-déversement.',
  'dangerousProducts':
      'Solvants inflammables, peintures, vernis, aérosols, colles, résines, huiles, lubrifiants, produits corrosifs acides et bases, produits comburants en petites quantités, produits de nettoyage inflammables, batteries lithium-ion, batteries plomb-acide, emballages souillés, chiffons contaminés, déchets dangereux, palettes bois, films plastiques et cartons.',
  'exposedWorkers':
      'Caristes, préparateurs de commandes, réceptionnaires, expéditeurs, techniciens maintenance, agents nettoyage, chefs d’équipe, personnel administratif proche de l’entrepôt, visiteurs, chauffeurs externes, sous-traitants, intérimaires, nouveaux travailleurs, travailleurs pouvant être isolés temporairement en zone déchets ou local batteries.',
  'knownIncidents':
      'Début d’échauffement sur chargeur de batterie en 2025, odeur de solvant signalée près du local produits inflammables, fuite mineure d’un bidon de solvant à la réception, palette d’aérosols stockée temporairement hors zone dédiée, porte coupe-feu maintenue ouverte par une cale, extincteur partiellement masqué par palettes, issue de secours obstruée par film plastique, exercice d’évacuation avec temps de sortie trop long pour l’équipe du quai B, confusion de certains intérimaires sur le point de rassemblement, absence de fiche réflexe claire en cas de déversement inflammable.',
  'constraints':
      'Stockage mixte de produits incompatibles à vérifier, rotation importante des stocks, pression liée aux délais de livraison, présence de chauffeurs externes, intérimaires non toujours formés, documentation FDS incomplète ou dispersée, accès pompiers parfois encombré par camions, grande hauteur de stockage, charge batteries proche de stockage combustible, ventilation à confirmer, sprinklage partiel ou non confirmé, signalisation d’évacuation à vérifier, coexistence de bureaux et entrepôt, travaux de maintenance ponctuels.',
  'additionalInformation':
      'L’analyse doit être particulièrement exigeante. Elle doit identifier les scénarios d’incendie plausibles, les incompatibilités chimiques, les sources d’ignition, les charges combustibles, les difficultés d’évacuation, les risques pour les équipiers de première intervention, les documents à créer ou mettre à jour, les contrôles périodiques et les actions prioritaires. Elle doit intégrer le dossier de prévention incendie, les consignes d’urgence, les plans d’évacuation, les exercices, le permis de feu, la gestion des produits dangereux, les FDS, la signalisation, les équipements d’extinction, la détection, le compartimentage, l’accès pompiers et le registre des contrôles.',
  'writtenInstructions':
      'Consigne incendie générale affichée. Plan d’évacuation présent mais à vérifier. Absence de consigne claire pour départ de feu batterie, fuite de solvant, stockage temporaire d’aérosols, porte coupe-feu, déversement inflammable et accueil chauffeurs.',
  'completedTrainings':
      'Exercice d’évacuation annuel réalisé mais résultats incomplets. Formation équipiers de première intervention réalisée pour 6 personnes, recyclage à vérifier. Formation nouveaux travailleurs et intérimaires à renforcer. Formation manipulation produits dangereux insuffisamment documentée.',
  'availablePpe':
      'Gants chimiques, lunettes, chaussures de sécurité, gilets haute visibilité, masques filtrants à vérifier, kits anti-déversement, douches oculaires. Protection respiratoire spécifique incendie non destinée aux travailleurs ; intervention incendie limitée à première alerte et évacuation.',
  'periodicControls':
      'Extincteurs contrôlés en 2026 à confirmer, éclairage de secours à vérifier, détection incendie à vérifier, installation électrique à vérifier, portes coupe-feu non suivies formellement, racks contrôlés partiellement, chargeurs batteries contrôlés partiellement.',
  'availableEvidence':
      'Quelques rapports de contrôle extincteurs, plan d’évacuation affiché, registre exercice évacuation incomplet, liste équipiers intervention, photos de certaines non-conformités, inventaire produits partiel, FDS partielles.',
  'oralMeasures':
      'Interdiction de fumer, consigne de ne pas bloquer les issues, tri des produits incompatibles, réaction en cas de déversement, maintien des portes coupe-feu fermées, accueil sécurité des chauffeurs, limitation du stockage temporaire.',
  'measuresToVerify':
      'Compartimentage, fermeture portes coupe-feu, accessibilité extincteurs, dégagement issues, signalisation, fonctionnement éclairage de secours, détection, ventilation local batteries, séparation produits incompatibles, rétention, accès pompiers, point de rassemblement, affichage plan évacuation, formation intérimaires, état des chargeurs batteries.',
  'workAtHeight':
      'Possible de façon ponctuelle pour accès à certains racks, maintenance de premier niveau, affichages ou contrôles visuels en hauteur. À encadrer avec moyens d’accès adaptés.',
  'dangerousMachines':
      'Oui – chariots élévateurs, transpalettes électriques, filmeuse, convoyeur, outillage électroportatif, compresseur, portes sectionnelles et chargeurs batteries.',
  'chemicalProducts':
      'Oui, importante. Inventaire, compatibilité, quantités maximales, FDS, étiquetage CLP, stockage en rétention et séparation des incompatibles à vérifier.',
  'manualHandling':
      'Oui – manutentions de colis, palettes, emballages endommagés, kits anti-déversement, déchets dangereux et matériel de maintenance.',
  'vehiclePedestrianTraffic':
      'Oui – circulation chariots élévateurs, piétons, chauffeurs externes, quais de chargement, parking poids lourds et accès pompiers.',
  'noise':
      'Présent autour des quais, chariots, compresseur, filmeuse et opérations de manutention. Impact secondaire par rapport au risque incendie mais à vérifier.',
  'fireRisk':
      'Incendie lié aux solvants inflammables, aérosols chauffés ou endommagés, batteries lithium-ion en charge, court-circuit électrique, travaux par points chauds, incompatibilité chimique, déversement inflammable, propagation par cartons/palettes/films plastiques, fumées toxiques, explosion d’aérosols, obstruction des issues, défaillance d’alerte, évacuation difficile de visiteurs ou chauffeurs, accès pompiers entravé. ATEX possible dans certaines zones en cas de vapeurs de solvants ou aérosols endommagés ; analyse ATEX à vérifier selon quantités, ventilation, sources d’ignition et conditions de stockage. Permis de feu à formaliser systématiquement pour les travaux par points chauds.',
  'loneWork':
      'Possible en zone déchets, local batteries ou fin de poste. Procédure à vérifier.',
  'coactivity':
      'Oui, chauffeurs externes, transporteurs, maintenance externe, nettoyage industriel, visiteurs, service incendie en intervention.',
  'weatherConstraints':
      'Influence sur quais, zone déchets extérieure, accès pompiers, stockage temporaire palettes et évacuation vers point de rassemblement.',
  'newWorkers': 'Oui. Accueil sécurité incendie à formaliser avec preuve.',
  'temporaryWorkers':
      'Oui. Formation courte obligatoire avant accès entrepôt à renforcer.',
  'youngWorkers':
      'Possible ponctuellement en stage. À éviter dans zones produits dangereux sans analyse spécifique.',
  'pregnantOrBreastfeedingWorkers':
      'À vérifier. Risques chimiques et évacuation à évaluer spécifiquement avec médecin du travail.',
  'medicalRestrictionsWorkers':
      'À vérifier avec médecin du travail dans le respect de la confidentialité.',
  'isolatedWorkers':
      'Oui – situations possibles en zone déchets, local batteries ou fin de poste, avec alerte et supervision à formaliser.',
  'subcontractors':
      'Oui. Maintenance, nettoyage, contrôles, travaux par points chauds. Coordination et permis de travail à formaliser.',
  'cpptPresence':
      'Oui, CPPT présent. Le projet doit être présenté pour avis, priorisation et suivi.',
  'preventionService':
      'Service interne présent. Service externe à consulter pour risques chimiques, incendie, ATEX potentiel, santé, ergonomie évacuation et conseils spécialisés.',
  'feedAnnualActionPlan':
      'Oui. Les actions urgentes doivent alimenter le PAA : dégagement issues, contrôle portes coupe-feu, inventaire FDS, stockage produits incompatibles, zone batteries, accès pompiers, formation évacuation, permis de feu.',
  'feedGlobalPreventionPlan':
      'Oui. Les actions structurelles doivent alimenter le PGP : compartimentage, détection, sprinklage, ventilation, gestion produits dangereux, formation, digitalisation FDS, gestion des exercices et suivi périodique.',
  'presentToCppt':
      'Oui – présentation recommandée au CPPT pour avis, priorisation, suivi et traçabilité.',
  'externalServiceValidation': 'Oui, fortement recommandée.',
  'occupationalDoctorAdvice':
      'Oui, pour exposition chimique, fumées potentielles, restrictions médicales, travailleuses enceintes, travailleurs vulnérables et aptitude à certaines tâches.',
};
