import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/generation_source.dart';
import '../models/document_form_data.dart';
import 'app_config_service.dart';
import 'license_service.dart';

class AiLinkedDocument {
  const AiLinkedDocument({required this.title, required this.content});

  final String title;
  final String content;
}

class AiDocumentResult {
  const AiDocumentResult({
    required this.content,
    required this.source,
    this.linkedDocuments = const [],
  });

  final String content;
  final GenerationSource source;
  final List<AiLinkedDocument> linkedDocuments;
}

class BackendAvailabilityResult {
  const BackendAvailabilityResult({
    required this.isAvailable,
    required this.healthUrl,
    this.statusCode,
    this.networkError,
  });

  final bool isAvailable;
  final String healthUrl;
  final int? statusCode;
  final String? networkError;

  String get unavailableMessage {
    if (networkError != null && networkError!.trim().isNotEmpty) {
      return 'Backend indisponible. URL testée : $healthUrl. Erreur réseau : $networkError';
    }
    if (statusCode != null) {
      return 'Backend indisponible. URL testée : $healthUrl. Code : $statusCode';
    }
    return 'Backend indisponible. URL testée : $healthUrl';
  }
}

class AiDocumentService {
  AiDocumentService({
    http.Client? client,
    Duration? timeout,
    LicenseService? licenseService,
  }) : _client = client ?? http.Client(),
       _licenseService = licenseService,
       _timeout = timeout ?? const Duration(seconds: 180);

  final http.Client _client;
  final LicenseService? _licenseService;
  final Duration _timeout;

  Future<bool> isBackendAvailable({String? backendUrl}) async {
    final result = await checkBackendAvailability(backendUrl: backendUrl);
    return result.isAvailable;
  }

  Future<BackendAvailabilityResult> checkBackendAvailability({
    String? backendUrl,
  }) async {
    final generateUrl = AppConfigService.shouldResetBackendUrl(backendUrl)
        ? AppConfigService.defaultBackendUrl
        : backendUrl!;
    final healthUrl = buildHealthUrl(generateUrl);

    try {
      final healthUri = _parseBackendUri(healthUrl);
      _debugLog('Backend health check: generateUrl=$generateUrl');
      _debugLog('Backend health check: healthUrl=$healthUri');
      final response = await _client
          .get(healthUri)
          .timeout(const Duration(seconds: 20));
      final isAvailable = _isSuccessfulHealthResponse(response);
      _debugLog(
        'Backend health check response: statusCode=${response.statusCode}',
      );
      return BackendAvailabilityResult(
        isAvailable: isAvailable,
        healthUrl: healthUri.toString(),
        statusCode: response.statusCode,
      );
    } on Object catch (error) {
      _debugLog('Backend health check error: $error');
      return BackendAvailabilityResult(
        isAvailable: false,
        healthUrl: healthUrl,
        networkError: error.toString(),
      );
    }
  }

  Future<AiDocumentResult> generateDocument({
    required String backendUrl,
    required DocumentFormData data,
    required String languageCode,
    required String languageLabel,
  }) async {
    final uri = _parseBackendUri(backendUrl);
    final licenseService =
        _licenseService ?? LicenseService(backendUrl: backendUrl);
    final payload = await _buildPayload(
      data,
      languageCode: languageCode,
      languageLabel: languageLabel,
      licenseService: licenseService,
    );
    final authToken = await licenseService.getAuthToken();
    final requestBody = jsonEncode(payload);

    try {
      _debugLog('IA backend request: backendUrl=$uri language=$languageCode');
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
              if (authToken != null) 'Authorization': 'Bearer $authToken',
            },
            body: requestBody,
          )
          .timeout(_timeout);
      _debugLog('IA backend response: status=${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final backendMessage = _extractBackendErrorMessage(response);
        throw AiDocumentException(
          backendMessage ??
              'Le backend IA a répondu avec le code ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const AiDocumentException(
          'La réponse du backend IA est invalide.',
        );
      }

