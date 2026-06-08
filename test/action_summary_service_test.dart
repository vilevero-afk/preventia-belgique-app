import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/services/action_summary_service.dart';

void main() {
  group('ActionSummaryService Dutch parsing', () {
    test('extracts actions from the Dutch action plan table', () {
      const content = '''
# Risicoanalyse - Ontwerp te valideren

## 11. Actieprioriteiten
Prioriteit 1 : Actie : Opleiding manueel hanteren organiseren - Betrokken risico : Rugbelasting - Verantwoordelijke : Technische dienst - Termijn : 3 maanden - Verwacht bewijs : Opleidingsregister

## 12. Ontwerp van actieplan
| Nr. | Betrokken risico | Voorgestelde maatregel | Doel | Verantwoordelijke | Termijn | Benodigde middelen | Indicator | Verwacht bewijs | Status | Link JAP/GPP |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Manueel hanteren van lasten | Opleiding manueel hanteren organiseren | Rugklachten beperken | Ploegbaas | 3 maanden | Opleider | 90% deelname | Opleidingsregister | Te starten | JAP |
| 2 | Chemische producten | Inventaris en VIB's bijwerken | Blootstelling beheersen | Magazijnier | 2 maanden | Productlijst | Inventaris beschikbaar | Veiligheidsinformatiebladen | Lopend | GPP |

## 14. Documenten op te stellen of bij te werken
- Opleidingsregister
- PBM-register

## 15. Te raadplegen of te betrekken actoren
- CPBW

## 16. Noodzakelijke bijlagen
- Foto's van de opslagzone
''';

      final summary = ActionSummaryService().build(content);

      expect(summary.priorityActions, hasLength(2));
      expect(
        summary.priorityActions.first.action,
        'Opleiding manueel hanteren organiseren',
      );
      expect(summary.priorityActions.first.risk, 'Manueel hanteren van lasten');
      expect(summary.priorityActions.first.responsible, 'Ploegbaas');
      expect(summary.priorityActions.first.deadline, '3 maanden');
      expect(summary.priorityActions.first.expectedProof, 'Opleidingsregister');
      expect(summary.expectedProofs, contains('Opleidingsregister'));
      expect(
        summary.expectedProofs,
        isNot(contains('Registre des formations')),
      );
    });

    test('uses Dutch local fallback texts for documents and actors', () {
      const content = '''
## 14. Documenten op te stellen of bij te werken
- PBM-register

## 15. Te raadplegen of te betrekken actoren
- CPBW
''';

      final summary = ActionSummaryService().build(content);

      expect(
        summary.documents.first.objective,
        'Een preventiebewijs verduidelijken, formaliseren of bijwerken.',
      );
      expect(
        summary.documents.first.expectedResult,
        'Gedateerd, toegankelijk en indien nodig gevalideerd document.',
      );
      expect(
        summary.actors.first.reason,
        'Vaststellingen bevestigen, acties prioriteren of valideren.',
      );
      expect(
        summary.actors.first.expectedTrace,
        'Advies, verslag, notulen of gedocumenteerde uitwisseling.',
      );
    });
  });

  group('ActionSummaryService English and German parsing', () {
    test('extracts actions from the English action plan table', () {
      const content = '''
# Risk assessment - Draft for validation

## 12. Draft action plan
| No. | Related risk | Proposed measure | Objective | Responsible person | Deadline | Required resources | Indicator | Expected evidence | Status | Link AAP/GPP |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Manual handling | Organise manual handling training | Reduce back injuries | Team leader | 3 months | Trainer | 90% attendance | Training register | To start | AAP |

## 14. Documents to create or update
- PPE register

## 15. Stakeholders to consult or involve
- Health and safety committee

## 16. Required appendices
- Photos of the storage area
''';

      final service = ActionSummaryService();
      final summary = service.build(content);
      final copy = service.buildCopyText(summary, language: 'en');

      expect(summary.priorityActions, hasLength(1));
      expect(
        summary.priorityActions.first.action,
        'Organise manual handling training',
      );
      expect(summary.priorityActions.first.risk, 'Manual handling');
      expect(summary.priorityActions.first.responsible, 'Team leader');
      expect(summary.priorityActions.first.deadline, '3 months');
      expect(summary.priorityActions.first.expectedProof, 'Training register');
      expect(
        summary.documents.first.objective,
        'Clarify, formalise or update prevention evidence.',
      );
      expect(copy, contains('Action summary'));
      expect(copy, isNot(contains('Clarifier, formaliser')));
    });

    test('extracts actions from the German action plan table', () {
      const content = '''
# Gefährdungsbeurteilung - Entwurf zur Validierung

## 12. Entwurf eines Maßnahmenplans
| Nr. | Betroffenes Risiko | Vorgeschlagene Maßnahme | Ziel | Verantwortliche Person | Frist | Erforderliche Mittel | Indikator | Erwarteter Nachweis | Status | Bezug JAP/GPP |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Manuelles Heben | Schulung zum Heben und Tragen organisieren | Rückenbeschwerden verringern | Teamleiter | 3 Monate | Ausbilder | 90% Teilnahme | Schulungsregister | Zu starten | JAP |

## 14. Zu erstellende oder zu aktualisierende Dokumente
- PSA-Register

## 15. Zu konsultierende oder einzubeziehende Akteure
- Ausschuss

## 16. Erforderliche Anhänge
- Fotos des Lagerbereichs
''';

      final service = ActionSummaryService();
      final summary = service.build(content);
      final copy = service.buildCopyText(summary, language: 'de');

      expect(summary.priorityActions, hasLength(1));
      expect(
        summary.priorityActions.first.action,
        'Schulung zum Heben und Tragen organisieren',
      );
      expect(summary.priorityActions.first.risk, 'Manuelles Heben');
      expect(summary.priorityActions.first.responsible, 'Teamleiter');
      expect(summary.priorityActions.first.deadline, '3 Monate');
      expect(summary.priorityActions.first.expectedProof, 'Schulungsregister');
      expect(
        summary.documents.first.objective,
        'Einen Präventionsnachweis klären, formalisieren oder aktualisieren.',
      );
      expect(copy, contains('Maßnahmenübersicht'));
      expect(copy, isNot(contains('Clarifier, formaliser')));
    });
  });
}
