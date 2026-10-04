import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/preventia_project.dart';
import '../models/document_type.dart';
import '../models/prevention_document_config.dart';
import '../services/license_service.dart';
import '../services/preventia_project_service.dart';
import '../widgets/adaptive_page.dart';
import '../widgets/language_selector.dart';
import 'ai_settings_screen.dart';
import 'document_form_screen.dart';
import 'document_type_screen.dart';
import 'history_screen.dart';
import 'license_screen.dart';
import 'limits_screen.dart';
import 'piu_form_screen.dart';
import 'preventia_project_screen.dart';
import 'risk_assessment_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<PreventiaProject?> _projectFuture;

  @override
  void initState() {
    super.initState();
    _projectFuture = PreventiaProjectService().getCurrentProject();
  }

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
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DocumentTypeScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.health_and_safety_outlined),
                          label: Text(l10n.riskAssessment),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const RiskAssessmentAssistantScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.playlist_add_check),
                          label: const Text('Nouvelle analyse assistée'),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.preventionDocuments,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
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
                        Text(
                          l10n.emergencyDocuments,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PiuFormScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.emergency_outlined),
                          label: const Text('Plan Interne d’Urgence — PIU'),
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
                        const SizedBox(height: 12),
                        FutureBuilder<PreventiaProject?>(
                          future: _projectFuture,
                          builder: (context, snapshot) => _projectAccess(
                            context,
                            snapshot.data,
                            waiting:
                                snapshot.connectionState ==
                                ConnectionState.waiting,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LicenseScreen(
                                onContinue: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(l10n.subscriptionLicense),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _confirmLogout(context),
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('Déconnexion'),
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

  Widget _projectAccess(
    BuildContext context,
    PreventiaProject? project, {
    required bool waiting,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!waiting && project == null) ...[
          Text(
            'Après la première analyse de risques, PreventIA vous proposera '
            'de choisir où créer le dossier local de la société.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: waiting
                ? const Icon(Icons.hourglass_empty)
                : const Icon(Icons.folder_copy_outlined),
            label: Text(
              project == null
                  ? 'Dossier PreventIA'
                  : 'Dossier PreventIA — ${project.companyName} / ${project.siteName}',
            ),
            onPressed: waiting ? null : _openProjectScreen,
          ),
        ),
      ],
    );
  }

  Future<void> _openProjectScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PreventiaProjectScreen()),
    );
    if (!mounted) return;
    setState(() {
      _projectFuture = PreventiaProjectService().getCurrentProject();
    });
  }

  IconData _iconFor(DocumentType type) {
    return switch (type.icon) {
      'plan' => Icons.event_note_outlined,
      'strategy' => Icons.account_tree_outlined,
      'visit' => Icons.fact_check_outlined,
      'job' => Icons.badge_outlined,
      'instruction' => Icons.assignment_outlined,
      'incident' => Icons.report_problem_outlined,
      'emergency' => Icons.emergency_outlined,
      _ => Icons.description_outlined,
    };
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: Text(l10n.confirmLogoutDeviceMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final service = LicenseService();
    try {
      await service.logoutThisDevice();
    } on Object catch (error) {
      debugPrint('Home logout unavailable: $error');
      await service.clearSession();
    }
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LicenseScreen()),
      (route) => false,
    );
  }
}
