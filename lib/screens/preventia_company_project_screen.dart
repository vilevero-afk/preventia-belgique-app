import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/preventia_company_project.dart';
import '../services/preventia_company_project_service.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/simple_markdown_document_view.dart';

class PreventiaCompanyProjectScreen extends StatefulWidget {
  const PreventiaCompanyProjectScreen({
    required this.companyKey,
    this.directoryPicker,
    super.key,
  });

  final String companyKey;
  final Future<String?> Function()? directoryPicker;

  @override
  State<PreventiaCompanyProjectScreen> createState() =>
      _PreventiaCompanyProjectScreenState();
}

class _PreventiaCompanyProjectScreenState
    extends State<PreventiaCompanyProjectScreen> {
  final _service = PreventiaCompanyProjectService();
  PreventiaCompanyProject? _project;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _reloadProject();
  }

  Future<void> _reloadProject() async {
    final loaded = await _service.findByKey(widget.companyKey);
    if (mounted) {
      setState(() {
        _project = loaded;
        _loaded = true;
      });
    }
  }

  Future<void> _defineLocalFolder() async {
    final project = _project;
    if (project == null) return;
    final selected =
        await (widget.directoryPicker?.call() ??
            FilePicker.getDirectoryPath(
              dialogTitle: 'Définir le dossier local de ${project.companyName}',
            ));
    if (selected == null || selected.trim().isEmpty) return;
    await _service.setLocalFolder(project, selected);
    if (mounted) {
      await _reloadProject();
    }
  }

  Future<void> _setStatus(_ItemKind kind, String id, String status) async {
    final project = _project;
    if (project == null) return;
    final updated = switch (kind) {
      _ItemKind.action => project.copyWith(
        actionItems: project.actionItems
            .map((item) => item.id == id ? item.copyWith(status: status) : item)
            .toList(),
      ),
      _ItemKind.piu => project.copyWith(
        piuItems: project.piuItems
            .map((item) => item.id == id ? item.copyWith(status: status) : item)
            .toList(),
      ),
      _ItemKind.diu => project.copyWith(
        diuItems: project.diuItems
            .map((item) => item.id == id ? item.copyWith(status: status) : item)
            .toList(),
      ),
      _ItemKind.evidence => project.copyWith(
        evidenceItems: project.evidenceItems
            .map((item) => item.id == id ? item.copyWith(status: status) : item)
            .toList(),
      ),
    };
    await _service.saveProject(updated);
    if (mounted) await _reloadProject();
  }

  Future<void> _deleteAnalysis(String id) async {
    await _service.deleteAnalysis(widget.companyKey, id);
    if (mounted) await _reloadProject();
  }

  void _open(PreventiaCompanyDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(document.title)),
          body: AdaptivePage(
            child: SimpleMarkdownDocumentView(
              content: document.markdown.isEmpty
                  ? '# ${document.title}\n\nStatut : ${document.status}'
                  : document.markdown,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    if (project == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.of(context).pop()),
          title: const Text('Dossier PreventIA'),
        ),
        body: Center(
          child: _loaded
              ? const Text('Dossier société introuvable.')
              : const CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('company-folder-back-button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Dossier PreventIA — ${project.companyName}'),
      ),
      body: AdaptivePage(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        project.localFolderPath == null
                            ? 'Aucun dossier physique défini — historique local actif'
                            : project.localFolderPath!,
                      ),
                      OutlinedButton.icon(
                        key: const Key('define-local-folder-button'),
                        onPressed: _defineLocalFolder,
                        icon: const Icon(Icons.create_new_folder_outlined),
                        label: const Text('Définir un dossier local'),
                      ),
                    ],
                  ),
                ),
              ),
              _documentsSection(project.analyses),
              _automaticDocumentSection(
                title: 'PIU',
                document: project.piuDocument,
                missingMessage: 'PIU non encore créé.',
                generateLabel: 'Ouvrir / Générer PIU',
              ),
              _automaticDocumentSection(
                title: 'PGA/PAA/PGP',
                document: project.pgaDocument,
                missingMessage: 'PGA/PAA/PGP non encore créé.',
                generateLabel: 'Ouvrir / Générer PGA/PAA/PGP',
                candidateCount: project.actionItems.length,
              ),
              _actions(project),
              _piuItems(project),
              _diuItems(project),
              _evidenceItems(project),
            ],
          ),
        ),
      ),
    );
  }

  Widget _documentsSection(
    List<PreventiaCompanyDocument> documents,
  ) => _section(
    title: 'Analyses de risques',
    emptyMessage: 'Aucune analyse de risques enregistrée.',
    children: documents.map(
      (document) => ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(document.title),
        subtitle: Text(
          'Référence : ${document.reference.isEmpty ? '—' : document.reference}\n'
          'Date : ${_formatDate(document.createdAt)}',
        ),
        trailing: Wrap(
          children: [
            TextButton(
              onPressed: () => _open(document),
              child: const Text('Ouvrir'),
            ),
            TextButton(
              onPressed: () => _deleteAnalysis(document.id),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _automaticDocumentSection({
    required String title,
    required PreventiaCompanyDocument? document,
    required String missingMessage,
    required String generateLabel,
    int? candidateCount,
  }) {
    return _section(
      title: title,
      emptyMessage: missingMessage,
      children: document == null
          ? const []
          : [
              ListTile(
                title: Text(document.title),
                subtitle: Text(
                  'Statut : ${document.status}'
                  '${candidateCount == null ? '' : '\nActions candidates : $candidateCount'}',
                ),
                trailing: OutlinedButton(
                  onPressed: () {
                    _open(document);
                  },
                  child: Text(generateLabel),
                ),
              ),
            ],
    );
  }

  Widget _actions(PreventiaCompanyProject project) => _section(
    title: 'Actions extraites',
    children: project.actionItems.map(
      (item) => _statusTile(
        title: item.action,
        source: item.sourceDocumentType,
        status: item.status,
        details: [
          item.priority,
          item.responsible,
          item.deadline,
          item.evidenceExpected,
        ].where((value) => value.isNotEmpty).join(' · '),
        onStatus: (status) => _setStatus(_ItemKind.action, item.id, status),
      ),
    ),
    emptyMessage: 'Aucune action extraite pour l’instant.',
  );

  Widget _piuItems(PreventiaCompanyProject project) => _section(
    title: 'Candidats PIU',
    children: project.piuItems.map(
      (item) => _statusTile(
        title: item.emergencyTopic,
        source: item.sourceDocumentId,
        status: item.status,
        details: item.information,
        onStatus: (status) => _setStatus(_ItemKind.piu, item.id, status),
      ),
    ),
    emptyMessage: 'Aucun point PIU extrait pour l’instant.',
  );

  Widget _diuItems(PreventiaCompanyProject project) => _section(
    title: 'Candidats DIU',
    children: project.diuItems.map(
      (item) => _statusTile(
        title: item.riskOrConstraint,
        source: item.sourceDocumentId,
        status: item.status,
        details: item.instructionForFutureWork,
        onStatus: (status) => _setStatus(_ItemKind.diu, item.id, status),
      ),
    ),
    emptyMessage: 'Aucun point DIU extrait pour l’instant.',
  );

  Widget _evidenceItems(PreventiaCompanyProject project) => _section(
    title: 'Preuves/photos',
    children: project.evidenceItems.map(
      (item) => _statusTile(
        title: item.label,
        source: item.sourceDocumentId,
        status: item.status,
        details: item.type,
        onStatus: (status) => _setStatus(_ItemKind.evidence, item.id, status),
      ),
    ),
    emptyMessage: 'Aucune preuve/photo à collecter pour l’instant.',
  );

  Widget _statusTile({
    required String title,
    required String source,
    required String status,
    required String details,
    required ValueChanged<String> onStatus,
  }) => ListTile(
    title: Text(title),
    subtitle: Text('Source : $source\n$details\nStatut : $status'),
    isThreeLine: true,
    trailing: PopupMenuButton<String>(
      onSelected: onStatus,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'validé', child: Text('Valider')),
        PopupMenuItem(value: 'ignoré', child: Text('Ignorer')),
        PopupMenuItem(value: 'à revoir', child: Text('À revoir')),
      ],
    ),
  );

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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

enum _ItemKind { action, piu, diu, evidence }
