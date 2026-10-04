import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../models/preventia_project.dart';
import '../services/preventia_project_service.dart';
import '../services/preventia_document_storage_service.dart';
import '../widgets/adaptive_page.dart';

class PreventiaProjectScreen extends StatefulWidget {
  const PreventiaProjectScreen({this.project, super.key});

  final PreventiaProject? project;

  @override
  State<PreventiaProjectScreen> createState() => _PreventiaProjectScreenState();
}

class _PreventiaProjectScreenState extends State<PreventiaProjectScreen> {
  final _service = PreventiaProjectService();
  PreventiaProject? _project;
  List<PreventiaProject> _knownProjects = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentProject();
  }

  Future<void> _loadCurrentProject() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final project = widget.project ?? await _service.getCurrentProject();
    if (widget.project != null) {
      await _service.setCurrentProject(widget.project!);
    }
    final knownProjects = await _service.getKnownProjects();
    if (!mounted) return;
    setState(() {
      _project = project;
      _knownProjects = knownProjects;
      _error = _service.lastError;
      _isLoading = false;
    });
  }

  Future<void> _createProject() async {
    final companyController = TextEditingController();
    final siteController = TextEditingController();
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Créer un dossier PreventIA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisissez l’emplacement où PreventIA créera le dossier '
              'de la société. Les documents resteront enregistrés localement '
              'sur cet appareil.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: companyController,
              decoration: const InputDecoration(labelText: 'Entreprise'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: siteController,
              decoration: const InputDecoration(labelText: 'Site (facultatif)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop((companyController.text.trim(), siteController.text.trim())),
            child: const Text('Choisir le dossier de base'),
          ),
        ],
      ),
    );
    companyController.dispose();
    siteController.dispose();
    if (values == null || !mounted) return;
    if (values.$1.isEmpty) {
      _showMessage('Le nom de la société est obligatoire.');
      return;
    }
    final existing = await _service.findProject(
      companyName: values.$1,
      siteName: values.$2,
    );
    if (!mounted) return;
    if (existing != null) {
      await _setActiveProject(existing);
      if (mounted) {
        _showMessage(
          'Cette société possède déjà un dossier PreventIA. Il est maintenant actif.',
        );
      }
      return;
    }

    final baseDirectory = await FilePicker.getDirectoryPath(
      dialogTitle:
          'Choisissez l’emplacement où enregistrer le dossier PreventIA',
    );
    if (baseDirectory == null || !mounted) return;
    await _runProjectOperation(() async {
      final project = await _service.createProject(
        companyName: values.$1,
        siteName: values.$2,
        baseDirectoryPath: baseDirectory,
      );
      if (mounted) {
        setState(() => _project = project);
        await _loadKnownProjects();
      }
    });
  }

  Future<void> _chooseExistingProject() async {
    final selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choisissez un dossier PreventIA existant',
    );
    if (selectedDirectory == null || !mounted) return;
    await _runProjectOperation(() async {
      final projectJson = await _findProjectJson(selectedDirectory);
      final project = await _service.loadProject(projectJson);
      await _service.setCurrentProject(project);
      if (mounted) {
        setState(() => _project = project);
        await _loadKnownProjects();
      }
    });
  }

  Future<void> _loadKnownProjects() async {
    final projects = await _service.getKnownProjects();
    if (mounted) setState(() => _knownProjects = projects);
  }

  Future<void> _setActiveProject(PreventiaProject project) async {
    await _runProjectOperation(() async {
      await _service.setCurrentProject(project);
      if (mounted) setState(() => _project = project);
    });
  }

  Future<void> _changeLocation() async {
    final current = _project;
    if (current == null) return;
    final baseDirectory = await FilePicker.getDirectoryPath(
      dialogTitle:
          'Choisissez l’emplacement où enregistrer le dossier PreventIA',
    );
    if (baseDirectory == null || !mounted) return;
    await _runProjectOperation(() async {
      final replacement = await _service.createProject(
        companyName: current.companyName,
        siteName: current.siteName,
        baseDirectoryPath: baseDirectory,
      );
      if (replacement.basePath != current.basePath) {
        await _service.removeProjectFromList(current);
        await _service.setCurrentProject(replacement);
      }
      if (mounted) setState(() => _project = replacement);
      await _loadKnownProjects();
    });
  }

  Future<void> _removeFromList(PreventiaProject project) async {
    await _runProjectOperation(() async {
      await _service.removeProjectFromList(project);
      final current = _project;
      if (current?.basePath == project.basePath && mounted) {
        setState(() => _project = null);
      }
      await _loadKnownProjects();
      if (mounted) {
        _showMessage(
          'Le dossier est retiré de PreventIA, mais les fichiers restent sur votre ordinateur.',
        );
      }
    });
  }

  Future<void> _deleteFolder(PreventiaProject project) async {
    var understood = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Supprimer définitivement le dossier ?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cette action supprimera le dossier local et tous les documents '
                'Word/PDF qu’il contient. Cette action est irréversible.',
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: understood,
                onChanged: (value) =>
                    setDialogState(() => understood = value ?? false),
                title: const Text(
                  'Je comprends que les fichiers seront supprimés définitivement.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: understood
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: const Text('Supprimer le dossier complet'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runProjectOperation(() async {
      await _service.deleteProjectPermanently(project);
      if (_project?.basePath == project.basePath && mounted) {
        setState(() => _project = null);
      }
      await _loadKnownProjects();
    });
  }

  Future<String> _findProjectJson(String selectedDirectory) async {
    return path.join(
      selectedDirectory,
      PreventiaProjectService.projectFileName,
    );
  }

  Future<void> _runProjectOperation(Future<void> Function() operation) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await operation();
      if (mounted) setState(() => _error = null);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
        _showMessage(error.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setItemStatus(
    _ProjectItemKind kind,
    String id,
    String status,
  ) async {
    final project = _project;
    if (project == null) return;
    final now = DateTime.now();
    final updated = switch (kind) {
      _ProjectItemKind.action => project.copyWith(
        actionItems: project.actionItems
            .map(
              (item) => item.id == id
                  ? item.copyWith(status: status, updatedAt: now)
                  : item,
            )
            .toList(),
      ),
      _ProjectItemKind.risk => project.copyWith(
        riskItems: project.riskItems
            .map((item) => item.id == id ? item.copyWith(status: status) : item)
            .toList(),
      ),
      _ProjectItemKind.evidence => project.copyWith(
        evidenceToCollect: project.evidenceToCollect
            .map((item) => item.id == id ? item.copyWith(status: status) : item)
            .toList(),
        photosToTake: project.photosToTake
            .map((item) => item.id == id ? item.copyWith(status: status) : item)
            .toList(),
      ),
      _ProjectItemKind.diu => project.copyWith(
        diuItems: project.diuItems
            .map((item) => item.id == id ? item.copyWith(status: status) : item)
            .toList(),
      ),
      _ProjectItemKind.piu => project.copyWith(
        piuItems: project.piuItems
            .map((item) => item.id == id ? item.copyWith(status: status) : item)
            .toList(),
      ),
    };
    await _runProjectOperation(() async {
      await _service.saveProject(updated);
      if (mounted) setState(() => _project = updated);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openActiveFolder() async {
    final project = _project;
    if (project == null) return;
    await _openProjectFolder(project);
  }

  Future<void> _openProjectFolder(PreventiaProject project) async {
    final error = await PreventiaDocumentStorageService.openFolder(
      project.basePath,
    );
    if (error != null && mounted) _showMessage(error);
  }

  Future<void> _regenerate({required bool piu}) async {
    final project = _project;
    if (project == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Créer une nouvelle version'),
        content: const Text(
          'Un document existe déjà. Voulez-vous créer une nouvelle version ?',
        ),
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
    if (confirmed != true) return;
    await _runProjectOperation(() async {
      final filePath = piu
          ? await _service.regeneratePiuWithValidatedItems(project)
          : await _service.regeneratePgaWithValidatedItems(project);
      final refreshed = await _service.getCurrentProject();
      if (mounted) {
        setState(() => _project = refreshed ?? project);
        _showMessage('Nouvelle version créée : $filePath');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 9,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dossier PreventIA'),
          bottom: _project == null
              ? null
              : const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Documents'),
                    Tab(text: 'Analyses de risques'),
                    Tab(text: 'PIU'),
                    Tab(text: 'PGA/PAA/PGP'),
                    Tab(text: 'Actions extraites'),
                    Tab(text: 'Candidats PIU'),
                    Tab(text: 'Candidats DIU'),
                    Tab(text: 'Preuves / photos'),
                    Tab(text: 'Sites concernés'),
                  ],
                ),
        ),
        body: AdaptivePage(
          maxTabletWidth: 900,
          maxDesktopWidth: 1100,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final project = _project;
    if (project == null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PrivacyNotice(),
            const SizedBox(height: 12),
            _knownProjectsCard(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _createProject,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Créer un dossier PreventIA'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseExistingProject,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Choisir un dossier'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PrivacyNotice(),
        const SizedBox(height: 8),
        _knownProjectsCard(),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dossier PreventIA — ${project.companyName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                SelectableText(project.basePath),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openActiveFolder,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Ouvrir dans Finder'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _changeLocation,
                      icon: const Icon(Icons.drive_file_move_outlined),
                      label: const Text('Changer d’emplacement'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _createProject,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: const Text('Créer nouveau dossier'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _chooseExistingProject,
                      icon: const Icon(Icons.folder_copy_outlined),
                      label: const Text('Choisir dossier existant'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _regenerate(piu: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Régénérer PIU avec éléments validés'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _regenerate(piu: false),
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Régénérer PGA/PAA/PGP avec actions validées',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            children: [
              _documents(project),
              _documents(
                project,
                filter: (item) =>
                    item.documentType.toLowerCase().contains('analyse') &&
                    item.documentType.toLowerCase().contains('risque'),
              ),
              _documents(
                project,
                filter: (item) =>
                    item.documentType.toLowerCase().contains('piu') ||
                    item.documentType.toLowerCase().contains('plan interne'),
              ),
              _documents(
                project,
                filter: (item) => RegExp(
                  r'pga|paa|pgp',
                  caseSensitive: false,
                ).hasMatch(item.documentType),
              ),
              _actions(project),
              _piu(project),
              _diu(project),
              _evidence(project),
              _sites(project),
            ],
          ),
        ),
      ],
    );
  }

  Widget _knownProjectsCard() {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: _project == null,
        title: const Text('Dossiers enregistrés en local'),
        subtitle: Text('${_knownProjects.length} dossier(s) connu(s)'),
        children: [
          if (_knownProjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun dossier enregistré en local.'),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _knownProjects.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _knownProjectTile(_knownProjects[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _knownProjectTile(PreventiaProject project) {
    final isActive = _project?.basePath == project.basePath;
    final isDuplicate =
        _knownProjects
            .where(
              (item) =>
                  projectKey(item.companyName, item.siteName) ==
                  projectKey(project.companyName, project.siteName),
            )
            .length >
        1;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${project.companyName} — ${project.siteName}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          SelectableText(project.basePath),
          if (isDuplicate) ...[
            const SizedBox(height: 4),
            const Text(
              'Plusieurs dossiers existent pour cette même société.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Date de création : ${_formatDate(project.createdAt)}\n'
            'Dernière modification : ${_formatDate(project.updatedAt)}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: () => _openProjectFolder(project),
                child: const Text('Ouvrir'),
              ),
              TextButton(
                onPressed: isActive ? null : () => _setActiveProject(project),
                child: Text(
                  isActive
                      ? 'Dossier actif'
                      : isDuplicate
                      ? 'Garder ce dossier comme principal'
                      : 'Définir comme dossier actif',
                ),
              ),
              TextButton(
                onPressed: () => _removeFromList(project),
                child: const Text('Supprimer de la liste'),
              ),
              TextButton(
                onPressed: () => _deleteFolder(project),
                child: const Text('Supprimer le dossier complet'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  Widget _documents(
    PreventiaProject project, {
    bool Function(PreventiaProjectDocument)? filter,
  }) => _list(
    project.documents
        .where(filter ?? (_) => true)
        .map(
          (item) => Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(item.title),
                  subtitle: SelectableText(
                    [
                      item.documentType,
                      'Source : ${item.reference.isEmpty ? item.id : item.reference}',
                      if (item.siteName.isNotEmpty) 'Site : ${item.siteName}',
                      if (item.wordPath.isNotEmpty) 'Word : ${item.wordPath}',
                      if (item.pdfPath.isNotEmpty) 'PDF : ${item.pdfPath}',
                    ].join('\n'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () =>
                            PreventiaDocumentStorageService.openFolder(
                              item.pdfPath.isNotEmpty
                                  ? item.pdfPath
                                  : item.wordPath,
                            ),
                        child: const Text('Ouvrir'),
                      ),
                      TextButton(
                        onPressed: () => _openProjectFolder(project),
                        child: const Text('Ouvrir le dossier'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _service.removeIndexedDocument(
                            documentId: item.id,
                            documentType: item.documentType,
                            title: item.title,
                            deleteFiles: false,
                          );
                          await _loadCurrentProject();
                        },
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
  );

  Widget _sites(PreventiaProject project) => _list(
    project.sites.map(
      (site) => ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: Text(site),
      ),
    ),
  );

  Widget _actions(PreventiaProject project) => _list(
    project.actionItems.map(
      (item) => _statusTile(
        source: item.sourceDocumentType,
        title: item.action,
        status: item.status,
        priority: item.priority,
        details: [
          if (item.responsible.isNotEmpty) 'Responsable : ${item.responsible}',
          if (item.deadline.isNotEmpty) 'Délai : ${item.deadline}',
          if (item.evidenceExpected.isNotEmpty)
            'Preuve : ${item.evidenceExpected}',
        ],
        onChanged: (status) =>
            _setItemStatus(_ProjectItemKind.action, item.id, status),
      ),
    ),
  );

  Widget _evidence(PreventiaProject project) => _list(
    [...project.evidenceToCollect, ...project.photosToTake].map(
      (item) => _statusTile(
        source: item.sourceDocumentId,
        title: item.label,
        status: item.status,
        onChanged: (status) =>
            _setItemStatus(_ProjectItemKind.evidence, item.id, status),
      ),
    ),
  );

  Widget _diu(PreventiaProject project) => _list(
    project.diuItems.map(
      (item) => _statusTile(
        source: item.sourceDocumentId,
        title: item.riskOrConstraint,
        status: item.status,
        onChanged: (status) =>
            _setItemStatus(_ProjectItemKind.diu, item.id, status),
      ),
    ),
  );

  Widget _piu(PreventiaProject project) => _list(
    project.piuItems.map(
      (item) => _statusTile(
        source: item.sourceDocumentId,
        title: item.emergencyTopic,
        status: item.status,
        details: [
          if (item.information.isNotEmpty) item.information,
          'Chapitre suggéré : Informations issues des analyses de risques',
        ],
        onChanged: (status) =>
            _setItemStatus(_ProjectItemKind.piu, item.id, status),
      ),
    ),
  );

  Widget _list(Iterable<Widget> children) {
    final items = children.toList();
    if (items.isEmpty) {
      return const Center(child: Text('Aucun élément extrait pour le moment.'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) => items[index],
    );
  }

  Widget _statusTile({
    required String source,
    required String title,
    required String status,
    String priority = '',
    List<String> details = const [],
    required ValueChanged<String> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              [
                'Source document : $source',
                if (priority.isNotEmpty) 'Priorité : $priority',
                'Statut : $status',
              ].join(' • '),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(details.join('\n')),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: () => onChanged('validé'),
                  child: const Text('Valider'),
                ),
                TextButton(
                  onPressed: () => onChanged('ignoré'),
                  child: const Text('Ignorer'),
                ),
                TextButton(
                  onPressed: () => onChanged('à revoir'),
                  child: const Text('À revoir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Les documents du client restent enregistrés localement sur cet '
          'appareil. PreventIA n’envoie pas ce dossier vers le serveur.',
        ),
      ),
    );
  }
}

enum _ProjectItemKind { action, risk, evidence, diu, piu }
