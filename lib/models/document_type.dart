class DocumentType {
  const DocumentType({
    required this.id,
    required this.label,
    required this.icon,
    this.isRiskAnalysis = false,
    this.supportsActionSummary = false,
  });

  final String id;
  final String label;
  final String icon;
  final bool isRiskAnalysis;
  final bool supportsActionSummary;
}

const documentTypes = <DocumentType>[
  DocumentType(
    id: 'general_risk_analysis',
    label: 'Analyse de risques générale',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'job_risk_analysis',
    label: 'Analyse de risques par poste de travail',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'machine_risk_analysis',
    label: 'Analyse de risques machines et équipements',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'chemical_risk_analysis',
    label: 'Analyse de risques produits chimiques',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'fire_risk_analysis',
    label: 'Analyse de risques incendie et évacuation',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'ergonomics_risk_analysis',
    label: 'Analyse de risques ergonomie',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'manual_handling_risk_analysis',
    label: 'Analyse de risques manutention manuelle',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'height_work_risk_analysis',
    label: 'Analyse de risques travail en hauteur',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'lone_work_risk_analysis',
    label: 'Analyse de risques travail isolé',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'psychosocial_risk_analysis',
    label: 'Analyse de risques psychosociaux',
    icon: 'risk',
    isRiskAnalysis: true,
    supportsActionSummary: true,
  ),
  DocumentType(
    id: 'annual_action_plan',
    label: 'Plan annuel d’action',
    icon: 'plan',
  ),
  DocumentType(
    id: 'five_year_prevention_plan',
    label: 'Plan global de prévention sur 5 ans',
    icon: 'strategy',
  ),
  DocumentType(
    id: 'safety_visit_report',
    label: 'Rapport de visite sécurité',
    icon: 'visit',
    supportsActionSummary: true,
  ),
  DocumentType(id: 'job_sheet', label: 'Fiche de poste', icon: 'job'),
  DocumentType(
    id: 'safety_instruction_sheet',
    label: 'Fiche d’instruction sécurité',
    icon: 'instruction',
  ),
  DocumentType(
    id: 'accident_incident_report',
    label: 'Rapport d’accident ou d’incident',
    icon: 'incident',
    supportsActionSummary: true,
  ),
];

DocumentType documentTypeByLabel(String label) {
  return documentTypes.firstWhere(
    (type) => type.label == label,
    orElse: () => documentTypes.first,
  );
}
