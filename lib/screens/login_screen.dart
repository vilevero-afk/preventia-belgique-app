import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/license_service.dart';
import '../widgets/adaptive_page.dart';
import 'home_screen.dart';
import 'register_license_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.licenseService, super.key});
  final LicenseService? licenseService;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LicenseService _service;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _service = widget.licenseService ?? LicenseService();
    _load();
  }

  Future<void> _load() async {
    try {
      final remember = await _service.getRememberMe();
      final email = remember ? await _service.getSavedEmail() : null;
      if (!mounted) return;
      setState(() {
        _rememberMe = remember;
        _emailController.text = email ?? '';
      });
    } on Object catch (error) {
      if (mounted) _showSnackBar(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(licenseService: _service),
      ),
    );
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
      appBar: AppBar(title: Text(l10n.signIn)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdaptivePage(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _LoginPanel(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isSubmitting: _isSubmitting,
                    rememberMe: _rememberMe,
                    obscurePassword: _obscurePassword,
                    onRememberMeChanged: (value) =>
                        setState(() => _rememberMe = value),
                    onTogglePasswordVisibility: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onLogin: _login,
                    onCreateLicense: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterLicenseScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _login() async {
    setState(() => _isSubmitting = true);
    try {
      final status = await _service.login(
        _emailController.text,
        _passwordController.text,
        _rememberMe,
      );
      if (!mounted) {
        return;
      }
      debugPrint('switching UI to logged in');
      setState(() {
        _isSubmitting = false;
        _emailController.text = status.email.isEmpty
            ? _emailController.text.trim()
            : status.email;
        _passwordController.clear();
        _obscurePassword = true;
      });
      _openHome();
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
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberMeChanged,
    required this.onTogglePasswordVisibility,
    required this.onLogin,
    required this.onCreateLicense,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final bool rememberMe;
  final bool obscurePassword;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onTogglePasswordVisibility;
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
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!isSubmitting) {
              onLogin();
            }
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.password,
            suffixIcon: IconButton(
              onPressed: onTogglePasswordVisibility,
              tooltip: obscurePassword ? l10n.showPassword : l10n.hidePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: rememberMe,
          onChanged: isSubmitting
              ? null
              : (value) => onRememberMeChanged(value ?? false),
          title: Text(l10n.rememberMe),
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
