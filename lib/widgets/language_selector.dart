import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/app_locale_controller.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  static const _languageOptions = <_LanguageOption>[
    _LanguageOption(code: 'fr'),
    _LanguageOption(code: 'nl'),
    _LanguageOption(code: 'en'),
    _LanguageOption(code: 'de'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = AppLocaleScope.of(context);
    final selectedCode = localeController.languageCode;

    return PopupMenuButton<String>(
      tooltip: l10n.language,
      onSelected: (code) => _selectLanguage(context, code),
      itemBuilder: (context) => _languageOptions
          .map(
            (option) => PopupMenuItem<String>(
              value: option.code,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: selectedCode == option.code
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  Text(option.localizedName(l10n)),
                ],
              ),
            ),
          )
          .toList(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                _languageCodeLabel(selectedCode),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final localeController = AppLocaleScope.of(context);
    await localeController.setLocaleCode(code);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).languageChanged)),
    );
  }

  static String _languageCodeLabel(String code) {
    return switch (code) {
      'nl' => 'NL',
      'en' => 'EN',
      'de' => 'DE',
      _ => 'FR',
    };
  }
}

class _LanguageOption {
  const _LanguageOption({required this.code});

  final String code;

  String localizedName(AppLocalizations l10n) {
    return switch (code) {
      'nl' => l10n.dutch,
      'en' => l10n.english,
      'de' => l10n.german,
      _ => l10n.french,
    };
  }
}
