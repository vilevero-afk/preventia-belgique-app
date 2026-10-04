import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/risk_assessment_assistant_service.dart';
import '../services/preventia_company_project_service.dart';
import '../models/preventia_company_project.dart';
import '../services/docx_export_service.dart';
import '../services/file_export_service.dart';

class RiskAssessmentAssistantScreen extends StatefulWidget {
  const RiskAssessmentAssistantScreen({super.key});

  @override
  State<RiskAssessmentAssistantScreen> createState() => _AssistantState();
}

class _AssistantState extends State<RiskAssessmentAssistantScreen> {
  final _subject = TextEditingController();
  final _answers = <String, String>{};
  final _conclusions = <String, String>{};
  final _decisions = <String, String>{};
  List<FieldQuestion> _questions = [];
  List<AssistantDanger> _dangers = [];
  int _step = 0;
  int _revision = 0;
  bool _saving = false;
  String? _seededSubject;
  static const _draftKey = 'risk_assessment_assistant_latest_markdown';
  static const _titles = [
    'Sujet',
    'Questionnaire de base',
    'Questions terrain proposées',
    'Dangers identifiés',
    'Cotation provisoire',
    'Conclusions proposées',
  ];

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    Key? key,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: key,
      initialValue: value,
      minLines: 1,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    ),
  );

  bool get _isErgonomics =>
      _subject.text.toLowerCase().contains('ergonomie') ||
      _subject.text.toLowerCase().contains('écran') ||
      _subject.text.toLowerCase().contains('ecran') ||
      _subject.text.toLowerCase().contains('poste écran');

  void _fillErgonomicsTest() {
    if (_questions.isEmpty) {
      _seed(
        _subject.text.trim().isEmpty
            ? 'Ergonomie poste écran'
            : _subject.text.trim(),
      );
    }
    RiskAssessmentAssistantService.fillErgonomicsTest(_questions);
    _conclusions
      ..clear()
      ..addAll(
        RiskAssessmentAssistantService.conclusionsFor(_questions, _dangers),
      );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Questionnaire ergonomie rempli pour le scénario test.'),
      ),
    );
  }

  void _next() {
    if (_step == 0) {
      final subject = _subject.text.trim();
      if (subject.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez préciser un sujet.')),
        );
        return;
      }
      if (_seededSubject != subject) {
        // Keep edited lists when returning to change the subject. Reseeding is explicit.
        if (_seededSubject == null) _seed(subject);
      }
    }
    if (_step == 4 && _conclusions.isEmpty) {
      _conclusions.addAll(
        RiskAssessmentAssistantService.conclusionsFor(_questions, _dangers),
      );
    }
    setState(() => _step++);
  }

  void _seed(String subject) {
    _questions = RiskAssessmentAssistantService.questionsFor(subject);
    _dangers = RiskAssessmentAssistantService.dangersFor(subject);
    _seededSubject = subject;
    _conclusions.clear();
    _revision++;
  }

  Future<void> _regenerate() async {
    if (_subject.text.trim().isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renouveler les propositions ?'),
        content: const Text(
          'Les questions, dangers, cotations et conclusions modifiés seront remplacés par les propositions du sujet actuel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remplacer'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) setState(() => _seed(_subject.text.trim()));
  }

  Widget _content(int step) {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _subject,
              decoration: const InputDecoration(
                labelText: 'Quel sujet voulez-vous analyser ?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RiskAssessmentAssistantService.subjects
                  .map(
                    (s) => ActionChip(
                      label: Text(s),
                      onPressed: () => setState(() => _subject.text = s),
                    ),
                  )
                  .toList(),
            ),
            if (_isErgonomics) ...[
              OutlinedButton.icon(
                onPressed: _fillErgonomicsTest,
                icon: const Icon(Icons.science_outlined),
                label: const Text(
                  'Remplir automatiquement — test ergonomie rien n’est fait',
                ),
              ),
            ],
            if (_seededSubject != null) ...[
              Text(
                'Propositions actuelles : $_seededSubject. Les modifications sont conservées tant que vous ne renouvelez pas les propositions.',
              ),
              TextButton(
                onPressed: _regenerate,
                child: const Text('Renouveler les propositions pour ce sujet'),
              ),
            ],
          ],
        );
      case 1:
        return Column(
          children: [
            if (_isErgonomics)
              FilledButton.icon(
                onPressed: _fillErgonomicsTest,
                icon: const Icon(Icons.science_outlined),
                label: const Text(
                  'Remplir automatiquement — test ergonomie rien n’est fait',
                ),
              ),
            ...RiskAssessmentAssistantService.questionnaire.map(
              (label) => _field(
                label,
                _answers[label] ?? '',
                (v) => _answers[label] = v,
                key: ValueKey(label),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            if (_isErgonomics)
              FilledButton.icon(
                onPressed: _fillErgonomicsTest,
                icon: const Icon(Icons.science_outlined),
                label: const Text(
                  'Remplir automatiquement — test ergonomie rien n’est fait',
                ),
              ),
            for (final q in _questions)
              Card(
                key: ObjectKey(q),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _field('Question terrain', q.text, (v) => q.text = v),
                      DropdownButtonFormField<String>(
                        initialValue: q.answer,
                        decoration: const InputDecoration(labelText: 'Réponse'),
                        items: const [
                          DropdownMenuItem(value: 'oui', child: Text('Oui')),
                          DropdownMenuItem(value: 'non', child: Text('Non')),
                          DropdownMenuItem(
                            value: 'non_applicable',
                            child: Text('Non applicable'),
                          ),
                          DropdownMenuItem(
                            value: 'a_verifier',
                            child: Text('À vérifier'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => q.answer = v ?? 'a_verifier'),
                      ),
                      _field('Commentaire', q.comment, (v) => q.comment = v),
                      _field(
                        'Preuve attendue',
                        q.evidenceExpected,
                        (v) => q.evidenceExpected = v,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Photo requise'),
                        value: q.photoRequired,
                        onChanged: (v) =>
                            setState(() => q.photoRequired = v ?? false),
                      ),
                      if (q.photoRequired)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Photo à ajouter plus tard'),
                        ),
                      Row(
                        children: [
                          Expanded(child: Text('Statut : ${q.status}')),
                          IconButton(
                            tooltip: 'Supprimer la question',
                            onPressed: () =>
                                setState(() => _questions.remove(q)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _questions.add(FieldQuestion(''))),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une question'),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            const Text(
              'Les dangers sont des hypothèses à compléter sur le terrain. Indiquez les références des preuves et photos attendues ; leur collecte reste à confirmer.',
            ),
            for (final d in _dangers)
              Card(
                key: ObjectKey(d),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _field('Danger', d.danger, (v) => d.danger = v),
                      _field(
                        'Scénario plausible',
                        d.scenario,
                        (v) => d.scenario = v,
                      ),
                      _field(
                        'Personnes exposées',
                        d.people,
                        (v) => d.people = v,
                      ),
                      _field(
                        'Mesures existantes',
                        d.measures,
                        (v) => d.measures = v,
                      ),
                      _field(
                        'Preuve attendue',
                        d.evidence,
                        (v) => d.evidence = v,
                      ),
                      _field('Photo attendue', d.photo, (v) => d.photo = v),
                      TextButton.icon(
                        onPressed: () => setState(() => _dangers.remove(d)),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer le danger'),
                      ),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _dangers.add(AssistantDanger(''))),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un danger'),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Échelle provisoire de 1 à 5 : gravité de mineure à majeure, probabilité de très improbable à très probable, exposition de rare à permanente. Score = G × P × E. Faible : 1–19 ; moyen : 20–49 ; élevé : 50–99 ; critique : 100–125. Cette grille doit être validée pour la situation étudiée.',
            ),
            for (final d in _dangers)
              Card(
                key: ObjectKey(d),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(d.danger),
                      _rating('Gravité', d.gravity, (v) => d.gravity = v),
                      _rating(
                        'Probabilité',
                        d.probability,
                        (v) => d.probability = v,
                      ),
                      _rating('Exposition', d.exposure, (v) => d.exposure = v),
                      Text(
                        'Score : ${d.score ?? 'Non coté'} — Niveau : ${d.level}',
                      ),
                    ],
                  ),
                ),
              ),
            if (_dangers.isEmpty)
              const Text(
                'Aucun danger renseigné. Retournez à l’étape précédente pour compléter l’analyse.',
              ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Propositions à vérifier et modifier. Une réponse oui/non doit être décidée par le conseiller ; aucune intégration automatique n’est effectuée.',
            ),
            TextButton(
              onPressed: () => setState(() {
                _conclusions.addAll(
                  RiskAssessmentAssistantService.conclusionsFor(
                    _questions,
                    _dangers,
                  ),
                );
                _revision++;
              }),
              child: const Text('Recalculer les conclusions proposées'),
            ),
            for (final label in RiskAssessmentAssistantService.conclusionLabels)
              _field(
                label,
                _conclusions[label] ?? '',
                (v) => _conclusions[label] = v,
                key: ValueKey('$label-$_revision'),
              ),
            for (final label in RiskAssessmentAssistantService.decisionLabels)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: _decisions[label] ?? 'À déterminer',
                  decoration: InputDecoration(labelText: label),
                  items: ['À déterminer', 'Oui', 'Non']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _decisions[label] = v!),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _saving ? null : _exportWord,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Exporter Word'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _saveToCompanyFolder,
              icon: const Icon(Icons.folder_copy_outlined),
              label: const Text('Sauvegarder dans le dossier société'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _createDraft,
              icon: const Icon(Icons.description_outlined),
              label: Text(
                _saving ? 'Enregistrement…' : 'Créer un brouillon d’analyse',
              ),
            ),
          ],
        );
    }
  }

  Widget _rating(String label, int? value, ValueChanged<int?> change) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DropdownButtonFormField<int>(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          hint: const Text('À coter'),
          items: [
            const DropdownMenuItem<int>(value: null, child: Text('À coter')),
            ...List.generate(
              5,
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
            ),
          ],
          onChanged: (v) => setState(() => change(v)),
        ),
      );

  Future<void> _exportWord() async {
    final subject = _subject.text.trim();
    if (subject.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Créez d’abord le brouillon d’analyse assistée.'),
        ),
      );
      return;
    }
    final markdown = RiskAssessmentAssistantService.draft(
      subject: subject,
      answers: _answers,
      questions: _questions,
      dangers: _dangers,
      conclusions: _conclusions,
      decisions: _decisions,
    );
    final now = DateTime.now();
    final document = PreventiaCompanyDocument(
      id: 'assistant-export',
      documentType: 'Analyse assistée de risques',
      title: 'Analyse assistée — $subject',
      status: 'Brouillon à valider',
      createdAt: now,
      autoCreated: false,
      source: 'assistant_local',
      markdown: markdown,
      reference: '',
      companyName: '',
      formData: {'subject': subject},
    );
    final bytes = DocxExportService.buildAssistedRiskAssessmentDocx(document);
    String slug(String value) => value
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9àâçéèêëîïôöùûüÿœ]+', caseSensitive: false),
          '_',
        )
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final name =
        'analyse_assistee_${slug(subject)}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.docx';
    await FileExportService.saveDocxBytes(
      bytes: bytes,
      suggestedFileName: name,
      context: context,
      successMessage: 'Document Word généré.',
      errorMessage: 'Impossible de générer le document Word.',
      showResultMessage: true,
    );
  }

  Future<void> _createDraft() async {
    setState(() => _saving = true);
    try {
      final markdown = RiskAssessmentAssistantService.draft(
        subject: _subject.text,
        answers: _answers,
        questions: _questions,
        dangers: _dangers,
        conclusions: _conclusions,
        decisions: _decisions,
      );
      final prefs = await SharedPreferences.getInstance();
      // Dedicated storage, independent of history, company folders and exports.
      final saved = await prefs.setString(_draftKey, markdown);
      if (!saved) throw StateError('Enregistrement local indisponible');
      if (mounted) await _showDraft(markdown);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Le brouillon n’a pas pu être enregistré localement. Réessayez.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveToCompanyFolder() async {
    setState(() => _saving = true);
    try {
      final markdown = RiskAssessmentAssistantService.draft(
        subject: _subject.text,
        answers: _answers,
        questions: _questions,
        dangers: _dangers,
        conclusions: _conclusions,
        decisions: _decisions,
      );
      await PreventiaCompanyProjectService().saveAssistedDraft(
        subject: _subject.text,
        markdown: markdown,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Le brouillon d’analyse assistée a été sauvegardé dans le dossier société.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final markdown = prefs.getString(_draftKey);
    if (!mounted) return;
    if (markdown == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun brouillon local enregistré.')),
      );
    } else {
      await _showDraft(markdown);
    }
  }

  Future<void> _showDraft(String markdown) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Brouillon Markdown enregistré localement'),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(child: SelectableText(markdown)),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: markdown));
            if (ctx.mounted) {
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(const SnackBar(content: Text('Markdown copié.')));
            }
          },
          child: const Text('Copier le Markdown'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Assistant d’analyse de risques')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            RiskAssessmentAssistantService.warning,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Stepper(
            currentStep: _step,
            onStepContinue: _step < 5 ? _next : null,
            onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
            controlsBuilder: (context, details) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 12,
                children: [
                  if (_step < 5)
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Suivant'),
                    ),
                  if (_step > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Précédent'),
                    ),
                ],
              ),
            ),
            steps: List.generate(
              _titles.length,
              (i) => Step(
                title: Text('Étape ${i + 1} — ${_titles[i]}'),
                isActive: i <= _step,
                content: i == _step ? _content(i) : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: _openDraft,
          child: const Text('Consulter le dernier brouillon local'),
        ),
      ],
    ),
  );
}
