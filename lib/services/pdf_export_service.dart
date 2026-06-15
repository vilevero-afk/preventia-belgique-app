import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/document_family.dart';
import 'risk_advisor_block_service.dart';
import 'document_generator.dart';

class PdfDocumentTexts {
  const PdfDocumentTexts({
    required this.projectStatus,
    required this.preventionDocumentStatus,
    required this.projectStatusUpper,
    required this.documentType,
    required this.generatedAt,
    required this.source,
    required this.localPdfSource,
  });

  static const french = PdfDocumentTexts(
    projectStatus: 'Projet à valider',
    preventionDocumentStatus: 'Document - Projet à valider',
    projectStatusUpper: 'PROJET À VALIDER',
    documentType: 'Document',
    generatedAt: 'Date de génération',
    source: 'Source',
    localPdfSource: 'IA backend Render - PDF généré localement sur l’appareil',
  );

  final String projectStatus;
  final String preventionDocumentStatus;
  final String projectStatusUpper;
  final String documentType;
  final String generatedAt;
  final String source;
  final String localPdfSource;
}

class PdfLocalizedContent {
  const PdfLocalizedContent({
    required this.rawMarkdown,
    required this.documentTitle,
    required this.languageCode,
    required this.documentFamily,
  });

  final String rawMarkdown;
  final String documentTitle;
  final String languageCode;
  final DocumentFamily documentFamily;
}

class PdfExportService {
  PdfExportService._();

  static const int _mainRiskFirstPartColumnCount = 16;

  static const Map<String, String> _missingSectionTextsByLanguage = {
    'fr': 'Information à compléter ou à valider sur le terrain.',
    'nl': 'Informatie aan te vullen of te valideren tijdens het terreinbezoek.',
    'en': 'Information to be completed or validated during the site visit.',
    'de': 'Informationen sind vor Ort zu ergänzen oder zu validieren.',
  };
  static const Map<String, String> _actionPlanMissingTextsByLanguage = {
    'fr': 'Le plan d’action doit être complété ou régénéré.',
    'nl': 'Het actieplan moet worden aangevuld of opnieuw gegenereerd.',
    'en': 'The action plan must be completed or regenerated.',
    'de': 'Der Maßnahmenplan muss ergänzt oder erneut generiert werden.',
  };
  static const Map<String, String> _riskTableMissingTextsByLanguage = {
    'fr':
        'Le tableau d’analyse détaillée doit être complété après observation de terrain ou relance de la génération IA.',
    'nl':
        'De gedetailleerde analysetabel moet worden aangevuld na terreinobservatie of na een nieuwe AI-generatie.',
    'en':
        'The detailed assessment table must be completed after a site observation or by running AI generation again.',
    'de':
        'Die detaillierte Beurteilungstabelle muss nach einer Vor-Ort-Beobachtung oder durch erneute KI-Generierung ergänzt werden.',
  };
  static const _finalNotice =
      'Ce document est un projet à adapter à la situation réelle de l’entreprise et à valider par le conseiller en prévention, l’employeur et, le cas échéant, le service externe, le médecin du travail ou le CPPT. Il ne constitue pas à lui seul une preuve de conformité réglementaire.';

  static const Map<String, String> _finalNoticesByLanguage = {
    'fr':
        'Ce document est un projet à adapter à la situation réelle de l’entreprise et à valider par le conseiller en prévention, l’employeur et, le cas échéant, le service externe, le médecin du travail ou le CPPT. Il ne constitue pas à lui seul une preuve de conformité réglementaire.',
    'nl':
        'Dit document is een ontwerp dat moet worden aangepast aan de werkelijke situatie van de onderneming en gevalideerd door de preventieadviseur, de werkgever en, indien van toepassing, de externe dienst, de arbeidsarts of het CPBW. Het vormt op zichzelf geen bewijs van reglementaire conformiteit.',
    'en':
        'This document is a draft that must be adapted to the actual situation of the organisation and validated by the prevention advisor, the employer and, where applicable, the external service, the occupational physician or the health and safety committee. It does not constitute proof of regulatory compliance on its own.',
    'de':
        'Dieses Dokument ist ein Entwurf, der an die tatsächliche Situation des Unternehmens angepasst und vom Präventionsberater, dem Arbeitgeber sowie gegebenenfalls vom externen Dienst, dem Arbeitsmediziner oder dem Ausschuss für Gefahrenverhütung und Schutz am Arbeitsplatz validiert werden muss. Es stellt für sich allein keinen Nachweis der regulatorischen Konformität dar.',
  };

  static const _brandColor = PdfColor.fromInt(0xff12355b);
  static const _mutedColor = PdfColor.fromInt(0xff5f6b7a);
  static const _borderColor = PdfColor.fromInt(0xffcbd5e1);
  static const _softBackground = PdfColor.fromInt(0xfff8fafc);
  static const double _tableStartMinFreeSpace = 82;
  static const double _sectionTableStartMinFreeSpace = 130;

  static Future<pw.ThemeData>? _pdfTheme;

  static const Map<String, List<String>> _sectionTitlesByLanguage = {
    'fr': [
      'Identification du document',
      'Contexte et objectif',
      'Références réglementaires belges applicables',
      'Glossaire des abréviations utilisées',
      'Périmètre de l’analyse',
      'Sources d’information utilisées ou à obtenir',
      'Hypothèses et limites',
      'Description des postes, tâches et travailleurs exposés',
      'Plan photos',
      'Identification détaillée des dangers',
      'Méthode de cotation',
      'Tableau principal d’analyse des risques',
      'Analyse des risques résiduels',
      'Priorités d’action',
      'Projet de plan d’action',
      'Lien avec le Plan Annuel d’Action et le Plan Global de Prévention',
      'Documents à créer ou à mettre à jour',
      'Acteurs à consulter ou à impliquer',
      'Annexes nécessaires',
      'Limites d’intervention du conseiller en prévention niveau 3',
      'Points bloquants avant validation',
      'Conclusion',
      'Mention de validation',
    ],
    'nl': [
      'Identificatie van het document',
      'Context en doelstelling',
      'Toepasselijke Belgische regelgevende referenties',
      'Glossarium van gebruikte afkortingen',
      'Afbakening van de analyse',
      'Gebruikte of nog te verkrijgen informatiebronnen',
      'Hypothesen en beperkingen',
      'Beschrijving van functies, taken en blootgestelde werknemers',
      'Fotoplan',
      'Gedetailleerde identificatie van de gevaren',
      'Beoordelingsmethode',
      'Hoofdtabel van de risicoanalyse',
      'Analyse van de restrisico’s',
      'Prioritaire acties',
      'Ontwerpactieplan',
      'Verband met het Jaaractieplan en het Globaal Preventieplan',
      'Documenten die moeten worden opgesteld of bijgewerkt',
      'Te raadplegen of te betrekken actoren',
      'Noodzakelijke bijlagen',
      'Grenzen van de tussenkomst van de preventieadviseur niveau 3',
      'Blokkerende punten vóór validatie',
      'Conclusie',
      'Validatievermelding',
    ],
    'en': [
      'Document identification',
      'Context and objective',
      'Applicable Belgian regulatory references',
      'Glossary of abbreviations used',
      'Scope of the assessment',
      'Information sources used or to be obtained',
      'Assumptions and limitations',
      'Description of jobs, tasks and exposed workers',
      'Photo plan',
      'Detailed identification of hazards',
      'Scoring method',
      'Main risk assessment table',
      'Residual risk analysis',
      'Action priorities',
      'Draft action plan',
      'Link with the Annual Action Plan and the Global Prevention Plan',
      'Documents to create or update',
      'Actors to consult or involve',
      'Required annexes',
      'Limits of intervention of the level 3 prevention advisor',
      'Blocking points before validation',
      'Conclusion',
      'Validation statement',
    ],
    'de': [
      'Dokumentidentifikation',
      'Kontext und Zielsetzung',
      'Anwendbare belgische regulatorische Referenzen',
      'Glossar der verwendeten Abkürzungen',
      'Umfang der Beurteilung',
      'Verwendete oder noch zu beschaffende Informationsquellen',
      'Annahmen und Einschränkungen',
      'Beschreibung der Arbeitsplätze, Tätigkeiten und exponierten Beschäftigten',
      'Fotoplan',
      'Detaillierte Identifikation der Gefährdungen',
      'Bewertungsmethode',
      'Haupttabelle der Gefährdungsbeurteilung',
      'Analyse der Restrisiken',
      'Handlungsprioritäten',
      'Entwurf des Maßnahmenplans',
      'Verbindung mit dem Jährlichen Aktionsplan und dem Globalen Präventionsplan',
      'Zu erstellende oder zu aktualisierende Dokumente',
      'Zu konsultierende oder einzubeziehende Akteure',
      'Erforderliche Anhänge',
      'Grenzen der Mitwirkung des Präventionsberaters Niveau 3',
      'Blockierende Punkte vor der Validierung',
      'Schlussfolgerung',
      'Validierungshinweis',
    ],
  };

  static const Map<DocumentFamily, Map<String, List<String>>>
  _preventionSectionTitlesByFamily = {
    DocumentFamily.annualActionPlan: {
      'fr': [
        'Identification du document',
        'Contexte',
        'Sources utilisées',
        'Objectifs de prévention pour l’année',
        'Actions prioritaires',
        'Tableau du plan annuel d’action',
        'Ressources nécessaires',
        'Budget estimatif',
        'Indicateurs de suivi',
        'Modalités de suivi',
        'Points à valider',
        'Conclusion',
        'Mention de validation',
      ],
      'nl': [
        'Identificatie van het document',
        'Context',
        'Gebruikte bronnen',
        'Preventiedoelstellingen voor het jaar',
        'Prioritaire acties',
        'Tabel van het jaaractieplan',
        'Benodigde middelen',
        'Geraamd budget',
        'Opvolgingsindicatoren',
        'Opvolgingsmodaliteiten',
        'Te valideren punten',
        'Conclusie',
        'Validatievermelding',
      ],
      'en': [
        'Document identification',
        'Context',
        'Sources used',
        'Prevention objectives for the year',
        'Priority actions',
        'Annual Action Plan table',
        'Required resources',
        'Estimated budget',
        'Follow-up indicators',
        'Follow-up arrangements',
        'Points to validate',
        'Conclusion',
        'Validation Statement',
      ],
      'de': [
        'Dokumentidentifikation',
        'Kontext',
        'Verwendete Quellen',
        'Präventionsziele für das Jahr',
        'Prioritäre Maßnahmen',
        'Tabelle des jährlichen Aktionsplans',
        'Erforderliche Mittel',
        'Geschätztes Budget',
        'Nachverfolgungsindikatoren',
        'Modalitäten der Nachverfolgung',
        'Zu validierende Punkte',
        'Schlussfolgerung',
        'Validierungshinweis',
      ],
    },
    DocumentFamily.globalPreventionPlan: {
      'fr': [
        'Identification du document',
        'Introduction',
        'Description de l’entreprise, du site ou du service',
        'Méthodologie',
        'Synthèse des risques prioritaires',
        'Objectifs à 5 ans',
        'Axes prioritaires',
        'Mesures structurelles prévues',
        'Planning pluriannuel',
        'Responsabilités',
        'Moyens humains, techniques et financiers',
        'Indicateurs de suivi',
        'Modalités d’évaluation annuelle',
        'Lien avec les plans annuels d’action',
        'Points à valider',
        'Conclusion',
        'Mention de validation',
      ],
      'nl': [
        'Identificatie van het document',
        'Inleiding',
        'Beschrijving van de onderneming, site of dienst',
        'Methodologie',
        'Synthese van de prioritaire risico’s',
        'Doelstellingen over 5 jaar',
        'Prioritaire assen',
        'Geplande structurele maatregelen',
        'Meerjarenplanning',
        'Verantwoordelijkheden',
        'Menselijke, technische en financiële middelen',
        'Opvolgingsindicatoren',
        'Modaliteiten voor jaarlijkse evaluatie',
        'Verband met de jaaractieplannen',
        'Te valideren punten',
        'Conclusie',
        'Validatievermelding',
      ],
      'en': [
        'Document identification',
        'Introduction',
        'Description of the organisation, site or department',
        'Methodology',
        'Summary of priority risks',
        'Five-year objectives',
        'Priority axes',
        'Planned structural measures',
        'Multi-year planning',
        'Responsibilities',
        'Human, technical and financial resources',
        'Follow-up indicators',
        'Annual evaluation arrangements',
        'Link with the Annual Action Plans',
        'Points to validate',
        'Conclusion',
        'Validation Statement',
      ],
      'de': [
        'Dokumentidentifikation',
        'Einleitung',
        'Beschreibung des Unternehmens, Standorts oder Dienstes',
        'Methodik',
        'Zusammenfassung der prioritären Risiken',
        'Ziele über 5 Jahre',
        'Prioritäre Handlungsachsen',
        'Geplante strukturelle Maßnahmen',
        'Mehrjahresplanung',
        'Verantwortlichkeiten',
        'Personelle, technische und finanzielle Mittel',
        'Nachverfolgungsindikatoren',
        'Modalitäten der jährlichen Bewertung',
        'Verbindung mit den jährlichen Aktionsplänen',
        'Zu validierende Punkte',
        'Schlussfolgerung',
        'Validierungshinweis',
      ],
    },
    DocumentFamily.safetyVisitReport: {
      'fr': [
        'Identification de la visite',
        'Date, heure et lieu',
        'Participants',
        'Objet de la visite',
        'Périmètre et zones visitées',
        'Constats positifs',
        'Écarts, anomalies ou non-conformités observés',
        'Risques observés',
        'Mesures immédiates déjà prises',
        'Recommandations',
        'Tableau d’actions',
        'Responsables',
        'Échéances',
        'Preuves attendues',
        'Suivi prévu',
        'Conclusion',
        'Points à valider',
        'Mention de validation',
      ],
      'nl': [
        'Identificatie van het bezoek',
        'Datum, uur en plaats',
        'Deelnemers',
        'Doel van het bezoek',
        'Afbakening en bezochte zones',
        'Positieve vaststellingen',
        'Vastgestelde afwijkingen, anomalieën of non-conformiteiten',
        'Vastgestelde risico’s',
        'Reeds genomen onmiddellijke maatregelen',
        'Aanbevelingen',
        'Actietabel',
        'Verantwoordelijken',
        'Termijnen',
        'Verwachte bewijzen',
        'Geplande opvolging',
        'Conclusie',
        'Te valideren punten',
        'Validatievermelding',
      ],
      'en': [
        'Visit identification',
        'Date, time and place',
        'Participants',
        'Purpose of the visit',
        'Scope and areas visited',
        'Positive findings',
        'Deviations, anomalies or non-conformities observed',
        'Observed risks',
        'Immediate measures already taken',
        'Recommendations',
        'Action table',
        'Responsible persons',
        'Deadlines',
        'Expected evidence',
        'Planned follow-up',
        'Conclusion',
        'Points to validate',
        'Validation Statement',
      ],
      'de': [
        'Identifikation der Begehung',
        'Datum, Uhrzeit und Ort',
        'Teilnehmer',
        'Zweck der Begehung',
        'Umfang und besichtigte Bereiche',
        'Positive Feststellungen',
        'Festgestellte Abweichungen, Anomalien oder Nichtkonformitäten',
        'Festgestellte Risiken',
        'Bereits ergriffene Sofortmaßnahmen',
        'Empfehlungen',
        'Maßnahmentabelle',
        'Verantwortliche Personen',
        'Fristen',
        'Erwartete Nachweise',
        'Geplante Nachverfolgung',
        'Schlussfolgerung',
        'Zu validierende Punkte',
        'Validierungshinweis',
      ],
    },
    DocumentFamily.jobDescriptionSheet: {
      'fr': [
        'Identification du poste',
        'Service concerné',
        'Mission principale',
        'Tâches principales',
        'Environnement de travail',
        'Équipements et outils utilisés',
        'Produits utilisés le cas échéant',
        'Compétences et aptitudes requises',
        'Risques liés au poste',
        'Mesures de prévention',
        'EPI requis',
        'Formations et habilitations',
        'Consignes particulières',
        'Surveillance de santé / points à vérifier',
        'Restrictions ou adaptations éventuelles',
        'Validation et diffusion',
        'Mention de validation',
      ],
      'nl': [
        'Identificatie van de functie',
        'Betrokken dienst',
        'Hoofdopdracht',
        'Belangrijkste taken',
        'Werkomgeving',
        'Gebruikte uitrusting en gereedschappen',
        'Gebruikte producten indien van toepassing',
        'Vereiste vaardigheden en bekwaamheden',
        'Risico’s verbonden aan de functie',
        'Preventiemaatregelen',
        'Vereiste PBM',
        'Opleidingen en bevoegdheden',
        'Bijzondere instructies',
        'Gezondheidstoezicht / te controleren punten',
        'Mogelijke beperkingen of aanpassingen',
        'Validatie en verspreiding',
        'Validatievermelding',
      ],
      'en': [
        'Job identification',
        'Department concerned',
        'Main mission',
        'Main tasks',
        'Work environment',
        'Equipment and tools used',
        'Products used where applicable',
        'Required skills and abilities',
        'Risks related to the job',
        'Prevention measures',
        'Required PPE',
        'Training and authorisations',
        'Specific instructions',
        'Health surveillance / points to check',
        'Possible restrictions or adaptations',
        'Validation and distribution',
        'Validation Statement',
      ],
      'de': [
        'Arbeitsplatzidentifikation',
        'Betroffener Dienst',
        'Hauptaufgabe',
        'Haupttätigkeiten',
        'Arbeitsumgebung',
        'Verwendete Ausrüstung und Werkzeuge',
        'Verwendete Produkte, falls zutreffend',
        'Erforderliche Fähigkeiten und Eignungen',
        'Mit dem Arbeitsplatz verbundene Risiken',
        'Präventionsmaßnahmen',
        'Erforderliche PSA',
        'Schulungen und Befähigungen',
        'Besondere Anweisungen',
        'Gesundheitsüberwachung / zu prüfende Punkte',
        'Mögliche Einschränkungen oder Anpassungen',
        'Validierung und Verteilung',
        'Validierungshinweis',
      ],
    },
    DocumentFamily.safetyInstructionSheet: {
      'fr': [
        'Identification de l’activité, machine ou situation',
        'Objectif de l’instruction',
        'Dangers principaux',
        'EPI requis',
        'Vérifications avant utilisation ou intervention',
        'Consignes pendant l’activité',
        'Consignes après l’activité',
        'Interdictions',
        'Conduite en cas d’anomalie',
        'Conduite à tenir en cas d’accident, incendie ou urgence',
        'Personnes de contact',
        'Diffusion, formation et preuve de communication',
        'Points à valider',
        'Mention de validation',
      ],
      'nl': [
        'Identificatie van de activiteit, machine of situatie',
        'Doel van de instructie',
        'Belangrijkste gevaren',
        'Vereiste PBM',
        'Controles vóór gebruik of interventie',
        'Instructies tijdens de activiteit',
        'Instructies na de activiteit',
        'Verboden handelingen',
        'Wat te doen bij een afwijking',
        'Wat te doen bij ongeval, brand of noodsituatie',
        'Contactpersonen',
        'Verspreiding, opleiding en bewijs van communicatie',
        'Te valideren punten',
        'Validatievermelding',
      ],
      'en': [
        'Identification of the activity, machine or situation',
        'Purpose of the instruction',
        'Main hazards',
        'Required PPE',
        'Checks before use or intervention',
        'Instructions during the activity',
        'Instructions after the activity',
        'Prohibited actions',
        'What to do in case of anomaly',
        'What to do in case of accident, fire or emergency',
        'Contact persons',
        'Distribution, training and proof of communication',
        'Points to validate',
        'Validation Statement',
      ],
      'de': [
        'Identifikation der Tätigkeit, Maschine oder Situation',
        'Ziel der Anweisung',
        'Hauptgefährdungen',
        'Erforderliche PSA',
        'Kontrollen vor der Nutzung oder dem Einsatz',
        'Anweisungen während der Tätigkeit',
        'Anweisungen nach der Tätigkeit',
        'Verbotene Handlungen',
        'Verhalten bei Abweichungen',
        'Verhalten bei Unfall, Brand oder Notfall',
        'Kontaktpersonen',
        'Verteilung, Schulung und Kommunikationsnachweis',
        'Zu validierende Punkte',
        'Validierungshinweis',
      ],
    },
    DocumentFamily.accidentIncidentReport: {
      'fr': [
        'Identification du dossier',
        'Date, heure et lieu',
        'Type d’événement',
        'Personne(s) concernée(s)',
        'Témoins',
        'Description factuelle de l’événement',
        'Conséquences observées',
        'Mesures immédiates',
        'Causes probables',
        'Causes immédiates',
        'Causes profondes ou organisationnelles',
        'Actions correctives',
        'Actions préventives',
        'Responsables',
        'Échéances',
        'Suivi prévu',
        'Documents et preuves',
        'Déclarations et validations à vérifier',
        'Conclusion',
        'Mention de validation',
      ],
      'nl': [
        'Identificatie van het dossier',
        'Datum, uur en plaats',
        'Type gebeurtenis',
        'Betrokken persoon/personen',
        'Getuigen',
        'Feitelijke beschrijving van de gebeurtenis',
        'Vastgestelde gevolgen',
        'Onmiddellijke maatregelen',
        'Waarschijnlijke oorzaken',
        'Onmiddellijke oorzaken',
        'Dieperliggende of organisatorische oorzaken',
        'Corrigerende acties',
        'Preventieve acties',
        'Verantwoordelijken',
        'Termijnen',
        'Geplande opvolging',
        'Documenten en bewijzen',
        'Aangiften en validaties te controleren',
        'Conclusie',
        'Validatievermelding',
      ],
      'en': [
        'Case identification',
        'Date, time and place',
        'Type of event',
        'Person(s) concerned',
        'Witnesses',
        'Factual description of the event',
        'Consequences observed',
        'Immediate measures',
        'Probable causes',
        'Immediate causes',
        'Root or organisational causes',
        'Corrective actions',
        'Preventive actions',
        'Responsible persons',
        'Deadlines',
        'Planned follow-up',
        'Documents and evidence',
        'Declarations and validations to check',
        'Conclusion',
        'Validation Statement',
      ],
      'de': [
        'Identifikation des Vorgangs',
        'Datum, Uhrzeit und Ort',
        'Art des Ereignisses',
        'Betroffene Person(en)',
        'Zeugen',
        'Sachliche Beschreibung des Ereignisses',
        'Festgestellte Folgen',
        'Sofortmaßnahmen',
        'Wahrscheinliche Ursachen',
        'Unmittelbare Ursachen',
        'Grundlegende oder organisatorische Ursachen',
        'Korrekturmaßnahmen',
        'Präventivmaßnahmen',
        'Verantwortliche Personen',
        'Fristen',
        'Geplante Nachverfolgung',
        'Dokumente und Nachweise',
        'Zu prüfende Meldungen und Validierungen',
        'Schlussfolgerung',
        'Validierungshinweis',
      ],
    },
  };