      final document = decoded['document'] ?? decoded['content'];
      final receivedSource = decoded['source'];
      final success = decoded['success'];
      if (success == false) {
        final message = decoded['message'] ?? decoded['error'];
        final extractedMessage = message is String && message.trim().isNotEmpty
            ? message.trim()
            : null;
        throw AiDocumentException(
          _isLicenseError(decoded, extractedMessage)
              ? 'Licence requise, expirée ou quota atteint.'
              : extractedMessage ?? 'Le backend IA a répondu sans succès.',
        );
      }
      if (document is! String || document.trim().isEmpty) {
        throw const AiDocumentException(
          'La réponse du backend IA ne contient pas de document.',
        );
      }

      final source = GenerationSource.aiBackend;
      _debugLog(
        'IA backend generation source=${receivedSource ?? source.value}',
      );
      return AiDocumentResult(
        content: document.trim(),
        source: source,
        linkedDocuments: _extractLinkedDocuments(decoded),
      );
    } on TimeoutException {
      throw const AiDocumentException(
        'Le backend IA met trop de temps à répondre. Vous pouvez réessayer ou utiliser la génération locale.',
      );
    } on FormatException {
      throw const AiDocumentException(
        'La réponse du backend IA n’est pas un JSON valide.',
      );
    } on http.ClientException catch (error) {
      throw AiDocumentException(
        'La connexion au backend IA a échoué : ${error.message}',
      );
    }
  }

  List<AiLinkedDocument> _extractLinkedDocuments(Map<String, dynamic> decoded) {
    final rawDocuments =
        decoded['linkedDocuments'] ??
        decoded['relatedDocuments'] ??
        decoded['additionalDocuments'] ??
        decoded['documentsLies'] ??
        decoded['documentsComplémentaires'];
    if (rawDocuments is! List) {
      return const [];
    }

    return rawDocuments
        .map((rawDocument) {
          if (rawDocument is String && rawDocument.trim().isNotEmpty) {
            return AiLinkedDocument(
              title: 'Document complémentaire',
              content: rawDocument.trim(),
            );
          }
          if (rawDocument is! Map<String, dynamic>) {
            return null;
          }
          final title =
              rawDocument['title'] ??
              rawDocument['documentType'] ??
              rawDocument['name'] ??
              rawDocument['titre'];
          final content =
              rawDocument['content'] ??
              rawDocument['document'] ??
              rawDocument['markdown'] ??
              rawDocument['texte'];
          if (content is! String || content.trim().isEmpty) {
            return null;
          }
          return AiLinkedDocument(
            title: title is String && title.trim().isNotEmpty
                ? title.trim()
                : 'Document complémentaire',
            content: content.trim(),
          );
        })
        .whereType<AiLinkedDocument>()
        .toList(growable: false);
  }

  Uri _parseBackendUri(String backendUrl) {
    final uri = Uri.tryParse(backendUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const AiDocumentException('L’URL du backend IA est invalide.');
    }
    if (uri.scheme == 'https') {
      return uri;
    }
    if (isLocalDevelopmentHttpUrl(uri)) {
      return uri;
    }
    if (uri.scheme == 'http') {
      throw const AiDocumentException(
        'Les URL HTTP publiques ne sont pas autorisées. Utilisez HTTPS en production.',
      );
    }
    throw const AiDocumentException(
      'L’URL du backend IA doit utiliser HTTPS en production.',
    );
  }

  static bool isLocalDevelopmentHttpUrl(Uri uri) {
    if (uri.scheme != 'http') {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1') {
      return true;
    }

    final parts = host.split('.');
    if (parts.length != 4) {
      return false;
    }

    final octets = parts.map(int.tryParse).toList();
    if (octets.any((octet) => octet == null || octet < 0 || octet > 255)) {
      return false;
    }

    final first = octets[0]!;
    final second = octets[1]!;
    return first == 10 ||
        first == 192 && second == 168 ||
        first == 172 && second >= 16 && second <= 31;
  }

  static bool shouldShowLocalHttpWarning(String backendUrl) {
    final uri = Uri.tryParse(backendUrl.trim());
    if (uri == null) {
      return false;
    }
    return isLocalDevelopmentHttpUrl(uri);
  }

  Future<Map<String, dynamic>> _buildPayload(
    DocumentFormData data, {
    required String languageCode,
    required String languageLabel,
    required LicenseService licenseService,
  }) async {
    final licenseKey = await licenseService.getLicenseKey();
    final authToken = await licenseService.getAuthToken();
    final deviceId = await licenseService.getOrCreateDeviceId();
    debugPrint(
      'License attached to generation: ${licenseKey == null && authToken == null ? 'no' : 'yes'}',
    );
    final formData = data.toJson()
      ..addAll({
        'nomEntreprise': data.companyName,
        'siteConcerne': data.siteConcerned,
        'serviceConcerne': data.serviceConcerned,
        'redacteur': data.author,
        'dateVisiteObservation': data.visitDate,
        'objectifDocument': data.documentObjective,
        'lieuxInclus': data.includedLocations,
        'lieuxExclus': data.excludedLocations,
        'postesConcernes': data.concernedPositions,
        'tachesConcernees': data.concernedTasks,
        'situationsIncluses': data.includedSituations,
        'dureeExposition': data.exposureDuration,
        'modeTravail': data.workMode,
        'visiteTerrainRealisee': data.fieldVisitDone,
        'observationPosteRealisee': data.jobObservationDone,
        'travailleursConsultes': data.workersConsulted,
        'ligneHierarchiqueConsultee': data.managementConsulted,
        'cpptConsulte': data.cpptConsulted,
        'registreAccidentsDisponible': data.incidentRegisterAvailable,
        'photosDisponibles': data.photosAvailable,
        'rapportsControleDisponibles': data.controlReportsAvailable,
        'fichesTechniquesDisponibles': data.technicalSheetsAvailable,
        'fdsDisponibles': data.safetyDataSheetsAvailable,
        'secteurActivite': data.sector,
        'nombreTravailleurs': data.workerCount,
        'siteLieuTravail': data.siteConcerned,
        'activitePoste': data.activity,
        'machinesEquipements': data.equipment,
        'produitsDangereux': data.dangerousProducts,
        'travailleursExposes': data.exposedWorkers,
        'accidentsIncidents': data.knownIncidents,
        'mesuresExistantes': data.existingMeasures,
        'presenceCppt': data.cpptPresence,
        'serviceInterneExterne': data.preventionService,
        'contraintesParticulieres': data.constraints,
        'informationsComplementaires': data.additionalInformation,
      });

    return {
      'documentType': data.documentType,
      'language': languageCode,
      'languageLabel': languageLabel,
      'licenseKey': licenseKey,
      'deviceId': deviceId,
      'formData': formData,
    };
  }

  String? _extractBackendErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
      if (error is Map<String, dynamic>) {
        final errorMessage = error['message'];
        if (errorMessage is String && errorMessage.trim().isNotEmpty) {
          return errorMessage.trim();
        }
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  bool _isLicenseError(Map<String, dynamic> decoded, String? message) {
    final code = decoded['code'] ?? decoded['errorCode'];
    final normalized = '${code ?? ''} ${message ?? ''}'.toLowerCase();
    return normalized.contains('license') ||
        normalized.contains('licence') ||
        normalized.contains('quota') ||
        normalized.contains('expired') ||
        normalized.contains('expir');
  }

  bool _isSuccessfulHealthResponse(http.Response response) {
    return response.statusCode == 200;
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}

String buildHealthUrl(String generateUrl) {
  final uri = Uri.tryParse(generateUrl.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return generateUrl.trim();
  }

  return uri.replace(path: '/health', query: null, fragment: null).toString();
}

class AiDocumentException implements Exception {
  const AiDocumentException(this.message);

  final String message;

  @override
  String toString() => message;
}
