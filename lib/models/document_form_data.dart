class DocumentFormData {
  const DocumentFormData({
    required this.documentType,
    required this.companyName,
    required this.siteConcerned,
    required this.serviceConcerned,
    required this.author,
    required this.version,
    required this.visitDate,
    required this.documentObjective,
    required this.includedLocations,
    required this.excludedLocations,
    required this.concernedPositions,
    required this.concernedTasks,
    required this.includedSituations,
    required this.exposureDuration,
    required this.workMode,
    required this.fieldVisitDone,
    required this.jobObservationDone,
    required this.workersConsulted,
    required this.managementConsulted,
    required this.cpptConsulted,
    required this.incidentRegisterAvailable,
    required this.photosAvailable,
    required this.controlReportsAvailable,
    required this.technicalSheetsAvailable,
    required this.safetyDataSheetsAvailable,
    required this.sector,
    required this.workerCount,
    required this.activity,
    required this.equipment,
    required this.dangerousProducts,
    required this.exposedWorkers,
    required this.knownIncidents,
    required this.constraints,
    required this.additionalInformation,
    required this.writtenInstructions,
    required this.completedTrainings,
    required this.availablePpe,
    required this.periodicControls,
    required this.availableEvidence,
    required this.oralMeasures,
    required this.measuresToVerify,
    required this.workAtHeight,
    required this.dangerousMachines,
    required this.chemicalProducts,
    required this.manualHandling,
    required this.vehiclePedestrianTraffic,
    required this.noise,
    required this.fireRisk,
    required this.loneWork,
    required this.coactivity,
    required this.weatherConstraints,
    required this.newWorkers,
    required this.temporaryWorkers,
    required this.youngWorkers,
    required this.pregnantOrBreastfeedingWorkers,
    required this.medicalRestrictionsWorkers,
    required this.isolatedWorkers,
    required this.subcontractors,
    required this.cpptPresence,
    required this.preventionService,
    required this.feedAnnualActionPlan,
    required this.feedGlobalPreventionPlan,
    required this.presentToCppt,
    required this.externalServiceValidation,
    required this.occupationalDoctorAdvice,
    this.extraFields = const {},
  });

  static const unknownValue = 'Non renseigné / à vérifier';

  final String documentType;
  final String companyName;
  final String siteConcerned;
  final String serviceConcerned;
  final String author;
  final String version;
  final String visitDate;
  final String documentObjective;
  final String includedLocations;
  final String excludedLocations;
  final String concernedPositions;
  final String concernedTasks;
  final String includedSituations;
  final String exposureDuration;
  final String workMode;
  final String fieldVisitDone;
  final String jobObservationDone;
  final String workersConsulted;
  final String managementConsulted;
  final String cpptConsulted;
  final String incidentRegisterAvailable;
  final String photosAvailable;
  final String controlReportsAvailable;
  final String technicalSheetsAvailable;
  final String safetyDataSheetsAvailable;
  final String sector;
  final String workerCount;
  final String activity;
  final String equipment;
  final String dangerousProducts;
  final String exposedWorkers;
  final String knownIncidents;
  final String constraints;
  final String additionalInformation;
  final String writtenInstructions;
  final String completedTrainings;
  final String availablePpe;
  final String periodicControls;
  final String availableEvidence;
  final String oralMeasures;
  final String measuresToVerify;
  final String workAtHeight;
  final String dangerousMachines;
  final String chemicalProducts;
  final String manualHandling;
  final String vehiclePedestrianTraffic;
  final String noise;
  final String fireRisk;
  final String loneWork;
  final String coactivity;
  final String weatherConstraints;
  final String newWorkers;
  final String temporaryWorkers;
  final String youngWorkers;
  final String pregnantOrBreastfeedingWorkers;
  final String medicalRestrictionsWorkers;
  final String isolatedWorkers;
  final String subcontractors;
  final String cpptPresence;
  final String preventionService;
  final String feedAnnualActionPlan;
  final String feedGlobalPreventionPlan;
  final String presentToCppt;
  final String externalServiceValidation;
  final String occupationalDoctorAdvice;
  final Map<String, String> extraFields;

  String get workplace => siteConcerned;

  String get existingMeasures {
    return [
      'Instructions écrites existantes : $writtenInstructions',
      'Formations déjà réalisées : $completedTrainings',
      'EPI disponibles : $availablePpe',
      'Contrôles périodiques réalisés : $periodicControls',
      'Preuves disponibles : $availableEvidence',
      'Mesures seulement orales ou non documentées : $oralMeasures',
      'Mesures à vérifier sur terrain : $measuresToVerify',
    ].join('\n');
  }

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType,
      'companyName': companyName,
      'siteConcerned': siteConcerned,
      'serviceConcerned': serviceConcerned,
      'author': author,
      'version': version,
      'visitDate': visitDate,
      'documentObjective': documentObjective,
      'includedLocations': includedLocations,
      'excludedLocations': excludedLocations,
      'concernedPositions': concernedPositions,
      'concernedTasks': concernedTasks,
      'includedSituations': includedSituations,
      'exposureDuration': exposureDuration,
      'workMode': workMode,
      'fieldVisitDone': fieldVisitDone,
      'jobObservationDone': jobObservationDone,
      'workersConsulted': workersConsulted,
      'managementConsulted': managementConsulted,
      'cpptConsulted': cpptConsulted,
      'incidentRegisterAvailable': incidentRegisterAvailable,
      'photosAvailable': photosAvailable,
      'controlReportsAvailable': controlReportsAvailable,
      'technicalSheetsAvailable': technicalSheetsAvailable,
      'safetyDataSheetsAvailable': safetyDataSheetsAvailable,
      'sector': sector,
      'workerCount': workerCount,
      'activity': activity,
      'equipment': equipment,
      'dangerousProducts': dangerousProducts,
      'exposedWorkers': exposedWorkers,
      'knownIncidents': knownIncidents,
      'constraints': constraints,
      'additionalInformation': additionalInformation,
      'writtenInstructions': writtenInstructions,
      'completedTrainings': completedTrainings,
      'availablePpe': availablePpe,
      'periodicControls': periodicControls,
      'availableEvidence': availableEvidence,
      'oralMeasures': oralMeasures,
      'measuresToVerify': measuresToVerify,
      'workAtHeight': workAtHeight,
      'dangerousMachines': dangerousMachines,
      'chemicalProducts': chemicalProducts,
      'manualHandling': manualHandling,
      'vehiclePedestrianTraffic': vehiclePedestrianTraffic,
      'noise': noise,
      'fireRisk': fireRisk,
      'loneWork': loneWork,
      'coactivity': coactivity,
      'weatherConstraints': weatherConstraints,
      'newWorkers': newWorkers,
      'temporaryWorkers': temporaryWorkers,
      'youngWorkers': youngWorkers,
      'pregnantOrBreastfeedingWorkers': pregnantOrBreastfeedingWorkers,
      'medicalRestrictionsWorkers': medicalRestrictionsWorkers,
      'isolatedWorkers': isolatedWorkers,
      'subcontractors': subcontractors,
      'cpptPresence': cpptPresence,
      'preventionService': preventionService,
      'feedAnnualActionPlan': feedAnnualActionPlan,
      'feedGlobalPreventionPlan': feedGlobalPreventionPlan,
      'presentToCppt': presentToCppt,
      'externalServiceValidation': externalServiceValidation,
      'occupationalDoctorAdvice': occupationalDoctorAdvice,
      'extraFields': extraFields,
      ...extraFields,
    };
  }
}
