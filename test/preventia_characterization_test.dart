import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/models/document_type.dart';
import 'package:preventia_belgique_app/services/preventia_company_project_service.dart';
import 'package:preventia_belgique_app/utils/preventia_document_text_utils.dart';

void main() {
  group('documentType characterization', () {
    test('keeps current Flutter document type labels stable', () {
      final labels = documentTypes.map((type) => type.label).toSet();

      expect(labels, contains('Analyse de risques par poste de travail'));
      expect(labels, contains('Fiche de poste'));
      expect(labels, contains('Analyse de risques — Ascenseur'));
      expect(
        labels,
        contains('Analyse de risques — Installations électriques BT/HT'),
      );
      expect(labels, contains('Analyse de risques incendie et évacuation'));
      expect(labels, contains('Plan Interne d’Urgence'));
    });

    test('documents current lookup behavior for priority labels', () {
      expect(
        documentTypeByLabel('Analyse de risques par poste de travail').id,
        'job_risk_analysis',
      );
      expect(documentTypeByLabel('Fiche de poste').id, 'job_sheet');
      expect(
        documentTypeByLabel('Analyse de risques — Ascenseur').id,
        'elevator_risk_assessment',
      );
      expect(
        documentTypeByLabel(
          'Analyse de risques — Installations électriques BT/HT',
        ).id,
        'electrical_installations_risk_analysis',
      );
      expect(
        documentTypeByLabel('Analyse de risques incendie et évacuation').id,
        'fire_risk_analysis',
      );
      expect(
        documentTypeByLabel('Plan Interne d’Urgence').id,
        'internal_emergency_plan',
      );
    });

    test('normalizes spacing and dash variants without broad aliasing', () {
      expect(
        normalizePreventiaDocumentType('  Analyse   de risques – Ascenseur  '),
        'Analyse de risques — Ascenseur',
      );
      expect(
        normalizePreventiaDocumentType('Analyse de risques — Ascenseur'),
        'Analyse de risques — Ascenseur',
      );
      expect(
        normalizePreventiaDocumentType(
          'Analyse de risques par poste de travail',
        ),
        isNot('Fiche de poste'),
      );
      expect(normalizePreventiaDocumentType('PGA/PAA/PGP'), 'PGA/PAA/PGP');
    });
  });

  group('PGA review candidate noise guards', () {
    test('rejects technical and documentary noise', () {
      const noise = [
        'Page 1 / 1',
        'documentType',
        'additionalInformation',
        'Conclusion',
        'Mention de validation',
        'Méthode de cotation',
        'Tableau principal d’analyse',
        'Famille de danger',
        'Danger précis',
        'Scénario plausible',
        '| N° | Activité | Danger | Risque | G | P | E | Score |',
      ];

      for (final value in noise) {
        final classification = classifyReviewCandidate(value);
        expect(
          classification.shouldReview,
          isFalse,
          reason: '"$value" must not be an action to validate',
        );
        expect(
          classification.destination,
          isNot('pgp'),
          reason: '"$value" must not feed PGA/PAA/PGP',
        );
      }
    });

    test('keeps real PGA actions reviewable', () {
      const actions = [
        'Obtenir ou vérifier le PV RGIE.',
        'Vérifier les habilitations BA4/BA5.',
        'Dégager les voies d’évacuation.',
        'Rendre les moyens d’extinction visibles et accessibles.',
        'Tester l’appel d’urgence ascenseur.',
        'Adapter les postes écran après observation ergonomique.',
      ];

      for (final value in actions) {
        final classification = classifyReviewCandidate(value);
        expect(classification.shouldReview, isTrue, reason: value);
        expect(classification.destination, 'pgp', reason: value);
      }
    });
  });

  test('sanitizePreventiaExportText removes single page footer noise', () {
    const input = '''
# Document

Contenu conservé.
Page 1 / 1
Référence AR-2026-0069 — Page 1 / 1
Référence AR-2026-0070 - Page 1 / 1

Fin conservée.
''';

    final sanitized = sanitizePreventiaExportText(input);

    expect(sanitized, contains('Contenu conservé.'));
    expect(sanitized, contains('Fin conservée.'));
    expect(sanitized, isNot(contains('Page 1 / 1')));
    expect(sanitized, isNot(contains('Référence AR-2026-0069')));
  });
}
