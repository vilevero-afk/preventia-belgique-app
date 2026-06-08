import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/document_type.dart';
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
            final title = type.label == 'Analyse de risques générale'
                ? l10n.generalRiskAnalysis
                : type.label;
            return Card(
              child: ListTile(
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
}
