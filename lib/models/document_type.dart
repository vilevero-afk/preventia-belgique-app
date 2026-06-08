class DocumentType {
  const DocumentType(this.label);

  final String label;
}

const documentTypes = <DocumentType>[
  DocumentType('Analyse de risques générale'),
  DocumentType('Analyse de risques par poste de travail'),
  DocumentType('Analyse de risques machines et équipements'),
  DocumentType('Analyse de risques produits chimiques'),
  DocumentType('Analyse de risques incendie et évacuation'),
  DocumentType('Analyse de risques ergonomie'),
  DocumentType('Analyse de risques manutention manuelle'),
  DocumentType('Analyse de risques travail en hauteur'),
  DocumentType('Analyse de risques travail isolé'),
  DocumentType('Analyse de risques psychosociaux'),
  DocumentType('Plan annuel d’action'),
  DocumentType('Plan global de prévention sur 5 ans'),
  DocumentType('Rapport de visite sécurité'),
  DocumentType('Fiche de poste'),
  DocumentType('Fiche d’instruction sécurité'),
  DocumentType('Rapport d’accident ou d’incident'),
];
