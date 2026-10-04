import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/localized_strings.dart';
import '../models/document_form_data.dart';
import '../models/generation_source.dart';
import '../services/ai_document_service.dart';
import '../services/app_config_service.dart';
import '../services/document_generator.dart';
import '../services/license_service.dart';
import '../widgets/adaptive_page.dart';
import 'home_screen.dart';
import 'result_screen.dart';

const piuDocumentType = 'Plan Interne d’Urgence';
const _missingValue = '[à compléter]';

const piuDefaultScenarios = <String>{
  'Incendie',
  'Accident corporel ou malaise',
  'Coupure de courant / délestage',
  'Intrusion dangereuse / AMOK',
  'Mise à l’abri / SEVESO / incident extérieur',
};

const piuScenarios = <String>[
  'Incendie',
  'Mise à l’abri / SEVESO / incident extérieur',
  'Alerte à la bombe / colis suspect',
  'Menace biologique ou chimique',
  'Déversement de substances dangereuses',
  'Inondation',
  'Tempête / orage',
  'Fuite de gaz',
  'Accident corporel ou malaise',
  'Pandémie / épidémie',
  'Coupure de courant / délestage',
  'Intrusion dangereuse / AMOK',
  'Agression',
];

const piuAvailablePlans = <String>[
  'Plan d’évacuation disponible',
  'Plan des accès secours disponible',
  'Plan des impétrants / énergies disponible',
  'Plan des moyens incendie disponible',
  'Plan des risques spécifiques disponible',
  'Registre visiteurs disponible',
  'Liste secouristes disponible',
  'Liste guides-files / serre-files disponible',
  'Dossier intervention pompiers disponible',
];

class PiuFormScreen extends StatefulWidget {
  const PiuFormScreen({super.key, this.onGenerate});

  final Future<void> Function(DocumentFormData data)? onGenerate;

  @override
  State<PiuFormScreen> createState() => _PiuFormScreenState();
}

class _PiuFormScreenState extends State<PiuFormScreen> {
  static const _stepCount = 8;
  static const _textKeys = <String>[
    'companyName',
    'siteName',
    'buildingName',
    'address',
    'postalCode',
    'city',
    'country',
    'activityType',
    'numberOfWorkers',
    'openingHours',
    'visitors',
    'externalCompanies',
    'nightWork',
    'cleaningHours',
    'securityGuarding',
    'personsNeedingAssistance',
    'siteDirection',
    'emergencyManager',
    'deputyEmergencyManager',
    'preventionAdvisor',
    'receptionContact',
    'technicalServiceContact',
    'securityContact',
    'firstAiders',
    'evacuationGuides',
    'fireAlarmSystem',
    'assemblyPoint',
    'mainExits',
    'pmrProcedure',
    'safeWaitingArea',
    'censusMethod',
    'emergencyServicesReceptionPoint',
    'firefighterFileLocation',
    'fireDetectionPanelLocation',
    'manualCallPoints',
    'extinguishers',
    'hydrants',
    'smokeExtraction',
    'gasShutoff',
    'electricityShutoff',
    'waterShutoff',
    'ventilationShutoff',
    'highVoltageCabin',
    'specificRisks',
    'validationDirection',
    'validationPreventionAdvisor',
    'cpptConsultation',
    'emergencyServicesConsultation',
    'municipalInformation',
    'openPoints',
  ];

