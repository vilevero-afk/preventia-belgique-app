import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../l10n/generated/app_localizations.dart';
import '../l10n/localized_strings.dart';
import '../l10n/pdf_texts.dart';
import '../models/document_form_data.dart';
import '../models/generation_source.dart';
import '../models/preventia_company_project.dart';
import '../models/preventia_project.dart'
    show PreventiaActionItem, PreventiaPiuItem, normalizeCompanyName;
import '../models/saved_document.dart';
import '../services/ai_document_service.dart';
import '../services/app_config_service.dart';
import '../services/company_piu_review_document_service.dart';
import '../services/docx_export_service.dart';
import '../services/file_export_service.dart';
import '../services/license_service.dart';
import '../services/local_document_storage.dart';
import '../services/pdf_delivery_service.dart';
import '../services/pdf_export_service.dart';
import '../services/preventia_document_storage_service.dart';
import '../services/preventia_company_project_service.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/simple_markdown_document_view.dart';
import 'result_screen.dart';

typedef PiuReviewWordExporter =
    Future<String?> Function(
      BuildContext context,
      PreventiaCompanyProject project,
      PreventiaCompanyDocument document,
    );

typedef PiuReviewPdfExporter =
    Future<String?> Function(
      BuildContext context,
      PreventiaCompanyProject project,
      PreventiaCompanyDocument document,
    );

class CompanyFolderDetailScreen extends StatefulWidget {
  const CompanyFolderDetailScreen({super.key, required this.companyKey});

  final String companyKey;

  @override
  State<CompanyFolderDetailScreen> createState() =>
      _CompanyFolderDetailScreenState();
}

const _companyProfileFields = {
  'companyName': 'Entreprise',
  'siteName': 'Site',
  'address': 'Adresse complète',
  'postalCode': 'Code postal',
  'city': 'Ville',
  'country': 'Pays',
  'siteContact': 'Personne de contact',
  'preventionAdvisor': 'Conseiller en prévention',
  'siteManager': 'Responsable site',
  'technicalServiceContact': 'Service technique',
  'generalPhone': 'Téléphone général',
  'generalEmail': 'E-mail général',
  'activityDescription': 'Activité',
  'riskProfile': 'Profil de risque',
  'numberOfWorkers': 'Travailleurs',
  'visitorsPresence': 'Visiteurs',
  'externalCompaniesPresence': 'Entreprises extérieures',
  'workingHours': 'Horaires',
};

String _formattedAddress(PreventiaCompanyProfile profile) {
  final parts = [
    profile.address,
    [
      profile.postalCode,
      profile.city,
    ].where((item) => item.isNotEmpty).join(' '),
    profile.country,
  ].where((item) => item.trim().isNotEmpty).join(', ');
  return parts;
}

