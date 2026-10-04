import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preventia_belgique_app/models/document_form_data.dart';
import 'package:preventia_belgique_app/models/generation_source.dart';
import 'package:preventia_belgique_app/services/ai_document_service.dart';
import 'package:preventia_belgique_app/services/app_config_service.dart';
import 'package:preventia_belgique_app/services/license_service.dart';

void main() {
  group('AiDocumentService.isBackendAvailable', () {
    test('tests Render health endpoint', () async {
      Uri? requestedUri;
      final service = AiDocumentService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response('{}', 200);
        }),
      );

      final isAvailable = await service.isBackendAvailable();

      expect(isAvailable, isTrue);
      expect(requestedUri, Uri.parse(AppConfigService.defaultBackendHealthUrl));
    });

    test('builds health endpoint from generation endpoint', () {
      expect(
        buildHealthUrl(
          'https://preventia-backend-gjhg.onrender.com/api/generate-document',
        ),
        'https://preventia-backend-gjhg.onrender.com/health',
      );
      expect(
        buildHealthUrl('https://preventia-backend-gjhg.onrender.com'),
        'https://preventia-backend-gjhg.onrender.com/health',
      );
      expect(
        buildHealthUrl(
          'https://preventia-backend-gjhg.onrender.com/api/generate-document/',
        ),
        'https://preventia-backend-gjhg.onrender.com/health',
      );
    });

    test('returns detailed HTTP failure result', () async {
      final service = AiDocumentService(
        client: MockClient((request) async => http.Response('{}', 404)),
      );

      final result = await service.checkBackendAvailability(
        backendUrl: AppConfigService.defaultBackendUrl,
      );

      expect(result.isAvailable, isFalse);
      expect(result.healthUrl, AppConfigService.defaultBackendHealthUrl);
      expect(result.statusCode, 404);
      expect(result.unavailableMessage, contains('Code : 404'));
    });

    test('returns false when backend health check fails', () async {
      final service = AiDocumentService(
        client: MockClient((request) async => http.Response('{}', 503)),
      );

      final isAvailable = await service.isBackendAvailable();

      expect(isAvailable, isFalse);
    });
  });

  group('AiDocumentService.generateDocument', () {
    test('sends expected payload and returns ai backend source', () async {
      Uri? requestedUri;
      Map<String, dynamic>? payload;
      String? authorization;
      final licenseStorage = _MemoryLicenseStorage();
      await licenseStorage.write(key: 'license_key', value: 'LIC-TEST');
      await licenseStorage.write(key: 'authToken', value: 'token-test');
      await licenseStorage.write(
        key: 'license_device_id',
        value: 'device-test',
      );
      final service = AiDocumentService(
        licenseService: LicenseService(storage: licenseStorage),
        client: MockClient((request) async {
          requestedUri = request.url;
          authorization = request.headers['Authorization'];
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'success': true, 'document': 'Document IA'}),
            200,
          );
        }),
      );

      final result = await service.generateDocument(
        backendUrl: AppConfigService.defaultBackendUrl,
        data: _documentFormData(),
        languageCode: 'nl',
        languageLabel: 'Nederlands',
      );

      expect(requestedUri, Uri.parse(AppConfigService.defaultBackendUrl));
      expect(payload?['documentType'], 'Analyse de risques générale');
      expect(payload?['language'], 'nl');
      expect(payload?['languageLabel'], 'Nederlands');
      expect(payload?['licenseKey'], 'LIC-TEST');
      expect(payload?['deviceId'], 'device-test');
      expect(authorization, 'Bearer token-test');
      expect(payload?['formData'], isA<Map<String, dynamic>>());
      expect(
        (payload?['formData'] as Map<String, dynamic>)['companyName'],
        'Entreprise test',
      );
      expect(result.content, 'Document IA');
      expect(result.source, GenerationSource.aiBackend);
    });

    test(
      'sends the electrical installations document type and fields',
      () async {
        Map<String, dynamic>? payload;
        final licenseStorage = _MemoryLicenseStorage();
        await licenseStorage.write(
          key: 'license_device_id',
          value: 'device-test',
        );
        final service = AiDocumentService(
          licenseService: LicenseService(storage: licenseStorage),
          client: MockClient((request) async {
            payload = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'success': true,
                'document':
                    '# Analyse de risques — Installations électriques BT/HT',
              }),
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8',
              },
            );
          }),
        );

        await service.generateDocument(
          backendUrl: AppConfigService.defaultBackendUrl,
          data: _documentFormData(
            documentType:
                'Analyse de risques — Installations électriques BT/HT',
            extraFields: const {
              'installationType': 'mixte',
              'rgieReportAvailable': 'oui',
              'ba4Ba5ListAvailable': 'à vérifier',
            },
          ),
          languageCode: 'fr',
          languageLabel: 'Français',
        );

        expect(
          payload?['documentType'],
          'Analyse de risques — Installations électriques BT/HT',
        );
        final formData = payload?['formData'] as Map<String, dynamic>;
        expect(
          formData['documentType'],
          'Analyse de risques — Installations électriques BT/HT',
        );
        expect(formData['companyName'], 'Entreprise test');
        expect(formData['installationType'], 'mixte');
        expect(formData['rgieReportAvailable'], 'oui');
        expect(formData['ba4Ba5ListAvailable'], 'à vérifier');
      },
    );

    test(
      'sends exact elevator type and accepts the dedicated renderer',
      () async {
        Map<String, dynamic>? payload;
        final licenseStorage = _MemoryLicenseStorage();
        final service = AiDocumentService(
          licenseService: LicenseService(storage: licenseStorage),
          client: MockClient((request) async {
            payload = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'success': true,
                'document': '# Analyse de risques — Ascenseur\nSECT',
              }),
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8',
              },
            );
          }),
        );

        final result = await service.generateDocument(
          backendUrl: AppConfigService.defaultBackendUrl,
          data: _documentFormData(
            documentType: 'Analyse de risques — Ascenseur',
            extraFields: const {'sect': 'À confirmer'},
          ),
          languageCode: 'fr',
          languageLabel: 'Français',
        );

        expect(payload?['documentType'], 'Analyse de risques — Ascenseur');
        expect(
          (payload?['formData'] as Map<String, dynamic>)['documentType'],
          'Analyse de risques — Ascenseur',
        );
        expect(result.content, contains('Analyse de risques — Ascenseur'));
      },
    );

    test('rejects a generic response for a dedicated renderer', () async {
      final service = AiDocumentService(
        licenseService: LicenseService(storage: _MemoryLicenseStorage()),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'document': '# Analyse de risques générale',
            }),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      await expectLater(
        service.generateDocument(
          backendUrl: AppConfigService.defaultBackendUrl,
          data: _documentFormData(
            documentType: 'Analyse de risques — Ascenseur',
          ),
          languageCode: 'fr',
          languageLabel: 'Français',
        ),
        throwsA(
          isA<AiDocumentException>().having(
            (error) => error.message,
            'message',
            contains('modèle Ascenseur attendu'),
          ),
        ),
      );
    });

    test('maps backend license errors to a clear message', () async {
      final licenseStorage = _MemoryLicenseStorage();
      await licenseStorage.write(key: 'license_key', value: 'LIC-TEST');
      await licenseStorage.write(
        key: 'license_device_id',
        value: 'device-test',
      );
      final service = AiDocumentService(
        licenseService: LicenseService(storage: licenseStorage),
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'code': 'LICENSE_QUOTA_REACHED',
              'message': 'quota reached',
            }),
            200,
          );
        }),
      );

      expect(
        () => service.generateDocument(
          backendUrl: AppConfigService.defaultBackendUrl,
          data: _documentFormData(),
          languageCode: 'fr',
          languageLabel: 'Français',
        ),
        throwsA(
          isA<AiDocumentException>().having(
            (error) => error.message,
            'message',
            'Licence requise, expirée ou quota atteint.',
          ),
        ),
      );
    });
  });
}