  late final Map<String, TextEditingController> _controllers;
  final _scenarios = {...piuDefaultScenarios};
  final _plans = <String>{};
  int _currentStep = 0;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _controllers = {for (final key in _textKeys) key: TextEditingController()};
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _controllers[key]!.text.trim();

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      _goToHome();
    }
  }

  void _changeStep(int offset) {
    if (_isGenerating) return;
    final nextStep = _currentStep + offset;
    if (nextStep < 0 || nextStep >= _stepCount) return;
    setState(() => _currentStep = nextStep);
  }

  DocumentFormData buildFormData() {
    return buildPiuFormData(
      textValues: {for (final key in _textKeys) key: _text(key)},
      choiceValues: const {},
      emergencyScenarios: _scenarios,
      availablePlans: _plans,
      localeName: AppLocalizations.of(context).localeName,
    );
  }

  Future<void> _generate() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    final data = buildFormData();

    try {
      if (widget.onGenerate != null) {
        await widget.onGenerate!(data);
        return;
      }

      final l10n = AppLocalizations.of(context);
      final settings = await AppConfigService().loadAiSettings();
      if (!mounted) return;

      if (!settings.useAiIfAvailable &&
          !settings.disableLocalFallbackForAiTests) {
        _openLocalResult(data);
        return;
      }
      if (!settings.hasBackendUrl) {
        if (settings.disableLocalFallbackForAiTests) {
          throw AiDocumentException(l10n.noBackendConfigured);
        }
        _openLocalResult(data);
        return;
      }

      final licenseService = LicenseService(backendUrl: settings.backendUrl);
      await licenseService.validateGeneration(piuDocumentType);
      final result = await AiDocumentService(licenseService: licenseService)
          .generateDocument(
            backendUrl: settings.backendUrl,
            data: data,
            languageCode: l10n.localeName,
            languageLabel: l10n.languageLabel,
          );
      if (!mounted) return;
      _openResult(result.content, result.source, result.linkedDocuments);
    } on LicenseException catch (error) {
      if (mounted) _showError(error.message);
    } on AiDocumentException catch (error) {
      if (mounted) _showError(error.message);
    } on Object catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openLocalResult(DocumentFormData data) {
    _openResult(
      DocumentGenerator().generate(data),
      GenerationSource.localFallback,
      const [],
    );
  }

  void _openResult(
    String content,
    GenerationSource source,
    List<AiLinkedDocument> linkedDocuments,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          documentType: piuDocumentType,
          content: content,
          companyName: _text('companyName'),
          siteName: _text('siteName').isNotEmpty
              ? _text('siteName')
              : _text('buildingName'),
          formData: buildFormData().toJson(),
          generationSource: source,
          linkedDocuments: linkedDocuments,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Plan Interne d’Urgence — PIU'),
        actions: [
          IconButton(
            tooltip: 'Accueil',
            onPressed: _goToHome,
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: AdaptivePage(
        maxTabletWidth: 760,
        maxDesktopWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PiuNotice(),
            const SizedBox(height: 12),
            Text(
              'Étape ${_currentStep + 1} / $_stepCount',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey('piu_step_$_currentStep'),
                child: _buildCurrentStep(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: _isGenerating ? null : () => _changeStep(-1),
                    child: const Text('Précédent'),
                  ),
                if (_currentStep < _stepCount - 1)
                  FilledButton(
                    onPressed: _isGenerating ? null : () => _changeStep(1),
                    child: const Text('Suivant'),
                  )
                else
                  FilledButton.icon(
                    key: const ValueKey('piu_generate'),
                    onPressed: _isGenerating ? null : _generate,
                    icon: _isGenerating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: const Text('Générer le PIU'),
                  ),
              ],
            ),
            TextButton.icon(
              onPressed: _goToHome,
              icon: const Icon(Icons.close),
              label: const Text('Annuler et revenir à l’accueil'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    final (title, fields) = switch (_currentStep) {
      0 => (
        'Identification du site',
        <Widget>[
          _field('companyName', 'Nom de l’entreprise'),
          _field('siteName', 'Nom du site / bâtiment'),
          _field('address', 'Adresse'),
          _field('postalCode', 'Code postal'),
          _field('city', 'Ville'),
          _field('country', 'Pays'),
          _field('activityType', 'Type d’activité'),
          _field('numberOfWorkers', 'Nombre de travailleurs'),
        ],
      ),
      1 => (
        'Occupation et horaires',
        <Widget>[
          _field('openingHours', 'Horaires d’ouverture'),
          _field('visitors', 'Présence de visiteurs'),
          _field('externalCompanies', 'Entreprises extérieures'),
          _field('nightWork', 'Travail de nuit'),
          _field('cleaningHours', 'Nettoyage hors heures'),
          _field('securityGuarding', 'Gardiennage'),
          _field(
            'personsNeedingAssistance',
            'Personnes nécessitant une assistance',
          ),
        ],
      ),
      2 => (
        'Personnes ressources',
        <Widget>[
          _field('siteDirection', 'Direction du site'),
          _field('preventionAdvisor', 'Conseiller en prévention'),
          _field('emergencyManager', 'Responsable évacuation'),
          _field('deputyEmergencyManager', 'Suppléant responsable évacuation'),
          _field('receptionContact', 'Accueil / réception'),
          _field('technicalServiceContact', 'Service technique'),
          _field('securityContact', 'Gardiennage'),
          _field('firstAiders', 'Secouristes'),
          _field('evacuationGuides', 'Guides-files / serre-files'),
        ],
      ),
      3 => (
        'Évacuation',
        <Widget>[
          _field('fireAlarmSystem', 'Signal d’alarme incendie'),
          _field('assemblyPoint', 'Point de rassemblement'),
          _field('mainExits', 'Issues principales'),
          _field('pmrProcedure', 'Procédure PMR', lines: 2),
          _field('safeWaitingArea', 'Zone d’attente sécurisée'),
          _field('censusMethod', 'Méthode de recensement'),
          _field(
            'emergencyServicesReceptionPoint',
            'Point d’accueil des secours',
          ),
          _field('firefighterFileLocation', 'Localisation du dossier pompiers'),
        ],
      ),
      4 => (
        'Moyens techniques',
        <Widget>[
          _field(
            'fireDetectionPanelLocation',
            'Centrale incendie / localisation',
          ),
          _field('manualCallPoints', 'Déclencheurs manuels'),
          _field('extinguishers', 'Extincteurs'),
          _field('hydrants', 'Dévidoirs / RIA'),
          _field('smokeExtraction', 'Désenfumage / EFC'),
          _field('gasShutoff', 'Coupure gaz'),
          _field('electricityShutoff', 'Coupure électricité'),
          _field('waterShutoff', 'Coupure eau'),
          _field('ventilationShutoff', 'Coupure ventilation'),
          _field('highVoltageCabin', 'Cabine HT'),
          _field('specificRisks', 'Risques spécifiques connus', lines: 3),
        ],
      ),
      5 => (
        'Scénarios',
        <Widget>[
          for (final scenario in piuScenarios)
            _checkbox(label: scenario, selected: _scenarios),
        ],
      ),
      6 => (
        'Plans et annexes',
        <Widget>[
          for (final plan in piuAvailablePlans)
            _checkbox(label: plan, selected: _plans),
        ],
      ),
      _ => (
        'Validation',
        <Widget>[
          _field('validationDirection', 'Direction à valider'),
          _field(
            'validationPreventionAdvisor',
            'Conseiller en prévention à valider',
          ),
          _field('cpptConsultation', 'CPPT à consulter'),
          _field(
            'emergencyServicesConsultation',
            'Service de secours à consulter',
          ),
          _field('municipalInformation', 'Administration communale à informer'),
          _field('openPoints', 'Commentaires / points ouverts', lines: 4),
        ],
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...fields,
      ],
    );
  }

  Widget _field(String key, String label, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: ValueKey('piu_$key'),
        controller: _controllers[key],
        enabled: !_isGenerating,
        maxLines: lines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _checkbox({required String label, required Set<String> selected}) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: selected.contains(label),
      title: Text(label),
      onChanged: _isGenerating
          ? null
          : (checked) {
              setState(() {
                if (checked == true) {
                  selected.add(label);
                } else {
                  selected.remove(label);
                }
              });
            },
    );
  }
}

class _PiuNotice extends StatelessWidget {
  const _PiuNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le PIU généré est une aide opérationnelle. Il doit être '
              'complété, vérifié sur site, adapté aux moyens réels et validé '
              'avant diffusion.',
            ),
            SizedBox(height: 6),
            Text(
              'Répondez court. Les champs vides seront repris comme '
              '[à compléter].',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

DocumentFormData buildPiuFormData({
  required Map<String, String> textValues,
  required Map<String, String> choiceValues,
  required Set<String> emergencyScenarios,
  required Set<String> availablePlans,
  String localeName = 'fr',
}) {
  String value(String key) {
    final rawValue = textValues[key]?.trim();
    final rawChoice = choiceValues[key]?.trim();
    if (rawValue != null && rawValue.isNotEmpty) return rawValue;
    if (rawChoice != null && rawChoice.isNotEmpty) return rawChoice;
    return _missingValue;
  }

  final extraFields = <String, dynamic>{
    '_isPreventionDocument': 'true',
    '_localeName': localeName,
    for (final key in _PiuFormScreenState._textKeys) key: value(key),
    'emergencyScenarios': emergencyScenarios.toList()..sort(),
    'availablePlans': availablePlans.toList()..sort(),
  };

  return DocumentFormData(
    documentType: piuDocumentType,
    companyName: value('companyName'),
    siteConcerned: value('siteName'),
    serviceConcerned: _missingValue,
    author: _missingValue,
    version: _missingValue,
    visitDate: _missingValue,
    documentObjective: 'Projet de Plan Interne d’Urgence à valider',
    includedLocations: _missingValue,
    excludedLocations: _missingValue,
    concernedPositions: _missingValue,
    concernedTasks: _missingValue,
    includedSituations: _missingValue,
    exposureDuration: _missingValue,
    workMode: _missingValue,
    fieldVisitDone: 'À vérifier sur site',
    jobObservationDone: _missingValue,
    workersConsulted: _missingValue,
    managementConsulted: value('validationDirection'),
    cpptConsulted: value('cpptConsultation'),
    incidentRegisterAvailable: _missingValue,
    photosAvailable: _missingValue,
    controlReportsAvailable: _missingValue,
    technicalSheetsAvailable: _missingValue,
    safetyDataSheetsAvailable: _missingValue,
    sector: value('activityType'),
    workerCount: value('numberOfWorkers'),
    activity: value('activityType'),
    equipment: _missingValue,
    dangerousProducts: _missingValue,
    exposedWorkers: value('personsNeedingAssistance'),
    knownIncidents: _missingValue,
    constraints: value('specificRisks'),
    additionalInformation: value('openPoints'),
    writtenInstructions: _missingValue,
    completedTrainings: _missingValue,
    availablePpe: _missingValue,
    periodicControls: _missingValue,
    availableEvidence: _missingValue,
    oralMeasures: _missingValue,
    measuresToVerify: _missingValue,
    workAtHeight: _missingValue,
    dangerousMachines: _missingValue,
    chemicalProducts: _missingValue,
    manualHandling: _missingValue,
    vehiclePedestrianTraffic: _missingValue,
    noise: _missingValue,
    fireRisk: 'Oui',
    loneWork: value('nightWork'),
    coactivity: value('externalCompanies'),
    weatherConstraints: _missingValue,
    newWorkers: _missingValue,
    temporaryWorkers: _missingValue,
    youngWorkers: _missingValue,
    pregnantOrBreastfeedingWorkers: _missingValue,
    medicalRestrictionsWorkers: _missingValue,
    isolatedWorkers: value('nightWork'),
    subcontractors: value('externalCompanies'),
    cpptPresence: value('cpptConsultation'),
    preventionService: value('preventionAdvisor'),
    feedAnnualActionPlan: _missingValue,
    feedGlobalPreventionPlan: _missingValue,
    presentToCppt: value('cpptConsultation'),
    externalServiceValidation: value('emergencyServicesConsultation'),
    occupationalDoctorAdvice: _missingValue,
    extraFields: extraFields,
  );
}
