import 'package:flutter_test/flutter_test.dart';
import 'package:preventia_belgique_app/models/analysis_project.dart';
import 'package:preventia_belgique_app/services/document_reference_service.dart';
import 'package:preventia_belgique_app/services/local_document_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('generates persistent references by prefix and year', () async {
    SharedPreferences.setMockInitialValues({});
    final service = DocumentReferenceService();
    final now = DateTime(2026, 6, 10);

    expect(
      await service.nextReference(
        documentType: 'Plan annuel d’action',
        now: now,
      ),
      'PAA-2026-0001',
    );
    expect(
      await service.nextReference(
        documentType: 'Plan annuel d’action',
        now: now,
      ),
      'PAA-2026-0002',
    );
    expect(
      await service.nextReference(documentType: 'Fiche de poste', now: now),
      'FP-2026-0001',
    );
  });

  test('continues after references already saved in history', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalDocumentStorage().saveOrUpdateProject(
      AnalysisProject(
        id: 'existing',
        name: 'PAA-2026-0007 – Plan annuel d’action',
        createdAt: DateTime(2026, 1),
        modifiedAt: DateTime(2026, 1),
        referenceNumber: 'PAA-2026-0007',
        analysisTitle: 'PAA-2026-0007 – Plan annuel d’action',
        analysisDocumentId: 'existing_main',
      ),
    );

    final reference = await DocumentReferenceService().nextReference(
      documentType: 'Plan annuel d’action',
      now: DateTime(2026, 6, 10),
    );

    expect(reference, 'PAA-2026-0008');
  });
}
