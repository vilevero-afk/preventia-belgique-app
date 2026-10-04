import 'preventia_project.dart';

class PreventiaCompanyProject {
  const PreventiaCompanyProject({
    required this.id,
    required this.companyName,
    required this.companyKey,
    required this.createdAt,
    required this.updatedAt,
    this.sites = const [],
    this.documents = const [],
    this.analyses = const [],
    this.piuDocument,
    this.pgaDocument,
    this.actionItems = const [],
    this.piuItems = const [],
    this.diuItems = const [],
    this.evidenceItems = const [],
    this.pointsToVerify = const [],
    this.requiredValidations = const [],
    this.companyProfile = const PreventiaCompanyProfile(),
    this.localFolderPath,
  });

  final String id;
  final String companyName;
  final String companyKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PreventiaSiteEntry> sites;
  final List<PreventiaCompanyDocument> documents;
  final List<PreventiaCompanyDocument> analyses;
  final PreventiaCompanyDocument? piuDocument;
  final PreventiaCompanyDocument? pgaDocument;
  final List<PreventiaActionItem> actionItems;
  final List<PreventiaPiuItem> piuItems;
  final List<PreventiaDiuItem> diuItems;
  final List<PreventiaEvidenceItem> evidenceItems;
  final List<String> pointsToVerify;
  final List<String> requiredValidations;
  final PreventiaCompanyProfile companyProfile;
  final String? localFolderPath;

  PreventiaCompanyProject copyWith({
    DateTime? updatedAt,
    List<PreventiaSiteEntry>? sites,
    List<PreventiaCompanyDocument>? documents,
    List<PreventiaCompanyDocument>? analyses,
    PreventiaCompanyDocument? piuDocument,
    PreventiaCompanyDocument? pgaDocument,
    List<PreventiaActionItem>? actionItems,
    List<PreventiaPiuItem>? piuItems,
    List<PreventiaDiuItem>? diuItems,
    List<PreventiaEvidenceItem>? evidenceItems,
    List<String>? pointsToVerify,
    List<String>? requiredValidations,
    PreventiaCompanyProfile? companyProfile,
    String? localFolderPath,
  }) => PreventiaCompanyProject(
    id: id,
    companyName: companyName,
    companyKey: companyKey,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sites: sites ?? this.sites,
    documents: documents ?? this.documents,
    analyses: analyses ?? this.analyses,
    piuDocument: piuDocument ?? this.piuDocument,
    pgaDocument: pgaDocument ?? this.pgaDocument,
    actionItems: actionItems ?? this.actionItems,
    piuItems: piuItems ?? this.piuItems,
    diuItems: diuItems ?? this.diuItems,
    evidenceItems: evidenceItems ?? this.evidenceItems,
    pointsToVerify: pointsToVerify ?? this.pointsToVerify,
    requiredValidations: requiredValidations ?? this.requiredValidations,
    companyProfile: companyProfile ?? this.companyProfile,
    localFolderPath: localFolderPath ?? this.localFolderPath,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'companyKey': companyKey,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sites': sites.map((item) => item.toJson()).toList(),
    'documents': documents.map((item) => item.toJson()).toList(),
    'analyses': analyses.map((item) => item.toJson()).toList(),
    'piuDocument': piuDocument?.toJson(),
    'pgaDocument': pgaDocument?.toJson(),
    'actionItems': actionItems.map((item) => item.toJson()).toList(),
    'piuItems': piuItems.map((item) => item.toJson()).toList(),
    'diuItems': diuItems.map((item) => item.toJson()).toList(),
    'evidenceItems': evidenceItems.map((item) => item.toJson()).toList(),
    'pointsToVerify': pointsToVerify,
    'requiredValidations': requiredValidations,
    'companyProfile': companyProfile.toJson(),
    'localFolderPath': localFolderPath,
  };

  factory PreventiaCompanyProject.fromJson(Map<String, dynamic> json) =>
      PreventiaCompanyProject(
        id: json['id']?.toString() ?? '',
        companyName: json['companyName']?.toString() ?? '',
        companyKey: json['companyKey']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        sites: _sites(json['sites']),
        documents: _items(json['documents'], PreventiaCompanyDocument.fromJson),
        analyses: _items(json['analyses'], PreventiaCompanyDocument.fromJson),
        piuDocument: _document(json['piuDocument']),
        pgaDocument: _document(json['pgaDocument']),
        actionItems: _items(json['actionItems'], PreventiaActionItem.fromJson),
        piuItems: _items(json['piuItems'], PreventiaPiuItem.fromJson),
        diuItems: _items(json['diuItems'], PreventiaDiuItem.fromJson),
        evidenceItems: _items(
          json['evidenceItems'],
          PreventiaEvidenceItem.fromJson,
        ),
        pointsToVerify: _strings(json['pointsToVerify']),
        requiredValidations: _strings(json['requiredValidations']),
        companyProfile: json['companyProfile'] is Map
            ? PreventiaCompanyProfile.fromJson(
                Map<String, dynamic>.from(json['companyProfile'] as Map),
              )
            : const PreventiaCompanyProfile(),
        localFolderPath: json['localFolderPath']?.toString(),
      );
}

