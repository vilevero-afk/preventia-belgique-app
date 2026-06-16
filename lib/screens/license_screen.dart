import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/license_status.dart';
import '../services/license_service.dart';
import '../widgets/adaptive_page.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = LicenseService();

  LicenseStatus? _status;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final email = await _service.getEmail();
      final status = await _service.getCurrentLicenseStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _emailController.text = email ?? status.email;
        _status = status;
        _isLoading = false;
      });
    } on LicenseException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = LicenseStatus.inactive();
        _isLoading = false;
      });
      _showSnackBar(error.message, isError: true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = LicenseStatus.inactive();
        _isLoading = false;
      });
      _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<void> _login() async {
    setState(() => _isSubmitting = true);
    try {
      final status = await _service.login(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _status = status;
        _emailController.text = status.email.isEmpty
            ? _emailController.text.trim()
            : status.email;
        _passwordController.clear();
      });
      _showSnackBar(l10n(context).loginSuccessful, isError: false);
    } on LicenseException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.message, isError: true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _isSubmitting = true);
    try {
      final status = await _service.getCurrentLicenseStatus(forceRefresh: true);
      if (!mounted) {
        return;
      }
      setState(() => _status = status);
    } on LicenseException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.message, isError: true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _logoutThisDevice() async {
    setState(() => _isSubmitting = true);
    try {
      await _service.logoutThisDevice();
      if (!mounted) {
        return;
      }
      setState(() {
        _status = LicenseStatus.inactive();
        _passwordController.clear();
      });
    } on LicenseException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.message, isError: true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionLicense)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdaptivePage(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (status == null || !status.isActive)
                    _LoginPanel(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isSubmitting: _isSubmitting,
                      onLogin: _login,
                    )
                  else
                    _StatusPanel(
                      status: status,
                      isSubmitting: _isSubmitting,
                      onRefresh: _refresh,
                      onLogout: _logoutThisDevice,
                    ),
                ],
              ),
            ),
    );
  }
}

AppLocalizations l10n(BuildContext context) => AppLocalizations.of(context);

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onLogin,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.emailAddress,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!isSubmitting) {
              onLogin();
            }
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.password,
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.personalLicenseInfo),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: isSubmitting ? null : onLogin,
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login_outlined),
          label: Text(l10n.signIn),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.status,
    required this.isSubmitting,
    required this.onRefresh,
    required this.onLogout,
  });

  final LicenseStatus status;
  final bool isSubmitting;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.verified_outlined),
          title: Text(l10n.activeLicense),
          subtitle: Text(status.email),
        ),
        _InfoRow(label: l10n.emailAddress, value: status.email),
        _InfoRow(
          label: l10n.licenseType,
          value: _licenseTypeText(l10n, status),
        ),
        _InfoRow(label: l10n.cycle, value: _cycleText(l10n, status)),
        _InfoRow(label: l10n.price, value: _priceText(status)),
        _InfoRow(
          label: l10n.expirationDate,
          value: status.endDate == null
              ? '-'
              : DateFormat.yMd(localeName).format(status.endDate!),
        ),
        _InfoRow(
          label: l10n.usedDevices,
          value: _quotaText(status.activatedDevices, status.maxDevices),
        ),
        _InfoRow(
          label: l10n.simpleDocuments,
          value: _quotaText(
            status.usedSimpleDocumentsThisMonth,
            status.monthlySimpleDocumentsLimit,
          ),
        ),
        _InfoRow(
          label: l10n.riskAnalyses,
          value: _quotaText(
            status.usedRiskAnalysisThisMonth,
            status.monthlyRiskAnalysisLimit,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : onRefresh,
              icon: const Icon(Icons.refresh_outlined),
              label: Text(l10n.refresh),
            ),
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : onLogout,
              icon: const Icon(Icons.logout_outlined),
              label: Text(l10n.logoutThisDevice),
            ),
          ],
        ),
      ],
    );
  }

  String _quotaText(int? used, int? limit) {
    return '${used ?? 0} / ${limit ?? '-'}';
  }

  String _licenseTypeText(AppLocalizations l10n, LicenseStatus status) {
    final normalized = status.licenseType.toLowerCase();
    if (normalized.contains('supp') ||
        normalized.contains('add') ||
        normalized.contains('extra')) {
      return l10n.additionalLicense;
    }
    return l10n.primaryLicense;
  }

  String _cycleText(AppLocalizations l10n, LicenseStatus status) {
    final normalized = status.billingCycle.toLowerCase();
    if (normalized.contains('year') ||
        normalized.contains('annual') ||
        normalized.contains('annuel') ||
        normalized.contains('jaar')) {
      return l10n.annualCycle;
    }
    return l10n.monthlyCycle;
  }

  String _priceText(LicenseStatus status) {
    final explicitPrice = status.price;
    if (explicitPrice != null) {
      return '$explicitPrice €';
    }
    final isAdditional =
        status.licenseType.toLowerCase().contains('supp') ||
        status.licenseType.toLowerCase().contains('add') ||
        status.licenseType.toLowerCase().contains('extra');
    final isAnnual =
        status.billingCycle.toLowerCase().contains('year') ||
        status.billingCycle.toLowerCase().contains('annual') ||
        status.billingCycle.toLowerCase().contains('annuel') ||
        status.billingCycle.toLowerCase().contains('jaar');
    if (isAdditional) {
      return isAnnual ? '390 €' : '39 €';
    }
    return isAnnual ? '790 €' : '79 €';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
