import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/pdf_texts.dart';
import '../models/document_family.dart';
import '../models/generation_source.dart';
import '../models/preventia_company_project.dart';
import '../models/preventia_project.dart' show normalizeCompanyName;
import '../services/analysis_project_service.dart';
import '../services/ai_document_service.dart';
import '../services/docx_export_service.dart';
import '../services/file_export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/pdf_delivery_service.dart';
import '../services/preventia_document_storage_service.dart';
import '../services/preventia_company_project_service.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/simple_markdown_document_view.dart';
import 'action_summary_screen.dart';
import 'company_folder_detail_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.documentType,
    required this.content,
    required this.generationSource,
    this.documentReference,
    this.companyName,
    this.siteName,
    this.formData = const {},
    this.linkedDocuments = const [],
    super.key,
  });

  final String documentType;
  final String content;
  final String? documentReference;
  final String? companyName;
  final String? siteName;
  final Map<String, dynamic> formData;
  final GenerationSource generationSource;
  final List<AiLinkedDocument> linkedDocuments;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _isExportingPdf = false;
  bool _isExportingWord = false;
  late final Future<void> _projectPreparation;
  PreventiaCompanyProject? _selectedProject;
  PreventiaCompanyUpdateResult? _companyUpdate;

  @override
  void initState() {
    super.initState();
    final completer = Completer<void>();
    _projectPreparation = completer.future;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _preparePreventiaProject();
      } finally {
        completer.complete();
      }
    });
  }

  Future<void> _preparePreventiaProject() async {
    try {
      final isRiskAssessment =
          resolveDocumentFamily(widget.documentType) ==
          DocumentFamily.riskAssessment;
      if (!isRiskAssessment) return;
      final service = PreventiaCompanyProjectService();
      final data = <String, dynamic>{
        ...widget.formData,
        if (widget.companyName?.trim().isNotEmpty == true)
          'companyName': widget.companyName,
        if (widget.siteName?.trim().isNotEmpty == true)
          'siteName': widget.siteName,
      };
      final companyKey = normalizeCompanyName(
        detectCompanyName(data, widget.content),
      );
      final before = await service.findByKey(companyKey);
      final project = await service.addRiskAssessmentToCompanyProject(
        documentType: widget.documentType,
        markdown: widget.content,
        formData: data,
        reference: widget.documentReference?.trim() ?? '',
      );
      final analysis = project.analyses.last;
      final update = PreventiaCompanyUpdateResult(
        project: project,
        actionCount: project.actionItems
            .where((item) => item.sourceDocumentId == analysis.id)
            .length,
        piuCount: project.piuItems
            .where((item) => item.sourceDocumentId == analysis.id)
            .length,
        diuCount: project.diuItems
            .where((item) => item.sourceDocumentId == analysis.id)
            .length,
        evidenceCount: project.evidenceItems
            .where((item) => item.sourceDocumentId == analysis.id)
            .length,
        piuCreated: before?.piuDocument == null,
        pgaCreated: before?.pgaDocument == null,
      );
      _companyUpdate = update;
      _selectedProject = update.project;
      if (mounted) await _showCompanySummary(update);
    } on Object catch (error) {
      debugPrint('PreventIA company history update unavailable: $error');
    }
  }

  Future<void> _showCompanySummary(PreventiaCompanyUpdateResult update) async {
    if (!mounted) return;
    final company = update.project.companyName;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Analyse ajoutée au dossier société'),
        content: Text(
          'Société : $company\n\n'
          'Ajouté au dossier :\nDossier PreventIA — $company\n\n'
          'Éléments mis à jour :\n'
          '- Analyse de risques ajoutée\n'
          '- PIU ${update.piuCreated ? 'créé' : 'déjà existant'}\n'
          '- PGA/PAA/PGP ${update.pgaCreated ? 'créé' : 'déjà existant'}\n'
          '- ${update.actionCount} actions candidates\n'
          '- ${update.piuCount} points candidats PIU\n'
          '- ${update.diuCount} points candidats DIU\n'
          '- ${update.evidenceCount} preuves/photos à obtenir',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyFolderDetailScreen(
                    companyKey: update.project.companyKey,
                  ),
                ),
              );
            },
            child: Text('Voir le dossier $company'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStorageSummary(
    PreventiaSavedDocument saved, {
    required bool includeExportPaths,
  }) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    final extraction = saved;
    final pathDetails = [
      if (saved.wordPath != null) 'Word :\n${saved.wordPath}',
      if (saved.pdfPath != null) 'PDF :\n${saved.pdfPath}',
      if (saved.folderPath.isNotEmpty) 'Dossier :\n${saved.folderPath}',
    ].join('\n\n');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          saved.isIndexed
              ? 'Analyse ajoutée au dossier société'
              : 'Document généré',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (saved.error != null) ...[
                Text(saved.error!),
                const SizedBox(height: 12),
              ],
              if (saved.folderPath.isNotEmpty)
                SelectableText(
                  'Société : ${widget.companyName ?? _selectedProject?.companyName ?? ''}\n'
                  'Dossier :\n${saved.folderPath}',
                ),
              if (includeExportPaths) ...[
                const SizedBox(height: 12),
                if (saved.wordPath != null)
                  SelectableText('Word : ${saved.wordPath}'),
                if (saved.pdfPath != null)
                  SelectableText('PDF : ${saved.pdfPath}'),
              ],
              if (saved.isIndexed &&
                  resolveDocumentFamily(widget.documentType) ==
                      DocumentFamily.riskAssessment) ...[
                const SizedBox(height: 16),
                const Text('Éléments ajoutés au dossier PreventIA :'),
                const SizedBox(height: 8),
                const Text('Documents :'),
                const Text('- Analyse enregistrée'),
                Text(
                  extraction.piuCreated
                      ? '- PIU vierge créé'
                      : '- PIU existant conservé',
                ),
                Text(
                  extraction.pgaCreated
                      ? '- PGA/PAA/PGP créé'
                      : '- PGA existant conservé',
                ),
                const SizedBox(height: 8),
                const Text('Éléments extraits :'),
                Text('- ${extraction.actionCount} actions pour PGA/PAA/PGP'),
                Text('- ${extraction.piuCount} points candidats PIU'),
                Text('- ${extraction.diuCount} points candidats DIU'),
                Text('- ${extraction.evidenceCount} preuves/photos à obtenir'),
              ],
            ],
          ),
        ),
        actions: [
          if (saved.folderPath.isNotEmpty)
            TextButton(
              onPressed: () async {
                final error = await PreventiaDocumentStorageService.openFolder(
                  saved.folderPath,
                );
                if (error != null && mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                }
              },
              child: const Text('Ouvrir le dossier'),
            ),
          if (saved.isIndexed && _selectedProject != null)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompanyFolderDetailScreen(
                      companyKey: _selectedProject!.companyKey,
                    ),
                  ),
                );
              },
              child: Text(
                'Voir le dossier ${_selectedProject?.companyName ?? ''}',
              ),
            ),
          if (pathDetails.isNotEmpty)
            TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: pathDetails)),
              child: const Text('Copier le chemin'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyDocument() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).copiedDocumentMessage),
      ),
    );
  }

  Future<void> _saveDocument() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    final supportsAutomaticSummary =
        resolveDocumentFamily(widget.documentType) ==
        DocumentFamily.riskAssessment;
    if (supportsAutomaticSummary) {
      await _projectPreparation;
    } else {
      await AnalysisProjectService().saveDocumentPackage(
        documentTitle: widget.documentType,
        documentContent: widget.content,
        referenceNumber: widget.documentReference,
        projectStatus: l10n.projectToValidate,
        sourceValue: _pdfSourceText(l10n),
        linkedDocuments: widget.linkedDocuments
            .map(
              (document) => LinkedDocumentDraft(
                title: document.title,
                content: document.content,
              ),
            )
            .toList(growable: false),
      );
    }

    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    if (supportsAutomaticSummary && _companyUpdate != null) {
      await _showCompanySummary(_companyUpdate!);
    }
  }

  Future<void> _exportPdf() async {
    await _projectPreparation;
    if (!mounted) return;
    setState(() => _isExportingPdf = true);
    final generatedAt = DateTime.now();
    final l10n = AppLocalizations.of(context);
    final exportProjectTitle = _exportProjectTitleFromContent();
    final exportReference = PdfExportService.resolveDocumentReference(
      metadataDocumentReference: widget.documentReference,
      content: widget.content,
    );

    try {
      final saved = await PdfDeliveryService.exportPdf(
        context: context,
        name: FileExportService.documentFileName(
          projectTitle: exportProjectTitle,
          documentType: widget.documentType,
          languageCode: l10n.localeName,
          referenceNumber: exportReference,
        ),
        projectDetails: _projectExportDetails(
          reference: exportReference,
          language: l10n.localeName,
        ),
        showResultMessage: false,
        onLayout: (_) => PdfExportService.buildDocumentPdf(
          documentType: widget.documentType,
          content: widget.content,
          generatedAt: generatedAt,
          referenceNumber: widget.documentReference,
          texts: pdfDocumentTexts(
            AppLocalizations.of(context),
            sourceText: _pdfSourceText(AppLocalizations.of(context)),
          ),
        ),
      );
      if (saved != null && mounted) {
        await _showStorageSummary(saved, includeExportPaths: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  Future<void> _exportWord() async {
    await _projectPreparation;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final exportReference = PdfExportService.resolveDocumentReference(
      metadataDocumentReference: widget.documentReference,
      content: widget.content,
    );
    setState(() => _isExportingWord = true);
    try {
      final generatedAt = DateTime.now();
      final bytes = DocxExportService.buildRiskAssessmentDocx(
        documentType: widget.documentType,
        content: widget.content,
        generatedAt: generatedAt,
        referenceNumber: widget.documentReference,
      );
      final saved = await FileExportService.saveDocxBytes(
        bytes: bytes,
        suggestedFileName: FileExportService.documentWordFileName(
          projectTitle: _exportProjectTitleFromContent(),
          documentType: widget.documentType,
          languageCode: l10n.localeName,
          referenceNumber: exportReference,
        ),
        context: context,
        successMessage: l10n.wordDocumentGenerated,
        errorMessage: l10n.unableToGenerateWordDocument,
        projectDetails: _projectExportDetails(
          reference: exportReference,
          language: l10n.localeName,
        ),
        showResultMessage: false,
      );
      if (saved != null && mounted) {
        await _showStorageSummary(saved, includeExportPaths: true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.unableToGenerateWordDocument)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingWord = false);
      }
    }
  }

  void _openActionSummary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActionSummaryScreen(
          documentContent: widget.content,
          sourceAnalysisTitle: widget.documentType,
          exportProjectTitle: _exportProjectTitleFromContent(),
          exportReferenceNumber: widget.documentReference,
          exportLanguageCode: AppLocalizations.of(context).localeName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final diagnosticLabel = _diagnosticLabel(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.projectDocument)),
      body: Column(
        children: [
          AdaptivePage(
            mobilePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  avatar: const Icon(Icons.verified_outlined, size: 18),
                  label: Text(diagnosticLabel),
                ),
                const SizedBox(height: 6),
                Text('${l10n.source} : $diagnosticLabel'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _copyDocument,
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(l10n.copyDocument),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          resolveDocumentFamily(widget.documentType) ==
                              DocumentFamily.riskAssessment
                          ? _openActionSummary
                          : null,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(l10n.viewActions),
                    ),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveDocument,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(l10n.saveLocally),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _isExportingPdf ? null : _exportPdf,
                      icon: _isExportingPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(l10n.exportPdf),
                    ),
                    if (resolveDocumentFamily(widget.documentType) ==
                        DocumentFamily.riskAssessment)
                      FilledButton.tonalIcon(
                        onPressed: _isExportingWord ? null : _exportWord,
                        icon: _isExportingWord
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.description_outlined),
                        label: Text(l10n.downloadWord),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AdaptivePage(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SimpleMarkdownDocumentView(content: widget.content),
                    for (final linkedDocument in widget.linkedDocuments) ...[
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                linkedDocument.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              SimpleMarkdownDocumentView(
                                content: linkedDocument.content,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _diagnosticLabel(AppLocalizations l10n) {
    return switch (widget.generationSource) {
      GenerationSource.aiBackend => l10n.renderBackendSource,
      GenerationSource.localFallback => l10n.localGenerationSource,
      GenerationSource.error => l10n.backendErrorSource,
    };
  }

  String _pdfSourceText(AppLocalizations l10n) {
    return switch (widget.generationSource) {
      GenerationSource.aiBackend => l10n.renderBackendPdfSource,
      GenerationSource.localFallback => l10n.localGenerationPdfSource,
      GenerationSource.error => l10n.backendErrorSource,
    };
  }

  String? _exportProjectTitleFromContent() {
    return FileExportService.projectTitleFromContent(widget.content);
  }

  ProjectExportDetails _projectExportDetails({
    required String? reference,
    required String language,
  }) {
    return ProjectExportDetails(
      documentType: widget.documentType,
      title: _exportProjectTitleFromContent() ?? widget.documentType,
      reference: reference ?? '',
      language: language,
      source: widget.generationSource.value,
      companyName: widget.companyName ?? '',
      siteName: widget.siteName ?? '',
      markdown: widget.content,
      formData: widget.formData,
      projectPath: _selectedProject?.localFolderPath,
      rememberProject: true,
    );
  }
}