class PreventiaCompanyProfile {
  const PreventiaCompanyProfile({
    this.companyName = '',
    this.siteName = '',
    this.address = '',
    this.postalCode = '',
    this.city = '',
    this.country = 'Belgique',
    this.siteContact = '',
    this.preventionAdvisor = '',
    this.siteManager = '',
    this.technicalServiceContact = '',
    this.generalPhone = '',
    this.generalEmail = '',
    this.activityDescription = '',
    this.riskProfile = '',
    this.numberOfWorkers = '',
    this.visitorsPresence = '',
    this.externalCompaniesPresence = '',
    this.workingHours = '',
  });

  final String companyName;
  final String siteName;
  final String address;
  final String postalCode;
  final String city;
  final String country;
  final String siteContact;
  final String preventionAdvisor;
  final String siteManager;
  final String technicalServiceContact;
  final String generalPhone;
  final String generalEmail;
  final String activityDescription;
  final String riskProfile;
  final String numberOfWorkers;
  final String visitorsPresence;
  final String externalCompaniesPresence;
  final String workingHours;

  PreventiaCompanyProfile merge(PreventiaCompanyProfile incoming) =>
      PreventiaCompanyProfile(
        companyName: _better(companyName, incoming.companyName),
        siteName: _better(siteName, incoming.siteName),
        address: _better(address, incoming.address),
        postalCode: _better(postalCode, incoming.postalCode),
        city: _better(city, incoming.city),
        country: _better(country, incoming.country),
        siteContact: _better(siteContact, incoming.siteContact),
        preventionAdvisor: _better(
          preventionAdvisor,
          incoming.preventionAdvisor,
        ),
        siteManager: _better(siteManager, incoming.siteManager),
        technicalServiceContact: _better(
          technicalServiceContact,
          incoming.technicalServiceContact,
        ),
        generalPhone: _better(generalPhone, incoming.generalPhone),
        generalEmail: _better(generalEmail, incoming.generalEmail),
        activityDescription: _better(
          activityDescription,
          incoming.activityDescription,
        ),
        riskProfile: _better(riskProfile, incoming.riskProfile),
        numberOfWorkers: _better(numberOfWorkers, incoming.numberOfWorkers),
        visitorsPresence: _better(visitorsPresence, incoming.visitorsPresence),
        externalCompaniesPresence: _better(
          externalCompaniesPresence,
          incoming.externalCompaniesPresence,
        ),
        workingHours: _better(workingHours, incoming.workingHours),
      );

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'siteName': siteName,
    'address': address,
    'postalCode': postalCode,
    'city': city,
    'country': country,
    'siteContact': siteContact,
    'preventionAdvisor': preventionAdvisor,
    'siteManager': siteManager,
    'technicalServiceContact': technicalServiceContact,
    'generalPhone': generalPhone,
    'generalEmail': generalEmail,
    'activityDescription': activityDescription,
    'riskProfile': riskProfile,
    'numberOfWorkers': numberOfWorkers,
    'visitorsPresence': visitorsPresence,
    'externalCompaniesPresence': externalCompaniesPresence,
    'workingHours': workingHours,
  };

  factory PreventiaCompanyProfile.fromJson(Map<String, dynamic> json) =>
      PreventiaCompanyProfile(
        companyName: json['companyName']?.toString() ?? '',
        siteName: json['siteName']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        postalCode: json['postalCode']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        country: json['country']?.toString() ?? 'Belgique',
        siteContact: json['siteContact']?.toString() ?? '',
        preventionAdvisor: json['preventionAdvisor']?.toString() ?? '',
        siteManager: json['siteManager']?.toString() ?? '',
        technicalServiceContact:
            json['technicalServiceContact']?.toString() ?? '',
        generalPhone: json['generalPhone']?.toString() ?? '',
        generalEmail: json['generalEmail']?.toString() ?? '',
        activityDescription: json['activityDescription']?.toString() ?? '',
        riskProfile: json['riskProfile']?.toString() ?? '',
        numberOfWorkers: json['numberOfWorkers']?.toString() ?? '',
        visitorsPresence: json['visitorsPresence']?.toString() ?? '',
        externalCompaniesPresence:
            json['externalCompaniesPresence']?.toString() ?? '',
        workingHours: json['workingHours']?.toString() ?? '',
      );
}

