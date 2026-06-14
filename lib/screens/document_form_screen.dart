import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/localized_strings.dart';
import '../data/document_examples.dart';
import '../models/document_form_data.dart';
import '../models/document_type.dart';
import '../models/generation_source.dart';
import '../models/prevention_document_config.dart';
import '../services/ai_document_service.dart';
import '../services/app_config_service.dart';
import '../services/document_reference_service.dart';
import '../services/document_generator.dart';
import '../widgets/adaptive_page.dart';
import 'result_screen.dart';

class DocumentFormScreen extends StatefulWidget {
  const DocumentFormScreen({required this.documentType, super.key});

  final String documentType;

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  bool _isGenerating = false;
  bool _isGeneratingWithAi = false;
  String? _currentDocumentReference;
  Future<void>? _referenceInitialization;
  late final DocumentType _documentType;
  late final PreventionDocumentConfig? _preventionConfig;

  @override
  void initState() {
    super.initState();
    _documentType = documentTypeByLabel(widget.documentType);
    _preventionConfig = preventionDocumentConfigFor(_documentType);
    for (final field in _currentFields) {
      _controllers[field.key] = TextEditingController();
    }
    _referenceInitialization = _generateAndSetDocumentReference();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generateDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _ensureDocumentReference();
    if (!mounted) {
      return;
    }
    final data = _buildFormData();
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isGenerating = true;
      _isGeneratingWithAi = false;
    });
    final settings = await AppConfigService().loadAiSettings();

    if (!mounted) {
      return;
    }

    if (!settings.useAiIfAvailable &&
        !settings.disableLocalFallbackForAiTests) {
      _openLocalDocument(data, source: GenerationSource.localFallback);
      return;
    }

    if (!settings.hasBackendUrl) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noBackendConfigured)));
      if (settings.disableLocalFallbackForAiTests) {
        setState(() {
          _isGenerating = false;
          _isGeneratingWithAi = false;
        });
        return;
      }
      _openLocalDocument(data, source: GenerationSource.localFallback);
      return;
    }

    try {
      setState(() => _isGeneratingWithAi = true);
      final result = await AiDocumentService().generateDocument(
        backendUrl: settings.backendUrl,
        data: data,
        languageCode: l10n.localeName,
        languageLabel: l10n.languageLabel,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isGenerating = false;
        _isGeneratingWithAi = false;
      });
      _openResult(
        content: _contentWithDocumentReference(result.content),
        generationSource: result.source,
        linkedDocuments: result.linkedDocuments,
      );
    } on AiDocumentException catch (error) {
      if (!mounted) {
        return;
      }
      if (settings.disableLocalFallbackForAiTests) {
        setState(() {
          _isGenerating = false;
          _isGeneratingWithAi = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.backendErrorSource}: ${error.message}'),
          ),
        );
        return;
      }
      final useLocal = await _showAiFallbackDialog(error.message);
      if (!mounted) {
        return;
      }
      if (useLocal) {
        _openLocalDocument(data, source: GenerationSource.localFallback);
      } else {
        setState(() {
          _isGenerating = false;
          _isGeneratingWithAi = false;
        });
      }
    }
  }

  DocumentFormData _buildFormData() {
    String value(String key) {
      final keys = [key, ...(_valueFallbackKeys[key] ?? const <String>[])];
      for (final candidateKey in keys) {
        final text = _controllers[candidateKey]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          return text;
        }
      }
      return DocumentFormData.unknownValue;
    }

    final documentReference = _documentReference;
    return DocumentFormData(
      documentType: widget.documentType,
      companyName: value('companyName'),
      siteConcerned: value('siteConcerned'),
      serviceConcerned: value('serviceConcerned'),
      author: value('author'),
      version: value('version'),
      visitDate: value('visitDate'),
      documentObjective: value('documentObjective'),
      includedLocations: value('includedLocations'),
      excludedLocations: value('excludedLocations'),
      concernedPositions: value('concernedPositions'),
      concernedTasks: value('concernedTasks'),
      includedSituations: value('includedSituations'),
      exposureDuration: value('exposureDuration'),
      workMode: value('workMode'),
      fieldVisitDone: value('fieldVisitDone'),
      jobObservationDone: value('jobObservationDone'),
      workersConsulted: value('workersConsulted'),
      managementConsulted: value('managementConsulted'),
      cpptConsulted: value('cpptConsulted'),
      incidentRegisterAvailable: value('incidentRegisterAvailable'),
      photosAvailable: value('photosAvailable'),
      controlReportsAvailable: value('controlReportsAvailable'),
      technicalSheetsAvailable: value('technicalSheetsAvailable'),
      safetyDataSheetsAvailable: value('safetyDataSheetsAvailable'),
      sector: value('sector'),
      workerCount: value('workerCount'),
      activity: value('activity'),
      equipment: value('equipment'),
      dangerousProducts: value('dangerousProducts'),
      exposedWorkers: value('exposedWorkers'),
      knownIncidents: value('knownIncidents'),
      constraints: value('constraints'),
      additionalInformation: value('additionalInformation'),
      writtenInstructions: value('writtenInstructions'),
      completedTrainings: value('completedTrainings'),
      availablePpe: value('availablePpe'),
      periodicControls: value('periodicControls'),
      availableEvidence: value('availableEvidence'),
      oralMeasures: value('oralMeasures'),
      measuresToVerify: value('measuresToVerify'),
      workAtHeight: value('workAtHeight'),
      dangerousMachines: value('dangerousMachines'),
      chemicalProducts: value('chemicalProducts'),
      manualHandling: value('manualHandling'),
      vehiclePedestrianTraffic: value('vehiclePedestrianTraffic'),
      noise: value('noise'),
      fireRisk: value('fireRisk'),
      loneWork: value('loneWork'),
      coactivity: value('coactivity'),
      weatherConstraints: value('weatherConstraints'),
      newWorkers: value('newWorkers'),
      temporaryWorkers: value('temporaryWorkers'),
      youngWorkers: value('youngWorkers'),
      pregnantOrBreastfeedingWorkers: value('pregnantOrBreastfeedingWorkers'),
      medicalRestrictionsWorkers: value('medicalRestrictionsWorkers'),
      isolatedWorkers: value('isolatedWorkers'),
      subcontractors: value('subcontractors'),
      cpptPresence: value('cpptPresence'),
      preventionService: value('preventionService'),
      feedAnnualActionPlan: value('feedAnnualActionPlan'),
      feedGlobalPreventionPlan: value('feedGlobalPreventionPlan'),
      presentToCppt: value('presentToCppt'),
      externalServiceValidation: value('externalServiceValidation'),
      occupationalDoctorAdvice: value('occupationalDoctorAdvice'),
      extraFields: {
        if (_preventionConfig != null)
          '_localeName': AppLocalizations.of(context).localeName,
        if (_preventionConfig != null) '_isPreventionDocument': 'true',
        if (documentReference.isNotEmpty) ...{
          'documentReference': documentReference,
          'reference': documentReference,
          if (_documentType.isRiskAnalysis) 'analysisNumber': documentReference,
        },
        for (final field in _currentFields)
          if (!_riskFieldKeys.contains(field.key)) field.key: value(field.key),
      },
    );
  }

  Future<void> _ensureDocumentReference() async {
    if (_documentReference.isNotEmpty) {
      return;
    }
    final pendingInitialization = _referenceInitialization;
    if (pendingInitialization != null) {
      await pendingInitialization;
      if (_documentReference.isNotEmpty) {
        return;
      }
    }
    _referenceInitialization = _generateAndSetDocumentReference();
    await _referenceInitialization;
  }

  Future<void> _generateAndSetDocumentReference() async {
    final reference = await DocumentReferenceService().nextReference(
      documentType: widget.documentType,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _currentDocumentReference = reference;
      _controllers['documentReference']?.text = reference;
    });
  }

  Future<bool> _showAiFallbackDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).aiUnavailableTitle),
            content: Text(
              AppLocalizations.of(context).aiUnavailableFallback(message),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context).useLocalGeneration),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _fillCompleteExample() {
    final localeName = AppLocalizations.of(context).localeName;
    final documentExample = getCompleteExampleForDocument(
      documentType: widget.documentType,
      languageCode: localeName,
    );
    final example = documentExample.isNotEmpty
        ? documentExample
        : getCompleteExampleData(localeName);
    if (example.isEmpty) {
      _showMissingExampleError(localeName);
      return;
    }

    _fillExampleValues(
      example.map((key, value) {
        return MapEntry(key, value?.toString() ?? '');
      }),
    );
  }

  void _clearForm() {
    final preservedReference = _documentReference;
    setState(() {
      for (final controller in _controllers.values) {
        controller.clear();
      }
      if (preservedReference.isNotEmpty) {
        _controllers['documentReference']?.text = preservedReference;
      }
    });
  }

  void _fillExampleValues(Map<String, String> values) {
    setState(() {
      for (final entry in values.entries) {
        if (_isReferenceField(entry.key) && _setReferenceOnlyIfEmpty()) {
          continue;
        }
        _set(entry.key, entry.value);
      }
    });
  }

  void _set(String key, String value) {
    _controllers[key]?.text = value;
  }

  bool _setReferenceOnlyIfEmpty() {
    final controller = _controllers['documentReference'];
    return controller != null && controller.text.trim().isNotEmpty;
  }

  void _openLocalDocument(
    DocumentFormData data, {
    required GenerationSource source,
  }) {
    final content = DocumentGenerator().generate(data);
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _isGeneratingWithAi = false;
      });
    }
    _openResult(content: content, generationSource: source);
  }

  void _openResult({
    required String content,
    required GenerationSource generationSource,
    List<AiLinkedDocument> linkedDocuments = const [],
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          documentType: widget.documentType,
          content: _contentWithDocumentReference(content),
          documentReference: _documentReference,
          generationSource: generationSource,
          linkedDocuments: linkedDocuments,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _preventionConfig == null
        ? widget.documentType
        : localizedDocumentTypeLabel(_documentType, l10n.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: AdaptivePage(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Text(
                l10n.completeFormIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _fillCompleteExample,
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: Text(l10n.fillCompleteExample),
                  ),
                  TextButton.icon(
                    onPressed: _isGenerating ? null : _clearForm,
                    icon: const Icon(Icons.clear_outlined),
                    label: Text(l10n.clearForm),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._currentSections.map(_buildSection),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isGenerating ? null : _generateDocument,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description_outlined),
                label: Text(l10n.generateDocument),
              ),
              if (_isGeneratingWithAi) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.aiGenerationInProgress,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(_FormSection section) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: section.initiallyExpanded,
        leading: const Icon(Icons.segment_outlined),
        title: Text(_localizedSectionTitle(l10n, section.title)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [_buildSectionFields(section.fields)],
      ),
    );
  }

  String _localizedSectionTitle(AppLocalizations l10n, String title) {
    if (_preventionConfig != null) {
      return localizedPreventionSectionTitle(title, l10n.localeName);
    }
    if (title.startsWith('A.')) {
      return l10n.formSectionIdentification;
    }
    if (title.startsWith('B.')) {
      return l10n.formSectionScope;
    }
    if (title.startsWith('C.')) {
      return l10n.formSectionSources;
    }
    if (title.startsWith('D.')) {
      return l10n.formSectionActivity;
    }
    if (title.startsWith('E.')) {
      return l10n.formSectionMeasures;
    }
    if (title.startsWith('F.')) {
      return l10n.formSectionRisks;
    }
    if (title.startsWith('G.')) {
      return l10n.formSectionWorkers;
    }
    if (title.startsWith('H.')) {
      return l10n.formSectionPrevention;
    }
    return title;
  }

  Widget _buildSectionFields(List<_FormFieldDefinition> fields) {
    if (!LayoutBreakpoints.isDesktop(context)) {
      return Column(children: fields.map(_buildField).toList());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columnWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: 0,
          children: fields.map((field) {
            final isLongField = field.maxLines > 2;
            return SizedBox(
              width: isLongField ? constraints.maxWidth : columnWidth,
              child: _buildField(field),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildField(_FormFieldDefinition field) {
    final help = _fieldHelp[field.key];
    final l10n = AppLocalizations.of(context);
    final label = _preventionConfig == null
        ? l10n.fieldLabel(field.key)
        : localizedPreventionFieldLabel(field.key, l10n.localeName);
    final hasHelp = _preventionConfig != null || help != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[field.key],
        enabled: !_isGenerating,
        maxLines: field.maxLines,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          filled: true,
          labelText: label,
          suffixIcon: !hasHelp
              ? null
              : IconButton(
                  tooltip: l10n.help,
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showFieldHelp(label, help, field.key),
                ),
        ),
      ),
    );
  }

  Future<void> _showFieldHelp(
    String fieldLabel,
    _FieldHelp? help,
    String fieldKey,
  ) async {
    final l10n = AppLocalizations.of(context);
    final documentExample = getCompleteExampleForDocument(
      documentType: widget.documentType,
      languageCode: l10n.localeName,
    )[fieldKey]?.toString();
    final description = _preventionConfig == null
        ? (help?.description ?? l10n.helpDescription)
        : localizedPreventionFieldHelp(fieldKey, l10n.localeName);
    final example = _preventionConfig == null
        ? (documentExample ?? help?.example ?? l10n.helpExample)
        : documentExample;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fieldLabel),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).example,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(example ?? AppLocalizations.of(context).helpExample),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).missingInformationHelp),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  void _showMissingExampleError(String localeName) {
    final message = switch (localeName) {
      'nl' =>
        'Geen compleet voorbeeld beschikbaar voor dit document of deze taal.',
      'en' => 'No complete example is available for this document or language.',
      'de' =>
        'Für dieses Dokument oder diese Sprache ist kein vollständiges Beispiel verfügbar.',
      _ =>
        'Aucun exemple complet n’est disponible pour ce document ou cette langue.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_FormSection> get _currentSections {
    final config = _preventionConfig;
    if (config == null) {
      return _sections;
    }
    return config.sections
        .map(
          (section) => _FormSection(
            title: section.key,
            initiallyExpanded: section.initiallyExpanded,
            fields: section.fields
                .map(
                  (field) => _FormFieldDefinition(
                    field.key,
                    field.key,
                    maxLines: field.maxLines,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  List<_FormFieldDefinition> get _currentFields {
    return _currentSections.expand((section) => section.fields).toList();
  }

  String get _documentReference {
    final controllerValue = _controllers['documentReference']?.text.trim();
    if (controllerValue != null && controllerValue.isNotEmpty) {
      return controllerValue;
    }
    return _currentDocumentReference ?? '';
  }

  String _contentWithDocumentReference(String content) {
    final reference = _documentReference;
    if (reference.isEmpty || content.contains(reference)) {
      return content;
    }
    final normalizedContent = content.trimLeft();
    return 'Document Reference: $reference\n\n$normalizedContent';
  }
}

bool _isReferenceField(String key) {
  return const {
    'documentReference',
    'reference',
    'analysisNumber',
    'projectNumber',
    'internalReference',
  }.contains(key);
}

const _valueFallbackKeys = {
  'author': ['preparedBy'],
  'visitDate': ['visitDateTime', 'eventDateTime', 'date'],
};

class _FormSection {
  const _FormSection({
    required this.title,
    required this.fields,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<_FormFieldDefinition> fields;
  final bool initiallyExpanded;
}

class _FormFieldDefinition {
  const _FormFieldDefinition(this.key, this.label, {this.maxLines = 1});

  final String key;
  final String label;
  final int maxLines;
}

class _FieldHelp {
  const _FieldHelp({required this.description, required this.example});

  final String description;
  final String example;
}

const _fieldHelp = <String, _FieldHelp>{
  'companyName': _FieldHelp(
    description:
        'Indiquez le nom légal ou usuel de l’entreprise, de l’administration ou de l’entité concernée par l’analyse.',
    example: 'Administration communale de Verviers – Service technique.',
  ),
  'siteConcerned': _FieldHelp(
    description:
        'Indiquez le lieu précis concerné par l’analyse afin de cadrer le périmètre de visite et d’observation.',
    example:
        'Atelier communal, garage véhicules, zone de stockage, bâtiments communaux, voiries.',
  ),
  'serviceConcerned': _FieldHelp(
    description:
        'Indiquez le service, département ou unité de travail analysé.',
    example: 'Service technique, voirie, espaces verts, maintenance.',
  ),
  'author': _FieldHelp(
    description:
        'Indiquez la personne qui prépare le projet de document ou coordonne l’analyse.',
    example:
        'Conseiller en prévention interne, responsable sécurité, chef de service.',
  ),
  'visitDate': _FieldHelp(
    description:
        'Indiquez la date de visite terrain ou précisez si elle doit encore être réalisée.',
    example: '07/06/2026 – à confirmer après visite de terrain.',
  ),
  'documentObjective': _FieldHelp(
    description:
        'Expliquez pourquoi l’analyse est réalisée et à quelle décision de prévention elle doit servir.',
    example:
        'Alimenter le Plan Annuel d’Action, préparer le CPPT, analyser un accident, préparer une visite terrain.',
  ),
  'includedLocations': _FieldHelp(
    description:
        'Listez les lieux réellement couverts par l’analyse pour éviter les interprétations trop larges.',
    example: 'Atelier, garage, zone de stockage, interventions extérieures.',
  ),
  'excludedLocations': _FieldHelp(
    description:
        'Listez ce qui n’est pas couvert par l’analyse afin d’éviter les ambiguïtés lors de la validation.',
    example:
        'Chantiers confiés à des entreprises externes, travaux haute tension.',
  ),
  'concernedPositions': _FieldHelp(
    description:
        'Indiquez les fonctions, métiers ou groupes de travailleurs concernés par les risques analysés.',
    example: 'Ouvriers polyvalents, agents de voirie, jardiniers, magasinier.',
  ),
  'concernedTasks': _FieldHelp(
    description:
        'Décrivez les tâches concrètes observées ou à analyser, pas seulement l’intitulé du poste.',
    example:
        'Manutention, découpe, perçage, nettoyage, intervention sur voirie.',
  ),
  'fieldVisitDone': _FieldHelp(
    description:
        'Indiquez si une visite terrain a été réalisée ou doit encore être planifiée comme source d’information.',
    example: 'Oui, visite atelier réalisée avec le chef d’équipe.',
  ),
  'jobObservationDone': _FieldHelp(
    description:
        'Précisez si les postes ou tâches ont été observés en situation réelle.',
    example: 'Observation d’une intervention sur voirie à planifier.',
  ),
  'workersConsulted': _FieldHelp(
    description:
        'Indiquez si les travailleurs concernés ont été consultés sur les risques, incidents et mesures existantes.',
    example: 'Deux agents de voirie et un magasinier consultés.',
  ),
  'managementConsulted': _FieldHelp(
    description:
        'Indiquez si la ligne hiérarchique a été consultée sur l’organisation du travail et les contraintes.',
    example: 'Chef d’équipe maintenance consulté.',
  ),
  'cpptConsulted': _FieldHelp(
    description:
        'Indiquez si le CPPT a été consulté ou doit l’être pour les points importants.',
    example: 'Projet à présenter au CPPT pour avis.',
  ),
  'incidentRegisterAvailable': _FieldHelp(
    description:
        'Indiquez si le registre accidents/incidents ou les signalements internes sont disponibles comme source.',
    example:
        'Registre accidents, quasi-accidents et plaintes bruit à consulter.',
  ),
  'photosAvailable': _FieldHelp(
    description:
        'Indiquez si des photos terrain existent ou doivent être prises pour objectiver les constats.',
    example: 'Photos atelier, stockage produits, rayonnages et circulation.',
  ),
  'controlReportsAvailable': _FieldHelp(
    description: 'Indiquez les rapports de contrôle disponibles ou à obtenir.',
    example: 'Rapports extincteurs, échelles, véhicules, rayonnages.',
  ),
  'technicalSheetsAvailable': _FieldHelp(
    description:
        'Indiquez si les notices, fiches techniques ou instructions fabricant sont disponibles.',
    example: 'Notices meuleuses, scies, débroussailleuses à centraliser.',
  ),
  'safetyDataSheetsAvailable': _FieldHelp(
    description:
        'Indiquez si les fiches de données de sécurité des produits dangereux sont disponibles et à jour.',
    example: 'FDS peintures, solvants, huiles et aérosols à vérifier.',
  ),
  'equipment': _FieldHelp(
    description:
        'Indiquez les équipements, machines, outils ou véhicules concernés par l’analyse.',
    example:
        'Perceuses, meuleuses, échelles, tondeuses, véhicules utilitaires.',
  ),
  'dangerousProducts': _FieldHelp(
    description:
        'Indiquez les produits chimiques, substances dangereuses ou produits nécessitant une FDS.',
    example:
        'Peintures, solvants, huiles, carburants, aérosols, produits de nettoyage.',
  ),
  'exposedWorkers': _FieldHelp(
    description:
        'Indiquez les groupes de travailleurs exposés aux risques identifiés.',
    example:
        'Ouvriers, jardiniers, agents de voirie, intérimaires, travailleurs isolés.',
  ),
  'knownIncidents': _FieldHelp(
    description:
        'Indiquez les accidents, quasi-accidents, plaintes ou incidents déjà signalés.',
    example:
        'Douleurs lombaires, coupures, glissades, plaintes liées au bruit.',
  ),
  'writtenInstructions': _FieldHelp(
    description: 'Indiquez les mesures existantes formalisées par écrit.',
    example: 'Consignes machines, procédure travail isolé, instruction EPI.',
  ),
  'completedTrainings': _FieldHelp(
    description:
        'Indiquez les formations déjà réalisées et celles qui doivent être vérifiées.',
    example:
        'Formation manutention, machines, produits chimiques, signalisation.',
  ),
  'availablePpe': _FieldHelp(
    description:
        'Indiquez les équipements de protection individuelle disponibles et les tâches concernées.',
    example:
        'Gants, lunettes, protections auditives, chaussures S3, haute visibilité.',
  ),
  'periodicControls': _FieldHelp(
    description: 'Indiquez les contrôles périodiques réalisés ou à obtenir.',
    example: 'Contrôle extincteurs, échelles, escabeaux, véhicules.',
  ),
  'availableEvidence': _FieldHelp(
    description: 'Indiquez comment prouver qu’une mesure existe réellement.',
    example:
        'Liste de présence, registre EPI, rapport de contrôle, photo, procédure signée.',
  ),
  'oralMeasures': _FieldHelp(
    description:
        'Indiquez les mesures existantes qui reposent seulement sur des habitudes ou consignes orales.',
    example: 'Briefing oral du chef d’équipe avant intervention.',
  ),
  'measuresToVerify': _FieldHelp(
    description:
        'Indiquez les mesures dont l’existence ou l’efficacité doit être vérifiée sur le terrain.',
    example: 'Port réel des EPI, état des câbles, accès aux FDS, rangement.',
  ),
  'workAtHeight': _FieldHelp(
    description:
        'Précisez si le travail en hauteur est réellement présent et dans quelles tâches.',
    example: 'Utilisation d’échelles et escabeaux pour petites réparations.',
  ),
  'dangerousMachines': _FieldHelp(
    description:
        'Précisez les machines ou outillages présentant des risques mécaniques, de projection ou de coupure.',
    example: 'Meuleuses, scies, perceuses, débroussailleuses, tondeuses.',
  ),
  'chemicalProducts': _FieldHelp(
    description:
        'Précisez les produits chimiques réellement utilisés et les situations d’exposition.',
    example: 'Peintures, solvants, dégraissants, carburants, aérosols.',
  ),
  'manualHandling': _FieldHelp(
    description:
        'Précisez les manutentions physiques susceptibles d’entraîner des TMS, chutes ou coincements.',
    example: 'Port de charges, sacs, caisses, outils, chargement de véhicule.',
  ),
  'vehiclePedestrianTraffic': _FieldHelp(
    description:
        'Précisez les situations de circulation ou cohabitation véhicules/piétons.',
    example:
        'Manœuvres au garage, interventions sur voirie, présence de citoyens.',
  ),
  'noise': _FieldHelp(
    description: 'Précisez les sources de bruit et les travailleurs exposés.',
    example:
        'Souffleurs, meuleuses, scies, débroussailleuses, nettoyeur haute pression.',
  ),
  'fireRisk': _FieldHelp(
    description:
        'Précisez les sources d’incendie ou d’explosion et les zones concernées.',
    example:
        'Produits inflammables, aérosols, carburants, équipements électriques.',
  ),
  'loneWork': _FieldHelp(
    description:
        'Précisez les situations où un travailleur intervient seul ou hors surveillance directe.',
    example: 'Intervention ponctuelle seul dans un bâtiment communal.',
  ),
  'coactivity': _FieldHelp(
    description:
        'Précisez les situations où plusieurs intervenants ou le public se croisent.',
    example:
        'Sous-traitants, citoyens, agents communaux et circulation sur voirie.',
  ),
  'weatherConstraints': _FieldHelp(
    description:
        'Précisez les contraintes météo influençant les risques de chute, visibilité, fatigue ou exposition.',
    example: 'Pluie, froid, chaleur, vent, surfaces glissantes.',
  ),
  'newWorkers': _FieldHelp(
    description:
        'Identifiez les nouveaux travailleurs nécessitant accueil, information et accompagnement renforcés.',
    example: 'Accueil sécurité à formaliser pour tout nouvel agent.',
  ),
  'temporaryWorkers': _FieldHelp(
    description:
        'Identifiez les intérimaires ou temporaires et les mesures d’accueil nécessaires.',
    example: 'Information risques atelier avant première prise de poste.',
  ),
  'youngWorkers': _FieldHelp(
    description:
        'Identifiez les jeunes travailleurs et les restrictions ou mesures spécifiques éventuelles.',
    example: 'Jeune travailleur affecté uniquement à des tâches encadrées.',
  ),
  'pregnantOrBreastfeedingWorkers': _FieldHelp(
    description:
        'Identifiez les situations nécessitant une attention particulière, dans le respect de la confidentialité.',
    example: 'Analyse spécifique à prévoir si une travailleuse est concernée.',
  ),
  'medicalRestrictionsWorkers': _FieldHelp(
    description:
        'Identifiez les restrictions utiles à l’adaptation du travail, sans encoder de données médicales sensibles.',
    example:
        'Restriction de port de charges à vérifier avec le médecin du travail.',
  ),
  'isolatedWorkers': _FieldHelp(
    description:
        'Identifiez les travailleurs susceptibles d’intervenir seuls et les moyens de contact ou d’alerte.',
    example: 'Agent technique seul dans un bâtiment en fin de journée.',
  ),
  'subcontractors': _FieldHelp(
    description:
        'Identifiez les entreprises externes présentes et les besoins de coordination.',
    example: 'Coordination avec entreprise de maintenance spécialisée.',
  ),
  'cpptPresence': _FieldHelp(
    description:
        'Indiquez si un CPPT existe. S’il est présent, il doit être consulté pour les actions importantes.',
    example: 'Oui, présentation au CPPT prévue pour avis et suivi.',
  ),
  'preventionService': _FieldHelp(
    description:
        'Indiquez qui participe à l’analyse, à l’avis ou à la validation prévention.',
    example: 'SIPPT, SEPPT, médecin du travail.',
  ),
  'additionalInformation': _FieldHelp(
    description:
        'Ajoutez tout élément utile non prévu ailleurs, surtout les contraintes ou signaux faibles.',
    example:
        'Incidents récents, plaintes, contraintes organisationnelles, urgence.',
  ),
};

const _sections = [
  _FormSection(
    title: 'A. Identification du document',
    initiallyExpanded: true,
    fields: [
      _FormFieldDefinition('documentReference', 'Référence documentaire'),
      _FormFieldDefinition('companyName', 'Nom de l’entreprise'),
      _FormFieldDefinition('siteConcerned', 'Site concerné'),
      _FormFieldDefinition('serviceConcerned', 'Service concerné'),
      _FormFieldDefinition('author', 'Rédacteur'),
      _FormFieldDefinition('version', 'Version'),
      _FormFieldDefinition('visitDate', 'Date de visite ou d’observation'),
      _FormFieldDefinition(
        'documentObjective',
        'Objectif du document : CPPT, audit, PAA, PGP, accident, visite terrain, autre',
        maxLines: 2,
      ),
    ],
  ),
  _FormSection(
    title: 'B. Périmètre de l’analyse',
    fields: [
      _FormFieldDefinition('includedLocations', 'Lieux inclus', maxLines: 2),
      _FormFieldDefinition('excludedLocations', 'Lieux exclus', maxLines: 2),
      _FormFieldDefinition(
        'concernedPositions',
        'Postes concernés',
        maxLines: 2,
      ),
      _FormFieldDefinition('concernedTasks', 'Tâches concernées', maxLines: 3),
      _FormFieldDefinition(
        'includedSituations',
        'Situations incluses : routine, urgence, coactivité, sous-traitance, travail isolé',
        maxLines: 3,
      ),
      _FormFieldDefinition(
        'exposureDuration',
        'Durée d’exposition quotidienne ou hebdomadaire',
        maxLines: 2,
      ),
      _FormFieldDefinition(
        'workMode',
        'Travail sur site, télétravail ou mixte',
      ),
    ],
  ),
  _FormSection(
    title: 'C. Sources d’information',
    fields: [
      _FormFieldDefinition(
        'fieldVisitDone',
        'Visite terrain réalisée : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'jobObservationDone',
        'Observation de poste réalisée : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'workersConsulted',
        'Travailleurs consultés : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'managementConsulted',
        'Ligne hiérarchique consultée : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'cpptConsulted',
        'CPPT consulté : oui/non/non applicable/à vérifier',
      ),
      _FormFieldDefinition(
        'incidentRegisterAvailable',
        'Registre accidents/incidents disponible : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'photosAvailable',
        'Photos disponibles : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'controlReportsAvailable',
        'Rapports de contrôle disponibles : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'technicalSheetsAvailable',
        'Fiches techniques disponibles : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'safetyDataSheetsAvailable',
        'Fiches de données de sécurité disponibles : oui/non/à vérifier',
      ),
    ],
  ),
  _FormSection(
    title: 'D. Activité, équipements et produits',
    fields: [
      _FormFieldDefinition('sector', 'Secteur d’activité', maxLines: 2),
      _FormFieldDefinition(
        'workerCount',
        'Nombre de travailleurs',
        maxLines: 2,
      ),
      _FormFieldDefinition(
        'activity',
        'Activité ou poste analysé',
        maxLines: 4,
      ),
      _FormFieldDefinition(
        'equipment',
        'Machines ou équipements utilisés',
        maxLines: 4,
      ),
      _FormFieldDefinition(
        'dangerousProducts',
        'Produits dangereux utilisés',
        maxLines: 3,
      ),
      _FormFieldDefinition(
        'exposedWorkers',
        'Travailleurs exposés',
        maxLines: 3,
      ),
      _FormFieldDefinition(
        'knownIncidents',
        'Accidents ou incidents connus',
        maxLines: 4,
      ),
      _FormFieldDefinition(
        'constraints',
        'Contraintes particulières',
        maxLines: 4,
      ),
      _FormFieldDefinition(
        'additionalInformation',
        'Informations complémentaires',
        maxLines: 4,
      ),
    ],
  ),
  _FormSection(
    title: 'E. Mesures existantes et preuves',
    fields: [
      _FormFieldDefinition(
        'writtenInstructions',
        'Instructions écrites existantes',
        maxLines: 3,
      ),
      _FormFieldDefinition(
        'completedTrainings',
        'Formations déjà réalisées',
        maxLines: 3,
      ),
      _FormFieldDefinition('availablePpe', 'EPI disponibles', maxLines: 3),
      _FormFieldDefinition(
        'periodicControls',
        'Contrôles périodiques réalisés',
        maxLines: 3,
      ),
      _FormFieldDefinition(
        'availableEvidence',
        'Preuves disponibles',
        maxLines: 3,
      ),
      _FormFieldDefinition(
        'oralMeasures',
        'Mesures seulement orales ou non documentées',
        maxLines: 3,
      ),
      _FormFieldDefinition(
        'measuresToVerify',
        'Mesures à vérifier sur terrain',
        maxLines: 3,
      ),
    ],
  ),
  _FormSection(
    title: 'F. Risques spécifiques',
    fields: [
      _FormFieldDefinition(
        'workAtHeight',
        'Travail en hauteur : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'dangerousMachines',
        'Machines ou outillage dangereux : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'chemicalProducts',
        'Produits chimiques : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'manualHandling',
        'Manutention manuelle : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'vehiclePedestrianTraffic',
        'Circulation véhicules/piétons : oui/non/à vérifier',
      ),
      _FormFieldDefinition('noise', 'Bruit : oui/non/à vérifier'),
      _FormFieldDefinition('fireRisk', 'Incendie : oui/non/à vérifier'),
      _FormFieldDefinition('loneWork', 'Travail isolé : oui/non/à vérifier'),
      _FormFieldDefinition(
        'coactivity',
        'Coactivité avec public/sous-traitants : oui/non/à vérifier',
      ),
      _FormFieldDefinition(
        'weatherConstraints',
        'Contraintes météo : oui/non/à vérifier',
      ),
    ],
  ),
  _FormSection(
    title: 'G. Travailleurs particuliers',
    fields: [
      _FormFieldDefinition('newWorkers', 'Nouveaux travailleurs'),
      _FormFieldDefinition('temporaryWorkers', 'Intérimaires'),
      _FormFieldDefinition('youngWorkers', 'Jeunes travailleurs'),
      _FormFieldDefinition(
        'pregnantOrBreastfeedingWorkers',
        'Travailleuses enceintes ou allaitantes',
      ),
      _FormFieldDefinition(
        'medicalRestrictionsWorkers',
        'Travailleurs avec restrictions médicales',
      ),
      _FormFieldDefinition('isolatedWorkers', 'Travailleurs isolés'),
      _FormFieldDefinition('subcontractors', 'Sous-traitants'),
    ],
  ),
  _FormSection(
    title: 'H. Objectif prévention',
    fields: [
      _FormFieldDefinition('cpptPresence', 'Présence d’un CPPT'),
      _FormFieldDefinition(
        'preventionService',
        'Service interne ou externe',
        maxLines: 2,
      ),
      _FormFieldDefinition(
        'feedAnnualActionPlan',
        'Le document doit-il alimenter le Plan Annuel d’Action ?',
      ),
      _FormFieldDefinition(
        'feedGlobalPreventionPlan',
        'Le document doit-il alimenter le Plan Global de Prévention ?',
      ),
      _FormFieldDefinition(
        'presentToCppt',
        'Le document doit-il être présenté au CPPT ?',
      ),
      _FormFieldDefinition(
        'externalServiceValidation',
        'Une validation du service externe est-elle prévue ?',
      ),
      _FormFieldDefinition(
        'occupationalDoctorAdvice',
        'Un avis du médecin du travail est-il nécessaire ?',
      ),
    ],
  ),
];

final _allFields = _sections.expand((section) => section.fields).toList();
final _riskFieldKeys = _allFields.map((field) => field.key).toSet();

Map<String, String> getCompleteExampleData(String localeName) {
  return switch (localeName) {
    'nl' => _dutchCompleteExample,
    'en' => _englishCompleteExample,
    'de' => _germanCompleteExample,
    _ => _frenchCompleteExample,
  };
}

const _frenchCompleteExample = <String, String>{
  'companyName': 'Administration communale de Verviers – Service technique',
  'siteConcerned':
      'Atelier communal de Verviers, zones de stockage, garage véhicules, locaux techniques et interventions sur sites communaux',
  'serviceConcerned':
      'Service technique communal – maintenance des bâtiments, voirie et espaces publics',
  'author': 'Conseiller en prévention interne – projet à compléter',
  'version': '1.0',
  'visitDate': '07/06/2026 – à confirmer après visite de terrain',
  'documentObjective':
      'Projet d’analyse de risques générale destiné à alimenter le Plan Annuel d’Action, le Plan Global de Prévention et la préparation d’une discussion au CPPT.',
  'includedLocations':
      'Atelier communal, garage véhicules, zone de stockage du matériel, armoire produits dangereux, locaux techniques, bâtiments communaux, voiries et espaces verts lors des interventions.',
  'excludedLocations':
      'Chantiers de construction lourde confiés à des entreprises externes, interventions spécialisées nécessitant un permis particulier, travaux électriques haute tension, interventions d’urgence des services de secours.',
  'concernedPositions':
      'Ouvriers polyvalents, agents de voirie, jardiniers, magasinier, chefs d’équipe, travailleurs intervenant ponctuellement seuls, nouveaux travailleurs et intérimaires éventuels.',
  'concernedTasks':
      'Préparation des interventions, chargement et déchargement du matériel, manutention, petites réparations, perçage, découpe, ponçage, nettoyage, entretien des espaces verts, utilisation d’outillage électroportatif, interventions sur voirie, rangement du stock, déplacement en véhicule utilitaire.',
  'includedSituations':
      'Travail de routine, interventions urgentes, coactivité avec citoyens ou sous-traitants, travail isolé ponctuel, travail extérieur, travail en atelier, déplacements entre sites, manutention de charges, utilisation de produits chimiques.',
  'exposureDuration':
      'Exposition variable selon les équipes. Utilisation d’outillage et manutention plusieurs fois par semaine. Déplacements quotidiens. Travail extérieur fréquent pour les agents de voirie et jardiniers. Durée précise à confirmer par observation terrain.',
  'workMode':
      'Travail principalement sur site et en intervention extérieure. Télétravail non applicable aux ouvriers, agents de voirie et jardiniers.',
  'fieldVisitDone':
      'À vérifier – visite terrain à planifier avec le conseiller en prévention et les chefs d’équipe.',
  'jobObservationDone':
      'À vérifier – observation recommandée pendant une journée type et pendant une intervention extérieure.',
  'workersConsulted':
      'À vérifier – consultation recommandée des ouvriers polyvalents, jardiniers, agents de voirie et magasinier.',
  'managementConsulted':
      'À vérifier – entretien à prévoir avec les chefs d’équipe et le responsable du service technique.',
  'cpptConsulted':
      'Oui, CPPT présent. Le projet doit être présenté au CPPT pour avis et suivi des actions prioritaires.',
  'incidentRegisterAvailable':
      'À vérifier – les douleurs lombaires, coupures, glissades, quasi-accidents et plaintes bruit doivent être recherchés dans le registre ou les signalements internes.',
  'photosAvailable':
      'Non renseigné / à vérifier – photos à prévoir pour atelier, stockage, circulation, produits dangereux, rayonnages, EPI, échelles et zones de travail extérieur.',
  'controlReportsAvailable':
      'À vérifier – rapports à rechercher pour échelles, escabeaux, petits échafaudages roulants, extincteurs, véhicules et équipements soumis à contrôle.',
  'technicalSheetsAvailable':
      'À vérifier – fiches techniques et notices des machines/outillages à centraliser.',
  'safetyDataSheetsAvailable':
      'Partiellement disponibles – inventaire des produits chimiques et FDS à mettre à jour.',
  'sector':
      'Service technique communal / maintenance des bâtiments et espaces publics',
  'workerCount':
      '24 travailleurs concernés : 14 ouvriers polyvalents, 4 agents de voirie, 3 jardiniers, 2 chefs d’équipe et 1 magasinier.',
  'activity':
      'Travaux de maintenance générale, petites réparations dans les bâtiments communaux, entretien des espaces publics, interventions sur voirie, manutention de matériel, gestion du stock et déplacements en véhicule utilitaire.',
  'equipment':
      'Perceuses, visseuses, meuleuses, scies, ponceuses, nettoyeur haute pression, compresseur, rallonges électriques, échelles, escabeaux, petits échafaudages roulants, tondeuses, débroussailleuses, souffleurs, véhicules utilitaires, transpalette manuel, diable, rayonnages, armoires de stockage, extincteurs, trousse de secours.',
  'dangerousProducts':
      'Peintures, solvants, dégraissants, huiles, carburants, produits de nettoyage, aérosols techniques, colles, mastics, produits phytosanitaires éventuels à vérifier, cartouches ou bouteilles de gaz selon interventions.',
  'exposedWorkers':
      'Ouvriers polyvalents, agents de voirie, jardiniers, magasinier, chefs d’équipe, nouveaux travailleurs, intérimaires éventuels, travailleurs isolés ponctuels, travailleurs avec restrictions médicales éventuelles à vérifier, sous-traitants présents ponctuellement.',
  'knownIncidents':
      'Douleurs lombaires signalées lors de manutentions, coupures mineures lors de réparations, quasi-accident lié à un câble au sol dans l’atelier, glissade dans une zone humide, plainte liée au bruit des machines, fatigue lors d’interventions urgentes, situations de coactivité avec citoyens ou sous-traitants.',
  'constraints':
      'Interventions variables et parfois urgentes, travail sur plusieurs sites, coactivité avec public ou sous-traitants, conditions météo variables, espaces exigus, rangement variable dans l’atelier, inventaire produits dangereux incomplet, formation machines et travail en hauteur à vérifier.',
  'additionalInformation':
      'L’analyse doit servir à prioriser les actions de prévention pour l’année à venir : rangement et circulation dans l’atelier, inventaire des produits chimiques, instructions de travail, contrôle des échelles et escabeaux, formation manutention, formation machines/outillage, organisation du travail isolé, gestion des EPI, suivi des incidents et consultation du CPPT.',
  'writtenInstructions':
      'Certaines notices fabricants sont disponibles pour les machines, mais les instructions internes de travail sécurisé sont incomplètes ou à vérifier.',
  'completedTrainings':
      'Briefing oral par les chefs d’équipe. Formations spécifiques manutention, machines, produits chimiques, travail en hauteur et signalisation de chantier à vérifier.',
  'availablePpe':
      'Chaussures de sécurité, gants, lunettes de protection, protections auditives, vêtements haute visibilité, vêtements de pluie, casques ou protections spécifiques à vérifier selon les tâches.',
  'periodicControls':
      'Entretien périodique de certains véhicules. Contrôle des extincteurs à vérifier. Contrôle des échelles, escabeaux, rayonnages et petits échafaudages roulants à vérifier.',
  'availableEvidence':
      'Trousse de secours visible, extincteurs présents, certains EPI disponibles, certaines notices fabricants présentes. Listes de formation, rapports de contrôle, fiches de poste et instructions internes à compléter ou vérifier.',
  'oralMeasures':
      'Briefings oraux, pratiques de rangement, choix des EPI selon expérience, consignes de manutention, organisation du travail isolé et gestion des interventions urgentes.',
  'measuresToVerify':
      'État réel du rangement, circulation piétons/véhicules, stockage produits chimiques, accessibilité des FDS, conformité des échelles, port réel des EPI, signalisation temporaire, organisation du travail isolé, état des câbles et rallonges.',
  'workAtHeight':
      'Oui – utilisation d’échelles, escabeaux et petits échafaudages roulants lors de réparations et interventions dans les bâtiments.',
  'dangerousMachines':
      'Oui – utilisation de meuleuses, scies, perceuses, ponceuses, débroussailleuses, tondeuses, souffleurs et nettoyeur haute pression.',
  'chemicalProducts':
      'Oui – peintures, solvants, dégraissants, huiles, carburants, aérosols, colles, mastics et produits de nettoyage. Inventaire et FDS à vérifier.',
  'manualHandling':
      'Oui – transport d’outils, charges, sacs, caisses, matériel, archives, équipements et chargement/déchargement des véhicules.',
  'vehiclePedestrianTraffic':
      'Oui – déplacements en véhicule utilitaire, circulation dans l’atelier, manœuvres au garage, interventions sur voirie et présence possible de citoyens.',
  'noise':
      'Oui – bruit lié aux machines, souffleurs, débroussailleuses, meuleuses, scies et nettoyeur haute pression. Niveau réel à évaluer.',
  'fireRisk':
      'Oui – présence de produits inflammables, carburants, aérosols, équipements électriques, stockage et atelier. Analyse incendie à vérifier.',
  'loneWork':
      'Oui – interventions ponctuelles seules dans bâtiments ou espaces extérieurs. Procédure à formaliser.',
  'coactivity':
      'Oui – interventions dans bâtiments communaux occupés, sur voirie, espaces publics, présence de citoyens ou sous-traitants.',
  'weatherConstraints':
      'Oui – pluie, froid, chaleur, vent, surfaces glissantes, visibilité réduite lors du travail extérieur.',
  'newWorkers': 'Oui – accueil sécurité et accompagnement à formaliser.',
  'temporaryWorkers':
      'Éventuels – conditions d’accueil, information sur les risques et encadrement à prévoir.',
  'youngWorkers': 'Non renseigné / à vérifier.',
  'pregnantOrBreastfeedingWorkers':
      'Non renseigné / à vérifier. Analyse spécifique à prévoir en cas de situation concernée.',
  'medicalRestrictionsWorkers':
      'Non renseigné / à vérifier avec le médecin du travail dans le respect de la confidentialité.',
  'isolatedWorkers':
      'Oui – interventions ponctuelles seules à organiser et tracer.',
  'subcontractors':
      'Oui – présence ponctuelle possible lors d’interventions techniques ou travaux spécialisés. Coordination à prévoir.',
  'cpptPresence':
      'Oui, CPPT présent. Les actions importantes doivent être présentées pour avis et suivi.',
  'preventionService':
      'Service interne de prévention présent. Service externe consulté pour surveillance de santé, risques chimiques, ergonomie, travail en hauteur, risques spécifiques et avis complémentaire.',
  'feedAnnualActionPlan':
      'Oui – actions prioritaires à intégrer au Plan Annuel d’Action : rangement atelier, inventaire produits chimiques, formation manutention, contrôle échelles, instructions machines, signalisation, travail isolé.',
  'feedGlobalPreventionPlan':
      'Oui – actions structurelles à intégrer au Plan Global de Prévention : politique EPI, programme de formation, gestion des produits dangereux, organisation des contrôles périodiques, amélioration des zones de stockage, procédures de coordination.',
  'presentToCppt':
      'Oui – présentation recommandée au CPPT pour avis, priorisation, suivi et traçabilité.',
  'externalServiceValidation':
      'Oui – validation ou avis recommandé pour risques chimiques, ergonomie, surveillance de santé, travail en hauteur et aspects spécifiques.',
  'occupationalDoctorAdvice':
      'Oui, si restrictions médicales, plaintes TMS, exposition à produits dangereux, bruit, manutention ou travailleurs sensibles sont concernés. À confirmer selon les situations individuelles.',
};

const _dutchCompleteExample = <String, String>{
  'companyName': 'Gemeentebestuur van Verviers – Technische dienst',
  'siteConcerned':
      'Gemeentelijke werkplaats van Verviers, opslagzones, voertuiggarage, technische lokalen en interventies op gemeentelijke sites',
  'serviceConcerned':
      'Technische dienst – onderhoud van gebouwen, wegenis en openbare ruimten',
  'author': 'Interne preventieadviseur – ontwerp aan te vullen',
  'version': '1.0',
  'visitDate': '07/06/2026 – te bevestigen na terreinbezoek',
  'documentObjective':
      'Ontwerp van algemene risicoanalyse bedoeld om het Jaaractieplan, het Globaal Preventieplan en de bespreking in het CPBW voor te bereiden.',
  'includedLocations':
      'Gemeentelijke werkplaats, voertuiggarage, opslagzone voor materiaal, kast voor gevaarlijke producten, technische lokalen, gemeentelijke gebouwen, wegenis en groenzones tijdens interventies.',
  'excludedLocations':
      'Zware bouwwerven uitgevoerd door externe aannemers, gespecialiseerde interventies waarvoor een specifieke vergunning vereist is, hoogspanningswerken en noodinterventies van hulpdiensten.',
  'concernedPositions':
      'Polyvalente arbeiders, wegenwerkers, tuiniers, magazijnier, ploegbazen, werknemers die occasioneel alleen werken, nieuwe werknemers en eventuele uitzendkrachten.',
  'concernedTasks':
      'Voorbereiding van interventies, laden en lossen van materiaal, manueel hanteren van lasten, kleine herstellingen, boren, slijpen, zagen, schuren, reinigen, onderhoud van groenzones, gebruik van elektrisch handgereedschap, interventies op de openbare weg, opslagbeheer en verplaatsingen met dienstvoertuigen.',
  'includedSituations':
      'Routinewerk, dringende interventies, samenwerking met burgers of onderaannemers, occasioneel alleenwerk, buitenwerk, werkplaatsactiviteiten, verplaatsingen tussen sites, manueel hanteren van lasten en gebruik van chemische producten.',
  'exposureDuration':
      'Variabele blootstelling afhankelijk van de ploegen. Gebruik van gereedschap en manueel hanteren van lasten meerdere keren per week. Dagelijkse verplaatsingen. Regelmatig buitenwerk voor wegenwerkers en tuiniers. De exacte duur moet worden bevestigd door terreinobservatie.',
  'workMode':
      'Voornamelijk werk op locatie en buiteninterventies. Telewerk is niet van toepassing op arbeiders, wegenwerkers en tuiniers.',
  'fieldVisitDone':
      'Te controleren – terreinbezoek te plannen met de preventieadviseur en de ploegbazen.',
  'jobObservationDone':
      'Te controleren – observatie aanbevolen tijdens een typische werkdag en tijdens een buiteninterventie.',
  'workersConsulted':
      'Te controleren – raadpleging aanbevolen van polyvalente arbeiders, tuiniers, wegenwerkers en magazijnier.',
  'managementConsulted':
      'Te controleren – overleg te voorzien met de ploegbazen en de verantwoordelijke van de technische dienst.',
  'cpptConsulted':
      'Ja, CPBW aanwezig. Het ontwerp moet aan het CPBW worden voorgelegd voor advies en opvolging van prioritaire acties.',
  'incidentRegisterAvailable':
      'Te controleren – rugklachten, snijwonden, uitglijders, bijna-ongevallen en klachten over lawaai moeten worden nagegaan in het register of interne meldingen.',
  'photosAvailable':
      'Niet meegedeeld / te controleren – foto’s te voorzien van de werkplaats, opslagzones, circulatie, gevaarlijke producten, rekken, PBM, ladders en buitenwerkzones.',
  'controlReportsAvailable':
      'Te controleren – verslagen op te zoeken voor ladders, trapladders, rolsteigers, brandblussers, voertuigen en arbeidsmiddelen die onderworpen zijn aan controle.',
  'technicalSheetsAvailable':
      'Te controleren – technische fiches en handleidingen van machines en gereedschappen centraliseren.',
  'safetyDataSheetsAvailable':
      'Gedeeltelijk beschikbaar – inventaris van chemische producten en VIB’s bijwerken.',
  'sector':
      'Gemeentelijke technische dienst / onderhoud van gebouwen en openbare ruimten',
  'workerCount':
      '24 betrokken werknemers: 14 polyvalente arbeiders, 4 wegenwerkers, 3 tuiniers, 2 ploegbazen en 1 magazijnier.',
  'activity':
      'Algemene onderhoudswerken, kleine herstellingen in gemeentelijke gebouwen, onderhoud van openbare ruimten, interventies op de openbare weg, manueel hanteren van materiaal, opslagbeheer en verplaatsingen met dienstvoertuigen.',
  'equipment':
      'Boormachines, schroefmachines, slijpmachines, zagen, schuurmachines, hogedrukreiniger, compressor, verlengkabels, ladders, trapladders, kleine rolsteigers, grasmaaiers, bosmaaiers, bladblazers, dienstvoertuigen, handtranspallet, steekwagen, rekken, opslagkasten, brandblussers en EHBO-koffer.',
  'dangerousProducts':
      'Verven, oplosmiddelen, ontvetters, oliën, brandstoffen, reinigingsproducten, technische spuitbussen, lijmen, mastieken, eventuele fytosanitaire producten te controleren, gaspatronen of gasflessen afhankelijk van de interventies.',
  'exposedWorkers':
      'Polyvalente arbeiders, wegenwerkers, tuiniers, magazijnier, ploegbazen, nieuwe werknemers, eventuele uitzendkrachten, werknemers die occasioneel alleen werken, werknemers met medische beperkingen te controleren en aanwezige onderaannemers.',
  'knownIncidents':
      'Rugklachten gemeld bij het hanteren van lasten, kleine snijwonden bij herstellingen, bijna-ongeval door een kabel op de vloer in de werkplaats, uitglijden in een natte zone, klacht over lawaai van machines, vermoeidheid bij dringende interventies en situaties van samenwerking met burgers of onderaannemers.',
  'constraints':
      'Variabele en soms dringende interventies, werk op meerdere sites, aanwezigheid van publiek of onderaannemers, wisselende weersomstandigheden, beperkte ruimtes, wisselende orde in de werkplaats, onvolledige inventaris van gevaarlijke producten, opleiding machines en werken op hoogte te controleren.',
  'additionalInformation':
      'De analyse moet dienen om preventieacties voor het komende jaar te prioriteren: orde en circulatie in de werkplaats, inventaris van chemische producten, werkinstructies, controle van ladders en trapladders, opleiding manueel hanteren van lasten, opleiding machines/gereedschap, organisatie van alleenwerk, beheer van PBM, opvolging van incidenten en raadpleging van het CPBW.',
  'writtenInstructions':
      'Sommige handleidingen van fabrikanten zijn beschikbaar, maar interne veiligheidsinstructies zijn onvolledig of te controleren.',
  'completedTrainings':
      'Mondelinge briefing door ploegbazen. Specifieke opleidingen rond manueel hanteren van lasten, machines, chemische producten, werken op hoogte en signalisatie van werken te controleren.',
  'availablePpe':
      'Veiligheidsschoenen, handschoenen, veiligheidsbrillen, gehoorbescherming, hoge zichtbaarheidskledij, regenkledij, helmen of specifieke bescherming te controleren volgens de taken.',
  'periodicControls':
      'Periodiek onderhoud van sommige voertuigen. Controle van brandblussers te controleren. Controle van ladders, trapladders, rekken en kleine rolsteigers te controleren.',
  'availableEvidence':
      'EHBO-koffer zichtbaar, brandblussers aanwezig, sommige PBM beschikbaar, sommige handleidingen van fabrikanten aanwezig. Opleidingslijsten, controleverslagen, werkpostfiches en interne instructies moeten worden aangevuld of gecontroleerd.',
  'oralMeasures':
      'Mondelinge briefings, opruimpraktijken, keuze van PBM op basis van ervaring, instructies voor manueel hanteren van lasten, organisatie van alleenwerk en beheer van dringende interventies.',
  'measuresToVerify':
      'Werkelijke staat van orde en netheid, circulatie van voetgangers en voertuigen, opslag van chemische producten, beschikbaarheid van VIB’s, conformiteit van ladders, effectief dragen van PBM, tijdelijke signalisatie, organisatie van alleenwerk, staat van kabels en verlengsnoeren.',
  'workAtHeight':
      'Ja – gebruik van ladders, trapladders en kleine rolsteigers tijdens herstellingen en interventies in gebouwen.',
  'dangerousMachines':
      'Ja – gebruik van slijpmachines, zagen, boormachines, schuurmachines, bosmaaiers, grasmaaiers, bladblazers en hogedrukreiniger.',
  'chemicalProducts':
      'Ja – verven, oplosmiddelen, ontvetters, oliën, brandstoffen, spuitbussen, lijmen, mastieken en reinigingsproducten. Inventaris en VIB’s te controleren.',
  'manualHandling':
      'Ja – transport van gereedschap, lasten, zakken, kratten, materiaal, archieven, uitrusting en laden/lossen van voertuigen.',
  'vehiclePedestrianTraffic':
      'Ja – verplaatsingen met dienstvoertuigen, circulatie in de werkplaats, manoeuvres in de garage, interventies op de openbare weg en aanwezigheid van burgers.',
  'noise':
      'Ja – lawaai door machines, bladblazers, bosmaaiers, slijpmachines, zagen en hogedrukreiniger. Werkelijk niveau te beoordelen.',
  'fireRisk':
      'Ja – aanwezigheid van ontvlambare producten, brandstoffen, spuitbussen, elektrische uitrusting, opslag en werkplaats. Brandrisicoanalyse te controleren.',
  'loneWork':
      'Ja – occasionele interventies alleen in gebouwen of buitenruimten. Procedure te formaliseren.',
  'coactivity':
      'Ja – interventies in bezette gemeentelijke gebouwen, op de openbare weg, in openbare ruimten, aanwezigheid van burgers of onderaannemers.',
  'weatherConstraints':
      'Ja – regen, koude, hitte, wind, gladde oppervlakken en verminderde zichtbaarheid bij buitenwerk.',
  'newWorkers': 'Ja – veiligheidsintroductie en begeleiding te formaliseren.',
  'temporaryWorkers':
      'Mogelijk – onthaal, informatie over risico’s en begeleiding te voorzien.',
  'youngWorkers': 'Niet meegedeeld / te controleren.',
  'pregnantOrBreastfeedingWorkers':
      'Niet meegedeeld / te controleren. Specifieke analyse te voorzien indien van toepassing.',
  'medicalRestrictionsWorkers':
      'Niet meegedeeld / te controleren met de arbeidsarts, met respect voor vertrouwelijkheid.',
  'isolatedWorkers':
      'Ja – occasionele interventies alleen moeten georganiseerd en geregistreerd worden.',
  'subcontractors':
      'Ja – mogelijke aanwezigheid bij technische interventies of gespecialiseerde werken. Coördinatie te voorzien.',
  'cpptPresence':
      'Ja, CPBW aanwezig. Belangrijke acties moeten voor advies en opvolging worden voorgelegd.',
  'preventionService':
      'Interne preventiedienst aanwezig. Externe dienst te raadplegen voor gezondheidstoezicht, chemische risico’s, ergonomie, werken op hoogte, specifieke risico’s en aanvullend advies.',
  'feedAnnualActionPlan':
      'Ja – prioritaire acties opnemen in het Jaaractieplan: orde in de werkplaats, inventaris van chemische producten, opleiding manueel hanteren van lasten, controle ladders, instructies machines, signalisatie, alleenwerk.',
  'feedGlobalPreventionPlan':
      'Ja – structurele acties opnemen in het Globaal Preventieplan: PBM-beleid, opleidingsprogramma, beheer van gevaarlijke producten, organisatie van periodieke controles, verbetering van opslagzones, coördinatieprocedures.',
  'presentToCppt':
      'Ja – voorstelling aanbevolen aan het CPBW voor advies, prioritering, opvolging en traceerbaarheid.',
  'externalServiceValidation':
      'Ja – validatie of advies aanbevolen voor chemische risico’s, ergonomie, gezondheidstoezicht, werken op hoogte en specifieke aspecten.',
  'occupationalDoctorAdvice':
      'Ja, indien medische beperkingen, klachten over TMS, blootstelling aan gevaarlijke producten, lawaai, manueel hanteren van lasten of kwetsbare werknemers betrokken zijn. Te bevestigen volgens de individuele situaties.',
};

const _englishCompleteExample = <String, String>{
  'companyName': 'Municipal Administration of Verviers – Technical Department',
  'siteConcerned':
      'Municipal workshop of Verviers, storage areas, vehicle garage, technical rooms and interventions on municipal sites',
  'serviceConcerned':
      'Technical Department – maintenance of buildings, roads and public areas',
  'author': 'Internal prevention advisor – draft to be completed',
  'version': '1.0',
  'visitDate': '07/06/2026 – to be confirmed after site visit',
  'documentObjective':
      'Draft general risk assessment intended to support the Annual Action Plan, the Global Prevention Plan and preparation of a discussion with the health and safety committee.',
  'includedLocations':
      'Municipal workshop, vehicle garage, material storage area, hazardous products cabinet, technical rooms, municipal buildings, roads and green areas during interventions.',
  'excludedLocations':
      'Major construction sites carried out by external contractors, specialised interventions requiring a specific permit, high-voltage electrical works and emergency interventions by rescue services.',
  'concernedPositions':
      'Multi-skilled workers, road workers, gardeners, storekeeper, team leaders, workers occasionally working alone, new workers and possible temporary workers.',
  'concernedTasks':
      'Preparation of interventions, loading and unloading of materials, manual handling of loads, minor repairs, drilling, grinding, sawing, sanding, cleaning, maintenance of green areas, use of portable electric tools, interventions on public roads, storage management and travel with service vehicles.',
  'includedSituations':
      'Routine work, urgent interventions, cooperation with citizens or subcontractors, occasional lone work, outdoor work, workshop activities, travel between sites, manual handling of loads and use of chemical products.',
  'exposureDuration':
      'Variable exposure depending on teams. Use of tools and manual handling several times per week. Daily travel. Regular outdoor work for road workers and gardeners. The exact duration must be confirmed by field observation.',
  'workMode':
      'Mainly on-site work and outdoor interventions. Remote work is not applicable to workers, road workers and gardeners.',
  'fieldVisitDone':
      'To be checked – site visit to be planned with the prevention advisor and team leaders.',
  'jobObservationDone':
      'To be checked – observation recommended during a typical working day and during an outdoor intervention.',
  'workersConsulted':
      'To be checked – consultation recommended with multi-skilled workers, gardeners, road workers and the storekeeper.',
  'managementConsulted':
      'To be checked – consultation to be organised with team leaders and the head of the technical department.',
  'cpptConsulted':
      'Yes, health and safety committee present. The draft must be submitted to the committee for opinion and follow-up of priority actions.',
  'incidentRegisterAvailable':
      'To be checked – back pain, cuts, slips, near misses and noise complaints must be checked in the register or internal reports.',
  'photosAvailable':
      'Not communicated / to be checked – photos to be taken of the workshop, storage areas, circulation, hazardous products, racks, PPE, ladders and outdoor work areas.',
  'controlReportsAvailable':
      'To be checked – reports to be collected for ladders, stepladders, mobile scaffolds, fire extinguishers, vehicles and work equipment subject to inspection.',
  'technicalSheetsAvailable':
      'To be checked – technical sheets and user manuals for machines and tools must be centralised.',
  'safetyDataSheetsAvailable':
      'Partially available – inventory of chemical products and SDS must be updated.',
  'sector':
      'Municipal technical service / maintenance of buildings and public areas',
  'workerCount':
      '24 workers concerned: 14 multi-skilled workers, 4 road workers, 3 gardeners, 2 team leaders and 1 storekeeper.',
  'activity':
      'General maintenance works, minor repairs in municipal buildings, maintenance of public areas, interventions on public roads, manual handling of materials, storage management and travel with service vehicles.',
  'equipment':
      'Drills, screwdrivers, grinders, saws, sanders, high-pressure cleaner, compressor, extension cords, ladders, stepladders, small mobile scaffolds, lawnmowers, brush cutters, leaf blowers, service vehicles, manual pallet truck, hand truck, racks, storage cabinets, fire extinguishers and first-aid kit.',
  'dangerousProducts':
      'Paints, solvents, degreasers, oils, fuels, cleaning products, technical aerosols, glues, sealants, possible plant protection products to be checked, gas cartridges or gas cylinders depending on interventions.',
  'exposedWorkers':
      'Multi-skilled workers, road workers, gardeners, storekeeper, team leaders, new workers, possible temporary workers, workers occasionally working alone, workers with medical restrictions to be checked and subcontractors present on site.',
  'knownIncidents':
      'Back pain reported during manual handling, minor cuts during repairs, near miss caused by a cable on the workshop floor, slip in a wet area, complaint about machine noise, fatigue during urgent interventions and situations involving cooperation with citizens or subcontractors.',
  'constraints':
      'Variable and sometimes urgent interventions, work on multiple sites, presence of public or subcontractors, changing weather conditions, confined spaces, variable orderliness in the workshop, incomplete inventory of hazardous products, training on machines and work at height to be checked.',
  'additionalInformation':
      'The assessment must help prioritise prevention actions for the coming year: order and circulation in the workshop, inventory of chemical products, work instructions, inspection of ladders and stepladders, manual handling training, machine/tool training, organisation of lone work, PPE management, incident follow-up and consultation of the health and safety committee.',
  'writtenInstructions':
      'Some manufacturer manuals are available, but internal safety instructions are incomplete or need to be checked.',
  'completedTrainings':
      'Oral briefing by team leaders. Specific training on manual handling, machines, chemical products, work at height and road work signage must be checked.',
  'availablePpe':
      'Safety shoes, gloves, safety glasses, hearing protection, high-visibility clothing, rainwear, helmets or specific protection to be checked according to the tasks.',
  'periodicControls':
      'Periodic maintenance of some vehicles. Inspection of fire extinguishers to be checked. Inspection of ladders, stepladders, racks and small mobile scaffolds to be checked.',
  'availableEvidence':
      'First-aid kit visible, fire extinguishers present, some PPE available, some manufacturer manuals present. Training lists, inspection reports, workstation sheets and internal instructions must be completed or checked.',
  'oralMeasures':
      'Oral briefings, housekeeping practices, choice of PPE based on experience, manual handling instructions, organisation of lone work and management of urgent interventions.',
  'measuresToVerify':
      'Actual state of order and cleanliness, pedestrian and vehicle circulation, storage of chemical products, availability of SDS, conformity of ladders, actual wearing of PPE, temporary signage, organisation of lone work, condition of cables and extension cords.',
  'workAtHeight':
      'Yes – use of ladders, stepladders and small mobile scaffolds during repairs and interventions in buildings.',
  'dangerousMachines':
      'Yes – use of grinders, saws, drills, sanders, brush cutters, lawnmowers, leaf blowers and high-pressure cleaner.',
  'chemicalProducts':
      'Yes – paints, solvents, degreasers, oils, fuels, aerosols, glues, sealants and cleaning products. Inventory and SDS to be checked.',
  'manualHandling':
      'Yes – transport of tools, loads, bags, crates, materials, archives, equipment and loading/unloading of vehicles.',
  'vehiclePedestrianTraffic':
      'Yes – travel with service vehicles, circulation in the workshop, manoeuvres in the garage, interventions on public roads and presence of citizens.',
  'noise':
      'Yes – noise from machines, leaf blowers, brush cutters, grinders, saws and high-pressure cleaner. Actual level to be assessed.',
  'fireRisk':
      'Yes – presence of flammable products, fuels, aerosols, electrical equipment, storage and workshop. Fire risk assessment to be checked.',
  'loneWork':
      'Yes – occasional interventions alone in buildings or outdoor areas. Procedure to be formalised.',
  'coactivity':
      'Yes – interventions in occupied municipal buildings, on public roads, in public areas, presence of citizens or subcontractors.',
  'weatherConstraints':
      'Yes – rain, cold, heat, wind, slippery surfaces and reduced visibility during outdoor work.',
  'newWorkers': 'Yes – safety induction and supervision to be formalised.',
  'temporaryWorkers':
      'Possible – reception, risk information and supervision to be planned.',
  'youngWorkers': 'Not communicated / to be checked.',
  'pregnantOrBreastfeedingWorkers':
      'Not communicated / to be checked. Specific assessment to be carried out if applicable.',
  'medicalRestrictionsWorkers':
      'Not communicated / to be checked with the occupational physician, respecting confidentiality.',
  'isolatedWorkers':
      'Yes – occasional lone interventions must be organised and recorded.',
  'subcontractors':
      'Yes – possible presence during technical interventions or specialised works. Coordination to be planned.',
  'cpptPresence':
      'Yes, health and safety committee present. Important actions must be submitted for opinion and follow-up.',
  'preventionService':
      'Internal prevention service present. External service to be consulted for health surveillance, chemical risks, ergonomics, work at height, specific risks and additional advice.',
  'feedAnnualActionPlan':
      'Yes – priority actions to be included in the Annual Action Plan: workshop order, inventory of chemical products, manual handling training, ladder inspection, machine instructions, signage, lone work.',
  'feedGlobalPreventionPlan':
      'Yes – structural actions to be included in the Global Prevention Plan: PPE policy, training programme, hazardous products management, organisation of periodic inspections, improvement of storage areas, coordination procedures.',
  'presentToCppt':
      'Yes – presentation recommended to the committee for opinion, prioritisation, follow-up and traceability.',
  'externalServiceValidation':
      'Yes – validation or advice recommended for chemical risks, ergonomics, health surveillance, work at height and specific aspects.',
  'occupationalDoctorAdvice':
      'Yes, if medical restrictions, complaints about musculoskeletal disorders, exposure to hazardous products, noise, manual handling or vulnerable workers are involved. To be confirmed according to individual situations.',
};

const _germanCompleteExample = <String, String>{
  'companyName': 'Gemeindeverwaltung Verviers – Technischer Dienst',
  'siteConcerned':
      'Kommunale Werkstatt von Verviers, Lagerbereiche, Fahrzeuggarage, technische Räume und Einsätze auf kommunalen Standorten',
  'serviceConcerned':
      'Technischer Dienst – Instandhaltung von Gebäuden, Straßen und öffentlichen Bereichen',
  'author': 'Interner Präventionsberater – Entwurf zu vervollständigen',
  'version': '1.0',
  'visitDate': '07/06/2026 – nach der Vor-Ort-Besichtigung zu bestätigen',
  'documentObjective':
      'Entwurf einer allgemeinen Gefährdungsbeurteilung zur Unterstützung des Jährlichen Aktionsplans, des Globalen Präventionsplans und zur Vorbereitung einer Besprechung mit dem Ausschuss für Gefahrenverhütung und Schutz am Arbeitsplatz.',
  'includedLocations':
      'Kommunale Werkstatt, Fahrzeuggarage, Materiallagerbereich, Schrank für gefährliche Produkte, technische Räume, kommunale Gebäude, Straßen und Grünflächen während der Einsätze.',
  'excludedLocations':
      'Große Baustellen, die von externen Unternehmen durchgeführt werden, spezialisierte Einsätze mit besonderer Genehmigung, Hochspannungsarbeiten und Notfalleinsätze der Rettungsdienste.',
  'concernedPositions':
      'Mehrzweckarbeiter, Straßenarbeiter, Gärtner, Lagerverwalter, Teamleiter, Beschäftigte mit gelegentlicher Alleinarbeit, neue Beschäftigte und mögliche Zeitarbeitskräfte.',
  'concernedTasks':
      'Vorbereitung von Einsätzen, Be- und Entladen von Material, manuelles Heben und Tragen von Lasten, kleinere Reparaturen, Bohren, Schleifen, Sägen, Schmirgeln, Reinigen, Pflege von Grünflächen, Nutzung von tragbaren Elektrowerkzeugen, Arbeiten im öffentlichen Straßenraum, Lagerverwaltung und Fahrten mit Dienstfahrzeugen.',
  'includedSituations':
      'Routinetätigkeiten, dringende Einsätze, Zusammenarbeit mit Bürgern oder Subunternehmern, gelegentliche Alleinarbeit, Außenarbeiten, Werkstattarbeiten, Fahrten zwischen Standorten, manuelles Heben und Tragen von Lasten und Verwendung chemischer Produkte.',
  'exposureDuration':
      'Variable Exposition je nach Team. Nutzung von Werkzeugen und manuelles Heben mehrmals pro Woche. Tägliche Fahrten. Regelmäßige Außenarbeiten für Straßenarbeiter und Gärtner. Die genaue Dauer muss durch Beobachtung vor Ort bestätigt werden.',
  'workMode':
      'Überwiegend Arbeit vor Ort und Außeneinsätze. Telearbeit ist für Arbeiter, Straßenarbeiter und Gärtner nicht anwendbar.',
  'fieldVisitDone':
      'Zu prüfen – Vor-Ort-Besichtigung mit dem Präventionsberater und den Teamleitern zu planen.',
  'jobObservationDone':
      'Zu prüfen – Beobachtung während eines typischen Arbeitstages und während eines Außeneinsatzes empfohlen.',
  'workersConsulted':
      'Zu prüfen – Konsultation von Mehrzweckarbeitern, Gärtnern, Straßenarbeitern und Lagerverwalter empfohlen.',
  'managementConsulted':
      'Zu prüfen – Austausch mit Teamleitern und dem Verantwortlichen des technischen Dienstes vorzusehen.',
  'cpptConsulted':
      'Ja, Ausschuss für Gefahrenverhütung und Schutz am Arbeitsplatz vorhanden. Der Entwurf muss dem Ausschuss zur Stellungnahme und zur Nachverfolgung prioritärer Maßnahmen vorgelegt werden.',
  'incidentRegisterAvailable':
      'Zu prüfen – Rückenbeschwerden, Schnittverletzungen, Ausrutscher, Beinaheunfälle und Lärmbeschwerden müssen im Register oder in internen Meldungen geprüft werden.',
  'photosAvailable':
      'Nicht mitgeteilt / zu prüfen – Fotos von Werkstatt, Lagerbereichen, Verkehrswegen, gefährlichen Produkten, Regalen, PSA, Leitern und Außenarbeitsbereichen vorzusehen.',
  'controlReportsAvailable':
      'Zu prüfen – Berichte zu Leitern, Trittleitern, kleinen Fahrgerüsten, Feuerlöschern, Fahrzeugen und prüfpflichtigen Arbeitsmitteln sammeln.',
  'technicalSheetsAvailable':
      'Zu prüfen – technische Datenblätter und Bedienungsanleitungen von Maschinen und Werkzeugen zentralisieren.',
  'safetyDataSheetsAvailable':
      'Teilweise verfügbar – Inventar der chemischen Produkte und Sicherheitsdatenblätter aktualisieren.',
  'sector':
      'Kommunaler technischer Dienst / Instandhaltung von Gebäuden und öffentlichen Bereichen',
  'workerCount':
      '24 betroffene Beschäftigte: 14 Mehrzweckarbeiter, 4 Straßenarbeiter, 3 Gärtner, 2 Teamleiter und 1 Lagerverwalter.',
  'activity':
      'Allgemeine Instandhaltungsarbeiten, kleinere Reparaturen in kommunalen Gebäuden, Pflege öffentlicher Bereiche, Einsätze auf öffentlichen Straßen, manuelle Handhabung von Material, Lagerverwaltung und Fahrten mit Dienstfahrzeugen.',
  'equipment':
      'Bohrmaschinen, Schrauber, Schleifmaschinen, Sägen, Schwingschleifer, Hochdruckreiniger, Kompressor, Verlängerungskabel, Leitern, Trittleitern, kleine Fahrgerüste, Rasenmäher, Motorsensen, Laubbläser, Dienstfahrzeuge, Handhubwagen, Sackkarre, Regale, Lagerschränke, Feuerlöscher und Erste-Hilfe-Kasten.',
  'dangerousProducts':
      'Farben, Lösungsmittel, Entfetter, Öle, Kraftstoffe, Reinigungsmittel, technische Sprays, Klebstoffe, Dichtmassen, mögliche Pflanzenschutzmittel zu prüfen, Gaskartuschen oder Gasflaschen je nach Einsatz.',
  'exposedWorkers':
      'Mehrzweckarbeiter, Straßenarbeiter, Gärtner, Lagerverwalter, Teamleiter, neue Beschäftigte, mögliche Zeitarbeitskräfte, Beschäftigte mit gelegentlicher Alleinarbeit, Beschäftigte mit medizinischen Einschränkungen zu prüfen und anwesende Subunternehmer.',
  'knownIncidents':
      'Gemeldete Rückenbeschwerden beim Heben und Tragen, kleinere Schnittverletzungen bei Reparaturen, Beinaheunfall durch ein Kabel auf dem Werkstattboden, Ausrutschen in einem nassen Bereich, Beschwerde wegen Maschinenlärm, Müdigkeit bei dringenden Einsätzen und Situationen mit Bürgern oder Subunternehmern.',
  'constraints':
      'Variable und teilweise dringende Einsätze, Arbeit an mehreren Standorten, Anwesenheit von Öffentlichkeit oder Subunternehmern, wechselnde Wetterbedingungen, enge Räume, wechselnde Ordnung in der Werkstatt, unvollständiges Inventar gefährlicher Produkte, Schulung zu Maschinen und Arbeiten in der Höhe zu prüfen.',
  'additionalInformation':
      'Die Beurteilung soll helfen, Präventionsmaßnahmen für das kommende Jahr zu priorisieren: Ordnung und Verkehrswege in der Werkstatt, Inventar chemischer Produkte, Arbeitsanweisungen, Kontrolle von Leitern und Trittleitern, Schulung zum Heben und Tragen, Schulung zu Maschinen/Werkzeugen, Organisation der Alleinarbeit, PSA-Verwaltung, Nachverfolgung von Ereignissen und Konsultation des Ausschusses.',
  'writtenInstructions':
      'Einige Herstelleranleitungen sind verfügbar, interne Sicherheitsanweisungen sind jedoch unvollständig oder zu prüfen.',
  'completedTrainings':
      'Mündliche Einweisung durch Teamleiter. Spezifische Schulungen zu Heben und Tragen, Maschinen, chemischen Produkten, Arbeiten in der Höhe und Baustellensignalisierung sind zu prüfen.',
  'availablePpe':
      'Sicherheitsschuhe, Handschuhe, Schutzbrillen, Gehörschutz, Warnkleidung, Regenkleidung, Helme oder spezifische Schutzausrüstung je nach Tätigkeit zu prüfen.',
  'periodicControls':
      'Regelmäßige Wartung einiger Fahrzeuge. Prüfung der Feuerlöscher zu prüfen. Prüfung von Leitern, Trittleitern, Regalen und kleinen Fahrgerüsten zu prüfen.',
  'availableEvidence':
      'Erste-Hilfe-Kasten sichtbar, Feuerlöscher vorhanden, einige PSA verfügbar, einige Herstelleranleitungen vorhanden. Schulungslisten, Prüfberichte, Arbeitsplatzblätter und interne Anweisungen müssen ergänzt oder geprüft werden.',
  'oralMeasures':
      'Mündliche Einweisungen, Aufräumpraktiken, Auswahl der PSA auf Grundlage von Erfahrung, Anweisungen zum Heben und Tragen, Organisation von Alleinarbeit und Umgang mit dringenden Einsätzen.',
  'measuresToVerify':
      'Tatsächlicher Zustand von Ordnung und Sauberkeit, Fußgänger- und Fahrzeugverkehr, Lagerung chemischer Produkte, Verfügbarkeit von Sicherheitsdatenblättern, Konformität von Leitern, tatsächliches Tragen von PSA, temporäre Beschilderung, Organisation der Alleinarbeit, Zustand von Kabeln und Verlängerungen.',
  'workAtHeight':
      'Ja – Verwendung von Leitern, Trittleitern und kleinen Fahrgerüsten bei Reparaturen und Einsätzen in Gebäuden.',
  'dangerousMachines':
      'Ja – Verwendung von Schleifmaschinen, Sägen, Bohrmaschinen, Schwingschleifern, Motorsensen, Rasenmähern, Laubbläsern und Hochdruckreiniger.',
  'chemicalProducts':
      'Ja – Farben, Lösungsmittel, Entfetter, Öle, Kraftstoffe, Sprays, Klebstoffe, Dichtmassen und Reinigungsprodukte. Inventar und Sicherheitsdatenblätter zu prüfen.',
  'manualHandling':
      'Ja – Transport von Werkzeugen, Lasten, Säcken, Kisten, Material, Archiven, Ausrüstung und Be-/Entladen von Fahrzeugen.',
  'vehiclePedestrianTraffic':
      'Ja – Fahrten mit Dienstfahrzeugen, Verkehr in der Werkstatt, Rangieren in der Garage, Einsätze auf öffentlichen Straßen und Anwesenheit von Bürgern.',
  'noise':
      'Ja – Lärm durch Maschinen, Laubbläser, Motorsensen, Schleifmaschinen, Sägen und Hochdruckreiniger. Tatsächliches Niveau zu bewerten.',
  'fireRisk':
      'Ja – Vorhandensein von entzündlichen Produkten, Kraftstoffen, Sprays, elektrischer Ausrüstung, Lagerung und Werkstatt. Brandrisikobeurteilung zu prüfen.',
  'loneWork':
      'Ja – gelegentliche Einsätze allein in Gebäuden oder Außenbereichen. Verfahren zu formalisieren.',
  'coactivity':
      'Ja – Einsätze in genutzten kommunalen Gebäuden, auf öffentlichen Straßen, in öffentlichen Bereichen, Anwesenheit von Bürgern oder Subunternehmern.',
  'weatherConstraints':
      'Ja – Regen, Kälte, Hitze, Wind, rutschige Oberflächen und eingeschränkte Sicht bei Außenarbeiten.',
  'newWorkers': 'Ja – Sicherheitsunterweisung und Begleitung zu formalisieren.',
  'temporaryWorkers':
      'Möglich – Empfang, Risikoinformation und Begleitung vorzusehen.',
  'youngWorkers': 'Nicht mitgeteilt / zu prüfen.',
  'pregnantOrBreastfeedingWorkers':
      'Nicht mitgeteilt / zu prüfen. Spezifische Beurteilung vorzusehen, falls zutreffend.',
  'medicalRestrictionsWorkers':
      'Nicht mitgeteilt / zu prüfen mit dem Arbeitsmediziner, unter Wahrung der Vertraulichkeit.',
  'isolatedWorkers':
      'Ja – gelegentliche Alleineinsätze müssen organisiert und dokumentiert werden.',
  'subcontractors':
      'Ja – mögliche Anwesenheit bei technischen Einsätzen oder spezialisierten Arbeiten. Koordination vorzusehen.',
  'cpptPresence':
      'Ja, Ausschuss für Gefahrenverhütung und Schutz am Arbeitsplatz vorhanden. Wichtige Maßnahmen müssen zur Stellungnahme und Nachverfolgung vorgelegt werden.',
  'preventionService':
      'Interner Präventionsdienst vorhanden. Externer Dienst zu konsultieren für Gesundheitsüberwachung, chemische Risiken, Ergonomie, Arbeiten in der Höhe, spezifische Risiken und zusätzliche Beratung.',
  'feedAnnualActionPlan':
      'Ja – prioritäre Maßnahmen in den Jährlichen Aktionsplan aufnehmen: Ordnung in der Werkstatt, Inventar chemischer Produkte, Schulung zum Heben und Tragen, Leiterkontrolle, Maschinenanweisungen, Beschilderung, Alleinarbeit.',
  'feedGlobalPreventionPlan':
      'Ja – strukturelle Maßnahmen in den Globalen Präventionsplan aufnehmen: PSA-Politik, Schulungsprogramm, Verwaltung gefährlicher Produkte, Organisation regelmäßiger Prüfungen, Verbesserung der Lagerbereiche, Koordinationsverfahren.',
  'presentToCppt':
      'Ja – Vorstellung beim Ausschuss zur Stellungnahme, Priorisierung, Nachverfolgung und Rückverfolgbarkeit empfohlen.',
  'externalServiceValidation':
      'Ja – Validierung oder Beratung empfohlen für chemische Risiken, Ergonomie, Gesundheitsüberwachung, Arbeiten in der Höhe und spezifische Aspekte.',
  'occupationalDoctorAdvice':
      'Ja, wenn medizinische Einschränkungen, Beschwerden über Muskel-Skelett-Erkrankungen, Exposition gegenüber gefährlichen Produkten, Lärm, manuelles Heben oder schutzbedürftige Beschäftigte betroffen sind. Je nach Einzelfall zu bestätigen.',
};
