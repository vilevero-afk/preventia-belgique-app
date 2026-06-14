import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/document_type.dart';
import '../models/prevention_document_config.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/language_selector.dart';
import 'ai_settings_screen.dart';
import 'document_form_screen.dart';
import 'document_type_screen.dart';
import 'history_screen.dart';
import 'limits_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: AdaptivePage(
            maxTabletWidth: 640,
            maxDesktopWidth: 720,
            mobilePadding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: LanguageSelector(),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 104,
                            height: 104,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_preventia.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.appTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.homeSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DocumentTypeScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.note_add_outlined),
                          label: Text(l10n.newDocument),
                        ),
                        const SizedBox(height: 20),
                        ...documentTypes
                            .where(isNewPreventionDocument)
                            .map(
                              (type) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => DocumentFormScreen(
                                        documentType: type.label,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(_iconFor(type)),
                                  label: Text(
                                    localizedDocumentTypeLabel(
                                      type,
                                      l10n.localeName,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.history_outlined),
                          label: Text(l10n.history),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LimitsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.info_outline),
                          label: Text(l10n.limitsAndMentions),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AiSettingsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.settings_outlined),
                          label: Text(l10n.aiSettings),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      _ => Icons.description_outlined,
    };
  }
}