String _better(String current, String incoming) {
  final trimmedCurrent = current.trim();
  final trimmedIncoming = incoming.trim();
  if (trimmedIncoming.isEmpty || _isPlaceholder(trimmedIncoming)) {
    return trimmedCurrent;
  }
  if (trimmedCurrent.isEmpty || _isPlaceholder(trimmedCurrent)) {
    return trimmedIncoming;
  }
  return trimmedIncoming.length > trimmedCurrent.length
      ? trimmedIncoming
      : trimmedCurrent;
}

bool _isPlaceholder(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp('[àáâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .trim();
  return normalized == '[a completer]' ||
      normalized == 'a completer' ||
      normalized == 'non renseigne / a verifier';
}

class PreventiaCompanyDocument {
  const PreventiaCompanyDocument({
    required this.id,
    required this.documentType,
    required this.title,
    required this.status,
    required this.createdAt,
    DateTime? updatedAt,
    required this.autoCreated,
    required this.source,
    this.markdown = '',
    this.reference = '',
    this.companyName = '',
    this.siteName = '',
    this.formData = const {},
    this.wordPath,
    this.pdfPath,
    this.isAssistedDraft = false,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String documentType;
  final String title;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool autoCreated;
  final String source;
  final String markdown;
  final String reference;
  final String companyName;
  final String siteName;
  final Map<String, dynamic> formData;
  final String? wordPath;
  final String? pdfPath;
  final bool isAssistedDraft;

  PreventiaCompanyDocument copyWith({
    DateTime? updatedAt,
    String? title,
    String? status,
    String? markdown,
    String? reference,
    String? companyName,
    String? siteName,
    Map<String, dynamic>? formData,
    String? wordPath,
    String? pdfPath,
    bool? isAssistedDraft,
  }) => PreventiaCompanyDocument(
    id: id,
    documentType: documentType,
    title: title ?? this.title,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    autoCreated: autoCreated,
    source: source,
    markdown: markdown ?? this.markdown,
    reference: reference ?? this.reference,
    companyName: companyName ?? this.companyName,
    siteName: siteName ?? this.siteName,
    formData: formData ?? this.formData,
    wordPath: wordPath ?? this.wordPath,
    pdfPath: pdfPath ?? this.pdfPath,
    isAssistedDraft: isAssistedDraft ?? this.isAssistedDraft,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentType': documentType,
    'title': title,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'autoCreated': autoCreated,
    'source': source,
    'markdown': markdown,
    'reference': reference,
    'companyName': companyName,
    'siteName': siteName,
    'formData': formData,
    'wordPath': wordPath,
    'pdfPath': pdfPath,
    'isAssistedDraft': isAssistedDraft,
  };

  factory PreventiaCompanyDocument.fromJson(Map<String, dynamic> json) =>
      PreventiaCompanyDocument(
        id: json['id']?.toString() ?? '',
        documentType: json['documentType']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
        autoCreated: json['autoCreated'] == true,
        source: json['source']?.toString() ?? '',
        markdown: json['markdown']?.toString() ?? '',
        reference: json['reference']?.toString() ?? '',
        companyName: json['companyName']?.toString() ?? '',
        siteName: json['siteName']?.toString() ?? '',
        formData: json['formData'] is Map
            ? Map<String, dynamic>.from(json['formData'] as Map)
            : const {},
        wordPath: json['wordPath']?.toString(),
        pdfPath: json['pdfPath']?.toString(),
        isAssistedDraft: json['isAssistedDraft'] == true,
      );
}

typedef PreventiaDocumentEntry = PreventiaCompanyDocument;

class PreventiaSiteEntry {
  const PreventiaSiteEntry({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name};

  factory PreventiaSiteEntry.fromJson(Map<String, dynamic> json) =>
      PreventiaSiteEntry(name: json['name']?.toString() ?? '');
}

PreventiaCompanyDocument? _document(Object? value) => value is Map
    ? PreventiaCompanyDocument.fromJson(Map<String, dynamic>.from(value))
    : null;

List<PreventiaSiteEntry> _sites(Object? value) => value is List
    ? value
          .map(
            (item) => item is Map
                ? PreventiaSiteEntry.fromJson(Map<String, dynamic>.from(item))
                : PreventiaSiteEntry(name: item.toString()),
          )
          .where((item) => item.name.trim().isNotEmpty)
          .toList(growable: false)
    : const [];

List<T> _items<T>(Object? value, T Function(Map<String, dynamic>) fromJson) =>
    value is List
    ? value
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false)
    : const [];

List<String> _strings(Object? value) => value is List
    ? value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false)
    : const [];
