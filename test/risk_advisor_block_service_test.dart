import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/docx_export_service.dart';
import 'package:preventia_belgique_app/services/risk_advisor_block_service.dart';

void main() {
  group('RiskAdvisorBlockService', () {
    test('extracts tagged French advisor blocks and strips raw tags', () {
      final segments = RiskAdvisorBlockService.parseSegments('''
Texte avant.
[À VÉRIFIER SUR LE TERRAIN]
Contrôler la largeur des chemins d’évacuation.
FIN DU BLOC
Texte après.
''', languageCode: 'fr');

      final blocks = segments
          .map((segment) => segment.block)
          .whereType<RiskAdvisorBlock>()
          .toList();

      expect(blocks, hasLength(1));
      expect(blocks.single.type, RiskAdvisorBlockType.checkOnSite);
      expect(blocks.single.title, 'À vérifier sur le terrain');
      expect(blocks.single.content, contains('chemins d’évacuation'));
      expect(
        segments.map((segment) => segment.text ?? '').join(),
        isNot(contains('[À VÉRIFIER SUR LE TERRAIN]')),
      );
    });

    test('detects common fallback wording in English', () {
      final segments = RiskAdvisorBlockService.parseSegments(
        'Emergency lighting to be checked during field verification.',
        languageCode: 'en',
      );

      final block = segments.single.block;
      expect(block, isNotNull);
      expect(block!.type, RiskAdvisorBlockType.checkOnSite);
      expect(block.title, 'To be checked on site');
    });
  });

  group('DocxExportService', () {
    test(
      'builds editable OpenXML with advisor blocks and without raw tags',
      () {
        final bytes = DocxExportService.buildRiskAssessmentDocx(
          documentType: 'Analyse de risques générale',
          content: '''
# Analyse de risques générale

[PREUVE ATTENDUE]
Photo du balisage et rapport de contrôle.
FIN DU BLOC
''',
          generatedAt: DateTime(2026, 6, 14),
          referenceNumber: 'AR-2026-0006',
          languageCode: 'fr',
        );
        final rawPackage = utf8.decode(bytes, allowMalformed: true);

        expect(rawPackage, contains('word/document.xml'));
        expect(rawPackage, contains('AR-2026-0006'));
        expect(rawPackage, contains('Preuve attendue'));
        expect(rawPackage, contains('<w:tbl>'));
        expect(rawPackage, isNot(contains('[PREUVE ATTENDUE]')));
      },
    );

    test(
      'renders wide risk tables in landscape without raw markdown tables',
      () {
        final bytes = DocxExportService.buildRiskAssessmentDocx(
          documentType: 'Analyse de risques incendie et évacuation',
          content: '''
# Analyse de risques incendie et évacuation

1. Identification du document
Document test.

9. Tableau principal d’analyse des risques
| N° | Activité ou tâche | Danger | Risque | Personnes exposées | Mesures existantes | Gravité | Probabilité | Exposition | Score | Niveau | Responsable |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Évacuation | Encombrement | Chute | Travailleurs | Rangement | 3 | 3 | 3 | 27 | Moyen | Employeur |

18. Mention de validation
Ce document est un projet à adapter à la situation réelle de l’entreprise et à valider par le conseiller en prévention, l’employeur et, le cas échéant, le service externe, le médecin du travail ou le CPPT. Il ne constitue pas à lui seul une preuve de conformité réglementaire.
''',
          generatedAt: DateTime(2026, 6, 14),
          referenceNumber: 'AR-2026-0007',
          languageCode: 'fr',
        );
        final rawPackage = utf8.decode(bytes, allowMalformed: true);

        expect(rawPackage, contains('w:orient="landscape"'));
        expect(rawPackage, contains('<w:tbl>'));
        expect(rawPackage, contains('<w:tblHeader/>'));
        expect(rawPackage, contains('<w:shd w:val="clear" w:fill="12355B"/>'));
        expect(rawPackage, isNot(contains('|---|')));
        expect(
          rawPackage,
          isNot(contains('[POINT BLOQUANT AVANT VALIDATION]')),
        );
        expect(
          'Ce document est un projet à adapter'.allMatches(rawPackage).length,
          1,
        );
      },
    );
  });
}