class _CompanyFolderDetailScreenState extends State<CompanyFolderDetailScreen> {
  final _service = PreventiaCompanyProjectService();
  PreventiaCompanyProject? _project;
  List<SavedDocument> _legacyDocuments = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final project = await _service.findByKey(widget.companyKey);
    final allLegacyDocuments = await LocalDocumentStorage().loadDocuments();
    final companyName = project?.companyName ?? widget.companyKey;
    final companyKey = normalizeCompanyName(companyName);
    final legacyDocuments = allLegacyDocuments
        .where((document) {
          final searchable = normalizeCompanyName(
            '${document.title}\n${document.documentType}\n${document.content}',
          );
          final isRiskAssessment =
              searchable.contains('analyse') && searchable.contains('risque');
          return searchable.contains(companyKey) || isRiskAssessment;
        })
        .toList(growable: false);
    debugPrint(
      '[PreventIA] loaded company folder companyKey=${widget.companyKey} '
      'found=${project != null} analyses=${project?.analyses.length ?? 0} '
      'documents=${project?.documents.length ?? 0}',
    );
    if (!mounted) return;
    setState(() {
      _project = project;
      _legacyDocuments = legacyDocuments;
      _loading = false;
    });
  }

  Future<void> _confirmDelete() async {
    final companyName = _project?.companyName ?? widget.companyKey;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Supprimer le dossier $companyName ?'),
        content: const Text(
          'Cette action supprime uniquement le dossier de l’historique '
          'PreventIA. Aucun fichier de votre Mac ne sera supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer de l’historique'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteProjectFromHistory(widget.companyKey);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _openAnalysis(PreventiaCompanyDocument document) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          documentType: document.documentType,
          content: document.markdown,
          documentReference: document.reference,
          companyName: document.companyName,
          siteName: document.siteName,
          formData: document.formData,
          generationSource: GenerationSource.localFallback,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _exportAnalysisPdf(PreventiaCompanyDocument document) async {
    if (document.markdown.trim().isEmpty) {
      _showMessage('Aucun markdown sauvegardé pour cette analyse.');
      return;
    }
    final project = _project;
    final generatedAt = DateTime.now();
    final saved = await PdfDeliveryService.exportPdf(
      context: context,
      name: FileExportService.documentFileName(
        projectTitle: project?.companyName ?? document.companyName,
        documentType: document.documentType,
        languageCode: Localizations.localeOf(context).languageCode,
        referenceNumber: document.reference,
      ),
      projectDetails: _exportDetails(document),
      onLayout: (_) => PdfExportService.buildDocumentPdf(
        documentType: document.documentType,
        content: document.markdown,
        generatedAt: generatedAt,
        referenceNumber: document.reference,
        texts: pdfDocumentTexts(AppLocalizations.of(context)),
      ),
    );
    if (saved?.pdfPath?.isNotEmpty == true) {
      await _service.updateAnalysisExportPaths(
        companyKey: widget.companyKey,
        documentId: document.id,
        pdfPath: saved!.pdfPath,
      );
      if (mounted) await _load();
    }
  }

  Future<void> _exportAnalysisWord(PreventiaCompanyDocument document) async {
    if (document.markdown.trim().isEmpty) {
      _showMessage('Aucun markdown sauvegardé pour cette analyse.');
      return;
    }
    final bytes = DocxExportService.buildRiskAssessmentDocx(
      documentType: document.documentType,
      content: document.markdown,
      generatedAt: DateTime.now(),
      referenceNumber: document.reference,
    );
    final l10n = AppLocalizations.of(context);
    final saved = await FileExportService.saveDocxBytes(
      bytes: bytes,
      suggestedFileName: FileExportService.documentWordFileName(
        projectTitle: _project?.companyName ?? document.companyName,
        documentType: document.documentType,
        languageCode: Localizations.localeOf(context).languageCode,
        referenceNumber: document.reference,
      ),
      context: context,
      successMessage: l10n.wordDocumentGenerated,
      errorMessage: l10n.unableToGenerateWordDocument,
      projectDetails: _exportDetails(document),
    );
    if (saved?.wordPath?.isNotEmpty == true) {
      await _service.updateAnalysisExportPaths(
        companyKey: widget.companyKey,
        documentId: document.id,
        wordPath: saved!.wordPath,
      );
      if (mounted) await _load();
    }
  }

  ProjectExportDetails _exportDetails(PreventiaCompanyDocument document) =>
      ProjectExportDetails(
        documentType: document.documentType,
        title: document.title,
        reference: document.reference,
        language: Localizations.localeOf(context).languageCode,
        source: document.source,
        companyName: _project?.companyName ?? document.companyName,
        siteName: document.siteName,
        markdown: document.markdown,
        formData: document.formData,
        projectPath: _project?.localFolderPath,
      );

  Future<void> _openExistingPath(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return;
    final error = await PreventiaDocumentStorageService.openFolder(
      path.dirname(filePath),
    );
    if (error != null) _showMessage(error);
  }

  Future<void> _deleteAnalysis(PreventiaCompanyDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette analyse ?'),
        content: const Text(
          'Cette action supprime uniquement cette analyse du dossier PreventIA local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteAnalysis(widget.companyKey, document.id);
    if (mounted) await _load();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editCompanyProfile() async {
    final project = _project;
    if (project == null) return;
    final profile = project.companyProfile;
    final controllers = {
      'companyName': TextEditingController(text: profile.companyName),
      'siteName': TextEditingController(text: profile.siteName),
      'address': TextEditingController(text: profile.address),
      'postalCode': TextEditingController(text: profile.postalCode),
      'city': TextEditingController(text: profile.city),
      'country': TextEditingController(text: profile.country),
      'siteContact': TextEditingController(text: profile.siteContact),
      'preventionAdvisor': TextEditingController(
        text: profile.preventionAdvisor,
      ),
      'siteManager': TextEditingController(text: profile.siteManager),
      'technicalServiceContact': TextEditingController(
        text: profile.technicalServiceContact,
      ),
      'generalPhone': TextEditingController(text: profile.generalPhone),
      'generalEmail': TextEditingController(text: profile.generalEmail),
      'activityDescription': TextEditingController(
        text: profile.activityDescription,
      ),
      'riskProfile': TextEditingController(text: profile.riskProfile),
      'numberOfWorkers': TextEditingController(text: profile.numberOfWorkers),
      'visitorsPresence': TextEditingController(text: profile.visitorsPresence),
      'externalCompaniesPresence': TextEditingController(
        text: profile.externalCompaniesPresence,
      ),
      'workingHours': TextEditingController(text: profile.workingHours),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier les informations société'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _companyProfileFields.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: controllers[entry.key],
                        maxLines:
                            entry.key == 'activityDescription' ||
                                entry.key == 'externalCompaniesPresence'
                            ? 3
                            : 1,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: entry.value,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await _service.updateCompanyProfile(
        companyKey: project.companyKey,
        profile: PreventiaCompanyProfile(
          companyName: controllers['companyName']!.text,
          siteName: controllers['siteName']!.text,
          address: controllers['address']!.text,
          postalCode: controllers['postalCode']!.text,
          city: controllers['city']!.text,
          country: controllers['country']!.text,
          siteContact: controllers['siteContact']!.text,
          preventionAdvisor: controllers['preventionAdvisor']!.text,
          siteManager: controllers['siteManager']!.text,
          technicalServiceContact: controllers['technicalServiceContact']!.text,
          generalPhone: controllers['generalPhone']!.text,
          generalEmail: controllers['generalEmail']!.text,
          activityDescription: controllers['activityDescription']!.text,
          riskProfile: controllers['riskProfile']!.text,
          numberOfWorkers: controllers['numberOfWorkers']!.text,
          visitorsPresence: controllers['visitorsPresence']!.text,
          externalCompaniesPresence:
              controllers['externalCompaniesPresence']!.text,
          workingHours: controllers['workingHours']!.text,
        ),
      );
      if (mounted) await _load();
    }
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  void _openLegacyDocument(SavedDocument document) {
    _openDocument(title: document.title, content: document.content);
  }

  void _openDocument({required String title, required String content}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: AdaptivePage(
            child: SingleChildScrollView(
              child: SimpleMarkdownDocumentView(content: content),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _project ?? _emptyProject();
    final companyName = project.companyName;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('company-folder-detail-back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Dossier PreventIA — $companyName'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AdaptivePage(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _companyProfileSection(project),
                    _preventionDossierSummarySection(project),
                    _section(
                      title: 'Analyses de risques',
                      emptyMessage:
                          'Aucune analyse de risques enregistrée dans ce dossier.',
                      children: project.analyses.map(_analysisCard),
                    ),
                    _automaticSection(
                      title: 'PIU',
                      document: project.piuDocument,
                      emptyMessage: 'PIU non créé.',
                      onOpen: () => _openPiu(project),
                    ),
                    _automaticSection(
                      title: 'PGA/PAA/PGP',
                      document: project.pgaDocument,
                      emptyMessage: 'PGA/PAA/PGP non créé.',
                      candidateCount: project.actionItems.length,
                      onOpen: () => _openPga(project),
                    ),
                    _section(
                      title: 'Actions extraites',
                      emptyMessage: 'Aucune action extraite pour l’instant.',
                      children: project.actionItems.map(
                        (item) => ListTile(
                          title: Text(item.action),
                          subtitle: Text('Statut : ${item.status}'),
                        ),
                      ),
                    ),
                    _section(
                      title: 'Candidats PIU',
                      emptyMessage: 'Aucun point PIU extrait pour l’instant.',
                      children: project.piuItems.map(
                        (item) => ListTile(
                          title: Text(item.emergencyTopic),
                          subtitle: Text('Statut : ${item.status}'),
                        ),
                      ),
                    ),
                    _section(
                      title: 'Candidats DIU',
                      emptyMessage: 'Aucun point DIU extrait pour l’instant.',
                      children: project.diuItems.map(
                        (item) => ListTile(
                          title: Text(item.riskOrConstraint),
                          subtitle: Text('Statut : ${item.status}'),
                        ),
                      ),
                    ),
                    _section(
                      title: 'Preuves/photos',
                      emptyMessage:
                          'Aucune preuve/photo à collecter pour l’instant.',
                      children: project.evidenceItems.map(
                        (item) => ListTile(
                          title: Text(item.label),
                          subtitle: Text('Statut : ${item.status}'),
                        ),
                      ),
                    ),
                    _section(
                      title: 'Documents bruts / anciens documents',
                      emptyMessage: 'Aucun ancien document correspondant.',
                      children: _legacyDocuments.map(
                        (document) => ListTile(
                          title: Text(document.title),
                          subtitle: Text(document.documentType),
                          trailing: TextButton(
                            onPressed: () => _openLegacyDocument(document),
                            child: const Text('Ouvrir'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('delete-company-folder-button'),
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer ce dossier de l’historique'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _automaticSection({
    required String title,
    required PreventiaCompanyDocument? document,
    required String emptyMessage,
    required VoidCallback onOpen,
    int? candidateCount,
  }) => _section(
    title: title,
    emptyMessage: emptyMessage,
    children: document == null
        ? const []
        : [
            ListTile(
              title: Text(document.title),
              subtitle: Text(
                'Statut : ${document.status}'
                '${candidateCount == null ? '' : '\nActions candidates : $candidateCount'}',
              ),
              trailing: TextButton(
                onPressed: onOpen,
                child: const Text('Ouvrir / Générer'),
              ),
            ),
          ],
  );

  Widget _analysisCard(PreventiaCompanyDocument document) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(document.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Référence : ${document.reference.isEmpty ? '—' : document.reference}\n'
              'Date : ${_date(document.createdAt)}\n'
              'Type : ${document.documentType}\n'
              'Site : ${document.siteName.isEmpty ? '—' : document.siteName}',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _openAnalysis(document),
                  child: const Text('Ouvrir'),
                ),
                OutlinedButton(
                  onPressed: () => _exportAnalysisPdf(document),
                  child: const Text('Exporter PDF'),
                ),
                OutlinedButton(
                  onPressed: () => _exportAnalysisWord(document),
                  child: const Text('Télécharger Word'),
                ),
                if (document.pdfPath?.isNotEmpty == true)
                  TextButton(
                    onPressed: () => _openExistingPath(document.pdfPath),
                    child: const Text('Ouvrir PDF'),
                  ),
                if (document.wordPath?.isNotEmpty == true)
                  TextButton(
                    onPressed: () => _openExistingPath(document.wordPath),
                    child: const Text('Ouvrir Word'),
                  ),
                TextButton(
                  onPressed: () => _deleteAnalysis(document),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _companyProfileSection(PreventiaCompanyProject project) {
    final profile = project.companyProfile;
    return _section(
      title: 'Informations société',
      emptyMessage: '',
      children: [
        _infoTile('Entreprise', profile.companyName),
        _infoTile('Site', profile.siteName),
        _infoTile('Adresse', _formattedAddress(profile)),
        _infoTile('Conseiller en prévention', profile.preventionAdvisor),
        _infoTile('Personne de contact', profile.siteContact),
        _infoTile('Responsable site', profile.siteManager),
        _infoTile('Service technique', profile.technicalServiceContact),
        _infoTile('Activité', profile.activityDescription),
        _infoTile('Profil de risque', profile.riskProfile),
        _infoTile('Travailleurs', profile.numberOfWorkers),
        _infoTile('Visiteurs', profile.visitorsPresence),
        _infoTile('Entreprises extérieures', profile.externalCompaniesPresence),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _editCompanyProfile,
            child: const Text('Modifier les informations société'),
          ),
        ),
      ],
    );
  }

  Widget _preventionDossierSummarySection(PreventiaCompanyProject project) {
    final profile = project.companyProfile;
    final newItemsToValidate =
        project.piuItems
            .where(
              (item) =>
                  _statusKey(item.status) == 'a valider' &&
                  classifyReviewCandidate(item).shouldReview,
            )
            .length +
        project.actionItems
            .where(
              (item) =>
                  _statusKey(item.status) == 'a valider' &&
                  classifyReviewCandidate(item).shouldReview,
            )
            .length +
        project.evidenceItems
            .where(
              (item) =>
                  _statusKey(item.status) == 'a valider' &&
                  classifyReviewCandidate(item).shouldReview,
            )
            .length;
    final validatedPiu = project.piuItems
        .where(
          (item) =>
              _statusKey(item.status) == 'valide' &&
              classifyReviewCandidate(item).destination == 'piu',
        )
        .length;
    final validatedPga = project.actionItems
        .where(
          (item) =>
              _statusKey(item.status) == 'valide' &&
              classifyReviewCandidate(item).destination == 'pgp',
        )
        .length;
    return _section(
      title: 'Synthèse dossier prévention',
      emptyMessage: '',
      children: [
        _infoTile('Profil de risque', profile.riskProfile),
        _infoTile('Analyses sources', project.analyses.length.toString()),
        _infoTile('Nouveaux éléments à valider', newItemsToValidate.toString()),
        _infoTile('Points PIU validés', validatedPiu.toString()),
        _infoTile('Actions PGA validées', validatedPga.toString()),
        _infoTile('Candidats PIU', project.piuItems.length.toString()),
        _infoTile('Candidats PGP/PAA', project.actionItems.length.toString()),
        _infoTile('Points DIU', project.diuItems.length.toString()),
        _infoTile('Preuves à obtenir', project.evidenceItems.length.toString()),
        _infoTile(
          'Points à vérifier',
          project.pointsToVerify.length.toString(),
        ),
        _infoTile(
          'Validations nécessaires',
          project.requiredValidations.length.toString(),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Ces éléments constituent une aide au conseiller en prévention. '
            'Ils doivent être vérifiés, complétés et validés avant utilisation.',
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label : ${value.trim().isEmpty ? '[à compléter]' : value}'),
    );
  }

  Future<void> _openPiu(PreventiaCompanyProject project) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanyPiuScreen(companyKey: project.companyKey),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openPga(PreventiaCompanyProject project) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanyPgaScreen(companyKey: project.companyKey),
      ),
    );
    if (mounted) await _load();
  }

  Widget _section({
    required String title,
    required Iterable<Widget> children,
    required String emptyMessage,
  }) {
    final values = children.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (values.isEmpty) Text(emptyMessage) else ...values,
          ],
        ),
      ),
    );
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  PreventiaCompanyProject _emptyProject() {
    final now = DateTime.now();
    final companyName = widget.companyKey.trim().isEmpty
        ? 'Société'
        : widget.companyKey;
    return PreventiaCompanyProject(
      id: widget.companyKey,
      companyName: companyName,
      companyKey: widget.companyKey,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class CompanyPiuScreen extends StatefulWidget {
  const CompanyPiuScreen({
    super.key,
    required this.companyKey,
    this.piuReviewWordExporter,
    this.piuReviewPdfExporter,
  });

  final String companyKey;
  final PiuReviewWordExporter? piuReviewWordExporter;
  final PiuReviewPdfExporter? piuReviewPdfExporter;

  @override
  State<CompanyPiuScreen> createState() => _CompanyPiuScreenState();
}

class _CompanyPiuScreenState extends State<CompanyPiuScreen> {
  final _service = PreventiaCompanyProjectService();
  PreventiaCompanyProject? _project;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final project = await _service.findByKey(widget.companyKey);
    if (!mounted) return;
    setState(() {
      _project = project;
      _loading = false;
    });
  }

  Future<void> _setStatus(PreventiaPiuItem item, String status) async {
    await _service.updatePiuStatus(
      companyKey: widget.companyKey,
      itemId: item.id,
      status: status,
    );
    await _load();
  }

  Future<void> _generate({required bool withValidatedItems}) async {
    final project = _project;
    if (project == null) return;
    if (withValidatedItems &&
        project.piuItems
            .where(
              (item) =>
                  item.status == 'validé' &&
                  classifyReviewCandidate(item).destination == 'piu',
            )
            .isEmpty) {
      await _dialog(
        'Aucun élément PIU validé. Validez d’abord des points candidats ou générez un modèle vierge.',
      );
      return;
    }
    if (!await _shouldCreateVersion(project.piuDocument)) return;
    final formData = withValidatedItems
        ? _service.buildPiuGenerationFormData(project)
        : _blankPiuGenerationFormData(project);
    final backendMarkdown = await _generatePiuBackendMarkdown(
      project: project,
      formData: formData,
    );
    final updated = await _service.generatePiuDocument(
      companyKey: widget.companyKey,
      withValidatedItems: withValidatedItems,
      markdown: backendMarkdown,
      formData: formData,
      source: backendMarkdown == null
          ? 'company-folder-local'
          : 'company-folder-backend',
    );
    await _load();
    final document = updated?.piuDocument;
    if (mounted && updated != null && document != null) {
      await _openPreview(updated, document);
    }
  }

  Future<String?> _generatePiuBackendMarkdown({
    required PreventiaCompanyProject project,
    required Map<String, dynamic> formData,
  }) async {
    final l10n = AppLocalizations.of(context);
    final settings = await AppConfigService().loadAiSettings();
    if (!settings.useAiIfAvailable) return null;
    try {
      final licenseService = LicenseService(backendUrl: settings.backendUrl);
      await licenseService.validateGeneration('Plan Interne d’Urgence');
      final result = await AiDocumentService(licenseService: licenseService)
          .generateDocument(
            backendUrl: settings.backendUrl,
            data: _companyDocumentFormData(
              documentType: 'Plan Interne d’Urgence',
              project: project,
              formData: formData,
            ),
            languageCode: l10n.localeName,
            languageLabel: l10n.languageLabel,
          );
      return result.content;
    } on Object catch (error) {
      if (mounted) _message(error.toString());
      return null;
    }
  }

  Future<bool> _shouldCreateVersion(PreventiaCompanyDocument? document) async {
    if (document == null || document.markdown.trim().isEmpty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Créer une nouvelle version ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Créer une nouvelle version'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _exportPdf() async {
    final document = _project?.piuDocument;
    if (document == null || document.markdown.trim().isEmpty) {
      _message('Générez d’abord le PIU.');
      return;
    }
    final saved = await _exportCompanyDocumentPdf(context, _project!, document);
    if (saved?.pdfPath?.isNotEmpty == true) {
      await _service.updateGeneratedDocumentExportPaths(
        companyKey: widget.companyKey,
        documentId: document.id,
        pdfPath: saved!.pdfPath,
      );
      await _load();
      _message('PIU exporté dans : ${saved.pdfPath}');
    }
  }

  Future<void> _exportWord() async {
    final document = _project?.piuDocument;
    if (document == null || document.markdown.trim().isEmpty) {
      _message('Générez d’abord le PIU.');
      return;
    }
    final saved = await _exportCompanyDocumentWord(
      context,
      _project!,
      document,
    );
    if (saved?.wordPath?.isNotEmpty == true) {
      await _service.updateGeneratedDocumentExportPaths(
        companyKey: widget.companyKey,
        documentId: document.id,
        wordPath: saved!.wordPath,
      );
      await _load();
      _message('PIU exporté dans : ${saved.wordPath}');
    }
  }

  PreventiaCompanyDocument _reviewDocument() {
    final now = DateTime.now();
    final profile = _resolvedProfile(_project!);
    return PreventiaCompanyDocument(
      id: 'piu-review-${now.millisecondsSinceEpoch}',
      documentType: 'Revue PIU à valider',
      title: 'Revue des éléments PIU à valider — ${_project!.companyName}',
      status: 'revue locale',
      createdAt: now,
      autoCreated: false,
      source: 'company-folder-local-review',
      markdown: CompanyPiuReviewDocumentService.buildPiuReviewMarkdown(
        _project!,
      ),
      reference: 'REV-PIU-${now.millisecondsSinceEpoch}',
      companyName: _project!.companyName,
      siteName: profile.siteName,
      formData: {
        ...profile.toJson(),
        'source': 'company-folder-local-review',
        'backendGeneration': false,
      },
    );
  }

  bool _hasPiuReviewItems(PreventiaCompanyProject project) {
    return project.piuItems.any((item) {
      final status = normalizeCompanyName(item.status);
      return classifyReviewCandidate(item).shouldReview &&
          (status == 'a valider' || status == 'a revoir');
    });
  }

  Future<void> _downloadPiuReviewPdf() async {
    final project = _project;
    if (project == null) return;
    if (!_hasPiuReviewItems(project)) {
      _message('Aucun élément PIU à exporter.');
      return;
    }
    final document = _reviewDocument();
    if (document.markdown.trim().isEmpty) {
      _message('Aucun élément PIU à exporter.');
      return;
    }
    try {
      final path =
          await (widget.piuReviewPdfExporter?.call(
                context,
                project,
                document,
              ) ??
              _writePiuReviewPdf(context, project, document));
      if (path?.trim().isNotEmpty == true) {
        _message('Document PDF généré : $path');
      }
    } on Object catch (error) {
      _message('Erreur lors de la génération PDF : $error');
    }
  }

  Future<void> _downloadPiuReviewWord() async {
    final project = _project;
    if (project == null) return;
    if (!_hasPiuReviewItems(project)) {
      _message('Aucun élément PIU à exporter.');
      return;
    }
    final document = _reviewDocument();
    if (document.markdown.trim().isEmpty) {
      _message('Aucun élément PIU à exporter.');
      return;
    }
    try {
      final path =
          await (widget.piuReviewWordExporter?.call(
                context,
                project,
                document,
              ) ??
              _writePiuReviewWord(context, project, document));
      if (path?.trim().isNotEmpty == true) {
        _message('Document Word généré : $path');
      }
    } on Object catch (error) {
      _message('Erreur lors de la génération Word : $error');
    }
  }

  Future<void> _dialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPreview(
    PreventiaCompanyProject project,
    PreventiaCompanyDocument document,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GeneratedCompanyDocumentPreviewScreen(
          project: project,
          document: document,
        ),
      ),
    );
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    return Scaffold(
      appBar: AppBar(title: Text('PIU — ${project?.companyName ?? ''}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : project == null
          ? const Center(child: Text('Dossier société introuvable.'))
          : AdaptivePage(
              child: ListView(
                children: [
                  _statusSection(project.piuDocument),
                  _piuInfoSection(project),
                  _piuItemsSection(
                    title: 'Points à revoir',
                    items: project.piuItems
                        .where((item) => _statusKey(item.status) == 'a revoir')
                        .toList(),
                    project: project,
                  ),
                  _piuItemsSection(
                    title: 'Points validés',
                    items: project.piuItems
                        .where((item) => _statusKey(item.status) == 'valide')
                        .toList(),
                    project: project,
                  ),
                  _piuItemsSection(
                    title: 'Points ignorés',
                    items: project.piuItems
                        .where((item) => _statusKey(item.status) == 'ignore')
                        .toList(),
                    project: project,
                  ),
                  _generationSection(
                    blankLabel: 'Générer PIU vierge',
                    validatedLabel: 'Générer PIU avec éléments validés',
                    onBlank: () => _generate(withValidatedItems: false),
                    onValidated: () => _generate(withValidatedItems: true),
                    onPdf: _exportPdf,
                    onWord: _exportWord,
                    finalExportHint:
                        'Ces boutons concernent le document PIU final généré.',
                    pdfLabel: 'Exporter PDF — PIU généré',
                    wordLabel: 'Télécharger Word — PIU généré',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _piuInfoSection(PreventiaCompanyProject project) {
    final pendingItems = project.piuItems
        .where((item) => _statusKey(item.status) == 'a valider')
        .toList();
    final items = pendingItems
        .where((item) => classifyReviewCandidate(item).shouldReview)
        .toList();
    final automaticCount = pendingItems.length - items.length;
    return _folderSection(
      context: context,
      title:
          'Informations issues des analyses de risques — À valider : ${items.length}',
      emptyMessage:
          'Aucun point PIU issu des analyses de risques pour l’instant.',
      children: [
        const Text(
          'Ces boutons servent à relire les éléments candidats avant validation.',
        ),
        const SizedBox(height: 8),
        if (automaticCount > 0) ...[
          Text('Éléments classés automatiquement : $automaticCount'),
          const SizedBox(height: 8),
        ],
        _reviewExportButtons(
          onWord: _downloadPiuReviewWord,
          onPdf: _downloadPiuReviewPdf,
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('Aucun point PIU à valider.')
        else
          ...items.map((item) => _piuTile(project: project, item: item)),
      ],
    );
  }

  Widget _piuItemsSection({
    required String title,
    required List<PreventiaPiuItem> items,
    required PreventiaCompanyProject project,
    Widget? header,
  }) {
    return _folderSection(
      context: context,
      title: '$title : ${items.length}',
      emptyMessage: 'Aucun point dans cette catégorie.',
      children: [
        ?header,
        ...items.map((item) => _piuTile(project: project, item: item)),
      ],
    );
  }

  Widget _piuTile({
    required PreventiaCompanyProject project,
    required PreventiaPiuItem item,
  }) {
    final source = _sourceDocument(project, item.sourceDocumentId);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(item.emergencyTopic),
        subtitle: Text(
          '${item.information}\n'
          'Source : ${source?.documentType ?? '—'} ${source?.reference ?? ''}\n'
          'Chapitre suggéré : ${_chapterSuggestion(item.emergencyTopic)}\n'
          'Statut : ${item.status}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          children: [
            TextButton(
              onPressed: () => _setStatus(item, 'validé'),
              child: const Text('Valider'),
            ),
            TextButton(
              onPressed: () => _setStatus(item, 'à revoir'),
              child: const Text('À revoir'),
            ),
            TextButton(
              onPressed: () => _setStatus(item, 'ignoré'),
              child: const Text('Ignorer'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ActionFilter { all, pending, validated, ignored }

class CompanyPgaScreen extends StatefulWidget {
  const CompanyPgaScreen({super.key, required this.companyKey});

  final String companyKey;

  @override
  State<CompanyPgaScreen> createState() => _CompanyPgaScreenState();
}

class _CompanyPgaScreenState extends State<CompanyPgaScreen> {
  final _service = PreventiaCompanyProjectService();
  PreventiaCompanyProject? _project;
  _ActionFilter _filter = _ActionFilter.pending;
  int _visibleCount = 50;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final project = await _service.findByKey(widget.companyKey);
    if (!mounted) return;
    setState(() {
      _project = project;
      _loading = false;
    });
  }

  Future<void> _setStatus(PreventiaActionItem item, String status) async {
    await _service.updateActionStatus(
      companyKey: widget.companyKey,
      itemId: item.id,
      status: status,
    );
    await _load();
  }

  Future<void> _generate({required bool withValidatedActions}) async {
    final project = _project;
    if (project == null) return;
    if (withValidatedActions &&
        project.actionItems
            .where(
              (item) =>
                  item.status == 'validé' &&
                  classifyReviewCandidate(item).destination == 'pgp',
            )
            .isEmpty) {
      await _dialog(
        'Aucune action validée. Validez d’abord des actions candidates ou générez un modèle vierge.',
      );
      return;
    }
    if (!await _shouldCreateVersion(project.pgaDocument)) return;
    final updated = await _service.generatePgaDocument(
      companyKey: widget.companyKey,
      withValidatedActions: withValidatedActions,
      formData: withValidatedActions
          ? _service.buildPgaGenerationFormData(project)
          : _blankPgaGenerationFormData(project),
      source: 'company-folder',
    );
    await _load();
    final document = updated?.pgaDocument;
    if (mounted && updated != null && document != null) {
      await _openPreview(updated, document);
    }
  }

  Future<bool> _shouldCreateVersion(PreventiaCompanyDocument? document) async {
    if (document == null || document.markdown.trim().isEmpty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Créer une nouvelle version ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Créer une nouvelle version'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _exportPdf() async {
    final document = _project?.pgaDocument;
    if (document == null || document.markdown.trim().isEmpty) {
      _message('Générez d’abord le PGA/PAA/PGP.');
      return;
    }
    final saved = await _exportCompanyDocumentPdf(context, _project!, document);
    if (saved?.pdfPath?.isNotEmpty == true) {
      await _service.updateGeneratedDocumentExportPaths(
        companyKey: widget.companyKey,
        documentId: document.id,
        pdfPath: saved!.pdfPath,
      );
      await _load();
      _message('PGA/PAA/PGP exporté dans : ${saved.pdfPath}');
    }
  }

  Future<void> _exportWord() async {
    final document = _project?.pgaDocument;
    if (document == null || document.markdown.trim().isEmpty) {
      _message('Générez d’abord le PGA/PAA/PGP.');
      return;
    }
    final saved = await _exportCompanyDocumentWord(
      context,
      _project!,
      document,
    );
    if (saved?.wordPath?.isNotEmpty == true) {
      await _service.updateGeneratedDocumentExportPaths(
        companyKey: widget.companyKey,
        documentId: document.id,
        wordPath: saved!.wordPath,
      );
      await _load();
      _message('PGA/PAA/PGP exporté dans : ${saved.wordPath}');
    }
  }

  PreventiaCompanyDocument _reviewDocument() {
    final now = DateTime.now();
    final profile = _resolvedProfile(_project!);
    return PreventiaCompanyDocument(
      id: 'pgp-review-${now.millisecondsSinceEpoch}',
      documentType: 'Revue PGP/PAA à valider',
      title: 'Revue des actions PGP/PAA à valider — ${_project!.companyName}',
      status: 'revue locale',
      createdAt: now,
      autoCreated: false,
      source: 'company-folder-local-review',
      markdown: buildPgpReviewMarkdown(_project!),
      reference: 'REV-PGP-PAA-${now.millisecondsSinceEpoch}',
      companyName: _project!.companyName,
      siteName: profile.siteName,
      formData: {
        ...profile.toJson(),
        'source': 'company-folder-local-review',
        'backendGeneration': false,
      },
    );
  }

  Future<void> _exportReviewPdf() async {
    final project = _project;
    if (project == null) return;
    final document = _reviewDocument();
    final saved = await _exportCompanyDocumentPdf(context, project, document);
    if (saved?.pdfPath?.isNotEmpty == true) {
      _message('Revue PGP/PAA exportée dans : ${saved!.pdfPath}');
    }
  }

  Future<void> _exportReviewWord() async {
    final project = _project;
    if (project == null) return;
    final document = _reviewDocument();
    final saved = await _exportCompanyDocumentWord(context, project, document);
    if (saved?.wordPath?.isNotEmpty == true) {
      _message('Revue PGP/PAA exportée dans : ${saved!.wordPath}');
    }
  }

  Future<void> _dialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPreview(
    PreventiaCompanyProject project,
    PreventiaCompanyDocument document,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GeneratedCompanyDocumentPreviewScreen(
          project: project,
          document: document,
        ),
      ),
    );
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    return Scaffold(
      appBar: AppBar(
        title: Text('PGA/PAA/PGP — ${project?.companyName ?? ''}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : project == null
          ? const Center(child: Text('Dossier société introuvable.'))
          : AdaptivePage(
              child: ListView(
                children: [
                  _statusSection(project.pgaDocument),
                  _actionsSection(project),
                  _actionSummarySection(
                    title: 'Actions à revoir',
                    items: project.actionItems
                        .where((item) => _statusKey(item.status) == 'a revoir')
                        .toList(),
                    project: project,
                  ),
                  _actionSummarySection(
                    title: 'Actions validées',
                    items: project.actionItems
                        .where((item) => _statusKey(item.status) == 'valide')
                        .toList(),
                    project: project,
                  ),
                  _actionSummarySection(
                    title: 'Actions ignorées',
                    items: project.actionItems
                        .where((item) => _statusKey(item.status) == 'ignore')
                        .toList(),
                    project: project,
                  ),
                  _generationSection(
                    blankLabel: 'Générer PGA/PAA/PGP vierge',
                    validatedLabel: 'Générer avec actions validées',
                    onBlank: () => _generate(withValidatedActions: false),
                    onValidated: () => _generate(withValidatedActions: true),
                    onPdf: _exportPdf,
                    onWord: _exportWord,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _actionsSection(PreventiaCompanyProject project) {
    final filtered = _filtered(project.actionItems);
    final visible = filtered.take(_visibleCount).toList();
    final automaticCount = project.actionItems
        .where(
          (item) =>
              _statusKey(item.status) == 'a valider' &&
              !classifyReviewCandidate(item).shouldReview,
        )
        .length;
    return _folderSection(
      context: context,
      title: 'Actions issues des analyses de risques',
      emptyMessage: 'Aucune action extraite pour l’instant.',
      children: [
        _reviewExportButtons(
          onWord: _exportReviewWord,
          onPdf: _exportReviewPdf,
          wordLabel: 'Télécharger Word — actions à valider',
          pdfLabel: 'Exporter PDF — actions à valider',
        ),
        const SizedBox(height: 8),
        if (automaticCount > 0) ...[
          Text('Éléments classés automatiquement : $automaticCount'),
          const SizedBox(height: 8),
        ],
        SegmentedButton<_ActionFilter>(
          segments: const [
            ButtonSegment(value: _ActionFilter.all, label: Text('Tous')),
            ButtonSegment(
              value: _ActionFilter.pending,
              label: Text('À valider'),
            ),
            ButtonSegment(
              value: _ActionFilter.validated,
              label: Text('Validés'),
            ),
            ButtonSegment(value: _ActionFilter.ignored, label: Text('Ignorés')),
          ],
          selected: {_filter},
          onSelectionChanged: (value) {
            setState(() {
              _filter = value.single;
              _visibleCount = 50;
            });
          },
        ),
        const SizedBox(height: 8),
        ...visible.map((item) => _actionTile(project: project, item: item)),
        if (filtered.length > visible.length)
          TextButton(
            onPressed: () => setState(() => _visibleCount += 50),
            child: const Text('Afficher plus'),
          ),
      ],
    );
  }

  List<PreventiaActionItem> _filtered(List<PreventiaActionItem> items) {
    return switch (_filter) {
      _ActionFilter.all => items,
      _ActionFilter.pending =>
        items
            .where(
              (item) =>
                  _statusKey(item.status) == 'a valider' &&
                  classifyReviewCandidate(item).shouldReview,
            )
            .toList(),
      _ActionFilter.validated =>
        items.where((item) => _statusKey(item.status) == 'valide').toList(),
      _ActionFilter.ignored =>
        items.where((item) => _statusKey(item.status) == 'ignore').toList(),
    };
  }

  Widget _actionSummarySection({
    required String title,
    required List<PreventiaActionItem> items,
    required PreventiaCompanyProject project,
  }) {
    return _folderSection(
      context: context,
      title: title,
      emptyMessage: 'Aucune action dans cette catégorie.',
      children: items
          .take(50)
          .map((item) => _actionTile(project: project, item: item))
          .toList(),
    );
  }

  Widget _actionTile({
    required PreventiaCompanyProject project,
    required PreventiaActionItem item,
  }) {
    final source = _sourceDocument(project, item.sourceDocumentId);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(item.action),
        subtitle: Text(
          'Source : ${item.sourceDocumentType} ${source?.reference ?? ''}\n'
          'Priorité : ${item.priority.isEmpty ? '—' : item.priority}\n'
          'Responsable : ${item.responsible.isEmpty ? '—' : item.responsible}\n'
          'Délai : ${item.deadline.isEmpty ? '—' : item.deadline}\n'
          'Preuve attendue : ${item.evidenceExpected.isEmpty ? '—' : item.evidenceExpected}\n'
          'Statut : ${item.status}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          children: [
            TextButton(
              onPressed: () => _setStatus(item, 'validé'),
              child: const Text('Valider'),
            ),
            TextButton(
              onPressed: () => _setStatus(item, 'à revoir'),
              child: const Text('À revoir'),
            ),
            TextButton(
              onPressed: () => _setStatus(item, 'ignoré'),
              child: const Text('Ignorer'),
            ),
          ],
        ),
      ),
    );
  }
}

class GeneratedCompanyDocumentPreviewScreen extends StatefulWidget {
  const GeneratedCompanyDocumentPreviewScreen({
    super.key,
    required this.project,
    required this.document,
  });

  final PreventiaCompanyProject project;
  final PreventiaCompanyDocument document;

  @override
  State<GeneratedCompanyDocumentPreviewScreen> createState() =>
      _GeneratedCompanyDocumentPreviewScreenState();
}

class _GeneratedCompanyDocumentPreviewScreenState
    extends State<GeneratedCompanyDocumentPreviewScreen> {
  bool _exporting = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.document.markdown));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Document copié.')));
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    final saved = await _exportCompanyDocumentPdf(
      context,
      widget.project,
      widget.document,
    );
    if (saved?.pdfPath?.isNotEmpty == true) {
      await PreventiaCompanyProjectService().updateGeneratedDocumentExportPaths(
        companyKey: widget.project.companyKey,
        documentId: widget.document.id,
        pdfPath: saved!.pdfPath,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.document.title} exporté dans : ${saved.pdfPath}',
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _exportWord() async {
    setState(() => _exporting = true);
    final saved = await _exportCompanyDocumentWord(
      context,
      widget.project,
      widget.document,
    );
    if (saved?.wordPath?.isNotEmpty == true) {
      await PreventiaCompanyProjectService().updateGeneratedDocumentExportPaths(
        companyKey: widget.project.companyKey,
        documentId: widget.document.id,
        wordPath: saved!.wordPath,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.document.title} exporté dans : ${saved.wordPath}',
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.document.title)),
      body: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Source : Dossier société',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _exporting ? null : _copy,
                  child: const Text('Copier'),
                ),
                OutlinedButton(
                  onPressed: _exporting ? null : _exportWord,
                  child: const Text('Télécharger Word'),
                ),
                OutlinedButton(
                  onPressed: _exporting ? null : _exportPdf,
                  child: const Text('Exporter PDF'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour au dossier société'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: SimpleMarkdownDocumentView(
                  content: widget.document.markdown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _statusSection(PreventiaCompanyDocument? document) {
  return _folderSection(
    context: null,
    title: 'Statut',
    emptyMessage: '',
    children: [
      Text(document?.status ?? 'Document non créé.'),
      if (document?.markdown.isNotEmpty == true)
        const Text('Contenu généré disponible.'),
    ],
  );
}

Widget _generationSection({
  required String blankLabel,
  required String validatedLabel,
  required VoidCallback onBlank,
  required VoidCallback onValidated,
  required VoidCallback onPdf,
  required VoidCallback onWord,
  String? finalExportHint,
  String pdfLabel = 'Exporter PDF',
  String wordLabel = 'Télécharger Word',
}) {
  return _folderSection(
    context: null,
    title: 'Génération',
    emptyMessage: '',
    children: [
      if (finalExportHint != null) Text(finalExportHint),
      if (finalExportHint != null) const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(onPressed: onBlank, child: Text(blankLabel)),
          FilledButton.tonal(
            onPressed: onValidated,
            child: Text(validatedLabel),
          ),
          OutlinedButton(onPressed: onPdf, child: Text(pdfLabel)),
          OutlinedButton(onPressed: onWord, child: Text(wordLabel)),
        ],
      ),
    ],
  );
}

Widget _reviewExportButtons({
  required VoidCallback onWord,
  required VoidCallback onPdf,
  String wordLabel = 'Télécharger Word — éléments à valider',
  String pdfLabel = 'Exporter PDF — éléments à valider',
}) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      OutlinedButton.icon(
        onPressed: onWord,
        icon: const Icon(Icons.description_outlined),
        label: Text(wordLabel),
      ),
      OutlinedButton.icon(
        onPressed: onPdf,
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: Text(pdfLabel),
      ),
    ],
  );
}

Widget _folderSection({
  required BuildContext? context,
  required String title,
  required String emptyMessage,
  required List<Widget> children,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (innerContext) => Text(
              title,
              style: Theme.of(context ?? innerContext).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          if (children.isEmpty && emptyMessage.isNotEmpty)
            Text(emptyMessage)
          else
            ...children,
        ],
      ),
    ),
  );
}

PreventiaCompanyDocument? _sourceDocument(
  PreventiaCompanyProject project,
  String sourceDocumentId,
) {
  for (final document in project.analyses) {
    if (document.id == sourceDocumentId) return document;
  }
  return null;
}

String _chapterSuggestion(String value) {
  final normalized = normalizeCompanyName(value);
  if (normalized.contains('incend') || normalized.contains('evac')) {
    return 'Incendie et évacuation';
  }
  if (normalized.contains('coupure') || normalized.contains('tgbt')) {
    return 'Coupures et installations techniques';
  }
  if (normalized.contains('ascenseur') || normalized.contains('bloquee')) {
    return 'Ascenseurs et personnes bloquées';
  }
  return 'Informations issues des analyses de risques';
}

String _statusKey(String value) => normalizeCompanyName(value);

Map<String, dynamic> _blankPiuGenerationFormData(
  PreventiaCompanyProject project,
) {
  final profile = _resolvedProfile(project);
  return {
    ...profile.toJson(),
    'mode': 'blank',
    'source': 'company-folder',
    'importedPiuItems': const [],
  };
}

Map<String, dynamic> _blankPgaGenerationFormData(
  PreventiaCompanyProject project,
) {
  final profile = _resolvedProfile(project);
  return {
    ...profile.toJson(),
    'companyProfile': profile.toJson(),
    'mode': 'blank',
    'source': 'company-folder',
    'importedActionItems': const [],
  };
}

String _primarySite(PreventiaCompanyProject project) {
  if (project.companyProfile.siteName.trim().isNotEmpty) {
    return project.companyProfile.siteName.trim();
  }
  if (project.sites.isNotEmpty) return project.sites.first.name;
  for (final analysis in project.analyses) {
    if (analysis.siteName.trim().isNotEmpty) return analysis.siteName.trim();
  }
  return '';
}

PreventiaCompanyProfile _resolvedProfile(PreventiaCompanyProject project) {
  return project.companyProfile.merge(
    PreventiaCompanyProfile(
      companyName: project.companyName,
      siteName: _primarySite(project),
    ),
  );
}

DocumentFormData _companyDocumentFormData({
  required String documentType,
  required PreventiaCompanyProject project,
  required Map<String, dynamic> formData,
}) {
  const missing = DocumentFormData.unknownValue;
  final siteName = formData['siteName']?.toString().trim();
  return DocumentFormData(
    documentType: documentType,
    companyName: project.companyName,
    siteConcerned: siteName?.isNotEmpty == true ? siteName! : missing,
    serviceConcerned: missing,
    author: missing,
    version: missing,
    visitDate: missing,
    documentObjective: documentType == 'Plan Interne d’Urgence'
        ? 'Projet de Plan Interne d’Urgence à valider'
        : 'Projet de PGA/PAA/PGP à valider',
    includedLocations: missing,
    excludedLocations: missing,
    concernedPositions: missing,
    concernedTasks: missing,
    includedSituations: missing,
    exposureDuration: missing,
    workMode: missing,
    fieldVisitDone: missing,
    jobObservationDone: missing,
    workersConsulted: missing,
    managementConsulted: missing,
    cpptConsulted: missing,
    incidentRegisterAvailable: missing,
    photosAvailable: missing,
    controlReportsAvailable: missing,
    technicalSheetsAvailable: missing,
    safetyDataSheetsAvailable: missing,
    sector: missing,
    workerCount: missing,
    activity: missing,
    equipment: missing,
    dangerousProducts: missing,
    exposedWorkers: missing,
    knownIncidents: missing,
    constraints: missing,
    additionalInformation: missing,
    writtenInstructions: missing,
    completedTrainings: missing,
    availablePpe: missing,
    periodicControls: missing,
    availableEvidence: missing,
    oralMeasures: missing,
    measuresToVerify: missing,
    workAtHeight: missing,
    dangerousMachines: missing,
    chemicalProducts: missing,
    manualHandling: missing,
    vehiclePedestrianTraffic: missing,
    noise: missing,
    fireRisk: missing,
    loneWork: missing,
    coactivity: missing,
    weatherConstraints: missing,
    newWorkers: missing,
    temporaryWorkers: missing,
    youngWorkers: missing,
    pregnantOrBreastfeedingWorkers: missing,
    medicalRestrictionsWorkers: missing,
    isolatedWorkers: missing,
    subcontractors: missing,
    cpptPresence: missing,
    preventionService: missing,
    feedAnnualActionPlan: missing,
    feedGlobalPreventionPlan: missing,
    presentToCppt: missing,
    externalServiceValidation: missing,
    occupationalDoctorAdvice: missing,
    extraFields: formData,
  );
}

String _companyDocumentFileName({
  required PreventiaCompanyProject project,
  required PreventiaCompanyDocument document,
  required String extension,
}) {
  final date = DateTime.now();
  final formattedDate =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  final company = normalizeCompanyName(
    project.companyName,
  ).replaceAll(RegExp(r'\s+'), '_');
  final normalizedType = normalizeCompanyName(document.documentType);
  final prefix =
      normalizedType.contains('revue') && normalizedType.contains('piu')
      ? 'Revue_PIU'
      : normalizedType.contains('revue') &&
            (normalizedType.contains('pgp') || normalizedType.contains('paa'))
      ? 'Revue_PGP_PAA'
      : document.documentType == 'Plan Interne d’Urgence'
      ? 'PIU'
      : 'PGA_PAA_PGP';
  return '${prefix}_${company}_$formattedDate.$extension';
}

Future<PreventiaSavedDocument?> _exportCompanyDocumentPdf(
  BuildContext context,
  PreventiaCompanyProject project,
  PreventiaCompanyDocument document,
) async {
  final markdown = _cleanGeneratedCompanyMarkdown(document.markdown);
  return PdfDeliveryService.exportPdf(
    context: context,
    name: _companyDocumentFileName(
      project: project,
      document: document,
      extension: 'pdf',
    ),
    projectDetails: _projectExportDetails(context, project, document),
    onLayout: (_) => PdfExportService.buildDocumentPdf(
      documentType: document.documentType,
      content: markdown,
      generatedAt: DateTime.now(),
      referenceNumber: document.reference,
      texts: pdfDocumentTexts(AppLocalizations.of(context)),
    ),
  );
}

Future<PreventiaSavedDocument?> _exportCompanyDocumentWord(
  BuildContext context,
  PreventiaCompanyProject project,
  PreventiaCompanyDocument document,
) async {
  final markdown = _cleanGeneratedCompanyMarkdown(document.markdown);
  final bytes = DocxExportService.buildRiskAssessmentDocx(
    documentType: document.documentType,
    content: markdown,
    generatedAt: DateTime.now(),
    referenceNumber: document.reference,
  );
  final l10n = AppLocalizations.of(context);
  return FileExportService.saveDocxBytes(
    bytes: bytes,
    suggestedFileName: _companyDocumentFileName(
      project: project,
      document: document,
      extension: 'docx',
    ),
    context: context,
    successMessage: l10n.wordDocumentGenerated,
    errorMessage: l10n.unableToGenerateWordDocument,
    projectDetails: _projectExportDetails(context, project, document),
  );
}

Future<String?> _writePiuReviewWord(
  BuildContext context,
  PreventiaCompanyProject project,
  PreventiaCompanyDocument document,
) async {
  final markdown = _cleanGeneratedCompanyMarkdown(document.markdown);
  final bytes = DocxExportService.buildRiskAssessmentDocx(
    documentType: document.documentType,
    content: markdown,
    generatedAt: DateTime.now(),
    referenceNumber: document.reference,
  );
  final fileName = _companyDocumentFileName(
    project: project,
    document: document,
    extension: 'docx',
  );
  final localDirectory = _piuReviewTargetDirectory(project);
  if (localDirectory != null) {
    await localDirectory.create(recursive: true);
    final targetPath = path.join(
      localDirectory.path,
      _safeReviewFileName(fileName),
    );
    await File(targetPath).writeAsBytes(bytes, flush: true);
    return targetPath;
  }

  final l10n = AppLocalizations.of(context);
  final saved = await FileExportService.saveDocxBytes(
    bytes: bytes,
    suggestedFileName: fileName,
    context: context,
    successMessage: l10n.wordDocumentGenerated,
    errorMessage: l10n.unableToGenerateWordDocument,
    projectDetails: _projectExportDetails(context, project, document),
  );
  return saved?.wordPath;
}

Future<String?> _writePiuReviewPdf(
  BuildContext context,
  PreventiaCompanyProject project,
  PreventiaCompanyDocument document,
) async {
  final fileName = _companyDocumentFileName(
    project: project,
    document: document,
    extension: 'pdf',
  );
  final localDirectory = _piuReviewTargetDirectory(project);
  if (localDirectory != null) {
    final texts = pdfDocumentTexts(AppLocalizations.of(context));
    await localDirectory.create(recursive: true);
    final bytes = await PdfExportService.buildDocumentPdf(
      documentType: document.documentType,
      content: document.markdown,
      generatedAt: DateTime.now(),
      referenceNumber: document.reference,
      texts: texts,
    );
    final targetPath = path.join(
      localDirectory.path,
      _safeReviewFileName(fileName),
    );
    await File(targetPath).writeAsBytes(bytes, flush: true);
    return targetPath;
  }
  return (await _exportCompanyDocumentPdf(context, project, document))?.pdfPath;
}

Directory? _piuReviewTargetDirectory(PreventiaCompanyProject project) {
  final basePath = project.localFolderPath?.trim();
  if (basePath == null || basePath.isEmpty) return null;
  return Directory(path.join(basePath, '02_PIU', '00_A_valider'));
}

String _safeReviewFileName(String fileName) {
  final basename = path.basename(fileName).trim();
  return basename
      .replaceAll(RegExp(r'[\x00-\x1F/\\:*?"<>|]'), '-')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
}

ProjectExportDetails _projectExportDetails(
  BuildContext context,
  PreventiaCompanyProject project,
  PreventiaCompanyDocument document,
) {
  final markdown = _cleanGeneratedCompanyMarkdown(document.markdown);
  return ProjectExportDetails(
    documentType: document.documentType,
    title: document.title,
    reference: document.reference,
    language: Localizations.localeOf(context).languageCode,
    source: document.source,
    companyName: project.companyName,
    siteName: document.siteName,
    markdown: markdown,
    formData: document.formData,
    projectPath: project.localFolderPath,
  );
}

String _cleanGeneratedCompanyMarkdown(String markdown) {
  return markdown
      .replaceAll(
        RegExp(r'^\s*Page\s+[0-9]+\s*/\s*[0-9]+\s*$', multiLine: true),
        '',
      )
      .replaceAll(
        RegExp(
          r'^\s*Référence.*Page\s+[0-9]+\s*/\s*[0-9]+\s*$',
          multiLine: true,
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