  static const Map<String, List<String>> _annualActionHeadersByLanguage = {
    'fr': [
      'N° d’action',
      'Risque / thème',
      'Mesure prévue',
      'Objectif',
      'Responsable',
      'Service concerné',
      'Échéance',
      'Moyens nécessaires',
      'Budget estimatif',
      'Indicateur de réalisation',
      'Statut',
      'Commentaire',
    ],
    'nl': [
      'Actienr.',
      'Risico / thema',
      'Voorziene maatregel',
      'Doel',
      'Verantwoordelijke',
      'Betrokken dienst',
      'Termijn',
      'Benodigde middelen',
      'Geraamd budget',
      'Realisatie-indicator',
      'Status',
      'Opmerking',
    ],
    'en': [
      'Action No.',
      'Risk / theme',
      'Planned measure',
      'Objective',
      'Responsible person',
      'Department concerned',
      'Deadline',
      'Required resources',
      'Estimated budget',
      'Completion indicator',
      'Status',
      'Comment',
    ],
    'de': [
      'Maßnahmen-Nr.',
      'Risiko / Thema',
      'Geplante Maßnahme',
      'Ziel',
      'Verantwortliche Person',
      'Betroffener Dienst',
      'Frist',
      'Erforderliche Mittel',
      'Geschätztes Budget',
      'Umsetzungsindikator',
      'Status',
      'Kommentar',
    ],
  };

  static const Map<String, List<String>> _riskSummaryHeadersByLanguage = {
    'fr': [
      'Numéro',
      'Activité',
      'Danger',
      'Risque',
      'Personnes exposées',
      'Score initial',
      'Niveau',
      'Priorité',
      'Responsable',
      'Échéance',
      'Score résiduel',
    ],
    'nl': [
      'Nr.',
      'Activiteit',
      'Gevaar',
      'Risico',
      'Blootgestelde personen',
      'Score',
      'Niveau',
      'Prioriteit',
      'Verantwoordelijke',
      'Termijn',
      'Restrisico',
    ],
    'en': [
      'No.',
      'Activity',
      'Hazard',
      'Risk',
      'Exposed persons',
      'Score',
      'Level',
      'Priority',
      'Responsible person',
      'Deadline',
      'Residual risk',
    ],
    'de': [
      'Nr.',
      'Tätigkeit',
      'Gefährdung',
      'Risiko',
      'Exponierte Personen',
      'Punktzahl',
      'Niveau',
      'Priorität',
      'Verantwortliche Person',
      'Frist',
      'Restrisiko',
    ],
  };

  static const Map<String, List<String>> _actionSummaryHeadersByLanguage = {
    'fr': [
      'N°',
      'Risque concerné',
      'Mesure proposée',
      'Responsable',
      'Échéance',
      'Statut',
    ],
    'nl': [
      'Nr.',
      'Betrokken risico',
      'Voorgestelde maatregel',
      'Verantwoordelijke',
      'Termijn',
      'Status',
    ],
    'en': [
      'No.',
      'Related risk',
      'Proposed measure',
      'Responsible person',
      'Deadline',
      'Status',
    ],
    'de': [
      'Nr.',
      'Betroffenes Risiko',
      'Vorgeschlagene Maßnahme',
      'Verantwortliche Person',
      'Frist',
      'Status',
    ],
  };

  static const Map<String, List<List<String>>> _actionDetailFieldsByLanguage = {
    'fr': [
      ['Objectif', 'objectif'],
      ['Moyens nécessaires', 'moyens nécessaires'],
      ['Budget estimatif si possible', 'budget estimatif si possible'],
      ['Indicateur de réalisation', 'indicateur de réalisation'],
      ['Preuve attendue', 'preuve attendue'],
    ],
    'nl': [
      ['Doel', 'objectif'],
      ['Benodigde middelen', 'moyens nécessaires'],
      ['Raming van budget indien mogelijk', 'budget estimatif si possible'],
      ['Indicator', 'indicateur de réalisation'],
      ['Verwacht bewijs', 'preuve attendue'],
    ],
    'en': [
      ['Objective', 'objectif'],
      ['Required resources', 'moyens nécessaires'],
      ['Estimated budget if possible', 'budget estimatif si possible'],
      ['Indicator', 'indicateur de réalisation'],
      ['Expected evidence', 'preuve attendue'],
    ],
    'de': [
      ['Ziel', 'objectif'],
      ['Erforderliche Mittel', 'moyens nécessaires'],
      ['Geschätztes Budget falls möglich', 'budget estimatif si possible'],
      ['Indikator', 'indicateur de réalisation'],
      ['Erwarteter Nachweis', 'preuve attendue'],
    ],
  };

  static Future<Uint8List> buildDocumentPdf({
    required String documentType,
    required String content,
    required DateTime generatedAt,
    PdfDocumentTexts texts = PdfDocumentTexts.french,
    String? referenceNumber,
  }) async {
    final family = resolveDocumentFamily(documentType);
    if (family != DocumentFamily.riskAssessment) {
      return buildGenericPreventionDocumentPdf(
        documentType: documentType,
        content: content,
        generatedAt: generatedAt,
        texts: texts,
        family: family,
        referenceNumber: referenceNumber,
      );
    }

    return _buildRiskAssessmentDocumentPdf(
      documentType: documentType,
      content: content,
      generatedAt: generatedAt,
      texts: texts,
      referenceNumber: referenceNumber,
    );
  }

  static Future<Uint8List> buildGenericPreventionDocumentPdf({
    required String documentType,
    required String content,
    required DateTime generatedAt,
    PdfDocumentTexts texts = PdfDocumentTexts.french,
    DocumentFamily? family,
    String? referenceNumber,
  }) {
    return _buildPreventionDocumentPdf(
      documentType: documentType,
      content: content,
      generatedAt: generatedAt,
      texts: texts,
      family: family ?? resolveDocumentFamily(documentType),
      referenceNumber: referenceNumber,
    );
  }

  static Future<Uint8List> _buildRiskAssessmentDocumentPdf({
    required String documentType,
    required String content,
    required DateTime generatedAt,
    required PdfDocumentTexts texts,
    String? referenceNumber,
  }) async {
    final theme = await _theme();
    final language = detectDocumentLanguage(content);
    final localized = normalizePdfContent(
      rawMarkdown: content,
      documentType: documentType,
      languageCode: language,
      documentFamily: DocumentFamily.riskAssessment,
    );
    final hasBackendHeader = startsWithBackendRiskHeader(content);
    final displayDocumentType = localized.documentTitle;
    final pdfTexts = localizedPdfDocumentTexts(localized.languageCode);
    final footerReference = resolveDocumentReference(
      metadataDocumentReference: referenceNumber,
      content: localized.rawMarkdown,
    );
    final document = pw.Document(
      title: 'PreventIA Belgique - $displayDocumentType',
      author: 'PreventIA Belgique',
      creator: 'PreventIA Belgique',
      subject: 'Projet de document de prévention',
    );
    final parsed = _splitDocumentIntoSections(
      localized.rawMarkdown,
      language: localized.languageCode,
    );
    final sections = parsed.sections;
    final mainRiskSection = sections.firstWhere(
      (section) => _isMainRiskTableSection(section),
      orElse: () => sections.length >= 12 ? sections[11] : sections.first,
    );
    final riskRows = _buildRiskRows(
      _parseMarkdownTable(mainRiskSection.tableRows, language: language),
    );

    final bufferedWidgets = <pw.Widget>[
      if (!hasBackendHeader) ...[
        _buildTitleBlock(
          documentType: displayDocumentType,
          generatedAt: generatedAt,
          texts: pdfTexts,
          language: localized.languageCode,
        ),
        pw.SizedBox(height: 18),
      ],
      if (parsed.introLines.isNotEmpty) ...[
        pw.SizedBox(height: 14),
        ..._buildRiskAdvisorParagraphs(
          parsed.introLines,
          localized.languageCode,
        ),
      ],
    ];
    var bufferedLandscape = false;

    void flushBufferedPage() {
      if (bufferedWidgets.isEmpty) {
        return;
      }
      final isLandscape = bufferedLandscape;
      final pageWidgets = List<pw.Widget>.from(bufferedWidgets);
      bufferedWidgets.clear();
      document.addPage(
        pw.MultiPage(
          pageFormat: isLandscape
              ? PdfPageFormat.a4.landscape
              : PdfPageFormat.a4,
          margin: isLandscape
              ? const pw.EdgeInsets.fromLTRB(14, 24, 14, 26)
              : const pw.EdgeInsets.fromLTRB(44, 48, 44, 46),
          theme: theme,
          header: (context) => _buildHeader(
            context,
            documentType: displayDocumentType,
            generatedAt: generatedAt,
          ),
          footer: (context) => _buildFooter(
            context,
            generatedAt,
            pdfTexts,
            languageCode: localized.languageCode,
            referenceNumber: footerReference,
          ),
          build: (context) => pageWidgets,
        ),
      );
    }

    void addSectionWidgets(bool isLandscape, List<pw.Widget> widgets) {
      if (bufferedWidgets.isNotEmpty && bufferedLandscape != isLandscape) {
        flushBufferedPage();
      }
      bufferedLandscape = isLandscape;
      bufferedWidgets.addAll(widgets);
    }

    for (final section in sections.where(
      (section) => !_isValidationSectionTitle(section.title),
    )) {
      final isLandscape = _sectionNeedsLandscapeInPdf(section);
      addSectionWidgets(
        isLandscape,
        _isMainRiskTableSection(section)
            ? _buildRiskSection(section, riskRows, localized.languageCode)
            : _buildSection(
                section,
                riskRows: riskRows,
                language: localized.languageCode,
                forceWideTables: isLandscape,
              ),
      );
    }
    addSectionWidgets(false, [
      _buildValidationNoticeSection(localized.languageCode),
    ]);
    flushBufferedPage();

    return document.save();
  }

