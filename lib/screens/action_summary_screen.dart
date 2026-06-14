import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/saved_document.dart';
import '../services/action_summary_pdf_service.dart';
import '../services/action_summary_service.dart';
import '../services/file_export_service.dart';
import '../services/local_document_storage.dart';
import '../services/pdf_delivery_service.dart';
import '../widgets/adaptive_page.dart';

class ActionSummaryScreen extends StatefulWidget {
  const ActionSummaryScreen({
    required this.documentContent,
    required this.sourceAnalysisTitle,
    this.sourceDocumentId,
    this.exportProjectTitle,
    this.exportReferenceNumber,
    this.exportLanguageCode,
    super.key,
  });

  final String documentContent;
  final String sourceAnalysisTitle;
  final String? sourceDocumentId;
  final String? exportProjectTitle;
  final String? exportReferenceNumber;
  final String? exportLanguageCode;

  @override
  State<ActionSummaryScreen> createState() => _ActionSummaryScreenState();
}

class _ActionSummaryScreenState extends State<ActionSummaryScreen> {
  late final ActionSummaryService _summaryService;
  late final ActionSummary _summary;
  String? _sourceDocumentId;
  bool _isSaving = false;
  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    _summaryService = ActionSummaryService();
    _summary = _summaryService.build(widget.documentContent);
    _sourceDocumentId = widget.sourceDocumentId;
  }

  Future<void> _copySummary() async {
    await Clipboard.setData(
      ClipboardData(
        text: _summaryService.buildCopyText(
          _summary,
          language: AppLocalizations.of(context).localeName,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).copiedSummaryMessage),
      ),
    );
  }

  Future<void> _saveSummary() async {
    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context);
    final storage = LocalDocumentStorage();
    final now = DateTime.now();
    var sourceId = _sourceDocumentId;

    if (sourceId == null) {
      final sourceDocument = SavedDocument(
        id: now.microsecondsSinceEpoch.toString(),
        title: widget.sourceAnalysisTitle,
        documentType: widget.sourceAnalysisTitle,
        content: widget.documentContent,
        createdAt: now,
        localDocumentType: SavedDocumentLocalType.riskAnalysis,
      );
      await storage.saveDocument(sourceDocument);
      sourceId = sourceDocument.id;
    }

    final existingSummary = await storage.findActionSummaryForAnalysis(
      sourceId,
    );
    final summaryContent = _structuredSummaryContent();
    final summaryDocument = existingSummary == null
        ? SavedDocument(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: '${l10n.actionSummary} - ${widget.sourceAnalysisTitle}',
            documentType: l10n.actionSummary,
            content: summaryContent,
            createdAt: DateTime.now(),
            localDocumentType: SavedDocumentLocalType.actionSummary,
            sourceDocumentId: sourceId,
            sourceDocumentTitle: widget.sourceAnalysisTitle,
            sourceLabel: l10n.generatedLocallyFromAnalysis,
            status: l10n.projectToValidate,
          )
        : existingSummary.copyWith(
            content: summaryContent,
            modifiedAt: DateTime.now(),
            sourceDocumentId: sourceId,
            sourceDocumentTitle: widget.sourceAnalysisTitle,
            sourceLabel: l10n.generatedLocallyFromAnalysis,
            status: l10n.projectToValidate,
          );

    if (existingSummary == null) {
      await storage.saveDocument(summaryDocument);
    } else {
      await storage.updateDocument(summaryDocument);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _sourceDocumentId = sourceId;
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).savedSummaryMessage)),
    );
  }

  Future<void> _exportSummaryPdf() async {
    setState(() => _isExportingPdf = true);
    final generatedAt = DateTime.now();
    final projectTitle = widget.exportProjectTitle;

    try {
      await PdfDeliveryService.exportPdf(
        context: context,
        name: FileExportService.actionSummaryFileName(
          referenceNumber: widget.exportReferenceNumber,
          projectTitle: projectTitle,
          languageCode: widget.exportLanguageCode,
          locale: projectTitle == null ? null : Localizations.localeOf(context),
        ),
        onLayout: (_) => ActionSummaryPdfService.buildPdf(
          summary: _summary,
          sourceAnalysisTitle: widget.sourceAnalysisTitle,
          generatedAt: generatedAt,
          referenceNumber: widget.exportReferenceNumber,
          texts: ActionSummaryPdfTexts.fromLocalizations(
            AppLocalizations.of(context),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  String _structuredSummaryContent() {
    final generatedAt = DateTime.now();
    final l10n = AppLocalizations.of(context);
    return [
      'PreventIA Belgique',
      l10n.actionSummary,
      l10n.projectToValidate,
      '',
      l10n.linkedAnalysis(widget.sourceAnalysisTitle),
      '${l10n.generatedAt} : ${_formatDate(generatedAt)}',
      '${l10n.source} : ${l10n.generatedLocallyFromAnalysis}',
      l10n.status(l10n.projectToValidate),
      '',
      _summaryService.buildCopyText(_summary, language: l10n.localeName),
      '',
      l10n.validationNoticeTitle,
      l10n.localValidationNotice,
    ].join('\n');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.actionsToDo),
        actions: [
          IconButton(
            tooltip: l10n.copy,
            onPressed: _copySummary,
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
      body: AdaptivePage(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Text(
              l10n.summaryIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.linkedAnalysis(widget.sourceAnalysisTitle),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.expectedProofExplanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _copySummary,
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.copy),
                ),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveSummary,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.saveSummary),
                ),
                FilledButton.tonalIcon(
                  onPressed: _isExportingPdf ? null : _exportSummaryPdf,
                  icon: _isExportingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.exportSummaryPdf),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'A. ${l10n.priorityActions}',
              emptyText: l10n.noPriorityActions,
              children: _summary.priorityActions
                  .map(
                    (action) => _InfoCard(
                      rows: [
                        _InfoRow(l10n.actionToPerform, action.action),
                        _InfoRow(l10n.riskConcerned, action.risk),
                        _InfoRow(l10n.responsible, action.responsible),
                        _InfoRow(l10n.deadline, action.deadline),
                        _InfoRow(l10n.expectedProof, action.expectedProof),
                        _InfoRow(l10n.whyImportant, action.importance),
                        _InfoRow(l10n.advisorExpected, l10n.advisorMustCheck),
                      ],
                    ),
                  )
                  .toList(),
            ),
            _Section(
              title: 'B. ${l10n.documentsToPrepare}',
              emptyText: l10n.noDocumentsDetected,
              children: _summary.documents
                  .map(
                    (document) => _InfoCard(
                      rows: [
                        _InfoRow(l10n.document, document.document),
                        _InfoRow(l10n.objective, document.objective),
                        _InfoRow(
                          l10n.whyImportant,
                          l10n.documentsNecessityExplanation,
                        ),
                        _InfoRow(l10n.expectedResult, document.expectedResult),
                      ],
                    ),
                  )
                  .toList(),
            ),
            _Section(
              title: 'C. ${l10n.actorsToConsult}',
              emptyText: l10n.noActorsDetected,
              children: _summary.actors
                  .map(
                    (actor) => _InfoCard(
                      rows: [
                        _InfoRow(l10n.actor, actor.actor),
                        _InfoRow(l10n.whyConsult, actor.reason),
                        _InfoRow(l10n.expectedTrace, actor.expectedTrace),
                        _InfoRow(
                          l10n.explanation,
                          l10n.consultationExplanation,
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            _Section(
              title: 'D. ${l10n.fieldChecks}',
              emptyText: l10n.noFieldChecks,
              children: _summary.fieldChecks
                  .map(
                    (check) => _InfoCard(
                      rows: [
                        _InfoRow(l10n.itemToVerify, check),
                        _InfoRow(
                          l10n.whyImportant,
                          l10n.unverifiedInfoImportance,
                        ),
                        _InfoRow(l10n.howToVerify, l10n.verifyBy),
                        _InfoRow(l10n.possibleProof, l10n.proofExamples),
                      ],
                    ),
                  )
                  .toList(),
            ),
            _Section(
              title: 'E. ${l10n.expectedProofs}',
              emptyText: l10n.noProofsDetected,
              children: _summary.expectedProofs
                  .map(
                    (proof) => _InfoCard(
                      rows: [
                        _InfoRow(l10n.proof, proof),
                        _InfoRow(l10n.whatItIsFor, l10n.proofPurpose),
                        _InfoRow(
                          l10n.concreteExample,
                          l10n.proofConcreteExamples,
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_outlined),
              label: Text(l10n.back),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = children.isEmpty
        ? Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
        : LayoutBreakpoints.isDesktop(context)
        ? LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final cardWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: 10,
                children: children
                    .map((child) => SizedBox(width: cardWidth, child: child))
                    .toList(),
              );
            },
          )
        : Column(children: children);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(row.value),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}
