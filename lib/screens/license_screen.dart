import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/license_status.dart';
import '../services/billing_service.dart';
import '../services/license_service.dart';
import '../widgets/adaptive_page.dart';
import 'login_screen.dart';

enum LicenseMenuAction { refresh, manageSubscription, logout }

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({this.licenseService, this.initialAction, super.key});

  final LicenseService? licenseService;
  final LicenseMenuAction? initialAction;

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  late final LicenseService _service;
  late final _billingService = BillingService(licenseService: _service);

  LicenseStatus? _licenseStatus;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _service = widget.licenseService ?? LicenseService();
    _load();
  }

  Future<void> _load() async {
    try {
      final rememberMe = await _service.getRememberMe();
      final token = await _service.getAuthToken();
      final status = token == null
          ? null
          : await _service.getCurrentLicenseStatus(
              forceRefresh: widget.initialAction != LicenseMenuAction.refresh,
            );
      final tokenAfterCheck = await _service.getAuthToken();
      if (!mounted) {
        return;
      }
      debugPrint(
        'LicenseScreen loaded active session ${status == null ? 'no' : 'yes'}',
      );
      setState(() {
        _rememberMe = rememberMe;
        _licenseStatus = status;
        _isLoading = false;
      });
      if (tokenAfterCheck == null) {
        _openLoginScreen();
        return;
      }
      switch (widget.initialAction) {
        case LicenseMenuAction.refresh:
          await _refresh();
        case LicenseMenuAction.manageSubscription:
          await _manageSubscription();
        case LicenseMenuAction.logout:
          await _logoutThisDevice();
        case null:
          break;
      }
      if (!mounted) return;
    } on LicenseException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _licenseStatus = null;
        _isLoading = false;
      });
      _showSnackBar(error.message, isError: true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _licenseStatus = null;
        _isLoading = false;
      });
      _showSnackBar(error.toString(), isError: true);
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
        _licenseStatus = status;
      });
      if (await _service.getAuthToken() == null) {
        if (mounted) _openLoginScreen();
        return;
      }
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

  void _openLoginScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(licenseService: _service),
      ),
      (route) => false,
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
        _licenseStatus = null;
      });
      _showSnackBar(l10n(context).deviceLoggedOut, isError: false);
    } on LicenseException catch (error) {
      if (!mounted) {
        return;
      }
      await _service.clearSession(keepRememberedEmail: _rememberMe);
      if (!mounted) {
        return;
      }
      setState(() {
        _licenseStatus = null;
      });
      _showSnackBar(error.message, isError: true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await _service.clearSession(keepRememberedEmail: _rememberMe);
      if (!mounted) {
        return;
      }
      setState(() {
        _licenseStatus = null;
      });
      _showSnackBar(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _openLoginScreen();
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
                  _StatusPanel(
                    status: status ?? LicenseStatus.inactive(),
                    isSubmitting: _isSubmitting,
                    onRefresh: _refresh,
                    onManageSubscription: _manageSubscription,
                    onLogout: _logoutThisDevice,
                  ),
                ],
              ),
            ),
    );
  }
}

AppLocalizations l10n(BuildContext context) => AppLocalizations.of(context);

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.status,
    required this.isSubmitting,
    required this.onRefresh,
    required this.onManageSubscription,
    required this.onLogout,
  });

  final LicenseStatus status;
  final bool isSubmitting;
  final VoidCallback onRefresh;
  final VoidCallback onManageSubscription;
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
          leading: Icon(
            status.isActive && !status.isExpired
                ? Icons.verified_outlined
                : Icons.warning_amber_outlined,
          ),
          title: Text(
            status.isExpired
                ? l10n.expiredLicense
                : status.isActive
                ? l10n.activeLicense
                : switch (l10n.localeName) {
                    'en' => 'Inactive license',
                    'nl' => 'Inactieve licentie',
                    'de' => 'Inaktive Lizenz',
                    _ => 'Licence inactive',
                  },
          ),
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
