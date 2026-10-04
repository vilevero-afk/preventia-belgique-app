import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/document_type.dart';
import '../models/prevention_document_config.dart';
import '../widgets/adaptive_page.dart';
import 'document_form_screen.dart';

class DocumentTypeScreen extends StatelessWidget {
  const DocumentTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final riskAnalysisTypes = documentTypes
        .where((type) => type.isRiskAnalysis)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.riskAssessment)),
      body: AdaptivePage(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: riskAnalysisTypes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final type = riskAnalysisTypes[index];
            final title = type.id == 'electrical_installations_risk_analysis'
                ? 'Installations électriques BT/HT'
                : type.id == 'elevator_risk_assessment'
                ? 'Ascenseur'
                : type.isRiskAnalysis
                ? (type.label == 'Analyse de risques générale'
                      ? l10n.generalRiskAnalysis
                      : type.label)
                : localizedDocumentTypeLabel(type, l10n.localeName);
            return Card(
              child: ListTile(
                leading: Icon(_iconFor(type)),
                title: Text(title),
                subtitle: type.id == 'electrical_installations_risk_analysis'
                    ? const Text(
                        'Basse tension, haute tension, armoires, cabines, consignation, BA4/BA5.',
                      )
                    : type.id == 'elevator_risk_assessment'
                    ? const Text(
                        'Cabine, portes palières, gaine, cuvette, salle machines, SECT.',
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  debugPrint(
                    '[PreventIA] selectedRiskAssessmentType=${type.label}',
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DocumentFormScreen(documentType: type.label),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(DocumentType type) {
    return switch (type.icon) {
      'plan' => Icons.event_note_outlined,
      'strategy' => Icons.account_tree_outlined,
      'visit' => Icons.fact_check_outlined,
      'job' => Icons.badge_outlined,
      'instruction' => Icons.assignment_outlined,
      'incident' => Icons.report_problem_outlined,
      'electrical' => Icons.electrical_services,
      'elevator' => Icons.elevator,
      _ => Icons.health_and_safety_outlined,
    };
  }
}
