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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newDocument)),
      body: AdaptivePage(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: documentTypes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final type = documentTypes[index];
            final title = type.isRiskAnalysis
                ? (type.label == 'Analyse de risques générale'
                      ? l10n.generalRiskAnalysis
                      : type.label)
                : localizedDocumentTypeLabel(type, l10n.localeName);
            return Card(
              child: ListTile(
                leading: Icon(_iconFor(type)),
                title: Text(title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DocumentFormScreen(documentType: type.label),
                  ),
                ),
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
      _ => Icons.health_and_safety_outlined,
    };
  }
}
