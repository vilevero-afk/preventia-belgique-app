import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/document_generator.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/section_title.dart';

class LimitsScreen extends StatelessWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.limitsAndMentions)),
      body: AdaptivePage(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            SectionTitle('Utilisation'),
            Text(
              'PreventIA Belgique aide à préparer des projets de documents de prévention sur base des informations saisies par l’utilisateur.',
            ),
            SectionTitle('Stockage local'),
            Text(
              'Aucune API externe n’est appelée par l’application. Les projets sauvegardés sont conservés localement sur l’appareil via le stockage applicatif.',
            ),
            SectionTitle('Limites'),
            Text(
              'Les projets générés ne constituent pas un avis juridique, médical ou technique définitif. Ils ne garantissent pas la conformité légale ni l’exhaustivité de l’analyse.',
            ),
            SectionTitle('Validation obligatoire'),
            Text(mandatoryValidationNotice),
          ],
        ),
      ),
    );
  }
}
