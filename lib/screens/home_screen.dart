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
  const HomeScreen({this.licenseService, super.key});

  final LicenseService? licenseService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<PreventiaProject?> _projectFuture;
  late final LicenseService _licenseService;

  @override
  void initState() {
    super.initState();
    _licenseService = widget.licenseService ?? LicenseService();
    _projectFuture = PreventiaProjectService().getCurrentProject();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(actions: const [LanguageSelector()]),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(l10n.subscriptionLicense),
                onTap: () => _openLicense(),
              ),
              ListTile(
                leading: const Icon(Icons.refresh_outlined),
                title: Text(switch (l10n.localeName) {
                  'nl' => 'Licentie vernieuwen',
                  'en' => 'Refresh license',
                  'de' => 'Lizenz aktualisieren',
                  _ => 'Actualiser la licence',
                }),
                onTap: () => _openLicense(LicenseMenuAction.refresh),
              ),
              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(l10n.manageSubscription),
                onTap: () => _openLicense(LicenseMenuAction.manageSubscription),
              ),
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: Text(l10n.logoutThisDevice),
                onTap: () => _openLicense(LicenseMenuAction.logout),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AdaptivePage(
            maxTabletWidth: 640,
            maxDesktopWidth: 720,
            mobilePadding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

  void _openLicense([LicenseMenuAction? action]) {
    Navigator.of(
      context,
    ).pop(); // Close the drawer before opening the existing page.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LicenseScreen(
          licenseService: _licenseService,
          managementOnly: true,
          initialAction: action,
        ),
      ),
    );
  }
}
