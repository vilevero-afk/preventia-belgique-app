import 'package:flutter/widgets.dart';

/// Applies only values for fields that exist in [controllers].
///
/// Exact key matches take precedence. Aliases let presets remain independent
/// from the naming conventions used by individual questionnaires.
void fillRiskAssessmentControllers({
  required Map<String, TextEditingController> controllers,
  required Map<String, dynamic> preset,
}) {
  for (final entry in controllers.entries) {
    if (_referenceFields.contains(entry.key)) {
      continue;
    }
    final value = _valueForField(entry.key, preset);
    if (value != null && value.trim().isNotEmpty) {
      entry.value.text = value;
    }
  }
}

String? _valueForField(String fieldKey, Map<String, dynamic> preset) {
  final candidates = <String>[fieldKey, ...?_presetKeysByFormField[fieldKey]];
  for (final key in candidates) {
    final value = preset[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

const _referenceFields = {
  'documentReference',
  'reference',
  'analysisNumber',
  'projectNumber',
  'internalReference',
};

const Map<String, List<String>> _presetKeysByFormField = {
  'companyName': ['companyController', 'enterpriseName', 'organisationName'],
  'companyController': ['companyName', 'enterpriseName', 'organisationName'],
  'enterpriseName': ['companyName', 'companyController', 'organisationName'],
  'organisationName': ['companyName', 'companyController', 'enterpriseName'],
  'siteConcerned': ['siteName', 'buildingName', 'workplaceName'],
  'siteName': ['siteConcerned', 'buildingName', 'workplaceName'],
  'buildingName': ['siteName', 'siteConcerned', 'workplaceName'],
  'workplaceName': ['siteName', 'buildingName', 'siteConcerned'],
  'siteAddress': ['address', 'elevatorAddress'],
  'address': ['siteAddress', 'elevatorAddress'],
  'author': ['preventionAdvisor'],
  'workerCount': ['numberOfWorkers'],
  'activity': ['activityType', 'activityDescription'],
  'includedLocations': [
    'workplaceDescription',
    'buildingDescription',
    'concernedAreas',
    'elevatorLocation',
  ],
  'concernedPositions': ['exposedPersons', 'occupants'],
  'concernedTasks': [
    'concernedActivities',
    'handledLoads',
    'productsUsed',
    'workstations',
    'connectedWorkEquipment',
  ],
  'equipment': ['workstations', 'connectedWorkEquipment', 'handledLoads'],
  'dangerousProducts': ['productsUsed'],
  'exposedWorkers': ['exposedPersons', 'occupants', 'vulnerableUsers'],
  'knownIncidents': ['mainRisks', 'fireRisks'],
  'constraints': ['priority', 'deadline'],
  'additionalInformation': ['additionalContext', 'pointsToCheck', 'fireRisks'],
  'comments': ['additionalContext'],
  'context': ['additionalContext'],
  'notes': ['additionalContext'],
  'writtenInstructions': ['existingMeasures'],
  'periodicControls': [
    'periodicInspectionAvailable',
    'lastPeriodicInspectionAvailable',
    'sectReportAvailable',
    'rgieReportAvailable',
  ],
  'availableEvidence': ['evidenceToCollect'],
  'measuresToVerify': ['plannedMeasures', 'pointsToCheck'],
  'preventionService': ['responsible', 'preventionAdvisor'],
  'subcontractors': ['externalCompanies'],
  'coactivity': ['concernedActivities', 'externalCompanies'],
  'fireRisk': ['fireRisks'],
  'chemicalProducts': ['productsUsed'],
  'manualHandling': ['handledLoads'],
  'vehiclePedestrianTraffic': ['mainRisks'],
  'lifecycleStage': ['analysisStage'],
  'lowVoltageCabinetPresent': ['hasLowVoltageCabinet'],
  'highVoltageCabinPresent': ['hasHighVoltageCabin'],
  'transformerPresent': ['hasTransformer'],
  'mainLowVoltageSwitchboardPresent': ['hasMainLowVoltagePanel'],
  'lastPeriodicInspectionAvailable': ['periodicInspectionAvailable'],
  'approvedBodyOpenRemarks': ['openInspectionRemarks'],
  'personCapacity': ['personsCapacity'],
  'lastPeriodicInspectionDate': ['lastPeriodicInspectionAvailable'],
  'modernizationWorkCompleted': ['modernizationWorksDone'],
  'openWork': ['openWorks'],
};
