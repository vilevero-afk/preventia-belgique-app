enum DocumentFamily {
  riskAssessment('AR'),
  annualActionPlan('PAA'),
  globalPreventionPlan('PGP'),
  safetyVisitReport('RVS'),
  jobDescriptionSheet('FP'),
  safetyInstructionSheet('FIS'),
  accidentIncidentReport('RAI'),
  unknown('DOC');

  const DocumentFamily(this.referencePrefix);

  final String referencePrefix;
}

DocumentFamily resolveDocumentFamily(String documentType) {
  final normalized = _normalizeDocumentType(documentType);

  for (final entry in _documentFamilyAliases.entries) {
    if (entry.value.any((alias) => normalized.contains(alias))) {
      return entry.key;
    }
  }

  return DocumentFamily.unknown;
}

const _documentFamilyAliases = <DocumentFamily, List<String>>{
  DocumentFamily.annualActionPlan: [
    'plan annuel action',
    'plan annuel d action',
    'jaaractieplan',
    'annual action plan',
    'jahrlicher aktionsplan',
    'jaehrlicher aktionsplan',
  ],
  DocumentFamily.globalPreventionPlan: [
    'plan global prevention',
    'plan global de prevention',
    'plan global de prevention sur 5 ans',
    'globaal preventieplan',
    'globaal preventieplan over 5 jaar',
    'global prevention plan',
    'five year global prevention plan',
    'globaler praventionsplan',
    'globaler praeventionsplan',
    'globaler praventionsplan uber 5 jahre',
    'globaler praeventionsplan ueber 5 jahre',
  ],
  DocumentFamily.safetyVisitReport: [
    'rapport de visite securite',
    'veiligheidsbezoekverslag',
    'safety visit report',
    'sicherheitsbegehungsbericht',
  ],
  DocumentFamily.jobDescriptionSheet: [
    'fiche de poste',
    'functiefiche',
    'job description sheet',
    'job sheet',
    'stellenbeschreibung',
  ],
  DocumentFamily.safetyInstructionSheet: [
    'fiche instruction securite',
    'fiche d instruction securite',
    'veiligheidsinstructieblad',
    'safety instruction sheet',
    'sicherheitsanweisungsblatt',
  ],
  DocumentFamily.accidentIncidentReport: [
    'rapport accident ou incident',
    'rapport d accident ou d incident',
    'ongevallen of incidentenrapport',
    'accident or incident report',
    'unfall oder vorfallbericht',
  ],
  DocumentFamily.riskAssessment: [
    'analyse de risques',
    'analyse de risque',
    'risicoanalyse',
    'risk assessment',
    'risk analysis',
    'gefahrdungsbeurteilung',
    'gefaehrdungsbeurteilung',
    'risikoanalyse',
  ],
};

String _normalizeDocumentType(String value) {
  const replacements = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'ae',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ï': 'i',
    'î': 'i',
    'ö': 'oe',
    'ù': 'u',
    'û': 'u',
    'ü': 'ue',
    'ÿ': 'y',
    'œ': 'oe',
    'ß': 'ss',
    '’': ' ',
    "'": ' ',
  };

  var normalized = value.toLowerCase();
  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
