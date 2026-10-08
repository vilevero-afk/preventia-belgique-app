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
  final _contentScroll = ScrollController();
  final _answers = <String, String>{};
  final _conclusions = <String, String>{};
  final _decisions = <String, String>{};
  List<FieldQuestion> _questions = [];
  List<AssistantDanger> _dangers = [];
  List<AssistantAction> _actions = [];
  String _status = 'Brouillon';
  String _companyName = '';
  String _siteName = '';
  String _documentReference = '';
  DateTime? _documentDate;
  bool _testValidation = false;
  String _advisor = '';
  String _finalConclusion = '';
  String? _finalMarkdown;
  bool _draftCreated = false;
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
    'Actions et conclusions proposées',
    'Validation de l’analyse',
  ];

  @override
  void dispose() {
    _subject.dispose();
    _contentScroll.dispose();
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
    setState(() {
      final subject = _subject.text.trim().isEmpty
          ? 'Ergonomie poste écran'
          : _subject.text.trim();
      _subject.text = subject;
      _seed(subject);
      RiskAssessmentAssistantService.fillErgonomicsBaseQuestionnaire(_answers);
      RiskAssessmentAssistantService.fillErgonomicsTest(_questions);
      RiskAssessmentAssistantService.fillErgonomicsDangersTest(_dangers);
      _conclusions.addAll(
        RiskAssessmentAssistantService.conclusionsFor(_questions, _dangers),
      );
    });
    _message('Questionnaire de base et scénario ergonomie remplis.');
  }

  void _next() {
    if (_step == 5) return;

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
    _scrollToTop();
  }

  void _seed(String subject) {
    _questions = RiskAssessmentAssistantService.questionsFor(subject);
    _dangers = RiskAssessmentAssistantService.dangersFor(subject);
    _seededSubject = subject;
    _conclusions.clear();
    _actions.clear();
    _draftCreated = false;
    _testValidation = false;
    _finalMarkdown = null;
    _status = 'Brouillon';
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
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Quel sujet voulez-vous analyser ?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _field('Entreprise', _companyName, (v) => _companyName = v),
            _field('Site', _siteName, (v) => _siteName = v),
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
                key: ValueKey('$label-$_revision'),
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
                key: ValueKey((q, _revision)),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Photo : ${q.photoRequired ? 'À prendre' : 'Non requise'}',
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: q.importance,
                        decoration: const InputDecoration(
                          labelText: 'Importance',
                        ),
                        items: ['faible', 'moyenne', 'élevée']
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => q.importance = v!),
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
      case 6:
        return _validation();
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
          ],
        );
    }
  }

  Widget _review(AdvisorReview review) => Column(
    key: ValueKey((review, _revision)),
    children: [
      DropdownButtonFormField<AdvisorDecision>(
        initialValue: review.decision,
        decoration: const InputDecoration(labelText: 'Décision conseiller'),
        items: AdvisorDecision.values
            .map(
              (d) => DropdownMenuItem(
                value: d,
                child: Text(switch (d) {
                  AdvisorDecision.accepted => 'Accepter',
                  AdvisorDecision.modified => 'Modifier',
                  AdvisorDecision.refused => 'Refuser',
                }),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => review.decision = v),
      ),
      _field(
        'Commentaire conseiller',
        review.advisorComment,
        (v) => setState(() => review.advisorComment = v),
      ),
      _field(
        'Responsable',
        review.responsible,
        (v) => setState(() => review.responsible = v),
      ),
      _field(
        'Délai',
        review.deadline,
        (v) => setState(() => review.deadline = v),
      ),
      _field(
        review is AssistantDanger
            ? 'Preuve finale attendue'
            : 'Preuve attendue',
        review.finalEvidence,
        (v) => setState(() => review.finalEvidence = v),
      ),
    ],
  );

  Widget _validation() {
    if (_finalMarkdown != null) {
      return Column(
        children: [
          Text(
            _testValidation
                ? 'Analyse finale à vérifier et valider.'
                : 'Document validé par le conseiller.',
          ),
          TextButton(
            onPressed: () => _showDraft(_finalMarkdown!),
            child: const Text('Consulter l’analyse finale'),
          ),
          TextButton(
            onPressed: () => setState(() {
              _finalMarkdown = null;
              _status = 'En validation';
            }),
            child: const Text('Reprendre la validation'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Le conseiller en prévention garde la décision finale. Destination : analyse finale, PAA/PGP, dossier prévention et preuves/photos.',
        ),
        const Text(
          'Actions proposées',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        for (final a in _actions)
          Card(
            key: ObjectKey(a),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _field('Action', a.action, (v) => a.action = v),
                  _field('Risque lié', a.linkedRisk, (v) => a.linkedRisk = v),
                  _field('Priorité', a.priority, (v) => a.priority = v),
                  DropdownButtonFormField<String>(
                    initialValue: a.type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: AssistantAction.types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => a.type = v!),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: a.integration,
                    decoration: const InputDecoration(
                      labelText: 'Proposition d’intégration',
                    ),
                    items: ['PAA', 'PGP']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => a.integration = v!),
                  ),
                  _review(a),
                ],
              ),
            ),
          ),
        const Text(
          'Dangers et cotations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        for (final d in _dangers)
          Card(
            key: ValueKey((d, _revision)),
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
                  _field('Personnes exposées', d.people, (v) => d.people = v),
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
                  _field(
                    'Mesure proposée',
                    d.proposedMeasure,
                    (v) => d.proposedMeasure = v,
                  ),
                  _field('Preuve attendue', d.evidence, (v) => d.evidence = v),
                  _review(d),
                ],
              ),
            ),
          ),
        _field(
          'Conseiller en prévention',
          _advisor,
          (v) => setState(() => _advisor = v),
          key: ValueKey('advisor-$_revision'),
        ),
        _field(
          'Conclusion finale du conseiller',
          _finalConclusion,
          (v) => setState(() => _finalConclusion = v),
          key: ValueKey('conclusion-$_revision'),
        ),
      ],
    );
  }

  Future<void> _createFinal() async {
    if (_step != 6) _startValidation();
    final missingDetails = _actions.any(
      (a) =>
          a.retained &&
          [
            a.responsible,
            a.deadline,
            a.finalEvidence,
          ].any((v) => v.trim().isEmpty),
    );
    if (missingDetails) {
      _message(
        'Complétez responsable, délai et preuve attendue pour les actions acceptées.',
      );
      return;
    }
    final errors = RiskAssessmentAssistantService.validationErrors(
      _dangers,
      _actions,
    );
    if (errors.isNotEmpty) {
      _message(errors.join('\n'));
      return;
    }
    if (_advisor.trim().isEmpty || _finalConclusion.trim().isEmpty) {
      _message('Complétez le nom du conseiller et sa conclusion finale.');
      return;
    }
    final date = DateTime.now();
    final markdown =
        RiskAssessmentAssistantService.buildFinalAssistedRiskMarkdown(
          subject: _subject.text,
          answers: _answers,
          questions: _questions,
          dangers: _dangers,
          actions: _actions,
          conclusion: _finalConclusion,
          advisor: _advisor,
          reference: _documentReference,
          date: date,
          companyName: _companyName,
          siteName: _siteName,
          validated: !_testValidation,
        );
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
        'risk_assessment_assistant_latest_final_markdown',
        markdown,
      )) {
        throw StateError('Enregistrement impossible');
      }
      if (mounted) {
        setState(() {
          _finalMarkdown = markdown;
          _documentDate = date;
          _status = 'Analyse finale créée';
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’enregistrer l’analyse finale.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _scrollToTop() {
    if (_contentScroll.hasClients) _contentScroll.jumpTo(0);
  }

  void _startValidation() {
    setState(() {
      _actions = RiskAssessmentAssistantService.actionsFor(
        _dangers,
        _conclusions['Actions proposées'] ?? '',
      );
      _status = 'En validation';
      _step = 6;
    });
    _scrollToTop();
  }

  void _fillValidationTest() {
    if (_step != 6) _startValidation();
    setState(() {
      _testValidation = true;
      RiskAssessmentAssistantService.fillValidationTest(_dangers, _actions);
      if (_advisor.trim().isEmpty) _advisor = 'Service prévention';
      if (_finalConclusion.trim().isEmpty) {
        _finalConclusion = 'À vérifier et valider sur site.';
      }
      _revision++;
    });
    _message(
      'Validation test remplie. Les décisions et cotations de test restent à vérifier sur site.',
    );
  }

  String? get _finalBlockReason {
    if (_actions.any(
      (a) =>
          a.retained &&
          [
            a.responsible,
            a.deadline,
            a.finalEvidence,
          ].any((v) => v.trim().isEmpty),
    )) {
      return 'Complétez responsable, délai et preuve attendue pour les actions acceptées.';
    }
    final errors = RiskAssessmentAssistantService.validationErrors(
      _dangers,
      _actions,
    );
    if (errors.isNotEmpty) return errors.first;
    if (_advisor.trim().isEmpty || _finalConclusion.trim().isEmpty) {
      return 'Complétez le nom du conseiller et sa conclusion finale.';
    }
    return null;
  }

  Widget _documentControls() => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_step < 5)
          FilledButton(
            onPressed: _saving ? null : _next,
            child: const Text('Suivant'),
          ),
        if (_step > 0)
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    setState(() {
                      _step--;
                      _finalMarkdown = null;
                      _status = 'Brouillon';
                    });
                    _scrollToTop();
                  },
            child: const Text('Précédent'),
          ),
        if (_step == 5 && !_draftCreated)
          FilledButton(
            onPressed: _saving ? null : _createDraft,
            child: const Text('Créer un brouillon d’analyse'),
          ),
        if (_draftCreated && _finalMarkdown == null) ...[
          OutlinedButton(
            onPressed: _saving ? null : () => _exportWord(),
            child: const Text('Exporter Word — brouillon'),
          ),
          if (_step != 6)
            FilledButton(
              onPressed: _saving ? null : _startValidation,
              child: const Text('Passer à la validation'),
            ),
        ],
        if (_draftCreated)
          OutlinedButton(
            onPressed: _saving ? null : _saveToCompanyFolder,
            child: const Text('Sauvegarder dans le dossier société'),
          ),
        if (_draftCreated && _finalMarkdown == null) ...[
          OutlinedButton(
            onPressed: _saving ? null : _fillValidationTest,
            child: const Text('Remplir validation test'),
          ),
          if (_finalBlockReason != null) Text(_finalBlockReason!),
          FilledButton(
            onPressed: _saving || _finalBlockReason != null
                ? null
                : _createFinal,
            child: const Text('Créer l’analyse finale'),
          ),
        ],
        if (_finalMarkdown != null) ...[
          const Text('Analyse finale créée'),
          FilledButton(
            onPressed: _saving ? null : () => _exportWord(finalDocument: true),
            child: const Text('Exporter Word — analyse finale'),
          ),
        ],
      ],
    ),
  );

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

  Future<void> _exportWord({bool finalDocument = false}) async {
    setState(() => _saving = true);
    try {
      await _writeWord(finalDocument: finalDocument);
    } catch (error) {
      if (mounted) _message('Export Word impossible : $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _writeWord({required bool finalDocument}) async {
    final subject = _subject.text.trim();
    if (finalDocument && _finalMarkdown == null) {
      _message('Créez d’abord l’analyse finale.');
      return;
    }
    if (subject.isEmpty) {
      _message('Veuillez préciser un sujet.');
      return;
    }
    final markdown = finalDocument
        ? _finalMarkdown!
        : RiskAssessmentAssistantService.draft(
            subject: subject,
            answers: _answers,
            questions: _questions,
            dangers: _dangers,
            conclusions: _conclusions,
            decisions: _decisions,
          );
    final now = _documentDate ?? DateTime.now();
    final document = PreventiaCompanyDocument(
      id: 'assistant-export',
      documentType: 'Analyse assistée de risques',
      title: 'Analyse assistée — $subject',
      status: finalDocument ? 'Analyse finale créée' : 'Brouillon',
      createdAt: now,
      autoCreated: false,
      source: 'assistant_local',
      markdown: markdown,
      reference: _documentReference,
      companyName: _companyName,
      siteName: _siteName,
      formData: {'subject': subject},
    );
    final bytes = DocxExportService.buildAssistedRiskAssessmentDocx(document);
    final name = DocxExportService.assistedRiskFileName(document);
    final saved = await FileExportService.saveDocxBytes(
      bytes: bytes,
      suggestedFileName: name,
      context: context,
      successMessage: finalDocument
          ? 'Analyse finale exportée en Word.'
          : 'Brouillon exporté en Word.',
      errorMessage: 'Export Word impossible',
      onError: (error) {
        if (mounted) _message('Export Word impossible : $error');
      },
      showResultMessage: false,
    );
    if (mounted && saved?.wordPath?.isNotEmpty == true) {
      _message(
        finalDocument
            ? 'Analyse finale exportée en Word.'
            : 'Brouillon exporté en Word.',
      );
    }
  }

  Future<void> _createDraft() async {
    setState(() => _saving = true);
    try {
      final markdown =
          _finalMarkdown ??
          RiskAssessmentAssistantService.draft(
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
      if (mounted) {
        setState(() {
          _draftCreated = true;
          _documentDate = DateTime.now();
          _documentReference =
              'AA-${_documentDate!.year}-${_documentDate!.microsecondsSinceEpoch}';
          _finalMarkdown = null;
          _status = 'Brouillon';
          _actions = RiskAssessmentAssistantService.actionsFor(
            _dangers,
            _conclusions['Actions proposées'] ?? '',
          );
        });
        _message(
          'Brouillon créé. Vous pouvez exporter le Word ou passer à la validation.',
        );
      }
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
      final markdown =
          _finalMarkdown ??
          RiskAssessmentAssistantService.draft(
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
        status: _status,
        actions: _actions,
        companyName: _companyName.trim().isEmpty ? null : _companyName,
        siteName: _siteName,
        reference: _documentReference,
        createdAt: _documentDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Le document d’analyse assistée a été sauvegardé dans le dossier prévention.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) _message('Sauvegarde impossible : $error');
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
      title: Text(
        _finalMarkdown == null
            ? 'Brouillon Markdown enregistré localement'
            : (_testValidation
                  ? 'Analyse finale à valider'
                  : 'Analyse finale validée'),
      ),
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
    bottomNavigationBar: SafeArea(child: _documentControls()),
    body: Column(
      children: [
        Text('Statut : $_status'),
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
          child: SingleChildScrollView(
            controller: _contentScroll,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Étape ${_step + 1} — ${_titles[_step]}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _content(_step),
              ],
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
