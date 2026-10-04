class PreventiaProject {
  const PreventiaProject({
    required this.id,
    required this.companyName,
    required this.siteName,
    required this.basePath,
    required this.createdAt,
    required this.updatedAt,
    this.sites = const [],
    this.documents = const [],
    this.riskItems = const [],
    this.actionItems = const [],
    this.diuItems = const [],
    this.piuItems = const [],
    this.photosToTake = const [],
    this.evidenceToCollect = const [],
  });

  final String id;
  final String companyName;
  final String siteName;
  final String basePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> sites;
  final List<PreventiaProjectDocument> documents;
  final List<PreventiaRiskItem> riskItems;
  final List<PreventiaActionItem> actionItems;
  final List<PreventiaDiuItem> diuItems;
  final List<PreventiaPiuItem> piuItems;
  final List<PreventiaEvidenceItem> photosToTake;
  final List<PreventiaEvidenceItem> evidenceToCollect;

  PreventiaProject copyWith({
    String? basePath,
    DateTime? updatedAt,
    List<String>? sites,
    List<PreventiaProjectDocument>? documents,
    List<PreventiaRiskItem>? riskItems,
    List<PreventiaActionItem>? actionItems,
    List<PreventiaDiuItem>? diuItems,
    List<PreventiaPiuItem>? piuItems,
    List<PreventiaEvidenceItem>? photosToTake,
    List<PreventiaEvidenceItem>? evidenceToCollect,
  }) {
    return PreventiaProject(
      id: id,
      companyName: companyName,
      siteName: siteName,
      basePath: basePath ?? this.basePath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sites: sites ?? this.sites,
      documents: documents ?? this.documents,
      riskItems: riskItems ?? this.riskItems,
      actionItems: actionItems ?? this.actionItems,
      diuItems: diuItems ?? this.diuItems,
      piuItems: piuItems ?? this.piuItems,
      photosToTake: photosToTake ?? this.photosToTake,
      evidenceToCollect: evidenceToCollect ?? this.evidenceToCollect,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'companyKey': normalizeCompanyName(companyName),
    'companyPath': basePath,
    'siteName': siteName,
    'basePath': basePath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sites': sites,
    'documents': documents.map((item) => item.toJson()).toList(),
    'riskItems': riskItems.map((item) => item.toJson()).toList(),
    'actionItems': actionItems.map((item) => item.toJson()).toList(),
    'pgaItems': actionItems.map((item) => item.toJson()).toList(),
    'diuItems': diuItems.map((item) => item.toJson()).toList(),
    'piuItems': piuItems.map((item) => item.toJson()).toList(),
    'photosToTake': photosToTake.map((item) => item.toJson()).toList(),
    'evidenceItems': evidenceToCollect.map((item) => item.toJson()).toList(),
    'evidenceToCollect': evidenceToCollect
        .map((item) => item.toJson())
        .toList(),
  };

  factory PreventiaProject.fromJson(Map<String, dynamic> json) {
    return PreventiaProject(
      id: _string(json, 'id'),
      companyName: _string(json, 'companyName'),
      siteName: _string(json, 'siteName'),
      basePath: _string(json, 'basePath'),
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
      sites:
          (json['sites'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList() ??
          [if (_string(json, 'siteName').isNotEmpty) _string(json, 'siteName')],
      documents: _items(json, 'documents', PreventiaProjectDocument.fromJson),
      riskItems: _items(json, 'riskItems', PreventiaRiskItem.fromJson),
      actionItems: _items(json, 'actionItems', PreventiaActionItem.fromJson),
      diuItems: _items(json, 'diuItems', PreventiaDiuItem.fromJson),
      piuItems: _items(json, 'piuItems', PreventiaPiuItem.fromJson),
      photosToTake: _items(
        json,
        'photosToTake',
        PreventiaEvidenceItem.fromJson,
      ),
      evidenceToCollect: _items(
        json,
        json.containsKey('evidenceItems')
            ? 'evidenceItems'
            : 'evidenceToCollect',
        PreventiaEvidenceItem.fromJson,
      ),
    );
  }
}

class PreventiaProjectDocument {
  const PreventiaProjectDocument({
    required this.id,
    required this.documentType,
    required this.title,
    required this.reference,
    required this.language,
    required this.createdAt,
    required this.wordPath,
    required this.pdfPath,
    required this.source,
    this.companyName = '',
    this.siteName = '',
    this.folderPath = '',
    this.extractedToPiu = false,
    this.extractedToPga = false,
    this.extractedToDiu = false,
    this.status = '',
  });

  final String id;
  final String documentType;
  final String title;
  final String reference;
  final String language;
  final DateTime createdAt;
  final String wordPath;
  final String pdfPath;
  final String source;
  final String companyName;
  final String siteName;
  final String folderPath;
  final bool extractedToPiu;
  final bool extractedToPga;
  final bool extractedToDiu;
  final String status;

  PreventiaProjectDocument copyWith({String? wordPath, String? pdfPath}) {
    return PreventiaProjectDocument(
      id: id,
      documentType: documentType,
      title: title,
      reference: reference,
      language: language,
      createdAt: createdAt,
      wordPath: wordPath ?? this.wordPath,
      pdfPath: pdfPath ?? this.pdfPath,
      source: source,
      companyName: companyName,
      siteName: siteName,
      folderPath: folderPath,
      extractedToPiu: extractedToPiu,
      extractedToPga: extractedToPga,
      extractedToDiu: extractedToDiu,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentType': documentType,
    'title': title,
    'reference': reference,
    'language': language,
    'createdAt': createdAt.toIso8601String(),
    'wordPath': wordPath,
    'pdfPath': pdfPath,
    'source': source,
    'companyName': companyName,
    'siteName': siteName,
    'folderPath': folderPath,
    'extractedToPiu': extractedToPiu,
    'extractedToPga': extractedToPga,
    'extractedToDiu': extractedToDiu,
    if (status.isNotEmpty) 'status': status,
  };

  factory PreventiaProjectDocument.fromJson(Map<String, dynamic> json) {
    return PreventiaProjectDocument(
      id: _string(json, 'id'),
      documentType: _string(json, 'documentType'),
      title: _string(json, 'title'),
      reference: _string(json, 'reference'),
      language: _string(json, 'language'),
      createdAt: _date(json, 'createdAt'),
      wordPath: _string(json, 'wordPath'),
      pdfPath: _string(json, 'pdfPath'),
      source: _string(json, 'source'),
      companyName: _string(json, 'companyName'),
      siteName: _string(json, 'siteName'),
      folderPath: _string(json, 'folderPath'),
      extractedToPiu: _bool(json, 'extractedToPiu'),
      extractedToPga: _bool(json, 'extractedToPga'),
      extractedToDiu: _bool(json, 'extractedToDiu'),
      status: _string(json, 'status'),
    );
  }
}

String normalizeCompanyName(String value) => value
    .replaceAll(
      RegExp(r'[\u0000-\u001F\u007F-\u009F\u200B-\u200D\u2060\uFEFF]'),
      '',
    )
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[àáâäãå]'), 'a')
    .replaceAll(RegExp('[ç]'), 'c')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îïíì]'), 'i')
    .replaceAll(RegExp('[ñ]'), 'n')
    .replaceAll(RegExp('[ôöóòõ]'), 'o')
    .replaceAll(RegExp('[ùûüú]'), 'u')
    .replaceAll(RegExp(r'[/\\:*?"<>|]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class PreventiaRiskItem {
  const PreventiaRiskItem({
    required this.id,
    required this.sourceDocumentId,
    required this.sourceDocumentType,
    required this.riskTitle,
    required this.location,
    required this.exposedPersons,
    required this.existingMeasures,
    required this.residualRisk,
    required this.priority,
    required this.evidenceToCollect,
    required this.photoToTake,
    required this.linkedToDiu,
    required this.linkedToPaaPgp,
    required this.linkedToPiu,
    this.status = 'à valider',
  });

  final String id;
  final String sourceDocumentId;
  final String sourceDocumentType;
  final String riskTitle;
  final String location;
  final String exposedPersons;
  final String existingMeasures;
  final String residualRisk;
  final String priority;
  final String evidenceToCollect;
  final String photoToTake;
  final bool linkedToDiu;
  final bool linkedToPaaPgp;
  final bool linkedToPiu;
  final String status;

  PreventiaRiskItem copyWith({String? status}) => PreventiaRiskItem(
    id: id,
    sourceDocumentId: sourceDocumentId,
    sourceDocumentType: sourceDocumentType,
    riskTitle: riskTitle,
    location: location,
    exposedPersons: exposedPersons,
    existingMeasures: existingMeasures,
    residualRisk: residualRisk,
    priority: priority,
    evidenceToCollect: evidenceToCollect,
    photoToTake: photoToTake,
    linkedToDiu: linkedToDiu,
    linkedToPaaPgp: linkedToPaaPgp,
    linkedToPiu: linkedToPiu,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceDocumentId': sourceDocumentId,
    'sourceDocumentType': sourceDocumentType,
    'riskTitle': riskTitle,
    'location': location,
    'exposedPersons': exposedPersons,
    'existingMeasures': existingMeasures,
    'residualRisk': residualRisk,
    'priority': priority,
    'evidenceToCollect': evidenceToCollect,
    'photoToTake': photoToTake,
    'linkedToDiu': linkedToDiu,
    'linkedToPaaPgp': linkedToPaaPgp,
    'linkedToPiu': linkedToPiu,
    'status': status,
  };

  factory PreventiaRiskItem.fromJson(Map<String, dynamic> json) {
    return PreventiaRiskItem(
      id: _string(json, 'id'),
      sourceDocumentId: _string(json, 'sourceDocumentId'),
      sourceDocumentType: _string(json, 'sourceDocumentType'),
      riskTitle: _string(json, 'riskTitle'),
      location: _string(json, 'location'),
      exposedPersons: _string(json, 'exposedPersons'),
      existingMeasures: _string(json, 'existingMeasures'),
      residualRisk: _string(json, 'residualRisk'),
      priority: _string(json, 'priority'),
      evidenceToCollect: _string(json, 'evidenceToCollect'),
      photoToTake: _string(json, 'photoToTake'),
      linkedToDiu: _bool(json, 'linkedToDiu'),
      linkedToPaaPgp: _bool(json, 'linkedToPaaPgp'),
      linkedToPiu: _bool(json, 'linkedToPiu'),
      status: _string(json, 'status', fallback: 'à valider'),
    );
  }
}

class PreventiaActionItem {
  const PreventiaActionItem({
    required this.id,
    required this.sourceDocumentId,
    required this.sourceDocumentType,
    required this.action,
    required this.priority,
    required this.responsible,
    required this.deadline,
    required this.status,
    required this.evidenceExpected,
    required this.destination,
    required this.createdAt,
    required this.updatedAt,
    this.redirectedFrom = '',
    this.redirectReason = '',
  });

  final String id;
  final String sourceDocumentId;
  final String sourceDocumentType;
  final String action;
  final String priority;
  final String responsible;
  final String deadline;
  final String status;
  final String evidenceExpected;
  final String destination;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String redirectedFrom;
  final String redirectReason;

  PreventiaActionItem copyWith({String? status, DateTime? updatedAt}) {
    return PreventiaActionItem(
      id: id,
      sourceDocumentId: sourceDocumentId,
      sourceDocumentType: sourceDocumentType,
      action: action,
      priority: priority,
      responsible: responsible,
      deadline: deadline,
      status: status ?? this.status,
      evidenceExpected: evidenceExpected,
      destination: destination,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      redirectedFrom: redirectedFrom,
      redirectReason: redirectReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceDocumentId': sourceDocumentId,
    'sourceDocumentType': sourceDocumentType,
    'action': action,
    'title': action,
    'priority': priority,
    'responsible': responsible,
    'deadline': deadline,
    'status': status,
    'evidenceExpected': evidenceExpected,
    'evidence': evidenceExpected,
    'destination': destination,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'redirectedFrom': redirectedFrom,
    'redirectReason': redirectReason,
  };

  factory PreventiaActionItem.fromJson(Map<String, dynamic> json) {
    return PreventiaActionItem(
      id: _string(json, 'id'),
      sourceDocumentId: _string(json, 'sourceDocumentId'),
      sourceDocumentType: _string(json, 'sourceDocumentType'),
      action: _string(json, 'action'),
      priority: _string(json, 'priority'),
      responsible: _string(json, 'responsible'),
      deadline: _string(json, 'deadline'),
      status: _string(json, 'status', fallback: 'à valider'),
      evidenceExpected: _string(json, 'evidenceExpected'),
      destination: _string(json, 'destination'),
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
      redirectedFrom: _string(json, 'redirectedFrom'),
      redirectReason: _string(json, 'redirectReason'),
    );
  }
}

class PreventiaDiuItem {
  const PreventiaDiuItem({
    required this.id,
    required this.sourceDocumentId,
    required this.riskOrConstraint,
    required this.location,
    required this.instructionForFutureWork,
    required this.planOrPhoto,
    required this.status,
  });

  final String id;
  final String sourceDocumentId;
  final String riskOrConstraint;
  final String location;
  final String instructionForFutureWork;
  final String planOrPhoto;
  final String status;

  PreventiaDiuItem copyWith({String? status}) => PreventiaDiuItem(
    id: id,
    sourceDocumentId: sourceDocumentId,
    riskOrConstraint: riskOrConstraint,
    location: location,
    instructionForFutureWork: instructionForFutureWork,
    planOrPhoto: planOrPhoto,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceDocumentId': sourceDocumentId,
    'riskOrConstraint': riskOrConstraint,
    'location': location,
    'instructionForFutureWork': instructionForFutureWork,
    'planOrPhoto': planOrPhoto,
    'status': status,
  };

  factory PreventiaDiuItem.fromJson(Map<String, dynamic> json) {
    return PreventiaDiuItem(
      id: _string(json, 'id'),
      sourceDocumentId: _string(json, 'sourceDocumentId'),
      riskOrConstraint: _string(json, 'riskOrConstraint'),
      location: _string(json, 'location'),
      instructionForFutureWork: _string(json, 'instructionForFutureWork'),
      planOrPhoto: _string(json, 'planOrPhoto'),
      status: _string(json, 'status', fallback: 'à valider'),
    );
  }
}

class PreventiaPiuItem {
  const PreventiaPiuItem({
    required this.id,
    required this.sourceDocumentId,
    required this.emergencyTopic,
    required this.information,
    required this.location,
    required this.actionRequired,
    required this.status,
    this.destination = '',
  });

  final String id;
  final String sourceDocumentId;
  final String emergencyTopic;
  final String information;
  final String location;
  final String actionRequired;
  final String status;
  final String destination;

  PreventiaPiuItem copyWith({String? status}) => PreventiaPiuItem(
    id: id,
    sourceDocumentId: sourceDocumentId,
    emergencyTopic: emergencyTopic,
    information: information,
    location: location,
    actionRequired: actionRequired,
    status: status ?? this.status,
    destination: destination,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceDocumentId': sourceDocumentId,
    'emergencyTopic': emergencyTopic,
    'title': emergencyTopic,
    'information': information,
    'description': information,
    'location': location,
    'actionRequired': actionRequired,
    'chapterSuggestion': _chapterSuggestion(emergencyTopic),
    'status': status,
    'destination': destination,
  };

  factory PreventiaPiuItem.fromJson(Map<String, dynamic> json) {
    return PreventiaPiuItem(
      id: _string(json, 'id'),
      sourceDocumentId: _string(json, 'sourceDocumentId'),
      emergencyTopic: _string(json, 'emergencyTopic'),
      information: _string(json, 'information'),
      location: _string(json, 'location'),
      actionRequired: _string(json, 'actionRequired'),
      status: _string(json, 'status', fallback: 'à valider'),
      destination: _string(json, 'destination'),
    );
  }
}

String _chapterSuggestion(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('incend') || normalized.contains('évac')) {
    return 'Incendie et évacuation';
  }
  if (normalized.contains('coupure') || normalized.contains('tgbt')) {
    return 'Coupures et installations techniques';
  }
  if (normalized.contains('ascenseur') || normalized.contains('bloqu')) {
    return 'Ascenseurs et personnes bloquées';
  }
  return 'Informations issues des analyses de risques';
}

class PreventiaEvidenceItem {
  const PreventiaEvidenceItem({
    required this.id,
    required this.sourceDocumentId,
    required this.label,
    required this.location,
    required this.type,
    required this.status,
    this.destination = '',
    this.redirectedFrom = '',
    this.redirectReason = '',
  });

  final String id;
  final String sourceDocumentId;
  final String label;
  final String location;
  final String type;
  final String status;
  final String destination;
  final String redirectedFrom;
  final String redirectReason;

  PreventiaEvidenceItem copyWith({String? status}) => PreventiaEvidenceItem(
    id: id,
    sourceDocumentId: sourceDocumentId,
    label: label,
    location: location,
    type: type,
    status: status ?? this.status,
    destination: destination,
    redirectedFrom: redirectedFrom,
    redirectReason: redirectReason,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceDocumentId': sourceDocumentId,
    'label': label,
    'location': location,
    'type': type,
    'status': status,
    'destination': destination,
    'redirectedFrom': redirectedFrom,
    'redirectReason': redirectReason,
  };

  factory PreventiaEvidenceItem.fromJson(Map<String, dynamic> json) {
    return PreventiaEvidenceItem(
      id: _string(json, 'id'),
      sourceDocumentId: _string(json, 'sourceDocumentId'),
      label: _string(json, 'label'),
      location: _string(json, 'location'),
      type: _string(json, 'type'),
      status: _string(json, 'status', fallback: 'à valider'),
      destination: _string(json, 'destination'),
      redirectedFrom: _string(json, 'redirectedFrom'),
      redirectReason: _string(json, 'redirectReason'),
    );
  }
}

String _string(Map<String, dynamic> json, String key, {String fallback = ''}) {
  final value = json[key];
  return value is String ? value : fallback;
}

bool _bool(Map<String, dynamic> json, String key) => json[key] == true;

DateTime _date(Map<String, dynamic> json, String key) {
  return DateTime.tryParse(_string(json, key)) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

List<T> _items<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final value = json[key];
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}
