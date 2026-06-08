import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preventia_belgique_app/models/document_form_data.dart';
import 'package:preventia_belgique_app/models/generation_source.dart';
import 'package:preventia_belgique_app/services/ai_document_service.dart';
import 'package:preventia_belgique_app/services/app_config_service.dart';

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
      final service = AiDocumentService(
        client: MockClient((request) async {
          requestedUri = request.url;
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
      expect(payload?['formData'], isA<Map<String, dynamic>>());
      expect(
        (payload?['formData'] as Map<String, dynamic>)['companyName'],
        'Entreprise test',
      );
      expect(result.content, 'Document IA');
      expect(result.source, GenerationSource.aiBackend);
    });
  });
}

DocumentFormData _documentFormData() {
  const value = 'Valeur test';
  return const DocumentFormData(
    documentType: 'Analyse de risques générale',
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
  );
}
