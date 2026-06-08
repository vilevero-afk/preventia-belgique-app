import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/ai_document_service.dart';
import '../services/app_config_service.dart';
import '../services/app_locale_controller.dart';
import '../widgets/adaptive_page.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _backendUrlController = TextEditingController();
  bool _useAiIfAvailable = false;
  bool _disableLocalFallbackForAiTests = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTestingBackend = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await AppConfigService().loadAiSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _backendUrlController.text = settings.backendUrl;
      _useAiIfAvailable = settings.useAiIfAvailable;
      _disableLocalFallbackForAiTests = settings.disableLocalFallbackForAiTests;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await AppConfigService().saveAiSettings(
      AiGenerationSettings(
        backendUrl: _backendUrlController.text,
        useAiIfAvailable: _useAiIfAvailable,
        disableLocalFallbackForAiTests: _disableLocalFallbackForAiTests,
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).savedSettingsMessage),
      ),
    );
  }

  Future<void> _resetBackendUrl() async {
    _backendUrlController.text = AppConfigService.defaultBackendUrl;
    await AppConfigService().resetBackendUrlToDefault();
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).savedSettingsMessage),
      ),
    );
  }

  Future<void> _testBackendConnection() async {
    setState(() => _isTestingBackend = true);
    final result = await AiDocumentService().checkBackendAvailability(
      backendUrl: _backendUrlController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isTestingBackend = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isAvailable
              ? l10n.backendAvailable
              : result.unavailableMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = AppLocaleScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiSettings)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdaptivePage(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Text(
                    l10n.advancedBackendSettings,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _InfoPanel(
                    icon: Icons.verified_user_outlined,
                    text: l10n.productionBackendInfo,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _backendUrlController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.aiBackendUrl,
                      hintText: AppConfigService.defaultBackendUrl,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetBackendUrl,
                        icon: const Icon(Icons.restore_outlined),
                        label: Text(l10n.resetDefaultBackendUrl),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isTestingBackend
                            ? null
                            : _testBackendConnection,
                        icon: _isTestingBackend
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.health_and_safety_outlined),
                        label: Text(l10n.testBackendConnection),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoPanel(
                    icon: Icons.security_outlined,
                    text: l10n.aiBackendSecurityInfo,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.useAiIfAvailable),
                    value: _useAiIfAvailable,
                    onChanged: (value) =>
                        setState(() => _useAiIfAvailable = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.disableLocalFallbackForAiTests),
                    value: _disableLocalFallbackForAiTests,
                    onChanged: (value) =>
                        setState(() => _disableLocalFallbackForAiTests = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: localeController.languageCode,
                    decoration: InputDecoration(labelText: l10n.appLanguage),
                    items: [
                      DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
                      DropdownMenuItem(value: 'nl', child: Text(l10n.dutch)),
                      DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                      DropdownMenuItem(value: 'de', child: Text(l10n.german)),
                    ],
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }
                      await localeController.setLocaleCode(value);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.languageChanged)),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _InfoPanel(
                    icon: Icons.translate_outlined,
                    text: l10n.languageScopeInfo,
                  ),
                  const SizedBox(height: 12),
                  _InfoPanel(
                    icon: Icons.privacy_tip_outlined,
                    text: l10n.privacyInfo,
                  ),
                  const SizedBox(height: 12),
                  _InfoPanel(
                    icon: Icons.devices_outlined,
                    text: l10n.localStorageDeviceInfo,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.save),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
