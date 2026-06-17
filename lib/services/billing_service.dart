import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/billing_plan.dart';
import 'app_config_service.dart';
import 'license_service.dart';

class BillingException implements Exception {
  const BillingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BillingService {
  BillingService({
    http.Client? client,
    LicenseService? licenseService,
    String? backendUrl,
  }) : _client = client ?? http.Client(),
       _licenseService = licenseService ?? LicenseService(),
       _backendUrl = backendUrl ?? AppConfigService.defaultBackendUrl;

  final http.Client _client;
  final LicenseService _licenseService;
  final String _backendUrl;

  Future<List<BillingPlan>> getPlans() async {
    final response = await _client.get(
      _billingUri('/api/billing/plans'),
      headers: const {'Accept': 'application/json'},
    );
    final decoded = _decodeResponse(response);
    final rawPlans = decoded['plans'] ?? decoded['data'] ?? decoded['items'];
    if (rawPlans is! List) {
      throw const BillingException('Réponse des plans invalide.');
    }
    return rawPlans
        .whereType<Map<String, dynamic>>()
        .map(BillingPlan.fromJson)
        .toList(growable: false);
  }

  Future<String> createCheckoutSession({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String firstName,
    required String lastName,
    required String companyName,
    String? vatNumber,
    String? addressLine1,
    String? postalCode,
    String? city,
    String country = 'BE',
    required String planId,
  }) async {
    final response = await _client.post(
      _billingUri('/api/billing/create-checkout-session'),
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'passwordConfirmation': passwordConfirmation,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'companyName': companyName.trim(),
        'vatNumber': _nullableTrim(vatNumber),
        'addressLine1': _nullableTrim(addressLine1),
        'postalCode': _nullableTrim(postalCode),
        'city': _nullableTrim(city),
        'country': country.trim().isEmpty ? 'BE' : country.trim(),
        'planId': planId,
      }),
    );
    final decoded = _decodeResponse(response);
    return _urlFrom(decoded, fallbackMessage: 'URL de paiement manquante.');
  }

  Future<String> createPortalSession() async {
    final token = await _licenseService.getAuthToken();
    if (token == null) {
      throw const BillingException('Connexion requise.');
    }
    final response = await _client.post(
      _billingUri('/api/billing/create-portal-session'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final decoded = _decodeResponse(response);
    return _urlFrom(
      decoded,
      fallbackMessage: 'URL de gestion d’abonnement manquante.',
    );
  }

  Uri _billingUri(String path) {
    final source = Uri.parse(_backendUrl.trim());
    return source.replace(path: path, query: null, fragment: null);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const BillingException('Réponse billing invalide.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BillingException(
        _messageFrom(decoded) ?? 'Service de paiement indisponible.',
      );
    }
    if (decoded['success'] == false) {
      throw BillingException(
        _messageFrom(decoded) ?? 'Demande de paiement refusée.',
      );
    }
    return decoded;
  }

  static String _urlFrom(
    Map<String, dynamic> decoded, {
    required String fallbackMessage,
  }) {
    final value =
        decoded['checkoutUrl'] ??
        decoded['portalUrl'] ??
        decoded['url'] ??
        decoded['sessionUrl'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw BillingException(fallbackMessage);
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _messageFrom(Map<String, dynamic> decoded) {
    final value = decoded['error'] ?? decoded['message'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is Map<String, dynamic>) {
      final message = value['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }
}
