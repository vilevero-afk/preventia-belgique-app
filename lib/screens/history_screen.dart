import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/pdf_texts.dart';
import '../models/analysis_project.dart';
import '../models/saved_document.dart';
import '../services/action_summary_pdf_service.dart';
import '../services/action_summary_service.dart';
import '../services/file_export_service.dart';
import '../services/local_document_storage.dart';
import '../services/pdf_delivery_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/adaptive_page.dart';
import 'action_summary_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  void _reloadDocuments() {
    setState(() {
      _historyFuture = _loadHistory();
    });
  }

  Future<_HistoryData> _loadHistory() async {
    final storage = LocalDocumentStorage();
    final projects = await storage.loadProjects();
    final documents = await storage.loadDocuments();
    final projectDocumentIds = projects
        .expand(
          (project) => [
            project.analysisDocumentId,
            project.actionSummaryDocumentId,
          ],
        )
        .toSet();
    final standaloneDocuments = documents
        .where((document) => !projectDocumentIds.contains(document.id))
        .toList();
    return _HistoryData(projects: projects, documents: standaloneDocuments);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
      body: FutureBuilder<_HistoryData>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? const _HistoryData();
          if (history.projects.isEmpty && history.documents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noHistory, textAlign: TextAlign.center),
              ),
            );
          }

          final itemCount = history.projects.length + history.documents.length;
          return AdaptivePage(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index < history.projects.length) {
                  final project = history.projects[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(project.name),
                      subtitle: Text(l10n.analysisFolderSubtitle),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                AnalysisProjectScreen(project: project),
                          ),
                        );
                        if (context.mounted) {
                          _reloadDocuments();
                        }
                      },
                    ),
                  );
                }

                final document =
                    history.documents[index - history.projects.length];
                return Card(
                  child: ListTile(
                    title: Text(document.title),
                    subtitle: Text(_historySubtitle(document)),
                    isThreeLine:
                        document.isModifiedLocally || document.isActionSummary,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              SavedDocumentDetailScreen(document: document),
                        ),
                      );
                      if (context.mounted) {
                        _reloadDocuments();
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _historySubtitle(SavedDocument document) {
    if (document.isActionSummary) {
      return 'Récapitulatif lié à ${document.sourceDocumentTitle ?? 'une analyse locale'}';
    }
    if (document.isModifiedLocally) {
      return '${document.documentType}\nVersion modifiée';
    }
    return document.documentType;
  }
}

class _HistoryData {
  const _HistoryData({this.projects = const [], this.documents = const []});

  final List<AnalysisProject> projects;
  final List<SavedDocument> documents;
}

class AnalysisProjectScreen extends StatefulWidget {
  const AnalysisProjectScreen({required this.project, super.key});

  final AnalysisProject project;

  @override
  State<AnalysisProjectScreen> createState() => _AnalysisProjectScreenState();
}

