import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/pdf_texts.dart';
import '../models/document_family.dart';
import '../models/generation_source.dart';
import '../services/analysis_project_service.dart';
import '../services/ai_document_service.dart';
import '../services/docx_export_service.dart';
import '../services/file_export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/pdf_delivery_service.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/simple_markdown_document_view.dart';
import 'action_summary_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.documentType,
    required this.content,
    required this.generationSource,
    this.documentReference,
    this.linkedDocuments = const [],
    super.key,
  });

  final String documentType;
  final String content;
  final String? documentReference;
  final GenerationSource generationSource;
  final List<AiLinkedDocument> linkedDocuments;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _isExportingPdf = false;
  bool _isExportingWord = false;

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
      await AnalysisProjectService().saveAnalysisWithSummary(
        analysisTitle: widget.documentType,
        analysisContent: widget.content,
        referenceNumber: widget.documentReference,
        projectStatus: l10n.projectToValidate,
        actionSummaryTitle: l10n.actionSummary,
        linkedAnalysisLabel: l10n.completeAnalysis,
        generatedAtLabel: l10n.generatedAt,
        sourceFieldLabel: l10n.source,
        sourceValue: _pdfSourceText(l10n),
        statusLabel: l10n.status('').replaceAll(':', '').trim(),
        validationNoticeTitle: l10n.validationNoticeTitle,
        validationNotice: l10n.localValidationNotice,
      );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).savedAnalysisFolderMessage),
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    final generatedAt = DateTime.now();
    final l10n = AppLocalizations.of(context);
    final exportProjectTitle = _exportProjectTitleFromContent();
    final exportReference = PdfExportService.resolveDocumentReference(
      metadataDocumentReference: widget.documentReference,
      content: widget.content,
    );

    try {
      await PdfDeliveryService.exportPdf(
        context: context,
        name: FileExportService.documentFileName(
          projectTitle: exportProjectTitle,
          documentType: widget.documentType,
          languageCode: l10n.localeName,
          referenceNumber: exportReference,
        ),
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
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  Future<void> _exportWord() async {
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
      await FileExportService.saveDocxBytes(
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
      );
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
}