  static Future<Uint8List> _buildPreventionDocumentPdf({
    required String documentType,
    required String content,
    required DateTime generatedAt,
    required PdfDocumentTexts texts,
    required DocumentFamily family,
    String? referenceNumber,
  }) async {
    final theme = await _theme();
    final language = _detectDocumentLanguageFor(documentType, content);
    final resolvedFamily = family == DocumentFamily.unknown
        ? resolveDocumentFamily(documentType)
        : family;
    final localized = normalizePdfContent(
      rawMarkdown: content,
      documentType: documentType,
      languageCode: language,
      documentFamily: resolvedFamily,
    );
    final displayDocumentType = localized.documentTitle;
    final pdfTexts = localizedPdfDocumentTexts(localized.languageCode);
    final footerReference = resolveDocumentReference(
      metadataDocumentReference: referenceNumber,
      content: localized.rawMarkdown,
    );
    final document = pw.Document(
      title: 'PreventIA Belgique - $displayDocumentType',
      author: 'PreventIA Belgique',
      creator: 'PreventIA Belgique',
      subject: 'Projet de document de prévention',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 48, 44, 46),
        theme: theme,
        header: (context) => _buildHeader(
          context,
          documentType: displayDocumentType,
          generatedAt: generatedAt,
        ),
        footer: (context) => _buildFooter(
          context,
          generatedAt,
          pdfTexts,
          languageCode: localized.languageCode,
          referenceNumber: footerReference,
        ),
        build: (context) => [
          _buildTitleBlock(
            documentType: displayDocumentType,
            generatedAt: generatedAt,
            texts: pdfTexts,
            language: localized.languageCode,
          ),
          pw.SizedBox(height: 18),
          ..._buildPreventionDocumentContent(
            content: localized.rawMarkdown,
            family: localized.documentFamily,
            language: localized.languageCode,
          ),
        ],
      ),
    );

    return document.save();
  }

  static List<pw.Widget> _buildPreventionDocumentContent({
    required String content,
    required DocumentFamily family,
    required String language,
  }) {
    if (family == DocumentFamily.unknown || _hasMarkdownStructure(content)) {
      return _buildGenericMarkdownContent(content, language);
    }

    final parsed = _splitPreventionDocumentIntoSections(
      content,
      family: family,
      language: language,
    );
    if (!parsed.hasSectionContent) {
      return _buildGenericMarkdownContent(content, language);
    }

    return [
      if (parsed.introLines.isNotEmpty) ...[
        ..._buildParagraphs(parsed.introLines, language),
        pw.SizedBox(height: 10),
      ],
      ...parsed.sections.expand(
        (section) => _buildPreventionSection(
          section,
          family: family,
          language: language,
        ),
      ),
    ];
  }

  static List<pw.Widget> _buildSection(
    _DocumentSection section, {
    List<_RiskRow> riskRows = const [],
    String language = 'fr',
    bool forceWideTables = false,
  }) {
    final sectionContent = stripDuplicatedValidationHeading(
      sectionTitle: section.title,
      sectionContent: section.bodyLines.join('\n'),
      languageCode: language,
    );
    final widgets = <pw.Widget>[
      if (section.tableRows.isNotEmpty) _buildSectionTableStartGuard(),
      _buildSectionTitle('${section.index}. ${section.title}'),
    ];
    final contentWidgets = <pw.Widget>[];

    if (section.blocks.isEmpty) {
      contentWidgets.addAll(
        _buildRiskAdvisorParagraphs(sectionContent.split('\n'), language),
      );
    } else {
      for (final block in section.blocks) {
        final text = block.text;
        final tableRows = block.tableRows;
        if (text != null) {
          final cleaned = stripDuplicatedValidationHeading(
            sectionTitle: section.title,
            sectionContent: text,
            languageCode: language,
          );
          contentWidgets.addAll(
            _buildRiskAdvisorParagraphs(cleaned.split('\n'), language),
          );
          continue;
        }
        if (tableRows == null || tableRows.isEmpty) {
          continue;
        }
        if (forceWideTables) {
          final table = _buildGenericTable(tableRows, language);
          if (table != null) {
            contentWidgets.add(_buildTableStartGuard());
            contentWidgets.add(table);
          }
        } else if (section.index == 15) {
          contentWidgets.add(_buildTableStartGuard());
          contentWidgets.addAll(_buildActionPlan(tableRows, language));
        } else {
          final table = _buildGenericTable(tableRows, language);
          if (table != null) {
            contentWidgets.add(_buildTableStartGuard());
            contentWidgets.add(table);
          }
        }
      }
    }
    if (section.index == 11 &&
        _shouldGeneratePriorities(section, contentWidgets, language)) {
      contentWidgets
        ..clear()
        ..addAll(_buildGeneratedPriorities(riskRows, language));
    }

    if (contentWidgets.isEmpty) {
      widgets.add(
        _buildParagraph(
          _isValidationSectionTitle(section.title)
              ? _finalNoticeForLanguage(language)
              : _missingSectionTextForLanguage(language),
          language,
        ),
      );
    } else {
      widgets.addAll(contentWidgets);
    }

    widgets.add(pw.SizedBox(height: 14));
    return widgets;
  }

  static bool _sectionNeedsLandscapeInPdf(_DocumentSection section) {
    if (section.index == 9 || _isMainRiskTableSection(section)) {
      return true;
    }
    if (section.tableRows.isEmpty) {
      return false;
    }
    final columnCount = section.tableRows.fold<int>(
      0,
      (max, row) => row.length > max ? row.length : max,
    );
    if (columnCount > 6) {
      return true;
    }
    final normalizedTitle = _normalizeTitle(section.title);
    return {
      _normalizeTitle('Tableau principal d’analyse des risques'),
      _normalizeTitle('Analyse des risques résiduels'),
      _normalizeTitle('Projet de plan d’action'),
      _normalizeTitle('Évaluation de complétude'),
      _normalizeTitle('Plan photos'),
      _normalizeTitle('Main risk assessment table'),
      _normalizeTitle('Residual risk assessment'),
      _normalizeTitle('Draft action plan'),
      _normalizeTitle('Completeness assessment'),
      _normalizeTitle('Photo plan'),
      _normalizeTitle('Hoofdtabel van de risicoanalyse'),
      _normalizeTitle('Analyse van restrisico’s'),
      _normalizeTitle('Ontwerp van actieplan'),
      _normalizeTitle('Volledigheidsbeoordeling'),
      _normalizeTitle('Fotoplan'),
      _normalizeTitle('Haupttabelle der Gefährdungsbeurteilung'),
      _normalizeTitle('Beurteilung der Restrisiken'),
      _normalizeTitle('Entwurf eines Maßnahmenplans'),
      _normalizeTitle('Vollständigkeitsbewertung'),
      _normalizeTitle('Fotoplan'),
    }.contains(normalizedTitle);
  }

  static bool _isMainRiskTableSection(_DocumentSection section) {
    final normalizedTitle = _normalizeTitle(section.title);
    return section.index == 12 ||
        {
          _normalizeTitle('Tableau principal d’analyse des risques'),
          _normalizeTitle('Main risk assessment table'),
          _normalizeTitle('Hoofdtabel van de risicoanalyse'),
          _normalizeTitle('Haupttabelle der Gefährdungsbeurteilung'),
        }.contains(normalizedTitle);
  }

  static List<pw.Widget> _buildPreventionSection(
    _DocumentSection section, {
    required DocumentFamily family,
    required String language,
  }) {
    final sectionContent = stripDuplicatedValidationHeading(
      sectionTitle: section.title,
      sectionContent: section.bodyLines.join('\n'),
      languageCode: language,
    );
    final widgets = <pw.Widget>[
      if (section.tableRows.isNotEmpty) _buildSectionTableStartGuard(),
      _buildSectionTitle('${section.index}. ${section.title}'),
    ];
    final contentWidgets = <pw.Widget>[
      ..._buildParagraphs(sectionContent.split('\n'), language),
    ];

    if (section.tableRows.isNotEmpty) {
      if (family == DocumentFamily.annualActionPlan && section.index == 6) {
        contentWidgets.add(_buildTableStartGuard());
        contentWidgets.addAll(
          _buildAnnualActionPlanTable(section.tableRows, language),
        );
      } else {
        contentWidgets.add(_buildTableStartGuard());
        contentWidgets.addAll(_buildReadableTable(section.tableRows, language));
      }
    }

    if (contentWidgets.isEmpty) {
      widgets.add(
        _buildParagraph(
          _isValidationSectionTitle(section.title)
              ? _finalNoticeForLanguage(language)
              : _missingSectionTextForLanguage(language),
          language,
        ),
      );
    } else {
      widgets.addAll(contentWidgets);
    }

    widgets.add(pw.SizedBox(height: 14));
    return widgets;
  }

  static List<pw.Widget> _buildRiskSection(
    _DocumentSection section,
    List<_RiskRow> riskRows,
    String language,
  ) {
    if (section.blocks.where((block) => block.tableRows != null).length > 1) {
      final widgets = <pw.Widget>[
        _buildSectionTableStartGuard(),
        _buildSectionTitle('${section.index}. ${section.title}'),
      ];
      for (final block in section.blocks) {
        final text = block.text;
        final tableRows = block.tableRows;
        if (text != null) {
          widgets.addAll(
            _buildRiskAdvisorParagraphs(text.split('\n'), language),
          );
          continue;
        }
        if (tableRows == null || tableRows.isEmpty) {
          continue;
        }
        final table = _buildGenericTable(tableRows, language);
        if (table != null) {
          widgets
            ..add(_buildTableStartGuard())
            ..add(table);
        }
      }
      return widgets;
    }

    if (riskRows.isEmpty ||
        _isPlaceholderRiskTable(riskRows) ||
        riskRows.every((risk) => _riskConcern(risk).trim().isEmpty)) {
      final rawTable = _buildGenericTable(section.tableRows, language);
      return [
        _buildSectionTableStartGuard(),
        _buildSectionTitle('${section.index}. ${section.title}'),
        if (rawTable != null) _buildTableStartGuard(),
        if (rawTable != null)
          rawTable
        else
          _buildParagraph(_riskTableMissingTextForLanguage(language)),
      ];
    }

    final mainRiskTable = _buildMainRiskTable(section.tableRows, language);
    return [
      _buildSectionTableStartGuard(),
      _buildSectionTitle('${section.index}. ${section.title}'),
      if (mainRiskTable != null)
        ...mainRiskTable
      else ...[
        _buildTableStartGuard(),
        _buildRiskSummaryTable(riskRows, language),
      ],
    ];
  }

  static List<pw.Widget>? _buildMainRiskTable(
    List<List<String>> rawRows,
    String language,
  ) {
    final rows = _parseMarkdownTable(rawRows, language: language);
    if (rows.length < 2 || _isPlaceholderTable(rows.skip(1).toList())) {
      final rawTable = _buildGenericTable(rawRows, language);
      return rawTable == null ? null : [rawTable];
    }
    final columnCount = rows.first.length;
    if (columnCount <= _mainRiskFirstPartColumnCount) {
      final table = _buildGenericTable(rawRows, language);
      return table == null ? null : [table];
    }

    final splitIndex = _mainRiskFirstPartColumnCount;
    final leftRows = _projectTableColumns(rows, [
      for (var index = 0; index < splitIndex; index++) index,
    ]);
    final rightRows = _projectTableColumns(rows, [
      0,
      for (var index = splitIndex; index < columnCount; index++) index,
    ]);
    final leftTable = _buildGenericTable(leftRows, language, true);
    final rightTable = _buildGenericTable(rightRows, language, true);
    if (leftTable == null || rightTable == null) {
      return null;
    }
    return [
      _buildTableStartGuard(),
      _buildSubsectionLabel(_mainRiskSplitTitle(language, firstPart: true)),
      leftTable,
      pw.SizedBox(height: 8),
      _buildTableStartGuard(),
      _buildSubsectionLabel(_mainRiskSplitTitle(language, firstPart: false)),
      rightTable,
    ];
  }

  static List<List<String>> _projectTableColumns(
    List<List<String>> rows,
    List<int> indexes,
  ) {
    return rows
        .map(
          (row) => indexes
              .map((index) => index < row.length ? row[index] : '')
              .toList(),
        )
        .toList();
  }

  static String _mainRiskSplitTitle(
    String language, {
    required bool firstPart,
  }) {
    if (firstPart) {
      return switch (language) {
        'nl' => 'Hoofdtabel A - Risicobeoordeling',
        'en' => 'Main table A - Risk evaluation',
        'de' => 'Haupttabelle A - Risikobewertung',
        _ => 'Tableau principal A - Évaluation du risque',
      };
    }
    return switch (language) {
      'nl' => 'Hoofdtabel B - Maatregelen en opvolging',
      'en' => 'Main table B - Measures and follow-up',
      'de' => 'Haupttabelle B - Maßnahmen und Nachverfolgung',
      _ => 'Tableau principal B - Mesures, suivi et validation',
    };
  }

  static pw.Widget _buildSubsectionLabel(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _brandColor,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildRiskSummaryTable(
    List<_RiskRow> risks,
    String language,
  ) {
    return pw.TableHelper.fromTextArray(
      headers:
          _riskSummaryHeadersByLanguage[language] ??
          _riskSummaryHeadersByLanguage['fr']!,
      data: risks
          .map(
            (risk) => [
              risk.value('numéro'),
              _displayCell(risk.value('activité ou tâche'), language),
              _displayCell(risk.value('danger'), language),
              _displayCell(
                risk.value('risque ou dommage possible', fallback: 'risque'),
                language,
              ),
              _displayCell(risk.value('personnes exposées'), language),
              _displayCell(risk.value('score initial'), language),
              _displayCell(
                risk.value('niveau de risque initial', fallback: 'niveau'),
                language,
              ),
              _displayCell(risk.value('priorité'), language),
              _displayCell(risk.value('responsable'), language),
              _displayCell(risk.value('échéance'), language),
              _displayCell(
                risk.value('score résiduel estimé', fallback: 'score résiduel'),
                language,
              ),
            ],
          )
          .toList(),
      border: pw.TableBorder.all(color: _borderColor, width: 0.45),
      headerDecoration: const pw.BoxDecoration(color: _brandColor),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 6,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        color: PdfColor.fromInt(0xff1f2937),
        fontSize: 5.7,
        lineSpacing: 1.1,
      ),
      cellAlignment: pw.Alignment.topLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2.6, vertical: 3),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.45),
        1: pw.FlexColumnWidth(1.05),
        2: pw.FlexColumnWidth(0.95),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(0.55),
        6: pw.FlexColumnWidth(0.62),
        7: pw.FlexColumnWidth(0.62),
        8: pw.FlexColumnWidth(0.85),
        9: pw.FlexColumnWidth(0.72),
        10: pw.FlexColumnWidth(0.72),
      },
    );
  }

  static List<pw.Widget> _buildActionPlan(
    List<List<String>> rawRows,
    String language,
  ) {
    final rows = _parseMarkdownTable(rawRows, language: language);
    final actions = _buildActionRows(rows).where((action) => action.isValid);

    if (actions.isEmpty) {
      final rawTable = _buildGenericTable(rawRows, language);
      return [
        if (rawTable != null)
          rawTable
        else
          _buildParagraph(_actionPlanMissingTextForLanguage(language)),
      ];
    }

    final validActions = actions.toList();
    return [
      _buildActionSummaryTable(validActions, language),
      pw.SizedBox(height: 10),
      ...validActions.expand(
        (action) => _buildActionDetailCard(action, language),
      ),
    ];
  }

  static List<pw.Widget> _buildAnnualActionPlanTable(
    List<List<String>> rawRows,
    String language,
  ) {
    final rows = _parseMarkdownTable(rawRows, language: language);
    if (rows.length < 2 || _isPlaceholderTable(rows.skip(1).toList())) {
      final rawTable = _buildGenericTable(rawRows, language);
      return [
        if (rawTable != null)
          rawTable
        else
          _buildParagraph(_actionPlanMissingTextForLanguage(language)),
      ];
    }

    final expectedHeaders =
        _annualActionHeadersByLanguage[language] ??
        _annualActionHeadersByLanguage['fr']!;
    final sourceHeaders = rows.first;
    final headers = List.generate(expectedHeaders.length, (index) {
      if (index < sourceHeaders.length &&
          sourceHeaders[index].trim().isNotEmpty) {
        return _displayCell(sourceHeaders[index], language);
      }
      return expectedHeaders[index];
    });

    return rows
        .skip(1)
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .map((row) {
          return _buildTableRowCard(headers, row, language);
        })
        .toList();
  }

  static List<pw.Widget> _buildReadableTable(
    List<List<String>> rawRows,
    String language,
  ) {
    final rows = _parseMarkdownTable(rawRows, language: language);
    if (rows.length < 2 || _isPlaceholderTable(rows.skip(1).toList())) {
      final table = _buildGenericTable(rawRows, language);
      return [?table];
    }
    if (rows.first.length <= 6) {
      final table = _buildGenericTable(rawRows, language);
      return [?table];
    }
    final headers = rows.first
        .map((cell) => _displayCell(cell, language))
        .toList();
    return rows
        .skip(1)
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .map((row) {
          return _buildTableRowCard(headers, row, language);
        })
        .toList();
  }

  static pw.Widget _buildTableRowCard(
    List<String> headers,
    List<String> row,
    String language,
  ) {
    final title = row.isNotEmpty && row.first.trim().isNotEmpty
        ? _displayCell(row.first, language)
        : switch (language) {
            'nl' => 'Item',
            'en' => 'Item',
            'de' => 'Eintrag',
            _ => 'Élément',
          };
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _softBackground,
        border: pw.Border.all(color: _borderColor, width: 0.6),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _brandColor,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          for (var index = 0; index < headers.length; index++)
            _buildSmallRichLine(
              headers[index],
              index < row.length ? row[index] : '',
              language,
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildActionSummaryTable(
    List<_ActionRow> actions,
    String language,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.TableHelper.fromTextArray(
        headers:
            _actionSummaryHeadersByLanguage[language] ??
            _actionSummaryHeadersByLanguage['fr']!,
        data: actions
            .map(
              (action) => [
                action.value('numéro d’action', fallback: 'n°'),
                _displayCell(action.value('risque concerné'), language),
                _displayCell(action.value('mesure proposée'), language),
                _displayCell(action.value('responsable'), language),
                _displayCell(action.value('échéance'), language),
                _displayCell(action.value('statut'), language),
              ],
            )
            .toList(),
        border: pw.TableBorder.all(color: _borderColor, width: 0.45),
        headerDecoration: const pw.BoxDecoration(color: _brandColor),
        headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: const pw.TextStyle(
          color: PdfColor.fromInt(0xff1f2937),
          fontSize: 6.8,
          lineSpacing: 1.15,
        ),
        cellAlignment: pw.Alignment.topLeft,
        headerAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(3.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(0.42),
          1: pw.FlexColumnWidth(1.05),
          2: pw.FlexColumnWidth(1.35),
          3: pw.FlexColumnWidth(0.85),
          4: pw.FlexColumnWidth(0.75),
          5: pw.FlexColumnWidth(0.7),
        },
      ),
    );
  }

  static List<pw.Widget> _buildActionDetailCard(
    _ActionRow action,
    String language,
  ) {
    final number = action.value('numéro d’action', fallback: 'n°');
    final measure = _displayCell(action.value('mesure proposée'), language);
    final title = switch (language) {
      'nl' => 'Actie $number - $measure',
      'en' => 'Action $number - $measure',
      'de' => 'Maßnahme $number - $measure',
      _ => 'Action $number - $measure',
    };
    final detailFields =
        _actionDetailFieldsByLanguage[language] ??
        _actionDetailFieldsByLanguage['fr']!;
    return [
      pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 7),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: _softBackground,
          border: pw.Border.all(color: _borderColor, width: 0.6),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: _brandColor,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            ...detailFields.map(
              (field) => _buildSmallRichLine(
                field[0],
                action.value(field[1]),
                language,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  static pw.Widget? _buildGenericTable(
    List<List<String>> rawRows, [
    String language = 'fr',
    bool forceCompact = false,
  ]) {
    final rows = _parseMarkdownTable(rawRows, language: language);
    if (rows.length < 2 || _isPlaceholderTable(rows.skip(1).toList())) {
      return null;
    }
    final dataRows = rows
        .skip(1)
        .map((row) => row.map((cell) => _displayCell(cell, language)).toList())
        .toList();
    final columnCount = rows.first.length;
    final isWide = columnCount > 6;
    final isVeryWide = forceCompact || columnCount > 12;
    final isUltraWide = columnCount > 20;
    final headerFontSize = isUltraWide
        ? 6.5
        : (isVeryWide ? 6.8 : (isWide ? 7.1 : 7.4));
    final cellFontSize = isUltraWide
        ? 6.5
        : (isVeryWide ? 6.8 : (isWide ? 7.0 : 7.2));
    final padding = isVeryWide
        ? const pw.EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.8)
        : isWide
        ? const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 2.8)
        : const pw.EdgeInsets.all(4);
    final headers = rows.first
        .map((cell) => _displayTableHeader(cell, language, compact: isVeryWide))
        .toList();
    final columnWidths = _tableColumnWidths(rows.first, compact: isVeryWide);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.TableHelper.fromTextArray(
        headers: headers,
        data: dataRows,
        border: pw.TableBorder.all(color: _borderColor, width: 0.45),
        headerDecoration: const pw.BoxDecoration(color: _brandColor),
        headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontSize: headerFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: pw.TextStyle(
          color: const PdfColor.fromInt(0xff1f2937),
          fontSize: cellFontSize,
          lineSpacing: isWide ? 1.05 : 1.2,
        ),
        cellAlignment: pw.Alignment.topLeft,
        headerAlignment: pw.Alignment.centerLeft,
        cellPadding: padding,
        columnWidths: isWide ? columnWidths : null,
        defaultColumnWidth: const pw.FlexColumnWidth(1),
        tableWidth: pw.TableWidth.max,
      ),
    );
  }

  static String _displayTableHeader(
    String value,
    String language, {
    required bool compact,
  }) {
    final cleaned = _displayCell(value, language);
    if (!compact) {
      return cleaned;
    }
    final normalized = _normalizeTitle(cleaned);
    final short = {
      _normalizeTitle('Numéro'): 'N°',
      _normalizeTitle('Activity or task'): 'Task',
      _normalizeTitle('Activité ou tâche'): 'Tâche',
      _normalizeTitle('Situation dangereuse'): 'Situation',
      _normalizeTitle('Personnes exposées'): 'Exposés',
      _normalizeTitle('Exposed persons'): 'Exposed',
      _normalizeTitle('Mesures existantes'): 'Mesures exist.',
      _normalizeTitle('Existing measures'): 'Existing',
      _normalizeTitle('Preuves existantes'): 'Preuves',
      _normalizeTitle('Existing evidence'): 'Evidence',
      _normalizeTitle('Éléments observés'): 'Observés',
      _normalizeTitle('Éléments à confirmer'): 'À confirmer',
      _normalizeTitle('Score initial'): 'Score init.',
      _normalizeTitle('Niveau initial'): 'Niveau init.',
      _normalizeTitle('Niveau de risque initial'): 'Niveau init.',
      _normalizeTitle('Mesure complémentaire'): 'Mesure',
      _normalizeTitle('Mesures complémentaires proposées'): 'Mesure',
      _normalizeTitle('Niveau STOP'): 'STOP',
      _normalizeTitle('Score résiduel'): 'Score rés.',
      _normalizeTitle('Score résiduel estimé'): 'Score rés.',
      _normalizeTitle('Justification du score résiduel'): 'Justif. rés.',
      _normalizeTitle('Preuve attendue'): 'Preuve',
      _normalizeTitle('Photo à insérer'): 'Photo',
      _normalizeTitle('Annexe à joindre'): 'Annexe',
      _normalizeTitle('Point bloquant'): 'Blocage',
      _normalizeTitle('Avis externe'): 'Avis ext.',
      _normalizeTitle('Responsible person'): 'Owner',
      _normalizeTitle('Deadline'): 'Due',
      _normalizeTitle('Priority'): 'Prio.',
    }[normalized];
    return short ?? cleaned;
  }

  static Map<int, pw.TableColumnWidth> _tableColumnWidths(
    List<String> headers, {
    required bool compact,
  }) {
    return {
      for (var index = 0; index < headers.length; index++)
        index: pw.FlexColumnWidth(_columnWeight(headers[index], compact)),
    };
  }

  static double _columnWeight(String header, bool compact) {
    final normalized = _normalizeTitle(header);
    if (_isNarrowTableColumn(normalized)) {
      return compact ? 0.35 : 0.45;
    }
    if (_isLongTextTableColumn(normalized)) {
      return compact ? 1.35 : 1.55;
    }
    if (_isMediumTextTableColumn(normalized)) {
      return compact ? 0.95 : 1.15;
    }
    return compact ? 0.7 : 1.0;
  }

  static bool _isNarrowTableColumn(String normalizedHeader) {
    return [
      'n',
      'no',
      'nr',
      'g',
      'p',
      'e',
      'score',
      'score initial',
      'niveau',
      'niveau initial',
      'priorite',
      'priority',
      'prioritat',
      'prioriteit',
      'deadline',
      'echeance',
      'frist',
      'termijn',
    ].contains(normalizedHeader);
  }

  static bool _isLongTextTableColumn(String normalizedHeader) {
    return [
      'justification',
      'justification du score residuel',
      'mesure complementaire',
      'mesures complementaires proposees',
      'measure',
      'additional measures',
      'preuve attendue',
      'expected evidence',
      'elements observes',
      'elements a confirmer',
      'situation dangereuse',
      'dangerous situation',
    ].any((value) => normalizedHeader.contains(_normalizeTitle(value)));
  }

  static bool _isMediumTextTableColumn(String normalizedHeader) {
    return [
      'activite',
      'activity',
      'task',
      'danger',
      'hazard',
      'risque',
      'risk',
      'personnes exposees',
      'exposed persons',
      'responsable',
      'responsible',
      'avis externe',
      'external advice',
    ].any((value) => normalizedHeader.contains(_normalizeTitle(value)));
  }

  static Future<pw.ThemeData> _theme() {
    return _pdfTheme ??= _loadPdfTheme();
  }

  static Future<pw.ThemeData> _loadPdfTheme() async {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();
    final boldItalic = await PdfGoogleFonts.notoSansBoldItalic();
    final fallback = await PdfGoogleFonts.notoSerifRegular();
    final emoji = await PdfGoogleFonts.notoColorEmoji();

    return pw.ThemeData.withFont(
      base: base,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
      fontFallback: [fallback, emoji, base],
    );
  }

  static String suggestedFileName(String documentType, DateTime generatedAt) {
    final date =
        '${generatedAt.year}${_twoDigits(generatedAt.month)}${_twoDigits(generatedAt.day)}';
    final type = documentType
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'preventia-belgique-$type-$date.pdf';
  }

  static String _cleanMarkdownText(String text, {String language = 'fr'}) {
    var cleaned = RiskAdvisorBlockService.stripAdvisorTags(
      text.replaceAll('\r', ''),
    );
    if (_isMarkdownSeparatorLine(cleaned.trim())) {
      return '';
    }
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'__([^_]+)__'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned
        .replaceAll(RegExp(r'^\s*#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\|\s*$'), '')
        .replaceAll(r'$1', '');
    return normalizePdfText(cleaned, language: language).trim();
  }

  static String normalizePdfText(String input, {String language = 'fr'}) {
    final translatedFallbacks = _translatePdfFallbacks(input, language);
    final languageCleaned = cleanLanguageSpecificText(
      translatedFallbacks,
      language,
    );
    return normalizeFrenchText(languageCleaned);
  }

  static PdfLocalizedContent normalizePdfContent({
    required String rawMarkdown,
    required String documentType,
    required String languageCode,
    required DocumentFamily documentFamily,
  }) {
    final language = _normalizeLanguageCode(languageCode);
    final family = documentFamily == DocumentFamily.unknown
        ? resolveDocumentFamily(documentType)
        : documentFamily;
    var normalized = _replaceDocumentTitleLines(
      rawMarkdown,
      family: family,
      language: language,
    );
    if (family == DocumentFamily.riskAssessment) {
      normalized = removeDuplicateLeadingReferenceDate(normalized);
    }
    normalized = _stripLeadingDuplicatedDocumentTitle(
      normalized,
      family: family,
      language: language,
    );
    normalized = _translatePdfFallbacks(normalized, language);
    normalized = cleanLanguageSpecificText(normalized, language);
    normalized = normalizeFrenchText(normalized);
    normalized = _removeExistingValidationBlocks(
      normalized,
      language: language,
    );
    normalized = _appendLocalizedValidationSection(
      normalized,
      family: family,
      language: language,
    );

    return PdfLocalizedContent(
      rawMarkdown: normalized,
      documentTitle: localizedDocumentTitle(
        family: family,
        languageCode: language,
        fallbackDocumentType: documentType,
      ),
      languageCode: language,
      documentFamily: family,
    );
  }

  static PdfDocumentTexts localizedPdfDocumentTexts(String languageCode) {
    return switch (_normalizeLanguageCode(languageCode)) {
      'nl' => const PdfDocumentTexts(
        projectStatus: 'Ontwerp te valideren',
        preventionDocumentStatus: 'Document - Ontwerp te valideren',
        projectStatusUpper: 'ONTWERP TE VALIDEREN',
        documentType: 'Document',
        generatedAt: 'Generatiedatum',
        source: 'Bron',
        localPdfSource:
            'IA-backend Render - PDF lokaal gegenereerd op het toestel',
      ),
      'en' => const PdfDocumentTexts(
        projectStatus: 'Draft for validation',
        preventionDocumentStatus: 'Document - Draft for validation',
        projectStatusUpper: 'DRAFT FOR VALIDATION',
        documentType: 'Document',
        generatedAt: 'Generation date',
        source: 'Source',
        localPdfSource:
            'AI backend Render - PDF generated locally on the device',
      ),
      'de' => const PdfDocumentTexts(
        projectStatus: 'Zu validierender Entwurf',
        preventionDocumentStatus: 'Dokument - Zu validierender Entwurf',
        projectStatusUpper: 'ZU VALIDIERENDER ENTWURF',
        documentType: 'Dokument',
        generatedAt: 'Generierungsdatum',
        source: 'Quelle',
        localPdfSource: 'KI-Backend Render - PDF lokal auf dem Gerät generiert',
      ),
      _ => PdfDocumentTexts.french,
    };
  }

  static String localizedDocumentTitle({
    required DocumentFamily family,
    required String languageCode,
    String? fallbackDocumentType,
  }) {
    final language = _normalizeLanguageCode(languageCode);
    final title = _documentTitlesByFamily[family]?[language];
    if (title != null) {
      return title;
    }
    return fallbackDocumentType ?? 'Document';
  }

  static String localizedValidationHeading(String languageCode) {
    return _validationTitleForLanguage(_normalizeLanguageCode(languageCode));
  }

  static String localizedValidationText(String languageCode) {
    return _finalNoticeForLanguage(_normalizeLanguageCode(languageCode));
  }

  static String localizedFallback(String languageCode) {
    return _missingSectionTextForLanguage(_normalizeLanguageCode(languageCode));
  }

  static String cleanLanguageSpecificText(String input, String languageCode) {
    final language = languageCode.toLowerCase();
    var fixed = input
        .replaceAll('\u2018', '’')
        .replaceAll('\u2019', '’')
        .replaceAll('\u201B', '’')
        .replaceAll('\u2032', '’')
        .replaceAll('\u00B4', '’')
        .replaceAll('´', '’');

    if (language == 'en') {
      fixed = fixed
          .replaceAll('Municipal’Administration', 'Municipal Administration')
          .replaceAll('Prohibited’Actions', 'Prohibited Actions')
          .replaceAll('municipal’interventions', 'municipal interventions')
          .replaceAll('specialised’interventions', 'specialised interventions')
          .replaceAll('road’interventions', 'road interventions')
          .replaceAll('and’interventions', 'and interventions')
          .replaceAll('planned’actions', 'planned actions')
          .replaceAll('closed’actions', 'closed actions')
          .replaceAll('completed’actions', 'completed actions')
          .replaceAll('structured’actions', 'structured actions')
          .replaceAll('listed’action', 'listed action')
          .replaceAll('implemented’actions', 'implemented actions')
          .replaceAll('completed’action', 'completed action')
          .replaceAll("completed'action", 'completed action')
          .replaceAll('implemented’action', 'implemented action')
          .replaceAll("implemented'action", 'implemented action')
          .replaceAll('proposed’actions', 'proposed actions')
          .replaceAll('EPI auditifs', 'hearing protection')
          .replaceAll('EPI auditif', 'hearing protection')
          .replaceAll('FDS', 'SDS')
          .replaceAll('Plan Global de Prévention', 'Global Prevention Plan')
          .replaceAll('Plan Annuel d’Action', 'Annual Action Plan');

      fixed = fixed.replaceAllMapped(
        RegExp(
          r"\b(and|road|municipal|specialised|planned|closed|completed|structured|listed|proposed|implemented)[’'](?=[A-Za-z])",
          caseSensitive: false,
        ),
        (match) => '${match.group(1)} ',
      );
      return fixed;
    }

    if (language == 'nl') {
      return fixed
          .replaceAll('Mention de validation', 'Validatievermelding')
          .replaceAll(_finalNotice, _finalNoticesByLanguage['nl']!)
          .replaceAll(
            'registreer der ongevallen/incidentele gebeurtenissen',
            'ongevallen- en incidentenregister',
          )
          .replaceAll('EPI auditifs', 'gehoorbescherming')
          .replaceAll('EPI auditif', 'gehoorbescherming');
    }

    if (language == 'de') {
      return fixed
          .replaceAll('Mention de validation', 'Validierungshinweis')
          .replaceAll(_finalNotice, _finalNoticesByLanguage['de']!)
          .replaceAll('Plan Global de Prévention', 'Globaler Präventionsplan')
          .replaceAll('plan global de prévention', 'Globaler Präventionsplan')
          .replaceAll('Plan Annuel d’Action', 'Jährlicher Aktionsplan')
          .replaceAll('Plan annuel d’action', 'Jährlicher Aktionsplan')
          .replaceAll('Annual Action Plan', 'Jährlicher Aktionsplan')
          .replaceAll('Global Prevention Plan', 'Globaler Präventionsplan')
          .replaceAll(
            'Verkehr Fahrzeuge/Pedestrian',
            'Fahrzeug- und Fußgängerverkehr',
          )
          .replaceAll(
            'Vehicle/Pedestrian traffic',
            'Fahrzeug- und Fußgängerverkehr',
          )
          .replaceAll(
            'vehicle/pedestrian traffic',
            'Fahrzeug- und Fußgängerverkehr',
          )
          .replaceAll('Pedestrian', 'Fußgänger')
          .replaceAll('pedestrian', 'Fußgänger')
          .replaceAll('Photos', 'Fotos')
          .replaceAll('photos', 'Fotos')
          .replaceAll('SDS-Register', 'Sicherheitsdatenblatt-Register')
          .replaceAll('SDS register', 'Sicherheitsdatenblatt-Register')
          .replaceAll('SDS', 'Sicherheitsdatenblatt')
          .replaceAll('Glissaden und Stürze', 'Ausrutschen und Stürze')
          .replaceAll('glissaden und stürze', 'Ausrutschen und Stürze')
          .replaceAll('EPI auditifs', 'Gehörschutz')
          .replaceAll('EPI auditif', 'Gehörschutz');
    }

    return fixed;
  }

  static String normalizeFrenchText(String input) {
    final replacements = <String, String>{
      'l entreprise': 'l’entreprise',
      'l employeur': 'l’employeur',
      'l utilisation': 'l’utilisation',
      'l exécution': 'l’exécution',
      'l Administration': 'l’Administration',
      'l exercice': 'l’exercice',
      'd Action': 'd’Action',
      'd action': 'd’action',
      'd analyse': 'd’analyse',
      'd information': 'd’information',
      'd intervention': 'd’intervention',
      'd intégration': 'd’intégration',
      'd évaluation': 'd’évaluation',
      'd équipe': 'd’équipe',
      'd utilisation': 'd’utilisation',
      'l analyse': 'l’analyse',
      'l information': 'l’information',
      'l intervention': 'l’intervention',
      'c est': 'c’est',
      'Municipal’Administration': 'Municipal Administration',
      'municipal’interventions': 'municipal interventions',
      'specialised’interventions': 'specialised interventions',
      'road’interventions': 'road interventions',
      'and’interventions': 'and interventions',
      'planned’actions': 'planned actions',
      'implemented’actions': 'implemented actions',
      'completed’actions': 'completed actions',
      'structured’actions': 'structured actions',
      'listed’action': 'listed action',
      'proposed’actions': 'proposed actions',
      'Company: Municipal’Administration': 'Company: Municipal Administration',
      'Company : Municipal’Administration': 'Company: Municipal Administration',
      'road’intervention': 'road intervention',
      'possible’intervention': 'possible intervention',
      'chef d équipe': 'chef d’équipe',
      'chefs d équipe': 'chefs d’équipe',
      'Plan Annuel d Action': 'Plan Annuel d’Action',
      'mise en uvre': 'mise en œuvre',
      'man uvre': 'manœuvre',
      'man uvres': 'manœuvres',
      'en uvre': 'en œuvre',
      'Cet analyse': 'Cette analyse',
      'annue de prévention': 'annuel de prévention',
    };

    var fixed = input
        .replaceAll('\u2018', '’')
        .replaceAll('\u2019', '’')
        .replaceAll('\u201B', '’')
        .replaceAll('\u2032', '’')
        .replaceAll('\u00B4', '’')
        .replaceAll('´', '’');

    for (final entry in replacements.entries) {
      fixed = fixed.replaceAll(entry.key, entry.value);
    }
    fixed = fixed.replaceAllMapped(
      RegExp(r'(?<![A-Za-zÀ-ÿŒœ])oeuvre(?![A-Za-zÀ-ÿŒœ])'),
      (_) => 'œuvre',
    );
    return fixed;
  }

  static String _translatePdfFallbacks(String input, String language) {
    final fallback = _missingSectionTextForLanguage(language);
    var translated = input;
    for (final source in _missingSectionTextsByLanguage.values) {
      final sourceWithoutPeriod = source.replaceAll(RegExp(r'\.$'), '');
      translated = translated.replaceAll(
        RegExp('${RegExp.escape(sourceWithoutPeriod)}\\.?'),
        fallback,
      );
    }
    return translated;
  }

  static String _replaceDocumentTitleLines(
    String input, {
    required DocumentFamily family,
    required String language,
  }) {
    if (family == DocumentFamily.unknown) {
      return input;
    }
    final localizedTitle = localizedDocumentTitle(
      family: family,
      languageCode: language,
    );
    return input.replaceAllMapped(
      RegExp(r'^(#{1,3}\s*)?(.+)$', multiLine: true),
      (match) {
        final prefix = match.group(1) ?? '';
        final text = (match.group(2) ?? '').trim();
        final isKnownTitle =
            _documentTitlesByFamily[family]?.values.any(
              (title) => _normalizeTitle(title) == _normalizeTitle(text),
            ) ??
            false;
        if (isKnownTitle) {
          return '$prefix$localizedTitle';
        }
        return match.group(0) ?? '';
      },
    );
  }

  static String _stripLeadingDuplicatedDocumentTitle(
    String input, {
    required DocumentFamily family,
    required String language,
  }) {
    if (family != DocumentFamily.riskAssessment) {
      return input;
    }
    if (startsWithBackendRiskHeader(input)) {
      return input;
    }
    final lines = input.replaceAll('\r\n', '\n').split('\n');
    var index = 0;
    while (index < lines.length && lines[index].trim().isEmpty) {
      index++;
    }
    if (index >= lines.length) {
      return input;
    }
    final firstLine = lines[index].trim();
    if (!_isRedundantRiskAssessmentTitle(firstLine, language)) {
      return input;
    }
    lines.removeAt(index);
    while (index < lines.length && lines[index].trim().isEmpty) {
      lines.removeAt(index);
    }
    return lines.join('\n');
  }

  static bool _isRedundantRiskAssessmentTitle(String line, String language) {
    final cleaned = _cleanMarkdownText(
      line,
      language: language,
    ).replaceAll(RegExp(r':$'), '').trim();
    final normalized = _normalizeTitle(cleaned);
    return _redundantRiskAssessmentTitles.any(
      (title) => normalized == _normalizeTitle(title),
    );
  }

  static const List<String> _redundantRiskAssessmentTitles = [
    'Analyse de risques – Projet à adapter et à valider',
    'Analyse de risques – Projet à valider',
    'Risicoanalyse – Ontwerp aan te passen en te valideren',
    'Risicoanalyse – Ontwerp te valideren',
    'Risk Assessment – Draft to be adapted and validated',
    'Risk Assessment – Draft for validation',
    'Gefährdungsbeurteilung – Entwurf zur Anpassung und Validierung',
    'Gefährdungsbeurteilung – Zu validierender Entwurf',
  ];

  static String removeDuplicateLeadingReferenceDate(String markdown) {
    final lineEnding = markdown.contains('\r\n') ? '\r\n' : '\n';
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');
    var index = 0;
    while (index < lines.length && lines[index].trim().isEmpty) {
      index++;
    }
    if (index >= lines.length) {
      return markdown;
    }

    final startsWithRiskTitle = _isRedundantRiskAssessmentTitle(
      lines[index].trim(),
      'fr',
    );
    var firstBlockStart = startsWithRiskTitle ? index + 1 : index;
    var firstBlock = _readLeadingReferenceDateBlock(lines, firstBlockStart);
    if (firstBlock == null && index + 1 < lines.length) {
      firstBlockStart = index + 1;
      firstBlock = _readLeadingReferenceDateBlock(lines, firstBlockStart);
    }
    if (firstBlock == null) {
      return markdown;
    }
    var secondStart = firstBlock.endExclusive;
    while (secondStart < lines.length && lines[secondStart].trim().isEmpty) {
      secondStart++;
    }
    final secondBlock = _readLeadingReferenceDateBlock(lines, secondStart);
    if (secondBlock == null || !firstBlock.matches(secondBlock)) {
      return markdown;
    }

    lines.removeRange(secondStart, secondBlock.endExclusive);
    while (secondStart < lines.length && lines[secondStart].trim().isEmpty) {
      lines.removeAt(secondStart);
    }
    return lines.join(lineEnding);
  }

  static _LeadingReferenceDateBlock? _readLeadingReferenceDateBlock(
    List<String> lines,
    int start,
  ) {
    var index = start;
    while (index < lines.length && lines[index].trim().isEmpty) {
      index++;
    }
    if (index + 1 >= lines.length) {
      return null;
    }
    final referenceLine = lines[index].trim();
    final dateLine = lines[index + 1].trim();
    final referenceValue = _rawReferenceLineValue(referenceLine);
    final dateValue = _rawDateLineValue(dateLine);
    if (referenceValue == null || dateValue == null) {
      return null;
    }
    return _LeadingReferenceDateBlock(
      normalizedReferenceLine: _normalizeTitle(referenceLine),
      normalizedDateLine: _normalizeTitle(dateLine),
      referenceValue: _normalizeTitle(referenceValue),
      dateValue: _normalizeTitle(dateValue),
      endExclusive: index + 2,
    );
  }

  static String? _rawReferenceLineValue(String line) {
    return RegExp(
      r'^\s*(?:Référence|Reference|Referentie|Referenz)\s*[:：]\s*(.+?)\s*$',
      caseSensitive: false,
    ).firstMatch(line)?.group(1);
  }

  static String? _rawDateLineValue(String line) {
    return RegExp(
      r'^\s*(?:Date|Datum)\s*[:：]\s*(.+?)\s*$',
      caseSensitive: false,
    ).firstMatch(line)?.group(1);
  }

  static bool startsWithBackendRiskHeader(String input) {
    final lines = input
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => _cleanMarkdownText(line).trim())
        .where((line) => line.isNotEmpty)
        .take(5)
        .toList();
    if (lines.length < 3 ||
        !_isRedundantRiskAssessmentTitle(lines.first, 'fr')) {
      return false;
    }
    return _isReferenceLine(lines[1]) && _isDateLine(lines[2]);
  }

  static bool _isReferenceLine(String line) {
    final normalized = _normalizeTitle(line);
    return [
      'reference',
      'referentie',
      'referenz',
    ].any((label) => normalized.startsWith(label));
  }

  static bool _isDateLine(String line) {
    final normalized = _normalizeTitle(line);
    return normalized.startsWith('date') || normalized.startsWith('datum');
  }

  static String _removeExistingValidationBlocks(
    String input, {
    required String language,
  }) {
    final lines = input.replaceAll('\r\n', '\n').split('\n');
    final kept = <String>[];
    var insideValidationSection = false;

    for (final line in lines) {
      final trimmed = line.trim();
      final sectionMatch = RegExp(
        r'^(#{1,6}\s*)?(\d+)[\.)]\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(trimmed);
      final headingText = sectionMatch?.group(3)?.trim() ?? trimmed;
      final startsValidation = _isValidationSectionTitle(headingText);

      if (startsValidation) {
        insideValidationSection = true;
        continue;
      }

      if (sectionMatch != null && insideValidationSection) {
        insideValidationSection = false;
      }

      if (_isValidationNotice(trimmed)) {
        continue;
      }

      if (insideValidationSection) {
        if (trimmed.isEmpty || _isValidationSectionTitle(trimmed)) {
          continue;
        }
        if (_isLanguageSpecificValidationBusinessLine(trimmed, language)) {
          kept.add(line);
        }
        continue;
      }

      kept.add(line);
    }

    return _trimTrailingBlankLines(kept).join('\n').trimRight();
  }

  static bool _isLanguageSpecificValidationBusinessLine(
    String line,
    String language,
  ) {
    final normalized = _normalizeTitle(line);
    if (language == 'nl' &&
        normalized.contains(_normalizeTitle('Dit plan wordt gevalideerd'))) {
      return true;
    }
    if (language == 'fr' &&
        normalized.contains(_normalizeTitle('Ce plan est validé'))) {
      return true;
    }
    if (language == 'en' &&
        normalized.contains(_normalizeTitle('This plan is validated'))) {
      return true;
    }
    if (language == 'de' &&
        normalized.contains(_normalizeTitle('Dieser Plan wird validiert'))) {
      return true;
    }
    return false;
  }

  static String _appendLocalizedValidationSection(
    String input, {
    required DocumentFamily family,
    required String language,
  }) {
    final sectionNumber = _validationSectionNumber(family);
    final heading = localizedValidationHeading(language);
    final text = localizedValidationText(language);
    final base = input.trimRight();
    final prefix = base.isEmpty ? '' : '$base\n\n';
    return '$prefix## $sectionNumber. $heading\n$text';
  }

  static int _validationSectionNumber(DocumentFamily family) {
    return switch (family) {
      DocumentFamily.annualActionPlan => 13,
      DocumentFamily.globalPreventionPlan => 17,
      DocumentFamily.safetyVisitReport => 18,
      DocumentFamily.jobDescriptionSheet => 17,
      DocumentFamily.safetyInstructionSheet => 14,
      DocumentFamily.accidentIncidentReport => 20,
      DocumentFamily.riskAssessment => 18,
      DocumentFamily.unknown => 18,
    };
  }

  static List<String> _trimTrailingBlankLines(List<String> lines) {
    var end = lines.length;
    while (end > 0 && lines[end - 1].trim().isEmpty) {
      end--;
    }
    return lines.sublist(0, end);
  }

  static String stripDuplicatedValidationHeading({
    required String sectionTitle,
    required String sectionContent,
    required String languageCode,
  }) {
    final titles =
        _validationHeadingTitlesByLanguage[languageCode.toLowerCase()] ??
        _validationHeadingTitlesByLanguage['fr']!;
    final normalizedSectionTitle = _normalizeValidationHeading(sectionTitle);
    final lines = sectionContent.replaceAll('\r\n', '\n').split('\n');
    var index = 0;
    while (index < lines.length && lines[index].trim().isEmpty) {
      index++;
    }
    if (index >= lines.length) {
      return '';
    }

    while (index < lines.length) {
      final firstNonEmpty = lines[index].trim();
      if (firstNonEmpty.isEmpty) {
        index++;
        continue;
      }
      final normalizedFirst = _normalizeValidationHeading(firstNonEmpty);
      final firstIsDuplicate =
          normalizedFirst == normalizedSectionTitle ||
          titles.any(
            (title) => normalizedFirst == _normalizeValidationHeading(title),
          );
      if (!firstIsDuplicate) {
        break;
      }
      index++;
      while (index < lines.length && lines[index].trim().isEmpty) {
        index++;
      }
    }

    if (index >= lines.length) {
      return '';
    }

    final remaining = lines.sublist(index).join('\n');
    return remaining.trimLeft();
  }

  static const Map<String, List<String>> _validationHeadingTitlesByLanguage = {
    'fr': [
      'Mention de validation',
      'Mention finale',
      'Mention finale obligatoire',
      'Validation',
    ],
    'nl': ['Validatievermelding', 'Slotvermelding', 'Validatie'],
    'en': [
      'Validation Statement',
      'Final statement',
      'Mandatory final statement',
      'Validation',
    ],
    'de': [
      'Validierungshinweis',
      'Abschlusshinweis',
      'Verbindlicher Abschlusshinweis',
      'Validierung',
    ],
  };

  static String _normalizeValidationHeading(String value) {
    var normalized = value.trim().toLowerCase();
    normalized = normalized.replaceFirst(RegExp(r'^\d+\s*[.)-]?\s*'), '');
    normalized = normalized.replaceAll(RegExp(r'\s*:\s*$'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
  }

  static bool _isMarkdownSeparatorLine(String line) {
    if (!line.startsWith('|') || !line.endsWith('|')) {
      return false;
    }
    return RegExp(r'^\|\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|$').hasMatch(line);
  }

  static String detectDocumentLanguage(String content) {
    final normalized = _normalizeTitle(content);
    if (normalized.contains(_normalizeTitle('Jaaractieplan')) ||
        normalized.contains(_normalizeTitle('Gebruikte bronnen')) ||
        normalized.contains(_normalizeTitle('Tabel van het jaaractieplan'))) {
      return 'nl';
    }
    if (normalized.contains(_normalizeTitle('Annual Action Plan')) ||
        normalized.contains(_normalizeTitle('Sources used')) ||
        normalized.contains(_normalizeTitle('Annual Action Plan table'))) {
      return 'en';
    }
    if (normalized.contains(_normalizeTitle('Jährlicher Aktionsplan')) ||
        normalized.contains(_normalizeTitle('Verwendete Quellen')) ||
        normalized.contains(
          _normalizeTitle('Tabelle des jährlichen Aktionsplans'),
        )) {
      return 'de';
    }
    if (normalized.contains(
          _normalizeTitle('Risk assessment – Draft for validation'),
        ) ||
        normalized.contains(_normalizeTitle('Document identification')) ||
        normalized.contains(_normalizeTitle('Draft action plan'))) {
      return 'en';
    }
    if (normalized.contains(
          _normalizeTitle('Risicoanalyse – Ontwerp te valideren'),
        ) ||
        normalized.contains(
          _normalizeTitle('Identificatie van het document'),
        ) ||
        normalized.contains(_normalizeTitle('Ontwerp van actieplan'))) {
      return 'nl';
    }
    if (normalized.contains(
          _normalizeTitle('Gefährdungsbeurteilung – Entwurf zur Validierung'),
        ) ||
        normalized.contains(_normalizeTitle('Dokumentidentifikation')) ||
        normalized.contains(_normalizeTitle('Entwurf eines Maßnahmenplans'))) {
      return 'de';
    }
    return 'fr';
  }

  static String _detectDocumentLanguageFor(
    String documentType,
    String content,
  ) {
    final fromType = _languageFromDocumentType(documentType);
    if (fromType != null) {
      return fromType;
    }
    return detectDocumentLanguage(content);
  }

  static String? _languageFromDocumentType(String documentType) {
    final normalized = _normalizeTitle(documentType);
    if (normalized.contains(_normalizeTitle('Jaaractieplan')) ||
        normalized.contains(_normalizeTitle('Globaal preventieplan')) ||
        normalized.contains(_normalizeTitle('Veiligheidsbezoekverslag')) ||
        normalized.contains(_normalizeTitle('Functiefiche')) ||
        normalized.contains(_normalizeTitle('Veiligheidsinstructieblad')) ||
        normalized.contains(
          _normalizeTitle('Ongevallen- of incidentenrapport'),
        )) {
      return 'nl';
    }
    if (normalized.contains(_normalizeTitle('Annual Action Plan')) ||
        normalized.contains(_normalizeTitle('Global Prevention Plan')) ||
        normalized.contains(_normalizeTitle('Safety Visit Report')) ||
        normalized.contains(_normalizeTitle('Job Description Sheet')) ||
        normalized.contains(_normalizeTitle('Safety Instruction Sheet')) ||
        normalized.contains(_normalizeTitle('Accident or Incident Report'))) {
      return 'en';
    }
    if (normalized.contains(_normalizeTitle('Jährlicher Aktionsplan')) ||
        normalized.contains(_normalizeTitle('Globaler Präventionsplan')) ||
        normalized.contains(_normalizeTitle('Sicherheitsbegehungsbericht')) ||
        normalized.contains(_normalizeTitle('Stellenbeschreibung')) ||
        normalized.contains(_normalizeTitle('Sicherheitsanweisungsblatt')) ||
        normalized.contains(_normalizeTitle('Unfall- oder Vorfallbericht'))) {
      return 'de';
    }
    return null;
  }

  static _ParsedDocument _splitDocumentIntoSections(
    String content, {
    required String language,
  }) {
    final sectionTitles =
        _sectionTitlesByLanguage[language] ?? _sectionTitlesByLanguage['fr']!;
    final builders = {
      for (var index = 1; index <= sectionTitles.length; index++)
        index: _DocumentSectionBuilder(
          index: index,
          title: sectionTitles[index - 1],
        ),
    };
    final introLines = <String>[];
    var currentIndex = 0;

    for (final rawLine in content.replaceAll('\r\n', '\n').split('\n')) {
      final cleanedLine = _cleanMarkdownText(rawLine).trimRight();
      final trimmed = cleanedLine.trim();

      if (_isValidationNotice(trimmed)) {
        continue;
      }
      if (_isDocumentChromeLine(trimmed)) {
        continue;
      }
      if (trimmed.isEmpty) {
        if (currentIndex == 0) {
          if (introLines.isNotEmpty) {
            introLines.add('');
          }
        } else {
          builders[currentIndex]!.addLine('');
        }
        continue;
      }

      final sectionInfo = _parseSectionTitle(trimmed, language: language);
      if (sectionInfo != null) {
        currentIndex = sectionInfo.index;
        builders[currentIndex]!.setTitle(sectionInfo.title);
        continue;
      }

      if (currentIndex == 0) {
        introLines.add(cleanedLine);
      } else if (!_isValidationSectionTitle(builders[currentIndex]!.title)) {
        builders[currentIndex]!.addLine(cleanedLine);
      }
    }

    return _ParsedDocument(
      introLines: _trimEmptyLines(introLines),
      sections: List.generate(
        sectionTitles.length,
        (index) => builders[index + 1]!.build(),
      ),
    );
  }

  static _ParsedDocument _splitPreventionDocumentIntoSections(
    String content, {
    required DocumentFamily family,
    required String language,
  }) {
    final sectionTitles = _preventionSectionTitles(family, language);
    final builders = {
      for (var index = 1; index <= sectionTitles.length; index++)
        index: _DocumentSectionBuilder(
          index: index,
          title: sectionTitles[index - 1],
        ),
    };
    final introLines = <String>[];
    var currentIndex = 0;
    var matchedSectionCount = 0;

    for (final rawLine in content.replaceAll('\r\n', '\n').split('\n')) {
      final cleanedLine = _cleanMarkdownText(
        rawLine,
        language: language,
      ).trimRight();
      final trimmed = cleanedLine.trim();

      if (_isValidationNotice(trimmed) || _isDocumentChromeLine(trimmed)) {
        continue;
      }
      if (currentIndex == 18 && _isValidationSectionTitle(trimmed)) {
        continue;
      }
      if (trimmed.isEmpty) {
        if (currentIndex == 0) {
          if (introLines.isNotEmpty) {
            introLines.add('');
          }
        } else {
          builders[currentIndex]!.addLine('');
        }
        continue;
      }

      final sectionInfo = _parsePreventionSectionTitle(
        trimmed,
        family: family,
        language: language,
      );
      if (sectionInfo != null) {
        currentIndex = sectionInfo.index;
        builders[currentIndex]!.setTitle(sectionInfo.title);
        matchedSectionCount++;
        continue;
      }

      if (currentIndex == 0) {
        introLines.add(cleanedLine);
      } else {
        builders[currentIndex]!.addLine(cleanedLine);
      }
    }

    final parsed = _ParsedDocument(
      introLines: _trimEmptyLines(introLines),
      sections: List.generate(
        sectionTitles.length,
        (index) => builders[index + 1]!.build(),
      ),
    );
    if (matchedSectionCount == 0) {
      return _ParsedDocument(
        introLines: _trimEmptyLines(content.split('\n')),
        sections: const [],
      );
    }
    return parsed;
  }

  static _SectionInfo? _parsePreventionSectionTitle(
    String line, {
    required DocumentFamily family,
    required String language,
  }) {
    final sectionTitles = _preventionSectionTitles(family, language);
    final numbered = RegExp(
      r'^(\d+)[\.)]\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (numbered != null) {
      final index = int.tryParse(numbered.group(1)!);
      if (index != null && index >= 1 && index <= sectionTitles.length) {
        final rawTitle = _cleanSectionDisplayTitle(numbered.group(2) ?? '');
        final title = _isKnownPreventionTitle(rawTitle, family)
            ? rawTitle
            : sectionTitles[index - 1];
        return _SectionInfo(index: index, title: title);
      }
    }

    final cleanTitle = _cleanSectionDisplayTitle(line);
    final index =
        sectionTitles.indexWhere(
          (title) => _normalizeTitle(title) == _normalizeTitle(cleanTitle),
        ) +
        1;
    if (index > 0) {
      return _SectionInfo(index: index, title: sectionTitles[index - 1]);
    }
    return null;
  }

  static bool _isKnownPreventionTitle(String title, DocumentFamily family) {
    return _preventionSectionTitlesByFamily[family]?.values.any(
          (titles) => titles.any(
            (knownTitle) =>
                _normalizeTitle(knownTitle) == _normalizeTitle(title),
          ),
        ) ??
        false;
  }

  static List<String> _preventionSectionTitles(
    DocumentFamily family,
    String language,
  ) {
    final titlesByLanguage = _preventionSectionTitlesByFamily[family];
    if (titlesByLanguage == null) {
      return const [];
    }
    return titlesByLanguage[language] ?? titlesByLanguage['fr']!;
  }

  static String displayPdfDocumentTitle(String documentType, String language) {
    final family = resolveDocumentFamily(documentType);
    return localizedDocumentTitle(
      family: family,
      languageCode: language,
      fallbackDocumentType: documentType,
    );
  }

  static String _normalizeLanguageCode(String languageCode) {
    final language = languageCode.toLowerCase().split(RegExp(r'[-_]')).first;
    return switch (language) {
      'nl' || 'en' || 'de' => language,
      _ => 'fr',
    };
  }

  static const Map<DocumentFamily, Map<String, String>>
  _documentTitlesByFamily = {
    DocumentFamily.riskAssessment: {
      'fr': 'Analyse de risques – Projet à adapter et à valider',
      'nl': 'Risicoanalyse – Ontwerp aan te passen en te valideren',
      'en': 'Risk Assessment – Draft to be adapted and validated',
      'de': 'Gefährdungsbeurteilung – Entwurf zur Anpassung und Validierung',
    },
    DocumentFamily.annualActionPlan: {
      'fr': 'Plan annuel d’action – Projet à adapter et à valider',
      'nl': 'Jaaractieplan – Ontwerp aan te passen en te valideren',
      'en': 'Annual Action Plan – Draft to be adapted and validated',
      'de': 'Jährlicher Aktionsplan – Entwurf zur Anpassung und Validierung',
    },
    DocumentFamily.globalPreventionPlan: {
      'fr':
          'Plan global de prévention sur 5 ans – Projet à adapter et à valider',
      'nl':
          'Globaal preventieplan over 5 jaar – Ontwerp aan te passen en te valideren',
      'en':
          'Five-Year Global Prevention Plan – Draft to be adapted and validated',
      'de':
          'Globaler Präventionsplan über 5 Jahre – Entwurf zur Anpassung und Validierung',
    },
    DocumentFamily.safetyVisitReport: {
      'fr': 'Rapport de visite sécurité – Projet à adapter et à valider',
      'nl': 'Veiligheidsbezoekverslag – Ontwerp aan te passen en te valideren',
      'en': 'Safety Visit Report – Draft to be adapted and validated',
      'de':
          'Sicherheitsbegehungsbericht – Entwurf zur Anpassung und Validierung',
    },
    DocumentFamily.jobDescriptionSheet: {
      'fr': 'Fiche de poste – Projet à adapter et à valider',
      'nl': 'Functiefiche – Ontwerp aan te passen en te valideren',
      'en': 'Job Description Sheet – Draft to be adapted and validated',
      'de': 'Stellenbeschreibung – Entwurf zur Anpassung und Validierung',
    },
    DocumentFamily.safetyInstructionSheet: {
      'fr': 'Fiche d’instruction sécurité – Projet à adapter et à valider',
      'nl': 'Veiligheidsinstructieblad – Ontwerp aan te passen en te valideren',
      'en': 'Safety Instruction Sheet – Draft to be adapted and validated',
      'de':
          'Sicherheitsanweisungsblatt – Entwurf zur Anpassung und Validierung',
    },
    DocumentFamily.accidentIncidentReport: {
      'fr': 'Rapport d’accident ou d’incident – Projet à adapter et à valider',
      'nl':
          'Ongevallen- of incidentenrapport – Ontwerp aan te passen en te valideren',
      'en': 'Accident or Incident Report – Draft to be adapted and validated',
      'de':
          'Unfall- oder Vorfallbericht – Entwurf zur Anpassung und Validierung',
    },
  };

  static bool _hasMarkdownStructure(String content) {
    return content.replaceAll('\r\n', '\n').split('\n').any((line) {
      final trimmed = line.trim();
      return RegExp(r'^#{1,3}\s+\S').hasMatch(trimmed) ||
          (trimmed.startsWith('|') && trimmed.endsWith('|'));
    });
  }

  static List<pw.Widget> _buildGenericMarkdownContent(
    String content,
    String language,
  ) {
    final widgets = <pw.Widget>[];
    final tableRows = <List<String>>[];
    var hasValidationSection = false;
    var currentIsValidationSection = false;
    var currentValidationTitle = '';
    var currentValidationHasContent = false;

    void flushTable() {
      if (tableRows.isEmpty) {
        return;
      }
      widgets.add(_buildTableStartGuard());
      widgets.addAll(_buildReadableTable(tableRows, language));
      widgets.add(pw.SizedBox(height: 10));
      tableRows.clear();
    }

    for (final rawLine in content.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      if (_isValidationNotice(trimmed) || _isDocumentChromeLine(trimmed)) {
        continue;
      }
      if (currentIsValidationSection && _isValidationSectionTitle(trimmed)) {
        continue;
      }

      final tableCells = _parseRawTableLine(trimmed);
      if (tableCells != null) {
        tableRows.add(tableCells);
        continue;
      }

      flushTable();

      if (trimmed.isEmpty) {
        if (widgets.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 5));
        }
        continue;
      }

      final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(trimmed);
      if (heading != null) {
        if (currentIsValidationSection && !currentValidationHasContent) {
          widgets.add(
            _buildParagraph(_finalNoticeForLanguage(language), language),
          );
        }
        final headingTitle = heading.group(2) ?? '';
        final isValidationSection = _isValidationSectionTitle(headingTitle);
        currentIsValidationSection = isValidationSection;
        currentValidationTitle = headingTitle;
        currentValidationHasContent = false;
        hasValidationSection = hasValidationSection || isValidationSection;
        widgets.add(
          _buildGenericMarkdownHeading(
            headingTitle,
            heading.group(1)!.length,
            language,
          ),
        );
        continue;
      }

      if (currentIsValidationSection) {
        final cleaned = stripDuplicatedValidationHeading(
          sectionTitle: currentValidationTitle,
          sectionContent: line,
          languageCode: language,
        );
        if (cleaned.trim().isEmpty) {
          continue;
        }
        widgets.addAll(_buildParagraphs([cleaned], language));
        currentValidationHasContent = true;
        continue;
      }

      widgets.addAll(_buildParagraphs([line], language));
    }

    if (currentIsValidationSection && !currentValidationHasContent) {
      widgets.add(_buildParagraph(_finalNoticeForLanguage(language), language));
    }

    flushTable();
    if (widgets.isEmpty) {
      return [_buildParagraph(_missingSectionTextForLanguage(language))];
    }
    if (!hasValidationSection) {
      widgets
        ..add(pw.SizedBox(height: 10))
        ..add(
          _buildGenericMarkdownHeading(
            _validationTitleForLanguage(language),
            2,
            language,
          ),
        )
        ..add(_buildParagraph(_finalNoticeForLanguage(language), language));
    }
    return widgets;
  }

  static pw.Widget _buildGenericMarkdownHeading(
    String title,
    int level,
    String language,
  ) {
    if (level == 1 || level == 2) {
      return _buildSectionTitle(_cleanMarkdownText(title, language: language));
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(0, 4, 0, 6),
      child: pw.Text(
        _cleanMarkdownText(title, language: language),
        style: pw.TextStyle(
          color: _brandColor,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static List<String>? _parseRawTableLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('|') || !trimmed.endsWith('|')) {
      return null;
    }
    if (_isMarkdownSeparatorLine(trimmed)) {
      return null;
    }
    return trimmed
        .substring(1, trimmed.length - 1)
        .split('|')
        .map((cell) => cell.trim())
        .toList();
  }

  static bool _isDocumentChromeLine(String text) {
    if (text.isEmpty) {
      return false;
    }
    return RegExp(
          r'^projet\s+de\s+document\b',
          caseSensitive: false,
        ).hasMatch(text) ||
        RegExp(
          r'^projet\s+à\s+valider$',
          caseSensitive: false,
        ).hasMatch(text) ||
        RegExp(
          r'^analyse de risques\s*[–-]\s*projet à valider$',
          caseSensitive: false,
        ).hasMatch(text);
  }

  static bool _isValidationNotice(String text) {
    final normalized = _normalizeTitle(text);
    return normalized == _normalizeTitle(mandatoryValidationNotice) ||
        normalized == _normalizeTitle(_finalNotice) ||
        _finalNoticesByLanguage.values.any(
          (notice) => normalized == _normalizeTitle(notice),
        ) ||
        [
          'Ce document est un projet à adapter à la situation réelle de l’entreprise',
          'Dit document is een ontwerp dat moet worden aangepast aan de werkelijke situatie van de onderneming',
          'Dit document is een ontwerp dat moet worden aangepast aan de werkelijke situatie',
          'This document is a draft that must be adapted to the actual situation of the organisation',
          'This document is a draft to be adapted to the real company situation',
          'Dieses Dokument ist ein Entwurf, der an die tatsächliche Situation des Unternehmens angepasst',
          'Dieses Dokument ist ein Entwurf, der an die tatsächliche Unternehmenssituation anzupassen',
        ].any((start) => normalized.contains(_normalizeTitle(start)));
  }

  static bool _isValidationSectionTitle(String title) {
    final cleaned = title
        .replaceFirst(RegExp(r'^#{1,6}\s*'), '')
        .replaceFirst(RegExp(r'^\d+\s*[.)-]?\s*'), '');
    final normalized = _normalizeTitle(cleaned);
    return [
      'Mention de validation',
      'Mention finale obligatoire',
      'Validatievermelding',
      'Validation Statement',
      'Validation notice',
      'Mandatory final statement',
      'Validierungshinweis',
      'Verbindlicher Abschlusshinweis',
    ].any((knownTitle) => normalized == _normalizeTitle(knownTitle));
  }

  static String _finalNoticeForLanguage(String language) {
    return _finalNoticesByLanguage[language] ?? _finalNoticesByLanguage['fr']!;
  }

  static String _validationTitleForLanguage(String language) {
    return switch (language) {
      'nl' => 'Validatievermelding',
      'en' => 'Validation Statement',
      'de' => 'Validierungshinweis',
      _ => 'Mention de validation',
    };
  }

  static _SectionInfo? _parseSectionTitle(
    String line, {
    required String language,
  }) {
    final sectionTitles =
        _sectionTitlesByLanguage[language] ?? _sectionTitlesByLanguage['fr']!;
    final numbered = RegExp(
      r'^(\d+)[\.)]\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (numbered != null) {
      final index = int.tryParse(numbered.group(1)!);
      if (index != null && index >= 1 && index <= sectionTitles.length) {
        final rawTitle = numbered.group(2) ?? '';
        final title = _cleanSectionDisplayTitle(rawTitle);
        return _SectionInfo(index: index, title: title);
      }
    }

    final title = _canonicalSectionTitle(line);
    var index =
        sectionTitles.indexWhere(
          (knownTitle) => _normalizeTitle(knownTitle) == _normalizeTitle(title),
        ) +
        1;
    if (index == 0) {
      index =
          _sectionTitlesByLanguage['fr']!.indexWhere(
            (knownTitle) =>
                _normalizeTitle(knownTitle) == _normalizeTitle(title),
          ) +
          1;
    }
    if (index > 0) {
      return _SectionInfo(index: index, title: sectionTitles[index - 1]);
    }
    return null;
  }

  static String _cleanSectionDisplayTitle(String title) {
    final cleaned = _cleanMarkdownText(title).replaceAll(RegExp(r':$'), '');
    return cleaned.trim();
  }

  static String _canonicalSectionTitle(String title) {
    final normalized = _normalizeTitle(title);
    final aliases = <String, int>{
      _normalizeTitle('Contexte'): 2,
      _normalizeTitle('Hypothèses utilisées'): 7,
      _normalizeTitle('Tableau d’analyse des risques'): 12,
      _normalizeTitle('Priorités d’action'): 14,
      _normalizeTitle('Documents à créer ou mettre à jour'): 17,
      _normalizeTitle('Documents à créer ou à mettre à jour'): 17,
      _normalizeTitle('Points à valider'): 21,
      _normalizeTitle('Mention de validation'): 23,
      _normalizeTitle('Mention finale obligatoire'): 23,
      _normalizeTitle('Identificatie van het document'): 1,
      _normalizeTitle('Context en doelstelling'): 2,
      _normalizeTitle('Toepasselijke Belgische regelgeving'): 3,
      _normalizeTitle('Afbakening van de analyse'): 5,
      _normalizeTitle('Gebruikte of te verkrijgen informatiebronnen'): 6,
      _normalizeTitle('Hypothesen en beperkingen'): 7,
      _normalizeTitle(
        'Beschrijving van functies, taken en blootgestelde werknemers',
      ): 8,
      _normalizeTitle('Gedetailleerde identificatie van gevaren'): 10,
      _normalizeTitle('Hoofdtabel van de risicoanalyse'): 12,
      _normalizeTitle('Analyse van restrisico’s'): 13,
      _normalizeTitle('Actieprioriteiten'): 14,
      _normalizeTitle('Ontwerp van actieplan'): 15,
      _normalizeTitle(
        'Verband met het Globaal Preventieplan en het Jaaractieplan',
      ): 16,
      _normalizeTitle('Documenten op te stellen of bij te werken'): 17,
      _normalizeTitle('Te raadplegen of te betrekken actoren'): 18,
      _normalizeTitle('Noodzakelijke bijlagen'): 19,
      _normalizeTitle('Conclusie'): 22,
      _normalizeTitle('Validatievermelding'): 23,
      _normalizeTitle('Document identification'): 1,
      _normalizeTitle('Context and objective'): 2,
      _normalizeTitle('Applicable Belgian regulatory references'): 3,
      _normalizeTitle('Scope of the assessment'): 5,
      _normalizeTitle('Information sources used or to be obtained'): 6,
      _normalizeTitle('Assumptions and limitations'): 7,
      _normalizeTitle('Description of jobs, tasks and exposed workers'): 8,
      _normalizeTitle('Detailed identification of hazards'): 10,
      _normalizeTitle('Main risk assessment table'): 12,
      _normalizeTitle('Residual risk assessment'): 13,
      _normalizeTitle('Action priorities'): 14,
      _normalizeTitle('Draft action plan'): 15,
      _normalizeTitle(
        'Link with the Global Prevention Plan and the Annual Action Plan',
      ): 16,
      _normalizeTitle('Documents to create or update'): 17,
      _normalizeTitle('Stakeholders to consult or involve'): 18,
      _normalizeTitle('Required appendices'): 19,
      _normalizeTitle('Mandatory final statement'): 23,
      _normalizeTitle('Dokumentidentifikation'): 1,
      _normalizeTitle('Anwendbare belgische Rechtsvorschriften'): 3,
      _normalizeTitle('Umfang der Beurteilung'): 5,
      _normalizeTitle('Verwendete oder noch einzuholende Informationsquellen'):
          6,
      _normalizeTitle('Annahmen und Grenzen'): 7,
      _normalizeTitle(
        'Beschreibung der Arbeitsplätze, Tätigkeiten und exponierten Beschäftigten',
      ): 8,
      _normalizeTitle('Detaillierte Ermittlung der Gefährdungen'): 10,
      _normalizeTitle('Haupttabelle der Gefährdungsbeurteilung'): 12,
      _normalizeTitle('Beurteilung der Restrisiken'): 13,
      _normalizeTitle('Handlungsprioritäten'): 14,
      _normalizeTitle('Entwurf eines Maßnahmenplans'): 15,
      _normalizeTitle(
        'Verbindung mit dem Globalen Präventionsplan und dem Jährlichen Aktionsplan',
      ): 16,
      _normalizeTitle('Zu erstellende oder zu aktualisierende Dokumente'): 17,
      _normalizeTitle('Zu konsultierende oder einzubeziehende Akteure'): 18,
      _normalizeTitle('Erforderliche Anhänge'): 19,
      _normalizeTitle('Schlussfolgerung'): 22,
      _normalizeTitle('Verbindlicher Abschlusshinweis'): 23,
    };
    final aliasIndex = aliases[normalized];
    if (aliasIndex != null) {
      return _sectionTitlesByLanguage['fr']![aliasIndex - 1];
    }
    return _cleanMarkdownText(title).replaceAll(RegExp(r':$'), '').trim();
  }

  static String _normalizeTitle(String title) {
    return _cleanMarkdownText(title)
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll('œ', 'oe')
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-zàâçéèêëîïôûùüÿñæ0-9]+'), ' ')
        .trim();
  }

  static List<pw.Widget> _buildParagraphs(
    List<String> lines, [
    String language = 'fr',
  ]) {
    final widgets = <pw.Widget>[];
    for (final line in lines) {
      final trimmed = _cleanMarkdownText(line, language: language).trim();
      if (trimmed.isEmpty) {
        if (widgets.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 5));
        }
        continue;
      }

      final bullet = RegExp(r'^[-*]\s+(.+)$').firstMatch(trimmed);
      if (bullet != null) {
        widgets.add(_buildBullet(bullet.group(1)!, language));
      } else {
        widgets.add(_buildParagraph(trimmed, language));
      }
    }
    if (widgets.isEmpty) {
      return const [];
    }
    return widgets;
  }

  static List<pw.Widget> _buildRiskAdvisorParagraphs(
    List<String> lines,
    String language,
  ) {
    final text = lines.join('\n');
    final segments = RiskAdvisorBlockService.parseSegments(
      text,
      languageCode: language,
    );
    final widgets = <pw.Widget>[];
    for (final segment in segments) {
      final block = segment.block;
      if (block != null) {
        widgets.add(_buildRiskAdvisorBlock(block, language));
        continue;
      }
      widgets.addAll(
        _buildParagraphs((segment.text ?? '').split('\n'), language),
      );
    }
    return widgets;
  }

  static pw.Widget _buildRiskAdvisorBlock(
    RiskAdvisorBlock block,
    String language,
  ) {
    final colors = _riskAdvisorColors(block.type);
    final cleanedTitle = _cleanMarkdownText(block.title, language: language);
    final contentLines = block.content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (block.content.length > 900 || contentLines.length > 8) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 4),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              color: colors.background,
              border: pw.Border.all(color: colors.border, width: 0.8),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              '${_riskAdvisorIcon(block.type)} $cleanedTitle',
              style: pw.TextStyle(
                color: colors.text,
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          ..._buildParagraphs(contentLines, language),
          pw.SizedBox(height: 4),
        ],
      );
    }
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: colors.background,
        border: pw.Border.all(color: colors.border, width: 0.9),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${_riskAdvisorIcon(block.type)} ${_cleanMarkdownText(block.title, language: language)}',
            style: pw.TextStyle(
              color: colors.text,
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          ..._buildParagraphs(contentLines, language),
        ],
      ),
    );
  }

  static _RiskAdvisorPdfColors _riskAdvisorColors(RiskAdvisorBlockType type) {
    return switch (type) {
      RiskAdvisorBlockType.usable => const _RiskAdvisorPdfColors(
        PdfColor.fromInt(0xffecfdf5),
        PdfColor.fromInt(0xff16a34a),
        PdfColor.fromInt(0xff166534),
      ),
      RiskAdvisorBlockType.checkOnSite => const _RiskAdvisorPdfColors(
        PdfColor.fromInt(0xffeff6ff),
        PdfColor.fromInt(0xff2563eb),
        PdfColor.fromInt(0xff1d4ed8),
      ),
      RiskAdvisorBlockType.completeBeforeValidation =>
        const _RiskAdvisorPdfColors(
          PdfColor.fromInt(0xfffff7ed),
          PdfColor.fromInt(0xfff97316),
          PdfColor.fromInt(0xffc2410c),
        ),
      RiskAdvisorBlockType.blocking => const _RiskAdvisorPdfColors(
        PdfColor.fromInt(0xfffef2f2),
        PdfColor.fromInt(0xffdc2626),
        PdfColor.fromInt(0xff991b1b),
      ),
      RiskAdvisorBlockType.evidence => const _RiskAdvisorPdfColors(
        PdfColor.fromInt(0xfff9fafb),
        PdfColor.fromInt(0xff6b7280),
        PdfColor.fromInt(0xff374151),
      ),
      RiskAdvisorBlockType.specialistAdvice => const _RiskAdvisorPdfColors(
        PdfColor.fromInt(0xfff5f3ff),
        PdfColor.fromInt(0xff7c3aed),
        PdfColor.fromInt(0xff5b21b6),
      ),
    };
  }

  static String _riskAdvisorIcon(RiskAdvisorBlockType type) {
    return switch (type) {
      RiskAdvisorBlockType.usable => '✓',
      RiskAdvisorBlockType.checkOnSite => 'i',
      RiskAdvisorBlockType.completeBeforeValidation => '!',
      RiskAdvisorBlockType.blocking => '!',
      RiskAdvisorBlockType.evidence => '□',
      RiskAdvisorBlockType.specialistAdvice => '*',
    };
  }

  static pw.Widget _buildParagraph(String text, [String language = 'fr']) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        _cleanMarkdownText(text, language: language),
        style: const pw.TextStyle(
          color: PdfColor.fromInt(0xff1f2937),
          fontSize: 10.2,
          lineSpacing: 2.2,
        ),
      ),
    );
  }

  static pw.Widget _buildBullet(String text, [String language = 'fr']) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 6, right: 8),
            decoration: const pw.BoxDecoration(
              color: _brandColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(child: _buildParagraph(text, language)),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 9),
      padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _borderColor, width: 0.8),
        ),
      ),
      child: pw.Text(
        _cleanMarkdownText(title),
        style: pw.TextStyle(
          color: _brandColor,
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildSectionTableStartGuard() {
    return pw.NewPage(freeSpace: _sectionTableStartMinFreeSpace);
  }

  static pw.Widget _buildTableStartGuard() {
    return pw.NewPage(freeSpace: _tableStartMinFreeSpace);
  }

  static pw.Widget _buildValidationNoticeSection(String language) {
    final titles =
        _sectionTitlesByLanguage[language] ?? _sectionTitlesByLanguage['fr']!;
    final notice =
        _finalNoticesByLanguage[language] ?? _finalNoticesByLanguage['fr']!;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('18. ${titles[17]}'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(13),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xffeef6ff),
            border: pw.Border.all(color: _brandColor, width: 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            notice,
            style: pw.TextStyle(
              color: _brandColor,
              fontSize: 9.5,
              lineSpacing: 2,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static List<List<String>> _parseMarkdownTable(
    List<List<String>> rows, {
    String language = 'fr',
  }) {
    return rows
        .where((row) {
          if (row.isEmpty) {
            return false;
          }
          return !_isMarkdownSeparatorRow(row);
        })
        .map(
          (row) => row
              .map((cell) => _cleanMarkdownText(cell, language: language))
              .toList(),
        )
        .toList();
  }

  static bool _isMarkdownSeparatorRow(List<String> row) {
    return row.every((cell) {
      final trimmed = cell.trim();
      return trimmed.isEmpty ||
          RegExp(r'^:?-{3,}:?$').hasMatch(trimmed) ||
          RegExp(r'^[-:\s]+$').hasMatch(trimmed);
    });
  }

  static List<_RiskRow> _buildRiskRows(List<List<String>> rows) {
    if (rows.length < 2) {
      return const [];
    }

    final header = rows.first.map((value) {
      return _canonicalRiskHeader(_normalizeTitle(value));
    }).toList();
    final language = _riskTableLanguage(rows.first);
    return rows
        .skip(1)
        .map((row) {
          final values = <String, String>{};
          for (
            var index = 0;
            index < header.length && index < row.length;
            index++
          ) {
            values[header[index]] = _cleanMarkdownText(row[index]);
          }
          final score = _readRiskScore(values);
          if (score != null) {
            // Le niveau de risque est recalculé localement pour garantir la cohérence de la méthode G x P x E.
            values[_normalizeTitle('niveau de risque initial')] =
                getRiskLevelFromScore(score, language: language);
            values[_normalizeTitle('niveau')] = getRiskLevelFromScore(
              score,
              language: language,
            );
          }
          return _RiskRow(values);
        })
        .where((risk) => !risk.isEmpty)
        .toList();
  }

  static String getRiskLevelFromScore(int score, {String language = 'fr'}) {
    final levels = switch (language) {
      'nl' => ['Laag', 'Gemiddeld', 'Hoog', 'Kritiek', 'Te controleren'],
      'en' => ['Low', 'Medium', 'High', 'Critical', 'To be checked'],
      'de' => ['Niedrig', 'Mittel', 'Hoch', 'Kritisch', 'Zu prüfen'],
      _ => ['Faible', 'Moyen', 'Élevé', 'Critique', 'À vérifier'],
    };
    if (score >= 1 && score <= 20) {
      return levels[0];
    }
    if (score >= 21 && score <= 50) {
      return levels[1];
    }
    if (score >= 51 && score <= 100) {
      return levels[2];
    }
    if (score >= 101 && score <= 125) {
      return levels[3];
    }
    return levels[4];
  }

  static int? _readRiskScore(Map<String, String> values) {
    final scoreText =
        values[_normalizeTitle('score initial')] ??
        values[_normalizeTitle('score')] ??
        values[_normalizeTitle('punktzahl')];
    if (scoreText == null) {
      return null;
    }
    final match = RegExp(r'\d+').firstMatch(scoreText);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static bool _isPlaceholderRiskTable(List<_RiskRow> risks) {
    if (risks.isEmpty) {
      return true;
    }
    return risks.every((risk) => risk.values.values.every(_isPlaceholderCell));
  }

  static List<_ActionRow> _buildActionRows(List<List<String>> rows) {
    if (rows.length < 2) {
      return const [];
    }

    final header = rows.first.map((value) {
      return _canonicalActionHeader(_normalizeTitle(value));
    }).toList();
    return rows
        .skip(1)
        .map((row) {
          final normalizedRow = _normalizeActionRowWidth(row, header.length);
          final values = <String, String>{};
          for (
            var index = 0;
            index < header.length && index < normalizedRow.length;
            index++
          ) {
            values[header[index]] = _cleanMarkdownText(normalizedRow[index]);
          }
          return _ActionRow(values);
        })
        .where((action) => !action.isEmpty)
        .toList();
  }

  static List<String> _normalizeActionRowWidth(
    List<String> row,
    int headerLength,
  ) {
    if (headerLength < 4 || row.length <= headerLength) {
      return row;
    }
    final trailingCellCount = headerLength - 3;
    final trailingStart = row.length - trailingCellCount;
    return [
      row[0],
      row[1],
      row.sublist(2, trailingStart).join(' | '),
      ...row.sublist(trailingStart),
    ];
  }

  static String _canonicalActionHeader(String normalizedHeader) {
    final aliases = <String, String>{
      _normalizeTitle('N°'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Nr.'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Nr'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('No.'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('No'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Numéro'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Action'): _normalizeTitle('numéro d’action'),
      _normalizeTitle('Risque'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Risque concerné'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Betrokken risico'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Related risk'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Betroffenes Risiko'): _normalizeTitle('risque concerné'),
      _normalizeTitle('Mesure'): _normalizeTitle('mesure proposée'),
      _normalizeTitle('Action proposée'): _normalizeTitle('mesure proposée'),
      _normalizeTitle('Mesure proposée'): _normalizeTitle('mesure proposée'),
      _normalizeTitle('Voorgestelde maatregel'): _normalizeTitle(
        'mesure proposée',
      ),
      _normalizeTitle('Proposed measure'): _normalizeTitle('mesure proposée'),
      _normalizeTitle('Vorgeschlagene Maßnahme'): _normalizeTitle(
        'mesure proposée',
      ),
      _normalizeTitle('Doel'): _normalizeTitle('objectif'),
      _normalizeTitle('Objective'): _normalizeTitle('objectif'),
      _normalizeTitle('Ziel'): _normalizeTitle('objectif'),
      _normalizeTitle('Responsable'): _normalizeTitle('responsable'),
      _normalizeTitle('Verantwoordelijke'): _normalizeTitle('responsable'),
      _normalizeTitle('Responsible person'): _normalizeTitle('responsable'),
      _normalizeTitle('Verantwortliche Person'): _normalizeTitle('responsable'),
      _normalizeTitle('Échéance'): _normalizeTitle('échéance'),
      _normalizeTitle('Termijn'): _normalizeTitle('échéance'),
      _normalizeTitle('Deadline'): _normalizeTitle('échéance'),
      _normalizeTitle('Frist'): _normalizeTitle('échéance'),
      _normalizeTitle('Benodigde middelen'): _normalizeTitle(
        'moyens nécessaires',
      ),
      _normalizeTitle('Required resources'): _normalizeTitle(
        'moyens nécessaires',
      ),
      _normalizeTitle('Erforderliche Mittel'): _normalizeTitle(
        'moyens nécessaires',
      ),
      _normalizeTitle('Indicator'): _normalizeTitle(
        'indicateur de réalisation',
      ),
      _normalizeTitle('Verwacht bewijs'): _normalizeTitle('preuve attendue'),
      _normalizeTitle('Expected evidence'): _normalizeTitle('preuve attendue'),
      _normalizeTitle('Erwarteter Nachweis'): _normalizeTitle(
        'preuve attendue',
      ),
      _normalizeTitle('Statut'): _normalizeTitle('statut'),
      _normalizeTitle('Status'): _normalizeTitle('statut'),
      _normalizeTitle('Link AAP/GPP'): _normalizeTitle(
        'lien avec plan annuel d’action / plan global de prévention',
      ),
      _normalizeTitle('Bezug JAP/GPP'): _normalizeTitle(
        'lien avec plan annuel d’action / plan global de prévention',
      ),
      _normalizeTitle('Link JAP/GPP'): _normalizeTitle(
        'lien avec plan annuel d’action / plan global de prévention',
      ),
    };
    return aliases[normalizedHeader] ?? normalizedHeader;
  }

  static String _canonicalRiskHeader(String normalizedHeader) {
    final aliases = <String, String>{
      _normalizeTitle('N°'): _normalizeTitle('numéro'),
      _normalizeTitle('Nr.'): _normalizeTitle('numéro'),
      _normalizeTitle('Nr'): _normalizeTitle('numéro'),
      _normalizeTitle('No.'): _normalizeTitle('numéro'),
      _normalizeTitle('No'): _normalizeTitle('numéro'),
      _normalizeTitle('Activité ou tâche'): _normalizeTitle(
        'activité ou tâche',
      ),
      _normalizeTitle('Activiteit'): _normalizeTitle('activité ou tâche'),
      _normalizeTitle('Activity or task'): _normalizeTitle('activité ou tâche'),
      _normalizeTitle('Tätigkeit oder Aufgabe'): _normalizeTitle(
        'activité ou tâche',
      ),
      _normalizeTitle('Danger'): _normalizeTitle('danger'),
      _normalizeTitle('Gevaar'): _normalizeTitle('danger'),
      _normalizeTitle('Hazard'): _normalizeTitle('danger'),
      _normalizeTitle('Gefährdung'): _normalizeTitle('danger'),
      _normalizeTitle('Risque'): _normalizeTitle('risque'),
      _normalizeTitle('Risico'): _normalizeTitle('risque'),
      _normalizeTitle('Risk'): _normalizeTitle('risque'),
      _normalizeTitle('Risiko'): _normalizeTitle('risque'),
      _normalizeTitle('Personnes exposées'): _normalizeTitle(
        'personnes exposées',
      ),
      _normalizeTitle('Blootgestelde personen'): _normalizeTitle(
        'personnes exposées',
      ),
      _normalizeTitle('Exposed persons'): _normalizeTitle('personnes exposées'),
      _normalizeTitle('Exponierte Personen'): _normalizeTitle(
        'personnes exposées',
      ),
      _normalizeTitle('Mesures existantes'): _normalizeTitle(
        'mesures existantes',
      ),
      _normalizeTitle('Bestaande maatregelen'): _normalizeTitle(
        'mesures existantes',
      ),
      _normalizeTitle('Existing measures'): _normalizeTitle(
        'mesures existantes',
      ),
      _normalizeTitle('Bestehende Maßnahmen'): _normalizeTitle(
        'mesures existantes',
      ),
      _normalizeTitle('Preuves existantes'): _normalizeTitle(
        'preuve des mesures existantes',
      ),
      _normalizeTitle('Bestaand bewijs'): _normalizeTitle(
        'preuve des mesures existantes',
      ),
      _normalizeTitle('Existing evidence'): _normalizeTitle(
        'preuve des mesures existantes',
      ),
      _normalizeTitle('Vorhandene Nachweise'): _normalizeTitle(
        'preuve des mesures existantes',
      ),
      _normalizeTitle('Justification Gravité'): _normalizeTitle(
        'motivering gravité',
      ),
      _normalizeTitle('Motivering ernst'): _normalizeTitle(
        'motivering gravité',
      ),
      _normalizeTitle('Severity justification'): _normalizeTitle(
        'motivering gravité',
      ),
      _normalizeTitle('Begründung Schwere'): _normalizeTitle(
        'motivering gravité',
      ),
      _normalizeTitle('Justification Probabilité'): _normalizeTitle(
        'motivering probabilité',
      ),
      _normalizeTitle('Motivering waarschijnlijkheid'): _normalizeTitle(
        'motivering probabilité',
      ),
      _normalizeTitle('Probability justification'): _normalizeTitle(
        'motivering probabilité',
      ),
      _normalizeTitle('Begründung Wahrscheinlichkeit'): _normalizeTitle(
        'motivering probabilité',
      ),
      _normalizeTitle('Justification Exposition'): _normalizeTitle(
        'motivering exposition',
      ),
      _normalizeTitle('Motivering blootstelling'): _normalizeTitle(
        'motivering exposition',
      ),
      _normalizeTitle('Exposure justification'): _normalizeTitle(
        'motivering exposition',
      ),
      _normalizeTitle('Begründung Exposition'): _normalizeTitle(
        'motivering exposition',
      ),
      _normalizeTitle('Gravité'): _normalizeTitle('gravité'),
      _normalizeTitle('Ernst'): _normalizeTitle('gravité'),
      _normalizeTitle('Severity'): _normalizeTitle('gravité'),
      _normalizeTitle('Schwere'): _normalizeTitle('gravité'),
      _normalizeTitle('Probabilité'): _normalizeTitle('probabilité'),
      _normalizeTitle('Waarschijnlijkheid'): _normalizeTitle('probabilité'),
      _normalizeTitle('Probability'): _normalizeTitle('probabilité'),
      _normalizeTitle('Wahrscheinlichkeit'): _normalizeTitle('probabilité'),
      _normalizeTitle('Exposition'): _normalizeTitle('exposition'),
      _normalizeTitle('Blootstelling'): _normalizeTitle('exposition'),
      _normalizeTitle('Exposure'): _normalizeTitle('exposition'),
      _normalizeTitle('Score'): _normalizeTitle('score initial'),
      _normalizeTitle('Punktzahl'): _normalizeTitle('score initial'),
      _normalizeTitle('Niveau'): _normalizeTitle('niveau de risque initial'),
      _normalizeTitle('Level'): _normalizeTitle('niveau de risque initial'),
      _normalizeTitle('Mesures complémentaires'): _normalizeTitle(
        'mesures complémentaires proposées',
      ),
      _normalizeTitle('Aanvullende maatregelen'): _normalizeTitle(
        'mesures complémentaires proposées',
      ),
      _normalizeTitle('Additional measures'): _normalizeTitle(
        'mesures complémentaires proposées',
      ),
      _normalizeTitle('Zusätzliche Maßnahmen'): _normalizeTitle(
        'mesures complémentaires proposées',
      ),
      _normalizeTitle('Type de mesure'): _normalizeTitle(
        'type de mesure selon la hiérarchie de prévention',
      ),
      _normalizeTitle('Type maatregel'): _normalizeTitle(
        'type de mesure selon la hiérarchie de prévention',
      ),
      _normalizeTitle('Type of measure'): _normalizeTitle(
        'type de mesure selon la hiérarchie de prévention',
      ),
      _normalizeTitle('Art der Maßnahme'): _normalizeTitle(
        'type de mesure selon la hiérarchie de prévention',
      ),
      _normalizeTitle('Responsable'): _normalizeTitle('responsable'),
      _normalizeTitle('Verantwoordelijke'): _normalizeTitle('responsable'),
      _normalizeTitle('Responsible person'): _normalizeTitle('responsable'),
      _normalizeTitle('Verantwortliche Person'): _normalizeTitle('responsable'),
      _normalizeTitle('Échéance'): _normalizeTitle('échéance'),
      _normalizeTitle('Termijn'): _normalizeTitle('échéance'),
      _normalizeTitle('Deadline'): _normalizeTitle('échéance'),
      _normalizeTitle('Frist'): _normalizeTitle('échéance'),
      _normalizeTitle('Risque résiduel'): _normalizeTitle(
        'score résiduel estimé',
      ),
      _normalizeTitle('Restrisico'): _normalizeTitle('score résiduel estimé'),
      _normalizeTitle('Restrisiko'): _normalizeTitle('score résiduel estimé'),
      _normalizeTitle('Residual risk'): _normalizeTitle(
        'score résiduel estimé',
      ),
      _normalizeTitle('Kontrolle/erwarteter Nachweis'): _normalizeTitle(
        'moyen de contrôle ou preuve attendue',
      ),
      _normalizeTitle('Contrôle/preuve attendue'): _normalizeTitle(
        'moyen de contrôle ou preuve attendue',
      ),
      _normalizeTitle('Controle/bewijs'): _normalizeTitle(
        'moyen de contrôle ou preuve attendue',
      ),
      _normalizeTitle('Expected control/evidence'): _normalizeTitle(
        'moyen de contrôle ou preuve attendue',
      ),
      _normalizeTitle('Prioriteit'): _normalizeTitle('priorité'),
      _normalizeTitle('Priority'): _normalizeTitle('priorité'),
      _normalizeTitle('Priorität'): _normalizeTitle('priorité'),
    };
    return aliases[normalizedHeader] ?? normalizedHeader;
  }

  static String _riskTableLanguage(List<String> headers) {
    final normalized = headers.map(_normalizeTitle).join(' | ');
    if (normalized.contains(_normalizeTitle('Activity or task')) ||
        normalized.contains(_normalizeTitle('Exposed persons'))) {
      return 'en';
    }
    if (normalized.contains(_normalizeTitle('Tätigkeit oder Aufgabe')) ||
        normalized.contains(_normalizeTitle('Punktzahl')) ||
        normalized.contains(_normalizeTitle('Exponierte Personen'))) {
      return 'de';
    }
    if (normalized.contains(_normalizeTitle('Activiteit')) ||
        normalized.contains(_normalizeTitle('Blootgestelde personen'))) {
      return 'nl';
    }
    return 'fr';
  }

  static List<String> _riskHeaderCandidates(String normalizedHeader) {
    final aliases = <String, List<String>>{
      _normalizeTitle('numéro'): ['Nr.', 'Nr', 'N°', 'No.', 'No'],
      _normalizeTitle('activité ou tâche'): [
        'Activiteit',
        'Activity or task',
        'Tätigkeit oder Aufgabe',
      ],
      _normalizeTitle('activité'): ['Activiteit', 'Activity', 'Tätigkeit'],
      _normalizeTitle('danger'): ['Gevaar', 'Hazard', 'Gefährdung'],
      _normalizeTitle('risque ou dommage possible'): [
        'Risico',
        'Risk',
        'Risiko',
      ],
      _normalizeTitle('risque'): ['Risico', 'Risk', 'Risiko'],
      _normalizeTitle('personnes exposées'): [
        'Blootgestelde personen',
        'Exposed persons',
        'Exponierte Personen',
      ],
      _normalizeTitle('mesures existantes'): [
        'Bestaande maatregelen',
        'Existing measures',
        'Bestehende Maßnahmen',
      ],
      _normalizeTitle('preuve des mesures existantes'): [
        'Bestaand bewijs',
        'Existing evidence',
        'Vorhandene Nachweise',
      ],
      _normalizeTitle('motivering gravité'): [
        'Justification Gravité',
        'Motivering ernst',
        'Severity justification',
        'Begründung Schwere',
      ],
      _normalizeTitle('motivering probabilité'): [
        'Justification Probabilité',
        'Motivering waarschijnlijkheid',
        'Probability justification',
        'Begründung Wahrscheinlichkeit',
      ],
      _normalizeTitle('motivering exposition'): [
        'Justification Exposition',
        'Motivering blootstelling',
        'Exposure justification',
        'Begründung Exposition',
      ],
      _normalizeTitle('gravité'): ['Ernst', 'Severity', 'Schwere'],
      _normalizeTitle('probabilité'): [
        'Waarschijnlijkheid',
        'Probability',
        'Wahrscheinlichkeit',
      ],
      _normalizeTitle('exposition'): ['Blootstelling', 'Exposure'],
      _normalizeTitle('score initial'): ['Score'],
      _normalizeTitle('niveau de risque initial'): ['Niveau', 'Level'],
      _normalizeTitle('niveau'): ['Niveau', 'Level'],
      _normalizeTitle('mesures complémentaires proposées'): [
        'Aanvullende maatregelen',
        'Additional measures',
        'Zusätzliche Maßnahmen',
      ],
      _normalizeTitle('type de mesure selon la hiérarchie de prévention'): [
        'Type maatregel',
        'Type of measure',
        'Art der Maßnahme',
      ],
      _normalizeTitle('responsable'): [
        'Verantwoordelijke',
        'Responsible person',
        'Verantwortliche Person',
      ],
      _normalizeTitle('échéance'): ['Termijn', 'Deadline', 'Frist'],
      _normalizeTitle('score résiduel estimé'): [
        'Restrisico',
        'Residual risk',
        'Restrisiko',
      ],
      _normalizeTitle('score résiduel'): [
        'Restrisico',
        'Residual risk',
        'Restrisiko',
      ],
      _normalizeTitle('moyen de contrôle ou preuve attendue'): [
        'Controle/bewijs',
        'Expected control/evidence',
        'Kontrolle/erwarteter Nachweis',
      ],
      _normalizeTitle('priorité'): ['Prioriteit', 'Priority', 'Priorität'],
    };
    return aliases[normalizedHeader]
            ?.map((alias) => _normalizeTitle(alias))
            .toList() ??
        const [];
  }

  static List<String> _actionHeaderCandidates(String normalizedHeader) {
    final aliases = <String, List<String>>{
      _normalizeTitle('numéro d’action'): ['Nr.', 'Nr', 'N°', 'No.', 'No'],
      _normalizeTitle('n°'): ['Nr.', 'Nr', 'No.', 'No'],
      _normalizeTitle('risque concerné'): [
        'Betrokken risico',
        'Related risk',
        'Betroffenes Risiko',
      ],
      _normalizeTitle('mesure proposée'): [
        'Voorgestelde maatregel',
        'Proposed measure',
        'Vorgeschlagene Maßnahme',
      ],
      _normalizeTitle('objectif'): ['Doel', 'Objective', 'Ziel'],
      _normalizeTitle('responsable'): [
        'Verantwoordelijke',
        'Responsible person',
        'Verantwortliche Person',
      ],
      _normalizeTitle('échéance'): ['Termijn', 'Deadline', 'Frist'],
      _normalizeTitle('moyens nécessaires'): [
        'Benodigde middelen',
        'Required resources',
        'Erforderliche Mittel',
      ],
      _normalizeTitle('indicateur de réalisation'): ['Indicator'],
      _normalizeTitle('preuve attendue'): [
        'Verwacht bewijs',
        'Expected evidence',
        'Erwarteter Nachweis',
      ],
      _normalizeTitle('statut'): ['Status'],
    };
    return aliases[normalizedHeader]
            ?.map((alias) => _normalizeTitle(alias))
            .toList() ??
        const [];
  }

  static bool _isPlaceholderTable(List<List<String>> rows) {
    if (rows.isEmpty) {
      return true;
    }
    return rows.every((row) => row.every(_isPlaceholderCell));
  }

  static bool _isPlaceholderCell(String value) {
    final normalized = _normalizeTitle(value);
    return normalized.isEmpty ||
        _missingSectionTextsByLanguage.values.any(
          (text) => normalized == _normalizeTitle(text),
        ) ||
        normalized == _normalizeTitle('À compléter') ||
        normalized == _normalizeTitle('Non renseigné / à vérifier') ||
        normalized == _normalizeTitle('À vérifier');
  }

  static String _displayCell(String value, String language) {
    final cleaned = _cleanMarkdownText(value, language: language).trim();
    if (_isPlaceholderCell(cleaned)) {
      return _missingSectionTextForLanguage(language);
    }
    return cleaned;
  }

  static String _missingSectionTextForLanguage(String language) {
    return _missingSectionTextsByLanguage[language] ??
        _missingSectionTextsByLanguage['fr']!;
  }

  static String _actionPlanMissingTextForLanguage(String language) {
    return _actionPlanMissingTextsByLanguage[language] ??
        _actionPlanMissingTextsByLanguage['fr']!;
  }

  static String _riskTableMissingTextForLanguage(String language) {
    return _riskTableMissingTextsByLanguage[language] ??
        _riskTableMissingTextsByLanguage['fr']!;
  }

  static bool _shouldGeneratePriorities(
    _DocumentSection section,
    List<pw.Widget> contentWidgets,
    String language,
  ) {
    if (section.tableRows.isNotEmpty) {
      return false;
    }
    if (contentWidgets.isEmpty) {
      return true;
    }
    final usefulLines = section.bodyLines
        .map((line) => _cleanMarkdownText(line, language: language).trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return usefulLines.isEmpty ||
        usefulLines.every(
          (line) => _missingSectionTextsByLanguage.values.any(
            (text) => _normalizeTitle(line) == _normalizeTitle(text),
          ),
        );
  }

  static List<pw.Widget> _buildGeneratedPriorities(
    List<_RiskRow> risks,
    String language,
  ) {
    final usefulRisks = risks.where((risk) => !risk.isEmpty).toList();
    if (usefulRisks.isEmpty) {
      return const [];
    }

    usefulRisks.sort((left, right) {
      return _prioritySortRank(
        left.value('priorité'),
      ).compareTo(_prioritySortRank(right.value('priorité')));
    });

    return [
      for (var index = 0; index < usefulRisks.length; index++)
        _buildBullet(
          _generatedPriorityText(index, usefulRisks[index], language),
          language,
        ),
    ];
  }

  static String _generatedPriorityText(
    int index,
    _RiskRow risk,
    String language,
  ) {
    final number = index + 1;
    final concern = _riskConcern(risk);
    return switch (language) {
      'nl' =>
        'Prioriteit $number: $concern - actie te bepalen - verantwoordelijke - termijn - verwacht bewijs.',
      'en' =>
        'Priority $number: $concern - action to define - responsible person - deadline - expected evidence.',
      'de' =>
        'Priorität $number: $concern - Maßnahme festzulegen - verantwortliche Person - Frist - erwarteter Nachweis.',
      _ =>
        'Priorité $number : $concern - action à définir - responsable - échéance - preuve attendue.',
    };
  }

  static int _prioritySortRank(String priority) {
    final normalized = _normalizeTitle(priority);
    if (normalized.contains('haute') ||
        normalized.contains('élevée') ||
        normalized.contains('elevee')) {
      return 0;
    }
    if (normalized.contains('moyenne')) {
      return 1;
    }
    if (normalized.contains('basse') || normalized.contains('faible')) {
      return 2;
    }
    return 3;
  }

  static String _riskConcern(_RiskRow risk) {
    final riskText = risk.value(
      'risque ou dommage possible',
      fallback: 'risque',
    );
    if (riskText.isNotEmpty) {
      return riskText;
    }
    final danger = risk.value('danger');
    if (danger.isNotEmpty) {
      return danger;
    }
    return risk.value('activité ou tâche');
  }

  static pw.Widget _buildSmallRichLine(
    String label,
    String value, [
    String language = 'fr',
  ]) {
    final labelText = language == 'fr' ? '$label : ' : '$label: ';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: labelText,
              style: pw.TextStyle(
                color: _brandColor,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: _displayCell(value, language),
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xff1f2937),
                fontSize: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildHeader(
    pw.Context context, {
    required String documentType,
    required DateTime generatedAt,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xffd6dce3)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'PreventIA Belgique',
            style: pw.TextStyle(
              color: _brandColor,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9.5,
            ),
          ),
          pw.Text(
            '$documentType - ${_formatDate(generatedAt)}',
            style: const pw.TextStyle(color: _mutedColor, fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    pw.Context context,
    DateTime generatedAt,
    PdfDocumentTexts texts, {
    required String languageCode,
    String? referenceNumber,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xffd6dce3)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _formatDate(generatedAt),
            style: const pw.TextStyle(color: _mutedColor, fontSize: 8),
          ),
          pw.Text(
            texts.projectStatus,
            style: pw.TextStyle(
              color: _brandColor,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            documentFooterText(
              languageCode: languageCode,
              referenceNumber: referenceNumber,
              pageNumber: context.pageNumber.toString(),
              pagesCount: context.pagesCount.toString(),
            ),
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xff374151),
              fontSize: 7.5,
            ),
          ),
        ],
      ),
    );
  }

  static String documentFooterText({
    required String languageCode,
    String? referenceNumber,
    String pageNumber = 'X',
    String? pagesCount,
  }) {
    final normalizedReference = _cleanDocumentReference(referenceNumber);
    final referencePart = normalizedReference == null
        ? null
        : '${documentReferenceLabel(languageCode)} $normalizedReference';
    final totalPart = pagesCount == null || pagesCount.trim().isEmpty
        ? ''
        : ' / ${pagesCount.trim()}';
    final pagePart = '${documentPageLabel(languageCode)} $pageNumber$totalPart';
    return referencePart == null ? pagePart : '$referencePart — $pagePart';
  }

  static String documentReferenceLabel(String languageCode) {
    return switch (languageCode) {
      'nl' => 'Referentie',
      'en' => 'Reference',
      'de' => 'Referenz',
      _ => 'Référence',
    };
  }

  static String documentPageLabel(String languageCode) {
    return switch (languageCode) {
      'nl' => 'Pagina',
      'de' => 'Seite',
      _ => 'Page',
    };
  }

  static String? resolveDocumentReference({
    String? metadataDocumentReference,
    String? savedDocumentReference,
    String? content,
  }) {
    return _cleanDocumentReference(metadataDocumentReference) ??
        _cleanDocumentReference(savedDocumentReference) ??
        _extractDocumentReference(content);
  }

  static String? _extractDocumentReference(String? content) {
    if (content == null || content.trim().isEmpty) {
      return null;
    }
    final patterns = [
      RegExp(
        r'(?:Référence\s*/\s*N[°o]\s*analyse|Référence|Reference|Referentie|Referenz)\s*:\s*(AR-\d{4}-\d{4})',
        caseSensitive: false,
        unicode: true,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        return _cleanDocumentReference(match.group(1));
      }
    }
    return null;
  }

  static String? _cleanDocumentReference(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(
      r'\bAR-\d{4}-\d{4}\b',
      caseSensitive: false,
    ).firstMatch(value.trim());
    return match?.group(0)?.toUpperCase();
  }

  static pw.Widget _buildTitleBlock({
    required String documentType,
    required DateTime generatedAt,
    required PdfDocumentTexts texts,
    String language = 'fr',
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PreventIA Belgique',
          style: pw.TextStyle(
            color: _brandColor,
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          texts.preventionDocumentStatus,
          style: const pw.TextStyle(
            color: PdfColor.fromInt(0xff374151),
            fontSize: 13,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xfffff7ed),
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border.all(color: const PdfColor.fromInt(0xfff59e0b)),
          ),
          child: pw.Center(
            child: pw.Text(
              texts.projectStatusUpper,
              style: pw.TextStyle(
                color: const PdfColor.fromInt(0xff92400e),
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _softBackground,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _borderColor),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSmallRichLine(texts.documentType, documentType, language),
              _buildSmallRichLine(
                texts.generatedAt,
                _formatDate(generatedAt),
                language,
              ),
              _buildSmallRichLine(texts.source, texts.localPdfSource, language),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static List<String> _trimEmptyLines(List<String> lines) {
    var start = 0;
    var end = lines.length;
    while (start < end && lines[start].trim().isEmpty) {
      start++;
    }
    while (end > start && lines[end - 1].trim().isEmpty) {
      end--;
    }
    return lines.sublist(start, end);
  }
}

class _DocumentSectionBuilder {
  _DocumentSectionBuilder({required this.index, required this.title});

  final int index;
  String title;
  final List<String> _bodyLines = [];
  final List<List<String>> _tableRows = [];
  final List<_DocumentContentBlock> _blocks = [];

  void setTitle(String value) {
    if (value.trim().isNotEmpty) {
      title = value.trim();
    }
  }

  void addLine(String line) {
    final cells = _parseTableLine(line);
    if (cells != null) {
      _tableRows.add(cells);
      if (_blocks.isNotEmpty && _blocks.last.tableRows != null) {
        _blocks.last.tableRows!.add(List<String>.of(cells));
      } else {
        _blocks.add(_DocumentContentBlock.table([List<String>.of(cells)]));
      }
      return;
    }
    if (index == 12 && _appendActionTableContinuation(line)) {
      return;
    }
    _bodyLines.add(line);
    _blocks.add(_DocumentContentBlock.text(line));
  }

  bool _appendActionTableContinuation(String line) {
    final cleaned = PdfExportService._cleanMarkdownText(line).trim();
    if (cleaned.isEmpty || _tableRows.length < 2) {
      return false;
    }
    final lastRow = _tableRows.last;
    if (lastRow.isEmpty) {
      return false;
    }
    final targetIndex = lastRow.length > 2 ? 2 : lastRow.length - 1;
    lastRow[targetIndex] = '${lastRow[targetIndex]}\n$cleaned'.trim();
    final blockRows = _blocks.isNotEmpty ? _blocks.last.tableRows : null;
    if (blockRows != null && blockRows.isNotEmpty) {
      final blockLastRow = blockRows.last;
      if (blockLastRow.isNotEmpty) {
        final blockTargetIndex = blockLastRow.length > 2
            ? 2
            : blockLastRow.length - 1;
        blockLastRow[blockTargetIndex] =
            '${blockLastRow[blockTargetIndex]}\n$cleaned'.trim();
      }
    }
    return true;
  }

  _DocumentSection build() {
    return _DocumentSection(
      index: index,
      title: title,
      bodyLines: PdfExportService._trimEmptyLines(_bodyLines),
      tableRows: _tableRows,
      blocks: _trimBlocks(_blocks),
    );
  }

  List<_DocumentContentBlock> _trimBlocks(List<_DocumentContentBlock> blocks) {
    var start = 0;
    var end = blocks.length;
    while (start < end && (blocks[start].text?.trim().isEmpty ?? false)) {
      start++;
    }
    while (end > start && (blocks[end - 1].text?.trim().isEmpty ?? false)) {
      end--;
    }
    return blocks.sublist(start, end);
  }

  List<String>? _parseTableLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('|') || !trimmed.endsWith('|')) {
      return null;
    }
    if (PdfExportService._isMarkdownSeparatorLine(trimmed)) {
      return null;
    }
    final cells = trimmed
        .substring(1, trimmed.length - 1)
        .split('|')
        .map((cell) => PdfExportService._cleanMarkdownText(cell))
        .toList();
    if (cells.every((cell) => cell.trim().isEmpty)) {
      return null;
    }
    return cells;
  }
}

class _ParsedDocument {
  const _ParsedDocument({required this.introLines, required this.sections});

  final List<String> introLines;
  final List<_DocumentSection> sections;

  bool get hasSectionContent {
    return sections.any(
      (section) => section.bodyLines.isNotEmpty || section.tableRows.isNotEmpty,
    );
  }
}

class _DocumentSection {
  const _DocumentSection({
    required this.index,
    required this.title,
    required this.bodyLines,
    required this.tableRows,
    required this.blocks,
  });

  final int index;
  final String title;
  final List<String> bodyLines;
  final List<List<String>> tableRows;
  final List<_DocumentContentBlock> blocks;
}

class _DocumentContentBlock {
  const _DocumentContentBlock._({this.text, this.tableRows});

  factory _DocumentContentBlock.text(String text) {
    return _DocumentContentBlock._(text: text);
  }

  factory _DocumentContentBlock.table(List<List<String>> rows) {
    return _DocumentContentBlock._(tableRows: rows);
  }

  final String? text;
  final List<List<String>>? tableRows;
}

class _SectionInfo {
  const _SectionInfo({required this.index, required this.title});

  final int index;
  final String title;
}

class _RiskRow {
  const _RiskRow(this.values);

  final Map<String, String> values;

  bool get isEmpty => values.values.every((value) => value.trim().isEmpty);

  String value(String key, {String? fallback}) {
    final normalized = PdfExportService._normalizeTitle(key);
    final fallbackNormalized = fallback == null
        ? null
        : PdfExportService._normalizeTitle(fallback);
    final fallbackAliases = fallbackNormalized == null
        ? null
        : PdfExportService._riskHeaderCandidates(fallbackNormalized);
    final candidates = [
      normalized,
      ...PdfExportService._riskHeaderCandidates(normalized),
      ?fallbackNormalized,
      ...?fallbackAliases,
    ];
    for (final candidate in candidates) {
      final value = values[candidate];
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}

class _LeadingReferenceDateBlock {
  const _LeadingReferenceDateBlock({
    required this.normalizedReferenceLine,
    required this.normalizedDateLine,
    required this.referenceValue,
    required this.dateValue,
    required this.endExclusive,
  });

  final String normalizedReferenceLine;
  final String normalizedDateLine;
  final String referenceValue;
  final String dateValue;
  final int endExclusive;

  bool matches(_LeadingReferenceDateBlock other) {
    return referenceValue == other.referenceValue &&
            dateValue == other.dateValue ||
        normalizedReferenceLine == other.normalizedReferenceLine &&
            normalizedDateLine == other.normalizedDateLine;
  }
}

class _ActionRow {
  const _ActionRow(this.values);

  final Map<String, String> values;

  bool get isEmpty => values.values.every((value) => value.trim().isEmpty);

  bool get isValid {
    final number = value('numéro d’action', fallback: 'n°');
    final measure = value('mesure proposée');
    final responsible = value('responsable');
    final deadline = value('échéance');
    return number.isNotEmpty &&
        measure.isNotEmpty &&
        (responsible.isNotEmpty || deadline.isNotEmpty);
  }

  String value(String key, {String? fallback}) {
    final normalized = PdfExportService._normalizeTitle(key);
    final fallbackNormalized = fallback == null
        ? null
        : PdfExportService._normalizeTitle(fallback);
    final fallbackAliases = fallbackNormalized == null
        ? null
        : PdfExportService._actionHeaderCandidates(fallbackNormalized);
    final candidates = [
      normalized,
      ...PdfExportService._actionHeaderCandidates(normalized),
      ?fallbackNormalized,
      ...?fallbackAliases,
    ];
    for (final candidate in candidates) {
      final value = values[candidate];
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}

class _RiskAdvisorPdfColors {
  const _RiskAdvisorPdfColors(this.background, this.border, this.text);

  final PdfColor background;
  final PdfColor border;
  final PdfColor text;
}
