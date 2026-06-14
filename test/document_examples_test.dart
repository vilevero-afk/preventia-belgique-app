import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/data/document_examples.dart';

void main() {
  test('returns complete examples for all new documents and languages', () {
    const documentTypes = [
      'Plan annuel d’action',
      'Plan global de prévention sur 5 ans',
      'Rapport de visite sécurité',
      'Fiche de poste',
      'Fiche d’instruction sécurité',
      'Rapport d’accident ou d’incident',
    ];
    const languages = ['fr', 'nl', 'en', 'de'];
    const forbiddenNonFrenchFragments = [
      'exemple complet réaliste',
      'constats concrets',
      'responsable, échéance, preuve de suivi',
      'Mission pour',
      'Tâches principales pour',
      'Information à compléter ou à valider sur le terrain',
    ];

    for (final documentType in documentTypes) {
      for (final languageCode in languages) {
        final example = getCompleteExampleForDocument(
          documentType: documentType,
          languageCode: languageCode,
        );

        expect(
          example,
          isNotEmpty,
          reason: '$documentType / $languageCode should have a full example',
        );
        expect(example.keys, contains('companyName'));
        expect(example.keys, contains('siteConcerned'));
        expect(example.keys, contains('serviceConcerned'));
        expect(example.keys, contains('preparedBy'));
        expect(example.keys, contains('version'));
        expect(example.keys, isNot(contains('documentReference')));
        expect(example.keys, isNot(contains('reference')));
        expect(example.keys, isNot(contains('analysisNumber')));
        expect(example.keys, isNot(contains('projectNumber')));
        expect(example.keys, isNot(contains('internalReference')));
        expect(
          example.keys.any((key) => key == 'visitDate' || key == 'date'),
          isTrue,
        );
        expect(example['companyName'], isNotEmpty);
        expect(example['siteConcerned'], isNotEmpty);
        expect(example['serviceConcerned'], isNotEmpty);
        expect(example['preparedBy'], isNotEmpty);
        expect(example['version'], '1.0');
        expect(
          example.values.every((value) => value is String),
          isTrue,
          reason: '$documentType / $languageCode should only return strings',
        );
        if (languageCode != 'fr') {
          final values = example.values.join('\n');
          for (final fragment in forbiddenNonFrenchFragments) {
            expect(
              values,
              isNot(contains(fragment)),
              reason: '$documentType / $languageCode leaks "$fragment"',
            );
          }
        }
      }
    }
  });

  test('examples use required professional vocabulary by language', () {
    const documentTypes = [
      'Plan annuel d’action',
      'Plan global de prévention sur 5 ans',
      'Rapport de visite sécurité',
      'Fiche de poste',
      'Fiche d’instruction sécurité',
      'Rapport d’accident ou d’incident',
    ];
    String examplesFor(String languageCode) {
      return documentTypes
          .expand(
            (documentType) => getCompleteExampleForDocument(
              documentType: documentType,
              languageCode: languageCode,
            ).values,
          )
          .join('\n');
    }

    final nl = examplesFor('nl');
    expect(nl, contains('preventieadviseur'));
    expect(nl, contains('CPBW'));
    expect(nl, contains('jaaractieplan'));
    expect(nl, contains('globaal preventieplan'));
    expect(nl, contains('PBM'));
    expect(nl, contains('VIB'));
    expect(nl, contains('terreinbezoek'));
    expect(nl, contains('arbeidsmiddelen'));

    final en = examplesFor('en');
    expect(en, contains('prevention advisor'));
    expect(en, contains('health and safety committee'));
    expect(en, contains('Global Prevention Plan'));
    expect(en, contains('Annual Action Plan'));
    expect(en, contains('PPE'));
    expect(en, contains('SDS'));
    expect(en, contains('site visit'));
    expect(en, contains('work equipment'));

    final de = examplesFor('de');
    expect(de, contains('Präventionsberater'));
    expect(
      de,
      contains('Ausschuss für Gefahrenverhütung und Schutz am Arbeitsplatz'),
    );
    expect(de, contains('Globalen Präventionsplans'));
    expect(de, contains('Jährlichen Aktionsplan'));
    expect(de, contains('PSA'));
    expect(de, contains('Sicherheitsdatenblätter'));
    expect(de, contains('Vor-Ort-Besichtigung'));
    expect(de, contains('Arbeitsmittel'));
  });

  test('returns an empty map for unsupported document types', () {
    final example = getCompleteExampleForDocument(
      documentType: 'Document inconnu',
      languageCode: 'fr',
    );

    expect(example, isEmpty);
  });

  test('returns the French fire evacuation example for dangerous products', () {
    final example = getCompleteExampleForDocument(
      documentType: 'Analyse de risques incendie et évacuation',
      languageCode: 'fr',
    );

    expect(example['companyName'], 'Chemipro Logistics Belgium SRL');
    expect(example['siteConcerned'], contains('Zone industrielle de Liège'));
    expect(example['fireRisk'], contains('batteries lithium-ion'));
    expect(example['fireRisk'], contains('ATEX'));
    expect(example['fireRisk'], contains('Permis de feu'));
    expect(example['dangerousProducts'], contains('Solvants inflammables'));
    expect(example['feedAnnualActionPlan'], contains('PAA'));
    expect(example['feedGlobalPreventionPlan'], contains('PGP'));
    expect(example.keys, isNot(contains('documentReference')));
    expect(example.values.join('\n'), isNot(contains('AR-2026-0001')));
  });
}