class _AnalysisProjectScreenState extends State<AnalysisProjectScreen> {
  late Future<_ProjectDocuments> _documentsFuture;
  bool _isExportingFolder = false;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _loadDocuments();
  }

  Future<_ProjectDocuments> _loadDocuments() async {
    final storage = LocalDocumentStorage();
    return _ProjectDocuments(
      analysis: await storage.findDocumentById(
        widget.project.analysisDocumentId,
      ),
      summary: await storage.findDocumentById(
        widget.project.actionSummaryDocumentId,
      ),
    );
  }

  Future<void> _copy(SavedDocument document) async {
    await Clipboard.setData(ClipboardData(text: document.content));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).copy)));
  }

  Future<void> _exportAnalysis(SavedDocument document) async {
    final generatedAt = DateTime.now();
    final locale = Localizations.localeOf(context);
    await PdfDeliveryService.exportPdf(
      context: context,
      name: FileExportService.riskAnalysisFileName(
        referenceNumber: widget.project.referenceNumber,
        projectTitle:
            FileExportService.projectTitleFromContent(document.content) ??
            widget.project.name,
        locale: locale,
      ),
      onLayout: (_) => PdfExportService.buildDocumentPdf(
        documentType: document.documentType,
        content: document.content,
        generatedAt: generatedAt,
        texts: pdfDocumentTexts(AppLocalizations.of(context)),
      ),
    );
  }

  Future<void> _exportSummary(SavedDocument analysis) async {
    final generatedAt = DateTime.now();
    final summary = ActionSummaryService().build(analysis.content);
    final locale = Localizations.localeOf(context);
    await PdfDeliveryService.exportPdf(
      context: context,
      name: FileExportService.actionSummaryFileName(
        referenceNumber: widget.project.referenceNumber,
        projectTitle:
            FileExportService.projectTitleFromContent(analysis.content) ??
            widget.project.name,
        locale: locale,
      ),
      onLayout: (_) => ActionSummaryPdfService.buildPdf(
        summary: summary,
        sourceAnalysisTitle: widget.project.name,
        generatedAt: generatedAt,
        texts: ActionSummaryPdfTexts.fromLocalizations(
          AppLocalizations.of(context),
        ),
      ),
    );
  }

  Future<void> _exportFolder(_ProjectDocuments documents) async {
    final analysis = documents.analysis;
    if (analysis == null) {
      return;
    }

    setState(() => _isExportingFolder = true);
    try {
      await _exportAnalysis(analysis);
      if (documents.summary != null) {
        await _exportSummary(analysis);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).exportSeparateSummaryHint,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingFolder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.analysisFolder)),
      body: FutureBuilder<_ProjectDocuments>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          final documents = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return AdaptivePage(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Text(
                  widget.project.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(l10n.analysisNumber(widget.project.referenceNumber)),
                Text(l10n.linkedAnalysis(widget.project.analysisTitle)),
                Text(l10n.creationDate(_formatDate(widget.project.createdAt))),
                Text(l10n.status(widget.project.status)),
                const SizedBox(height: 12),
                Text(l10n.riskAnalysisAndSummaryFolderInfo),
                const SizedBox(height: 16),
                if (documents?.analysis != null)
                  _ProjectDocumentCard(
                    title: l10n.fullRiskAnalysis,
                    document: documents!.analysis!,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SavedDocumentDetailScreen(
                          document: documents.analysis!,
                          project: widget.project,
                        ),
                      ),
                    ),
                    onCopy: () => _copy(documents.analysis!),
                    onExport: () => _exportAnalysis(documents.analysis!),
                  ),
                if (documents?.summary != null && documents?.analysis != null)
                  _ProjectDocumentCard(
                    title: l10n.actionSummary,
                    document: documents!.summary!,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SavedDocumentDetailScreen(
                          document: documents.summary!,
                          project: widget.project,
                        ),
                      ),
                    ),
                    onCopy: () => _copy(documents.summary!),
                    onExport: () => _exportSummary(documents.analysis!),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isExportingFolder || documents?.analysis == null
                      ? null
                      : () => _exportFolder(documents!),
                  icon: const Icon(Icons.folder_zip_outlined),
                  label: Text(l10n.exportFolder),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _ProjectDocumentCard extends StatelessWidget {
  const _ProjectDocumentCard({
    required this.title,
    required this.document,
    required this.onOpen,
    required this.onCopy,
    required this.onExport,
  });

  final String title;
  final SavedDocument document;
  final VoidCallback onOpen;
  final VoidCallback onCopy;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(document.title),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(onPressed: onOpen, child: Text(l10n.open)),
                OutlinedButton(onPressed: onCopy, child: Text(l10n.copy)),
                FilledButton.tonal(
                  onPressed: onExport,
                  child: Text(l10n.exportPdf),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDocuments {
  const _ProjectDocuments({required this.analysis, required this.summary});

  final SavedDocument? analysis;
  final SavedDocument? summary;
}

class SavedDocumentDetailScreen extends StatefulWidget {
  const SavedDocumentDetailScreen({
    required this.document,
    this.project,
    super.key,
  });

  final SavedDocument document;
  final AnalysisProject? project;

  @override
  State<SavedDocumentDetailScreen> createState() =>
      _SavedDocumentDetailScreenState();
}

class _SavedDocumentDetailScreenState extends State<SavedDocumentDetailScreen> {
  late SavedDocument _document;
  late TextEditingController _contentController;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _contentController = TextEditingController(text: _document.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _document.content));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).copiedDocumentMessage),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final updatedDocument = _document.copyWith(
      content: _contentController.text,
      modifiedAt: DateTime.now(),
    );

    await LocalDocumentStorage().updateDocument(updatedDocument);

    if (!mounted) {
      return;
    }
    setState(() {
      _document = updatedDocument;
      _isEditing = false;
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).changesSavedLocally)),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    final generatedAt = DateTime.now();
    final project = widget.project;
    final locale = Localizations.localeOf(context);
    final name = _document.isActionSummary
        ? FileExportService.actionSummaryFileName(
            referenceNumber: project?.referenceNumber,
            projectTitle: _exportProjectTitle(project),
            locale: project == null ? null : locale,
          )
        : FileExportService.riskAnalysisFileName(
            referenceNumber: project?.referenceNumber,
            projectTitle: _exportProjectTitle(project),
            locale: project == null ? null : locale,
          );

    try {
      await PdfDeliveryService.exportPdf(
        context: context,
        name: name,
        onLayout: (_) => PdfExportService.buildDocumentPdf(
          documentType: _document.documentType,
          content: _document.content,
          generatedAt: generatedAt,
          texts: pdfDocumentTexts(AppLocalizations.of(context)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  String? _exportProjectTitle(AnalysisProject? project) {
    return FileExportService.projectTitleFromContent(_document.content) ??
        project?.name;
  }

  Future<void> _openLinkedSummary() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActionSummaryScreen(
          documentContent: _document.content,
          sourceAnalysisTitle: _document.title,
          sourceDocumentId: _document.id,
          exportProjectTitle: widget.project?.name,
          exportReferenceNumber: widget.project?.referenceNumber,
        ),
      ),
    );
  }

  Future<void> _openLinkedAnalysis() async {
    final sourceId = _document.sourceDocumentId;
    if (sourceId == null) {
      return;
    }

    final linkedAnalysis = await LocalDocumentStorage().findDocumentById(
      sourceId,
    );
    if (!mounted) {
      return;
    }

    if (linkedAnalysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).linkedAnalysisNotFound),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedDocumentDetailScreen(
          document: linkedAnalysis,
          project: widget.project,
        ),
      ),
    );
  }

  void _openReadOnly() {
    setState(() {
      _isEditing = false;
      _contentController.text = _document.content;
    });
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _contentController.text = _document.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_document.documentType)),
      body: Column(
        children: [
          AdaptivePage(
            mobilePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_document.isModifiedLocally) ...[
                  Chip(
                    avatar: const Icon(Icons.edit_note_outlined, size: 18),
                    label: Text(l10n.documentModifiedLocally),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _document.isActionSummary
                      ? l10n.summaryStoredLocallyInfo
                      : l10n.pdfFromSavedContent,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openReadOnly,
                      icon: const Icon(Icons.article_outlined),
                      label: Text(l10n.open),
                    ),
                    OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(l10n.copyDocument),
                    ),
                    if (!_document.isActionSummary) _linkedSummaryButton(),
                    if (_document.isActionSummary &&
                        _document.sourceDocumentId != null)
                      OutlinedButton.icon(
                        onPressed: _openLinkedAnalysis,
                        icon: const Icon(Icons.article_outlined),
                        label: Text(l10n.viewLinkedAnalysis),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: _startEditing,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.edit),
                    ),
                    FilledButton.icon(
                      onPressed: _isEditing && !_isSaving ? _saveChanges : null,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(l10n.saveChanges),
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
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AdaptivePage(
              child: _isEditing
                  ? TextField(
                      controller: _contentController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.document,
                        alignLabelWithHint: true,
                      ),
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        _document.content,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkedSummaryButton() {
    return FutureBuilder<SavedDocument?>(
      future: LocalDocumentStorage().findActionSummaryForAnalysis(_document.id),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final hasLinkedSummary = snapshot.data != null;
        return OutlinedButton.icon(
          onPressed: _openLinkedSummary,
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(
            hasLinkedSummary ? l10n.openLinkedSummary : l10n.createSummary,
          ),
        );
      },
    );
  }
}
