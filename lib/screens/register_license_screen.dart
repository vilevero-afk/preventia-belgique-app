import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/billing_plan.dart';
import '../services/billing_service.dart';
import '../widgets/adaptive_page.dart';

class RegisterLicenseScreen extends StatefulWidget {
  const RegisterLicenseScreen({super.key});

  @override
  State<RegisterLicenseScreen> createState() => _RegisterLicenseScreenState();
}

class _RegisterLicenseScreenState extends State<RegisterLicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billingService = BillingService();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController(text: 'BE');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  late List<_PlanOption> _planOptions;
  String _selectedPlanId = 'primary_monthly';
  bool _isLoadingPlans = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _planOptions = _fallbackPlans();
    _loadPlans();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _vatNumberController.dispose();
    _addressLine1Controller.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _billingService.getPlans();
      if (!mounted) {
        return;
      }
      setState(() {
        _planOptions = _fallbackPlans(plans);
        if (!_planOptions.any((plan) => plan.id == _selectedPlanId)) {
          _selectedPlanId = _planOptions.first.id;
        }
        _isLoadingPlans = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingPlans = false);
    }
  }

  Future<void> _continueToPayment() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final checkoutUrl = await _billingService.createCheckoutSession(
        email: _emailController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        companyName: _companyNameController.text,
        vatNumber: _vatNumberController.text,
        addressLine1: _addressLine1Controller.text,
        postalCode: _postalCodeController.text,
        city: _cityController.text,
        country: _countryController.text,
        planId: _selectedPlanId,
      );
      final uri = Uri.parse(checkoutUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) {
        return;
      }
      if (!opened) {
        _showSnackBar(
          AppLocalizations.of(context).unableToOpenCheckout,
          isError: true,
        );
        return;
      }
      _showSnackBar(
        AppLocalizations.of(context).afterPaymentReturnToApp,
        isError: false,
      );
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createLicense)),
      body: AdaptivePage(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Text(
                l10n.createPreventiaLicenseTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _field(
                controller: _firstNameController,
                label: l10n.firstName,
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              _field(
                controller: _lastNameController,
                label: l10n.lastName,
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              _field(
                controller: _companyNameController,
                label: l10n.companyName,
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              _field(
                controller: _vatNumberController,
                label: l10n.vatNumber,
                textInputAction: TextInputAction.next,
              ),
              _field(
                controller: _addressLine1Controller,
                label: l10n.addressLine1,
                textInputAction: TextInputAction.next,
              ),
              _field(
                controller: _postalCodeController,
                label: l10n.postalCode,
                textInputAction: TextInputAction.next,
              ),
              _field(
                controller: _cityController,
                label: l10n.city,
                textInputAction: TextInputAction.next,
              ),
              _field(
                controller: _countryController,
                label: l10n.country,
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              _field(
                controller: _emailController,
                label: l10n.emailAddress,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _emailValidator,
              ),
              _field(
                controller: _passwordController,
                label: l10n.password,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: _passwordValidator,
              ),
              _field(
                controller: _passwordConfirmationController,
                label: l10n.repeatPassword,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: _passwordConfirmationValidator,
              ),
              const SizedBox(height: 12),
              Text(l10n.plan, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_isLoadingPlans) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 680;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 112,
                    ),
                    itemCount: _planOptions.length,
                    itemBuilder: (context, index) {
                      final option = _planOptions[index];
                      return _PlanCard(
                        title: option.title(l10n),
                        price: option.priceLabel,
                        selected: option.id == _selectedPlanId,
                        onTap: _isSubmitting
                            ? null
                            : () => setState(() => _selectedPlanId = option.id),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _continueToPayment,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment_outlined),
                label: Text(l10n.continueToPayment),
              ),
              const SizedBox(height: 12),
              Text(l10n.afterPaymentReturnToApp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty
        ? AppLocalizations.of(context).requiredField
        : null;
  }

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
    return isValid ? null : AppLocalizations.of(context).invalidEmail;
  }

  String? _passwordValidator(String? value) {
    return value != null && value.length >= 8
        ? null
        : AppLocalizations.of(context).passwordMinLength;
  }

  String? _passwordConfirmationValidator(String? value) {
    return value == _passwordController.text
        ? null
        : AppLocalizations.of(context).passwordConfirmationMismatch;
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String price;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(price),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanOption {
  const _PlanOption({
    required this.id,
    required this.kind,
    required this.cycle,
    required this.priceLabel,
  });

  final String id;
  final _PlanKind kind;
  final _PlanCycle cycle;
  final String priceLabel;

  String title(AppLocalizations l10n) {
    return switch ((kind, cycle)) {
      (_PlanKind.primary, _PlanCycle.monthly) => l10n.primaryMonthlyLicense,
      (_PlanKind.primary, _PlanCycle.annual) => l10n.primaryAnnualLicense,
      (_PlanKind.additional, _PlanCycle.monthly) =>
        l10n.additionalMonthlyLicense,
      (_PlanKind.additional, _PlanCycle.annual) => l10n.additionalAnnualLicense,
    };
  }
}

enum _PlanKind { primary, additional }

enum _PlanCycle { monthly, annual }

List<_PlanOption> _fallbackPlans([List<BillingPlan> backendPlans = const []]) {
  return [
    _PlanOption(
      id: _matchingPlanId(
        backendPlans,
        kind: _PlanKind.primary,
        cycle: _PlanCycle.monthly,
        fallback: 'primary_monthly',
      ),
      kind: _PlanKind.primary,
      cycle: _PlanCycle.monthly,
      priceLabel: '79 €/mois',
    ),
    _PlanOption(
      id: _matchingPlanId(
        backendPlans,
        kind: _PlanKind.primary,
        cycle: _PlanCycle.annual,
        fallback: 'primary_annual',
      ),
      kind: _PlanKind.primary,
      cycle: _PlanCycle.annual,
      priceLabel: '790 €/an',
    ),
    _PlanOption(
      id: _matchingPlanId(
        backendPlans,
        kind: _PlanKind.additional,
        cycle: _PlanCycle.monthly,
        fallback: 'additional_monthly',
      ),
      kind: _PlanKind.additional,
      cycle: _PlanCycle.monthly,
      priceLabel: '39 €/mois',
    ),
    _PlanOption(
      id: _matchingPlanId(
        backendPlans,
        kind: _PlanKind.additional,
        cycle: _PlanCycle.annual,
        fallback: 'additional_annual',
      ),
      kind: _PlanKind.additional,
      cycle: _PlanCycle.annual,
      priceLabel: '390 €/an',
    ),
  ];
}

String _matchingPlanId(
  List<BillingPlan> plans, {
  required _PlanKind kind,
  required _PlanCycle cycle,
  required String fallback,
}) {
  for (final plan in plans) {
    final type = '${plan.id} ${plan.name} ${plan.licenseType}'.toLowerCase();
    final billingCycle = '${plan.id} ${plan.name} ${plan.billingCycle}'
        .toLowerCase();
    final matchesKind = kind == _PlanKind.additional
        ? type.contains('add') ||
              type.contains('supp') ||
              type.contains('extra') ||
              type.contains('suppl')
        : type.contains('primary') ||
              type.contains('main') ||
              type.contains('princip');
    final matchesCycle = cycle == _PlanCycle.annual
        ? billingCycle.contains('year') ||
              billingCycle.contains('annual') ||
              billingCycle.contains('annuel') ||
              billingCycle.contains('jaar')
        : billingCycle.contains('month') ||
              billingCycle.contains('monthly') ||
              billingCycle.contains('mens') ||
              billingCycle.contains('mois') ||
              billingCycle.contains('maand');
    if (matchesKind && matchesCycle) {
      return plan.id;
    }
  }
  return fallback;
}
