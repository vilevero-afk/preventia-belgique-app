// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PreventIA Belgium';

  @override
  String get homeSubtitle => 'Prevention and wellbeing at work assistant';

  @override
  String get newDocument => 'New document';

  @override
  String get generalRiskAnalysis => 'General risk assessment';

  @override
  String get history => 'History';

  @override
  String get limitsAndMentions => 'Notices and limits';

  @override
  String get aiSettings => 'AI settings';

  @override
  String get completeFormIntro =>
      'Complete the information you know. Empty fields will be sent as \"Not provided / to be checked\".';

  @override
  String get fillCompleteExample => 'Fill with a complete example';

  @override
  String get clearForm => 'Clear form';

  @override
  String get generateDocument => 'Generate draft document';

  @override
  String get aiGenerationInProgress =>
      'AI generation in progress. A complete analysis can take up to 2 to 3 minutes.';

  @override
  String get aiGenerated => 'Document generated through the secure AI backend';

  @override
  String get localGenerated => 'Document generated locally';

  @override
  String get projectDocument => 'Draft document';

  @override
  String get copy => 'Copy';

  @override
  String get copyDocument => 'Copy document';

  @override
  String get saveLocally => 'Save locally';

  @override
  String get exportPdf => 'Export as PDF';

  @override
  String get viewActions => 'View actions to perform';

  @override
  String get actionsToDo => 'Actions to perform';

  @override
  String get actionSummary => 'Action summary';

  @override
  String get saveSummary => 'Save this summary';

  @override
  String get exportSummaryPdf => 'Export the summary as PDF';

  @override
  String get analysisFolder => 'Risk assessment folder';

  @override
  String get completeAnalysis => 'Complete analysis';

  @override
  String get fullRiskAnalysis => 'Complete risk assessment';

  @override
  String get advancedBackendSettings => 'Advanced backend settings';

  @override
  String get aiBackendUrl => 'Secure backend URL';

  @override
  String get resetDefaultBackendUrl => 'Reset default backend URL';

  @override
  String get testBackendConnection => 'Test backend';

  @override
  String get backendAvailable => 'Backend Render available';

  @override
  String get backendUnavailable => 'Backend Render unavailable';

  @override
  String get productionBackendInfo =>
      'The application uses the secure production backend. Documents remain stored locally on the device, except during AI generation when the necessary data is sent to the backend.';

  @override
  String get language => 'Language';

  @override
  String get appLanguage => 'Application language';

  @override
  String get french => 'Français';

  @override
  String get dutch => 'Nederlands';

  @override
  String get english => 'English';

  @override
  String get german => 'Deutsch';

  @override
  String get applicationLanguage => 'Application language';

  @override
  String get projectToValidate => 'Draft to validate';

  @override
  String get documentSaved => 'Document saved';

  @override
  String get error => 'Error';

  @override
  String get cancel => 'Cancel';

  @override
  String get validate => 'Validate';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get open => 'Open';

  @override
  String get edit => 'Edit';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get copiedDocumentMessage => 'Draft copied to the clipboard.';

  @override
  String get copiedSummaryMessage => 'Summary copied.';

  @override
  String get savedAnalysisFolderMessage =>
      'Risk assessment folder saved locally.';

  @override
  String get savedSummaryMessage => 'Summary saved locally.';

  @override
  String get savedSettingsMessage => 'AI settings saved locally.';

  @override
  String get languageChanged => 'Application language updated.';

  @override
  String get languageChangedMessage => 'Application language updated.';

  @override
  String get languageScopeInfo =>
      'The selected language applies to the interface and to newly generated documents. Already saved documents keep their existing content.';

  @override
  String get localStorageDeviceInfo =>
      'The application is designed for mobile, tablet and desktop. Documents remain stored locally on the device.';

  @override
  String get aiBackendSecurityInfo =>
      'The API key must never be stored in the mobile app. AI generation must go through a secure backend validated by the organization.';

  @override
  String get privacyInfo =>
      'Entered data may contain sensitive information. Anonymize personal names, private addresses and medical information. The organization must validate its own data processing framework.';

  @override
  String get httpDevWarning =>
      'Local development mode: HTTP is allowed only for private network tests. Use HTTPS in production.';

  @override
  String get useAiIfAvailable => 'Use AI generation if available';

  @override
  String get disableLocalFallbackForAiTests =>
      'Disable local fallback generation for tests';

  @override
  String get renderBackendSource => 'AI backend Render';

  @override
  String get localGenerationSource => 'Local generation';

  @override
  String get backendErrorSource => 'Backend error';

  @override
  String get renderBackendPdfSource =>
      'AI backend Render - PDF generated locally on the device';

  @override
  String get localGenerationPdfSource =>
      'Local generation - PDF generated locally on the device';

  @override
  String get aiUnavailableTitle => 'AI generation unavailable';

  @override
  String aiUnavailableFallback(String message) {
    return '$message\n\nYou can fall back to local generation. The data will then not be sent to the backend.';
  }

  @override
  String get useLocalGeneration => 'Use local generation';

  @override
  String get noBackendConfigured =>
      'No AI backend configured. Local generation used.';

  @override
  String get documentModifiedLocally => 'Document modified locally';

  @override
  String get pdfFromSavedContent =>
      'The PDF is generated from the currently saved content.';

  @override
  String get summaryStoredLocallyInfo =>
      'This summary is stored locally and linked to its source analysis if it still exists on the device.';

  @override
  String get openLinkedSummary => 'View linked summary';

  @override
  String get createSummary => 'Create summary';

  @override
  String get viewLinkedAnalysis => 'View linked analysis';

  @override
  String get linkedAnalysisNotFound => 'Linked analysis not found locally.';

  @override
  String get changesSavedLocally => 'Changes saved locally.';

  @override
  String get noHistory => 'No project saved locally yet.';

  @override
  String get analysisFolderSubtitle =>
      'Risk assessment folder\n2 documents: complete analysis + action summary';

  @override
  String get riskAnalysisAndSummaryFolderInfo =>
      'This folder groups the risk assessment and its operational action summary.';

  @override
  String analysisNumber(String number) {
    return 'Number: $number';
  }

  @override
  String linkedAnalysis(String title) {
    return 'Linked analysis: $title';
  }

  @override
  String creationDate(String date) {
    return 'Creation date: $date';
  }

  @override
  String status(String status) {
    return 'Status: $status';
  }

  @override
  String get exportFolder => 'Export folder';

  @override
  String get exportSeparateSummaryHint =>
      'Then export the summary PDF with the dedicated button.';

  @override
  String get exportSeparateDocumentsFallback => 'Export both PDFs separately.';

  @override
  String get summaryObjectiveTitle => 'Purpose of the summary';

  @override
  String get summaryObjectiveText =>
      'Turn the risk assessment into concrete follow-up tasks for the prevention adviser, without changing the source analysis document.';

  @override
  String get priorityActions => 'Priority actions';

  @override
  String get documentsToPrepare => 'Documents to prepare or update';

  @override
  String get actorsToConsult => 'People to consult';

  @override
  String get fieldChecks => 'Information to check in the field';

  @override
  String get expectedProofs => 'Expected evidence';

  @override
  String get usefulExplanations =>
      'Useful explanations for the prevention adviser';

  @override
  String get validationNoticeTitle => 'Validation notice';

  @override
  String get summaryIntro =>
      'This summary helps the prevention adviser turn the analysis into concrete tasks. It does not replace validation of the document by the competent stakeholders.';

  @override
  String get expectedProofExplanation =>
      'Expected evidence is the concrete element used to show that an action was completed: report, photo, register, attendance list, signed procedure or CPPT minutes.';

  @override
  String get advisorMustCheck =>
      'The prevention adviser must check that each action is realistic, assigned to an owner, planned within a coherent deadline and followed by concrete evidence.';

  @override
  String get missingInformationHelp =>
      'If the information is not available, you can leave the field empty or indicate that it must be checked in the field.';

  @override
  String get actionToPerform => 'Action to perform';

  @override
  String get riskConcerned => 'Risk concerned';

  @override
  String get responsible => 'Responsible';

  @override
  String get deadline => 'Deadline';

  @override
  String get expectedProof => 'Expected evidence';

  @override
  String get whyImportant => 'Why it matters';

  @override
  String get advisorExpected => 'What is expected from the prevention adviser';

  @override
  String get advisorExpectedShort => 'Expected from the prevention adviser';

  @override
  String get document => 'Document';

  @override
  String get objective => 'Objective';

  @override
  String get expectedResult => 'Expected result';

  @override
  String get actor => 'Person';

  @override
  String get whyConsult => 'Why consult them';

  @override
  String get expectedTrace => 'Expected trace';

  @override
  String get explanation => 'Explanation';

  @override
  String get itemToVerify => 'Item to check';

  @override
  String get howToVerify => 'How to check';

  @override
  String get possibleProof => 'Possible evidence';

  @override
  String get proof => 'Evidence';

  @override
  String get whatItIsFor => 'What it is used for';

  @override
  String get concreteExample => 'Concrete example';

  @override
  String get noPriorityActions =>
      'No structured action was detected. Read the full document or generate the analysis again.';

  @override
  String get noDocumentsDetected =>
      'No document to prepare or update could be extracted automatically.';

  @override
  String get noActorsDetected =>
      'No person to consult could be extracted automatically.';

  @override
  String get noFieldChecks =>
      'No mention to check, not provided, to confirm, to complete, field visit or field observation was found.';

  @override
  String get noProofsDetected =>
      'No expected evidence was detected automatically.';

  @override
  String get documentsNecessityExplanation =>
      'These documents show that prevention measures are organized, known and traceable.';

  @override
  String get consultationExplanation =>
      'Consultation validates field reality, involves workers and documents decisions.';

  @override
  String get unverifiedInfoImportance =>
      'Unverified information must not be considered established.';

  @override
  String get verifyBy =>
      'Confirm by observation, interview, document or inspection.';

  @override
  String get proofExamples => 'Photo, report, visit note, register or minutes.';

  @override
  String get proofPurpose =>
      'Show concretely that an action has been completed or followed up.';

  @override
  String get proofConcreteExamples =>
      'Report, photo, register, attendance list, signed procedure or CPPT minutes.';

  @override
  String get localValidationNotice =>
      'This summary is a support tool for action follow-up. It must be checked, adapted and validated with the competent stakeholders before being used as follow-up evidence.';

  @override
  String get source => 'Source';

  @override
  String get generatedAt => 'Generation date';

  @override
  String get generatedLocallyFromAnalysis =>
      'Generated locally from the risk assessment';

  @override
  String get help => 'Help';

  @override
  String get example => 'Example';

  @override
  String get formSectionIdentification => 'A. Document identification';

  @override
  String get formSectionScope => 'B. Scope of the analysis';

  @override
  String get formSectionSources => 'C. Information sources';

  @override
  String get formSectionActivity => 'D. Activity, equipment and products';

  @override
  String get formSectionMeasures => 'E. Existing measures and evidence';

  @override
  String get formSectionRisks => 'F. Specific risks';

  @override
  String get formSectionWorkers => 'G. Specific workers';

  @override
  String get formSectionPrevention => 'H. Prevention objective';

  @override
  String get field_companyName => 'Company name';

  @override
  String get field_siteConcerned => 'Site concerned';

  @override
  String get field_serviceConcerned => 'Service concerned';

  @override
  String get field_author => 'Author';

  @override
  String get field_version => 'Version';

  @override
  String get field_visitDate => 'Visit or observation date';

  @override
  String get field_documentObjective =>
      'Document objective: CPPT, audit, annual plan, global plan, accident, field visit, other';

  @override
  String get field_includedLocations => 'Included locations';

  @override
  String get field_excludedLocations => 'Excluded locations';

  @override
  String get field_concernedPositions => 'Positions concerned';

  @override
  String get field_concernedTasks => 'Tasks concerned';

  @override
  String get field_includedSituations =>
      'Included situations: routine, emergency, coactivity, subcontracting, lone work';

  @override
  String get field_exposureDuration => 'Daily or weekly exposure duration';

  @override
  String get field_workMode => 'On-site, remote or hybrid work';

  @override
  String get field_fieldVisitDone =>
      'Field visit performed: yes/no/to be checked';

  @override
  String get field_jobObservationDone =>
      'Job observation performed: yes/no/to be checked';

  @override
  String get field_workersConsulted =>
      'Workers consulted: yes/no/to be checked';

  @override
  String get field_managementConsulted =>
      'Management consulted: yes/no/to be checked';

  @override
  String get field_cpptConsulted =>
      'CPPT consulted: yes/no/not applicable/to be checked';

  @override
  String get field_incidentRegisterAvailable =>
      'Accident/incident register available: yes/no/to be checked';

  @override
  String get field_photosAvailable => 'Photos available: yes/no/to be checked';

  @override
  String get field_controlReportsAvailable =>
      'Inspection reports available: yes/no/to be checked';

  @override
  String get field_technicalSheetsAvailable =>
      'Technical sheets available: yes/no/to be checked';

  @override
  String get field_safetyDataSheetsAvailable =>
      'Safety data sheets available: yes/no/to be checked';

  @override
  String get field_sector => 'Business sector';

  @override
  String get field_workerCount => 'Number of workers';

  @override
  String get field_activity => 'Activity or job analyzed';

  @override
  String get field_equipment => 'Machines or equipment used';

  @override
  String get field_dangerousProducts => 'Dangerous products used';

  @override
  String get field_exposedWorkers => 'Exposed workers';

  @override
  String get field_knownIncidents => 'Known accidents or incidents';

  @override
  String get field_constraints => 'Specific constraints';

  @override
  String get field_additionalInformation => 'Additional information';

  @override
  String get field_writtenInstructions => 'Existing written instructions';

  @override
  String get field_completedTrainings => 'Completed training';

  @override
  String get field_availablePpe => 'Available PPE';

  @override
  String get field_periodicControls => 'Periodic inspections performed';

  @override
  String get field_availableEvidence => 'Available evidence';

  @override
  String get field_oralMeasures => 'Only oral or undocumented measures';

  @override
  String get field_measuresToVerify => 'Measures to check in the field';

  @override
  String get field_workAtHeight => 'Work at height: yes/no/to be checked';

  @override
  String get field_dangerousMachines =>
      'Dangerous machines or tools: yes/no/to be checked';

  @override
  String get field_chemicalProducts =>
      'Chemical products: yes/no/to be checked';

  @override
  String get field_manualHandling => 'Manual handling: yes/no/to be checked';

  @override
  String get field_vehiclePedestrianTraffic =>
      'Vehicle/pedestrian traffic: yes/no/to be checked';

  @override
  String get field_noise => 'Noise: yes/no/to be checked';

  @override
  String get field_fireRisk => 'Fire: yes/no/to be checked';

  @override
  String get field_loneWork => 'Lone work: yes/no/to be checked';

  @override
  String get field_coactivity =>
      'Coactivity with public/subcontractors: yes/no/to be checked';

  @override
  String get field_weatherConstraints =>
      'Weather constraints: yes/no/to be checked';

  @override
  String get field_newWorkers => 'New workers';

  @override
  String get field_temporaryWorkers => 'Temporary workers';

  @override
  String get field_youngWorkers => 'Young workers';

  @override
  String get field_pregnantOrBreastfeedingWorkers =>
      'Pregnant or breastfeeding workers';

  @override
  String get field_medicalRestrictionsWorkers =>
      'Workers with medical restrictions';

  @override
  String get field_isolatedWorkers => 'Isolated workers';

  @override
  String get field_subcontractors => 'Subcontractors';

  @override
  String get field_cpptPresence => 'Presence of a CPPT';

  @override
  String get field_preventionService => 'Internal or external service';

  @override
  String get field_feedAnnualActionPlan =>
      'Should the document feed the Annual Action Plan?';

  @override
  String get field_feedGlobalPreventionPlan =>
      'Should the document feed the Global Prevention Plan?';

  @override
  String get field_presentToCppt =>
      'Should the document be presented to the CPPT?';

  @override
  String get field_externalServiceValidation =>
      'Is external service validation planned?';

  @override
  String get field_occupationalDoctorAdvice =>
      'Is occupational physician advice needed?';

  @override
  String get helpDescription =>
      'Enter the useful information for this field to frame the analysis correctly.';

  @override
  String get helpExample =>
      'Example to adapt to the real situation of the company or service concerned.';
}
