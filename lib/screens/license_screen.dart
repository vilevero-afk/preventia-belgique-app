import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/license_status.dart';
import '../services/billing_service.dart';
import '../services/license_service.dart';
import '../widgets/adaptive_page.dart';
import 'home_screen.dart';
import 'register_license_screen.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({this.onContinue, super.key});

  final VoidCallback? onContinue;

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = LicenseService();
  late final _billingService = BillingService(licenseService: _service);

  bool _isLoggedIn = false;
  LicenseStatus? _licenseStatus;
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
      final status = await _service.getCurrentLicenseStatus();
      final email = await _service.getEmail();
      if (!mounted) {
        return;
      }
      debugPrint(
        'LicenseScreen loaded active session ${status == null ? 'no' : 'yes'}',
      );
      setState(() {
        _emailController.text = email ?? status?.email ?? '';
        _isLoggedIn = status != null;
        _licenseStatus = status;
        _isLoading = false;
      });
    } on LicenseException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoggedIn = false;
        _licenseStatus = null;
        _isLoading = false;
      });
      _showSnackBar(error.message, isError: true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoggedIn = false;
        _licenseStatus = null;
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
      debugPrint('switching UI to logged in');
      setState(() {
        _isLoggedIn = true;
        _licenseStatus = status;
        _isLoading = false;
        _isSubmitting = false;
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
      setState(() {
        _isLoggedIn = status != null;
        _licenseStatus = status;
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

  Future<void> _manageSubscription() async {
    setState(() => _isSubmitting = true);
    try {
      final portalUrl = await _billingService.createPortalSession();
      final opened = await launchUrl(
        Uri.parse(portalUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) {
        return;
      }
      if (!opened) {
        _showSnackBar(l10n(context).unableToOpenPortal, isError: true);
      }
    } on BillingException catch (error) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.logoutThisDevice),
          content: Text(l10n.confirmLogoutDeviceMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.logoutThisDevice),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _performLogout(localOnly: false);
  }

  void _continueToApp() {
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _performLogout({required bool localOnly}) async {
    setState(() => _isSubmitting = true);
    try {
      await _service.logoutThisDevice(localOnly: localOnly);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoggedIn = false;
        _licenseStatus = null;
        _emailController.clear();
        _passwordController.clear();
      });
      _showSnackBar(l10n(context).deviceLoggedOut, isError: false);
    } on LicenseException catch (error) {
      if (!mounted) {
        return;
      }
      await _service.clearSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoggedIn = false;
        _licenseStatus = null;
        _emailController.clear();
        _passwordController.clear();
      });
      _showSnackBar(error.message, isError: true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await _service.clearSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoggedIn = false;
        _licenseStatus = null;
        _emailController.clear();
        _passwordController.clear();
      });
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
    final status = _licenseStatus;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionLicense)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdaptivePage(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (!_isLoggedIn || status == null)
                    _LoginPanel(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isSubmitting: _isSubmitting,
                      onLogin: _login,
                      onCreateLicense: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegisterLicenseScreen(),
                          ),
                        );
                      },
                    )
                  else
                    _StatusPanel(
                      status: status,
                      isSubmitting: _isSubmitting,
                      onRefresh: _refresh,
                      onManageSubscription: _manageSubscription,
                      onLogout: _logoutThisDevice,
                      onContinue: _continueToApp,
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
    required this.onCreateLicense,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onLogin;
  final VoidCallback onCreateLicense;

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
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isSubmitting ? null : onCreateLicense,
          icon: const Icon(Icons.add_card_outlined),
          label: Text(l10n.createLicense),
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
    required this.onManageSubscription,
    required this.onLogout,
    required this.onContinue,
  });

  final LicenseStatus status;
  final bool isSubmitting;
  final VoidCallback onRefresh;
  final VoidCallback onManageSubscription;
  final VoidCallback onLogout;
  final VoidCallback? onContinue;

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
              onPressed: isSubmitting ? null : onManageSubscription,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: Text(l10n.manageSubscription),
            ),
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : onLogout,
              icon: const Icon(Icons.logout_outlined),
              label: Text(l10n.logoutThisDevice),
            ),
          ],
        ),
        if (onContinue != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isSubmitting ? null : onContinue,
            icon: const Icon(Icons.arrow_forward_outlined),
            label: Text(l10n.continueToApp),
          ),
        ],
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