class _MemoryLicenseStorage implements LicenseStorage {
  final _values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }
}

DocumentFormData _documentFormData({
  String documentType = 'Analyse de risques générale',
  Map<String, dynamic> extraFields = const {},
}) {
  const value = 'Valeur test';
  return DocumentFormData(
    documentType: documentType,
    companyName: 'Entreprise test',
    siteConcerned: value,
    serviceConcerned: value,
    author: value,
    version: value,
    visitDate: value,
    documentObjective: value,
    includedLocations: value,
    excludedLocations: value,
    concernedPositions: value,
    concernedTasks: value,
    includedSituations: value,
    exposureDuration: value,
    workMode: value,
    fieldVisitDone: value,
    jobObservationDone: value,
    workersConsulted: value,
    managementConsulted: value,
    cpptConsulted: value,
    incidentRegisterAvailable: value,
    photosAvailable: value,
    controlReportsAvailable: value,
    technicalSheetsAvailable: value,
    safetyDataSheetsAvailable: value,
    sector: value,
    workerCount: value,
    activity: value,
    equipment: value,
    dangerousProducts: value,
    exposedWorkers: value,
    knownIncidents: value,
    constraints: value,
    additionalInformation: value,
    writtenInstructions: value,
    completedTrainings: value,
    availablePpe: value,
    periodicControls: value,
    availableEvidence: value,
    oralMeasures: value,
    measuresToVerify: value,
    workAtHeight: value,
    dangerousMachines: value,
    chemicalProducts: value,
    manualHandling: value,
    vehiclePedestrianTraffic: value,
    noise: value,
    fireRisk: value,
    loneWork: value,
    coactivity: value,
    weatherConstraints: value,
    newWorkers: value,
    temporaryWorkers: value,
    youngWorkers: value,
    pregnantOrBreastfeedingWorkers: value,
    medicalRestrictionsWorkers: value,
    isolatedWorkers: value,
    subcontractors: value,
    cpptPresence: value,
    preventionService: value,
    feedAnnualActionPlan: value,
    feedGlobalPreventionPlan: value,
    presentToCppt: value,
    externalServiceValidation: value,
    occupationalDoctorAdvice: value,
    extraFields: extraFields,
  );
}
