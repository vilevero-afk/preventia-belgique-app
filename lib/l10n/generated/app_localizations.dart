import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('nl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'PreventIA Belgique'**
  String get appTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Assistant de prévention et bien-être au travail'**
  String get homeSubtitle;

  /// No description provided for @newDocument.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau document'**
  String get newDocument;

  /// No description provided for @riskAssessment.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de risques'**
  String get riskAssessment;

  /// No description provided for @preventionDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents de prévention'**
  String get preventionDocuments;

  /// No description provided for @generalRiskAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de risques générale'**
  String get generalRiskAnalysis;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @limitsAndMentions.
  ///
  /// In fr, this message translates to:
  /// **'Mentions et limites'**
  String get limitsAndMentions;

  /// No description provided for @aiSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres IA'**
  String get aiSettings;

  /// No description provided for @subscriptionLicense.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement / Licence'**
  String get subscriptionLicense;

  /// No description provided for @activateLicense.
  ///
  /// In fr, this message translates to:
  /// **'Activer la licence'**
  String get activateLicense;

  /// No description provided for @licenseKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé de licence'**
  String get licenseKey;

  /// No description provided for @activeLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence active'**
  String get activeLicense;

  /// No description provided for @expiredLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence expirée'**
  String get expiredLicense;

  /// No description provided for @quotaReached.
  ///
  /// In fr, this message translates to:
  /// **'Quota atteint'**
  String get quotaReached;

  /// No description provided for @usedDevices.
  ///
  /// In fr, this message translates to:
  /// **'Appareils utilisés'**
  String get usedDevices;

  /// No description provided for @deactivateThisDevice.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver cet appareil'**
  String get deactivateThisDevice;

  /// No description provided for @logoutThisDevice.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter cet appareil'**
  String get logoutThisDevice;

  /// No description provided for @emailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @personalLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence personnelle'**
  String get personalLicense;

  /// No description provided for @personalLicenseInfo.
  ///
  /// In fr, this message translates to:
  /// **'Une licence PreventIA est personnelle. Elle est liée à votre adresse e-mail et peut être utilisée sur plusieurs appareils autorisés.'**
  String get personalLicenseInfo;

  /// No description provided for @primaryLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence principale'**
  String get primaryLicense;

  /// No description provided for @additionalLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence supplémentaire'**
  String get additionalLicense;

  /// No description provided for @licenseType.
  ///
  /// In fr, this message translates to:
  /// **'Type de licence'**
  String get licenseType;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @cycle.
  ///
  /// In fr, this message translates to:
  /// **'Cycle'**
  String get cycle;

  /// No description provided for @monthlyCycle.
  ///
  /// In fr, this message translates to:
  /// **'Cycle mensuel'**
  String get monthlyCycle;

  /// No description provided for @annualCycle.
  ///
  /// In fr, this message translates to:
  /// **'Cycle annuel'**
  String get annualCycle;

  /// No description provided for @deviceLimitReached.
  ///
  /// In fr, this message translates to:
  /// **'Limite d’appareils atteinte'**
  String get deviceLimitReached;

  /// No description provided for @loginRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connexion requise'**
  String get loginRequired;

  /// No description provided for @loginSuccessful.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie'**
  String get loginSuccessful;

  /// No description provided for @incorrectPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect'**
  String get incorrectPassword;

  /// No description provided for @simpleDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents simples'**
  String get simpleDocuments;

  /// No description provided for @riskAnalyses.
  ///
  /// In fr, this message translates to:
  /// **'Analyses de risques'**
  String get riskAnalyses;

  /// No description provided for @subscriptionDoesNotAllowDocument.
  ///
  /// In fr, this message translates to:
  /// **'Votre abonnement ne permet pas ce document'**
  String get subscriptionDoesNotAllowDocument;

  /// No description provided for @noSensitiveHardwareIdentifier.
  ///
  /// In fr, this message translates to:
  /// **'La licence est liée à l’entreprise et à cet appareil. Aucun identifiant matériel sensible n’est collecté.'**
  String get noSensitiveHardwareIdentifier;

  /// No description provided for @company.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get company;

  /// No description provided for @plan.
  ///
  /// In fr, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @expirationDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d’expiration'**
  String get expirationDate;

  /// No description provided for @allowedFeatures.
  ///
  /// In fr, this message translates to:
  /// **'Fonctions autorisées'**
  String get allowedFeatures;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @completeFormIntro.
  ///
  /// In fr, this message translates to:
  /// **'Complétez les informations connues. Les champs vides seront envoyés comme \"Non renseigné / à vérifier\".'**
  String get completeFormIntro;

  /// No description provided for @fillCompleteExample.
  ///
  /// In fr, this message translates to:
  /// **'Remplir avec un exemple complet'**
  String get fillCompleteExample;

  /// No description provided for @clearForm.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le formulaire'**
  String get clearForm;

  /// No description provided for @generateDocument.
  ///
  /// In fr, this message translates to:
  /// **'Générer le projet de document'**
  String get generateDocument;

  /// No description provided for @aiGenerationInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Génération IA en cours. Une analyse complète peut prendre jusqu’à 2 à 3 minutes.'**
  String get aiGenerationInProgress;

  /// No description provided for @aiGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Document généré via backend IA sécurisé'**
  String get aiGenerated;

  /// No description provided for @localGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Document généré localement'**
  String get localGenerated;

  /// No description provided for @projectDocument.
  ///
  /// In fr, this message translates to:
  /// **'Projet de document'**
  String get projectDocument;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @copyDocument.
  ///
  /// In fr, this message translates to:
  /// **'Copier le document'**
  String get copyDocument;

  /// No description provided for @saveLocally.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder localement'**
  String get saveLocally;

  /// No description provided for @exportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF'**
  String get exportPdf;

  /// No description provided for @downloadWord.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger Word'**
  String get downloadWord;

  /// No description provided for @wordDocumentGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Document Word généré'**
  String get wordDocumentGenerated;

  /// No description provided for @unableToGenerateWordDocument.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le document Word'**
  String get unableToGenerateWordDocument;

  /// No description provided for @exportWord.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en Word'**
  String get exportWord;

  /// No description provided for @editableVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version modifiable'**
  String get editableVersion;

  /// No description provided for @viewActions.
  ///
  /// In fr, this message translates to:
  /// **'Voir les actions à réaliser'**
  String get viewActions;

  /// No description provided for @actionsToDo.
  ///
  /// In fr, this message translates to:
  /// **'Actions à réaliser'**
  String get actionsToDo;

  /// No description provided for @actionSummary.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif des actions'**
  String get actionSummary;

  /// No description provided for @saveSummary.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder ce récapitulatif'**
  String get saveSummary;

  /// No description provided for @exportSummaryPdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le récapitulatif en PDF'**
  String get exportSummaryPdf;

  /// No description provided for @analysisFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier d’analyse de risques'**
  String get analysisFolder;

  /// No description provided for @completeAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse complète'**
  String get completeAnalysis;

  /// No description provided for @fullRiskAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de risques complète'**
  String get fullRiskAnalysis;

  /// No description provided for @advancedBackendSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres backend avancés'**
  String get advancedBackendSettings;

  /// No description provided for @aiBackendUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL du backend sécurisé'**
  String get aiBackendUrl;

  /// No description provided for @resetDefaultBackendUrl.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l’URL backend par défaut'**
  String get resetDefaultBackendUrl;

  /// No description provided for @testBackendConnection.
  ///
  /// In fr, this message translates to:
  /// **'Tester le backend'**
  String get testBackendConnection;

  /// No description provided for @backendAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Backend Render disponible'**
  String get backendAvailable;

  /// No description provided for @backendUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Backend Render indisponible'**
  String get backendUnavailable;

  /// No description provided for @productionBackendInfo.
  ///
  /// In fr, this message translates to:
  /// **'L’application utilise le backend sécurisé de production. Les documents restent stockés localement sur l’appareil, sauf lors de la génération IA où les données nécessaires sont envoyées au backend.'**
  String get productionBackendInfo;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @appLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l’application'**
  String get appLanguage;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @dutch.
  ///
  /// In fr, this message translates to:
  /// **'Nederlands'**
  String get dutch;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In fr, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @applicationLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l’application'**
  String get applicationLanguage;

  /// No description provided for @projectToValidate.
  ///
  /// In fr, this message translates to:
  /// **'Projet à valider'**
  String get projectToValidate;

  /// No description provided for @documentSaved.
  ///
  /// In fr, this message translates to:
  /// **'Document sauvegardé'**
  String get documentSaved;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get save;

  /// No description provided for @open.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get open;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get saveChanges;

  /// No description provided for @copiedDocumentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Projet copié dans le presse-papiers.'**
  String get copiedDocumentMessage;

  /// No description provided for @copiedSummaryMessage.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif copié.'**
  String get copiedSummaryMessage;

  /// No description provided for @savedAnalysisFolderMessage.
  ///
  /// In fr, this message translates to:
  /// **'Dossier d’analyse sauvegardé localement.'**
  String get savedAnalysisFolderMessage;

  /// No description provided for @savedSummaryMessage.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif sauvegardé localement.'**
  String get savedSummaryMessage;

  /// No description provided for @savedSettingsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres IA sauvegardés localement.'**
  String get savedSettingsMessage;

  /// No description provided for @languageChanged.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l’application mise à jour.'**
  String get languageChanged;

  /// No description provided for @languageChangedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l’application mise à jour.'**
  String get languageChangedMessage;

  /// No description provided for @languageScopeInfo.
  ///
  /// In fr, this message translates to:
  /// **'La langue choisie s’applique à l’interface et aux nouveaux documents générés. Les documents déjà sauvegardés conservent leur contenu existant.'**
  String get languageScopeInfo;

  /// No description provided for @localStorageDeviceInfo.
  ///
  /// In fr, this message translates to:
  /// **'L’application fonctionne sur mobile, tablette et ordinateur. Les documents restent stockés localement sur l’appareil.'**
  String get localStorageDeviceInfo;

  /// No description provided for @aiBackendSecurityInfo.
  ///
  /// In fr, this message translates to:
  /// **'La clé API ne doit jamais être stockée dans l’application mobile. La génération IA doit passer par un backend sécurisé validé par l’entreprise.'**
  String get aiBackendSecurityInfo;

  /// No description provided for @privacyInfo.
  ///
  /// In fr, this message translates to:
  /// **'Les données encodées peuvent contenir des informations sensibles. Anonymisez les noms de personnes, adresses privées et informations médicales. L’entreprise doit valider son propre cadre de traitement des données.'**
  String get privacyInfo;

  /// No description provided for @httpDevWarning.
  ///
  /// In fr, this message translates to:
  /// **'Mode développement local : HTTP est autorisé uniquement pour les tests sur réseau privé. En production, utilisez HTTPS.'**
  String get httpDevWarning;

  /// No description provided for @useAiIfAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser la génération IA si disponible'**
  String get useAiIfAvailable;

  /// No description provided for @disableLocalFallbackForAiTests.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la génération locale de secours pour les tests'**
  String get disableLocalFallbackForAiTests;

  /// No description provided for @renderBackendSource.
  ///
  /// In fr, this message translates to:
  /// **'IA backend Render'**
  String get renderBackendSource;

  /// No description provided for @localGenerationSource.
  ///
  /// In fr, this message translates to:
  /// **'Génération locale'**
  String get localGenerationSource;

  /// No description provided for @backendErrorSource.
  ///
  /// In fr, this message translates to:
  /// **'Erreur backend'**
  String get backendErrorSource;

  /// No description provided for @renderBackendPdfSource.
  ///
  /// In fr, this message translates to:
  /// **'IA backend Render - PDF généré localement sur l’appareil'**
  String get renderBackendPdfSource;

  /// No description provided for @localGenerationPdfSource.
  ///
  /// In fr, this message translates to:
  /// **'Génération locale - PDF généré localement sur l’appareil'**
  String get localGenerationPdfSource;

  /// No description provided for @aiUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Génération IA indisponible'**
  String get aiUnavailableTitle;

  /// No description provided for @aiUnavailableFallback.
  ///
  /// In fr, this message translates to:
  /// **'{message}\n\nVous pouvez revenir à la génération locale. Les données ne seront alors pas envoyées au backend.'**
  String aiUnavailableFallback(String message);

  /// No description provided for @useLocalGeneration.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser la génération locale'**
  String get useLocalGeneration;

  /// No description provided for @noBackendConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Aucun backend IA configuré. Génération locale utilisée.'**
  String get noBackendConfigured;

  /// No description provided for @documentModifiedLocally.
  ///
  /// In fr, this message translates to:
  /// **'Document modifié localement'**
  String get documentModifiedLocally;

  /// No description provided for @pdfFromSavedContent.
  ///
  /// In fr, this message translates to:
  /// **'Le PDF est généré à partir du contenu actuellement sauvegardé.'**
  String get pdfFromSavedContent;

  /// No description provided for @summaryStoredLocallyInfo.
  ///
  /// In fr, this message translates to:
  /// **'Ce récapitulatif est stocké localement et lié à son analyse source si elle existe encore sur l’appareil.'**
  String get summaryStoredLocallyInfo;

  /// No description provided for @openLinkedSummary.
  ///
  /// In fr, this message translates to:
  /// **'Voir le récapitulatif lié'**
  String get openLinkedSummary;

  /// No description provided for @createSummary.
  ///
  /// In fr, this message translates to:
  /// **'Créer le récapitulatif'**
  String get createSummary;

  /// No description provided for @viewLinkedAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’analyse liée'**
  String get viewLinkedAnalysis;

  /// No description provided for @linkedAnalysisNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Analyse liée introuvable localement.'**
  String get linkedAnalysisNotFound;

  /// No description provided for @changesSavedLocally.
  ///
  /// In fr, this message translates to:
  /// **'Modifications sauvegardées localement.'**
  String get changesSavedLocally;

  /// No description provided for @noHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun projet sauvegardé localement pour le moment.'**
  String get noHistory;

  /// No description provided for @analysisFolderSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Dossier d’analyse de risques\n2 documents : analyse complète + récapitulatif des actions'**
  String get analysisFolderSubtitle;

  /// No description provided for @riskAnalysisAndSummaryFolderInfo.
  ///
  /// In fr, this message translates to:
  /// **'Ce dossier regroupe l’analyse de risques et le récapitulatif opérationnel associé.'**
  String get riskAnalysisAndSummaryFolderInfo;

  /// No description provided for @analysisNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro : {number}'**
  String analysisNumber(String number);

  /// No description provided for @linkedAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Analyse liée : {title}'**
  String linkedAnalysis(String title);

  /// No description provided for @creationDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de création : {date}'**
  String creationDate(String date);

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut : {status}'**
  String status(String status);

  /// No description provided for @exportFolder.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le dossier'**
  String get exportFolder;

  /// No description provided for @exportSeparateSummaryHint.
  ///
  /// In fr, this message translates to:
  /// **'Exportez ensuite le PDF récapitulatif avec le bouton dédié.'**
  String get exportSeparateSummaryHint;

  /// No description provided for @exportSeparateDocumentsFallback.
  ///
  /// In fr, this message translates to:
  /// **'Exportez les deux PDF séparément.'**
  String get exportSeparateDocumentsFallback;

  /// No description provided for @summaryObjectiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectif du récapitulatif'**
  String get summaryObjectiveTitle;

  /// No description provided for @summaryObjectiveText.
  ///
  /// In fr, this message translates to:
  /// **'Transformer l’analyse de risques en tâches concrètes de suivi pour le conseiller en prévention, sans modifier le document d’analyse source.'**
  String get summaryObjectiveText;

  /// No description provided for @priorityActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions prioritaires'**
  String get priorityActions;

  /// No description provided for @documentsToPrepare.
  ///
  /// In fr, this message translates to:
  /// **'Documents à préparer ou mettre à jour'**
  String get documentsToPrepare;

  /// No description provided for @actorsToConsult.
  ///
  /// In fr, this message translates to:
  /// **'Acteurs à consulter'**
  String get actorsToConsult;

  /// No description provided for @fieldChecks.
  ///
  /// In fr, this message translates to:
  /// **'Informations à vérifier sur le terrain'**
  String get fieldChecks;

  /// No description provided for @expectedProofs.
  ///
  /// In fr, this message translates to:
  /// **'Preuves attendues'**
  String get expectedProofs;

  /// No description provided for @usefulExplanations.
  ///
  /// In fr, this message translates to:
  /// **'Explications utiles pour le conseiller en prévention'**
  String get usefulExplanations;

  /// No description provided for @validationNoticeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mention de validation'**
  String get validationNoticeTitle;

  /// No description provided for @summaryIntro.
  ///
  /// In fr, this message translates to:
  /// **'Ce récapitulatif aide le conseiller en prévention à transformer l’analyse en tâches concrètes. Il ne remplace pas la validation du document par les acteurs compétents.'**
  String get summaryIntro;

  /// No description provided for @expectedProofExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Une preuve attendue est l’élément concret permettant de démontrer que l’action a été réalisée : rapport, photo, registre, liste de présence, procédure signée ou PV CPPT.'**
  String get expectedProofExplanation;

  /// No description provided for @advisorMustCheck.
  ///
  /// In fr, this message translates to:
  /// **'Le conseiller en prévention doit vérifier que chaque action est réaliste, attribuée à un responsable, planifiée dans un délai cohérent et suivie par une preuve concrète.'**
  String get advisorMustCheck;

  /// No description provided for @missingInformationHelp.
  ///
  /// In fr, this message translates to:
  /// **'Si l’information n’est pas disponible, vous pouvez laisser le champ vide ou indiquer qu’elle est à vérifier sur le terrain.'**
  String get missingInformationHelp;

  /// No description provided for @actionToPerform.
  ///
  /// In fr, this message translates to:
  /// **'Action à réaliser'**
  String get actionToPerform;

  /// No description provided for @riskConcerned.
  ///
  /// In fr, this message translates to:
  /// **'Risque concerné'**
  String get riskConcerned;

  /// No description provided for @responsible.
  ///
  /// In fr, this message translates to:
  /// **'Responsable'**
  String get responsible;

  /// No description provided for @deadline.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get deadline;

  /// No description provided for @expectedProof.
  ///
  /// In fr, this message translates to:
  /// **'Preuve attendue'**
  String get expectedProof;

  /// No description provided for @whyImportant.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi c’est important'**
  String get whyImportant;

  /// No description provided for @advisorExpected.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui est attendu du conseiller en prévention'**
  String get advisorExpected;

  /// No description provided for @advisorExpectedShort.
  ///
  /// In fr, this message translates to:
  /// **'Attendu du conseiller en prévention'**
  String get advisorExpectedShort;

  /// No description provided for @document.
  ///
  /// In fr, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @objective.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get objective;

  /// No description provided for @expectedResult.
  ///
  /// In fr, this message translates to:
  /// **'Résultat attendu'**
  String get expectedResult;

  /// No description provided for @actor.
  ///
  /// In fr, this message translates to:
  /// **'Acteur'**
  String get actor;

  /// No description provided for @whyConsult.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi le consulter'**
  String get whyConsult;

  /// No description provided for @expectedTrace.
  ///
  /// In fr, this message translates to:
  /// **'Trace attendue'**
  String get expectedTrace;

  /// No description provided for @explanation.
  ///
  /// In fr, this message translates to:
  /// **'Explication'**
  String get explanation;

  /// No description provided for @itemToVerify.
  ///
  /// In fr, this message translates to:
  /// **'Élément à vérifier'**
  String get itemToVerify;

  /// No description provided for @howToVerify.
  ///
  /// In fr, this message translates to:
  /// **'Comment vérifier'**
  String get howToVerify;

  /// No description provided for @possibleProof.
  ///
  /// In fr, this message translates to:
  /// **'Preuve possible'**
  String get possibleProof;

  /// No description provided for @proof.
  ///
  /// In fr, this message translates to:
  /// **'Preuve'**
  String get proof;

  /// No description provided for @whatItIsFor.
  ///
  /// In fr, this message translates to:
  /// **'À quoi elle sert'**
  String get whatItIsFor;

  /// No description provided for @concreteExample.
  ///
  /// In fr, this message translates to:
  /// **'Exemple concret'**
  String get concreteExample;

  /// No description provided for @noPriorityActions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune action structurée n’a été détectée. Consultez le document complet ou régénérez l’analyse.'**
  String get noPriorityActions;

  /// No description provided for @noDocumentsDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document à préparer ou mettre à jour n’a pu être extrait automatiquement.'**
  String get noDocumentsDetected;

  /// No description provided for @noActorsDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun acteur à consulter n’a pu être extrait automatiquement.'**
  String get noActorsDetected;

  /// No description provided for @noFieldChecks.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mention à vérifier, non renseignée, à confirmer, à compléter, visite terrain ou observation terrain n’a été trouvée.'**
  String get noFieldChecks;

  /// No description provided for @noProofsDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune preuve attendue n’a été détectée automatiquement.'**
  String get noProofsDetected;

  /// No description provided for @documentsNecessityExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Ces documents permettent de démontrer que les mesures de prévention sont organisées, connues et traçables.'**
  String get documentsNecessityExplanation;

  /// No description provided for @consultationExplanation.
  ///
  /// In fr, this message translates to:
  /// **'La consultation permet de valider la réalité du terrain, d’impliquer les travailleurs et de documenter les décisions.'**
  String get consultationExplanation;

  /// No description provided for @unverifiedInfoImportance.
  ///
  /// In fr, this message translates to:
  /// **'Une information non vérifiée ne doit pas être considérée comme acquise.'**
  String get unverifiedInfoImportance;

  /// No description provided for @verifyBy.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer par observation, entretien, document ou contrôle.'**
  String get verifyBy;

  /// No description provided for @proofExamples.
  ///
  /// In fr, this message translates to:
  /// **'Photo, rapport, note de visite, registre ou compte rendu.'**
  String get proofExamples;

  /// No description provided for @proofPurpose.
  ///
  /// In fr, this message translates to:
  /// **'Démontrer concrètement qu’une action a été réalisée ou suivie.'**
  String get proofPurpose;

  /// No description provided for @proofConcreteExamples.
  ///
  /// In fr, this message translates to:
  /// **'Rapport, photo, registre, liste de présence, procédure signée ou PV CPPT.'**
  String get proofConcreteExamples;

  /// No description provided for @localValidationNotice.
  ///
  /// In fr, this message translates to:
  /// **'Ce récapitulatif est un outil d’aide au suivi des actions. Il doit être vérifié, adapté et validé avec les acteurs compétents avant utilisation comme preuve de suivi.'**
  String get localValidationNotice;

  /// No description provided for @source.
  ///
  /// In fr, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @generatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Date de génération'**
  String get generatedAt;

  /// No description provided for @generatedLocallyFromAnalysis.
  ///
  /// In fr, this message translates to:
  /// **'Généré localement à partir de l’analyse de risques'**
  String get generatedLocallyFromAnalysis;

  /// No description provided for @help.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get help;

  /// No description provided for @example.
  ///
  /// In fr, this message translates to:
  /// **'Exemple'**
  String get example;

  /// No description provided for @formSectionIdentification.
  ///
  /// In fr, this message translates to:
  /// **'A. Identification du document'**
  String get formSectionIdentification;

  /// No description provided for @formSectionScope.
  ///
  /// In fr, this message translates to:
  /// **'B. Périmètre de l’analyse'**
  String get formSectionScope;

  /// No description provided for @formSectionSources.
  ///
  /// In fr, this message translates to:
  /// **'C. Sources d’information'**
  String get formSectionSources;

  /// No description provided for @formSectionActivity.
  ///
  /// In fr, this message translates to:
  /// **'D. Activité, équipements et produits'**
  String get formSectionActivity;

  /// No description provided for @formSectionMeasures.
  ///
  /// In fr, this message translates to:
  /// **'E. Mesures existantes et preuves'**
  String get formSectionMeasures;

  /// No description provided for @formSectionRisks.
  ///
  /// In fr, this message translates to:
  /// **'F. Risques spécifiques'**
  String get formSectionRisks;

  /// No description provided for @formSectionWorkers.
  ///
  /// In fr, this message translates to:
  /// **'G. Travailleurs particuliers'**
  String get formSectionWorkers;

  /// No description provided for @formSectionPrevention.
  ///
  /// In fr, this message translates to:
  /// **'H. Objectif prévention'**
  String get formSectionPrevention;

  /// No description provided for @field_companyName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’entreprise'**
  String get field_companyName;

  /// No description provided for @field_siteConcerned.
  ///
  /// In fr, this message translates to:
  /// **'Site concerné'**
  String get field_siteConcerned;

  /// No description provided for @field_serviceConcerned.
  ///
  /// In fr, this message translates to:
  /// **'Service concerné'**
  String get field_serviceConcerned;

  /// No description provided for @field_author.
  ///
  /// In fr, this message translates to:
  /// **'Rédacteur'**
  String get field_author;

  /// No description provided for @field_version.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get field_version;

  /// No description provided for @field_visitDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de visite ou d’observation'**
  String get field_visitDate;

  /// No description provided for @field_documentObjective.
  ///
  /// In fr, this message translates to:
  /// **'Objectif du document : CPPT, audit, PAA, PGP, accident, visite terrain, autre'**
  String get field_documentObjective;

  /// No description provided for @field_includedLocations.
  ///
  /// In fr, this message translates to:
  /// **'Lieux inclus'**
  String get field_includedLocations;

  /// No description provided for @field_excludedLocations.
  ///
  /// In fr, this message translates to:
  /// **'Lieux exclus'**
  String get field_excludedLocations;

  /// No description provided for @field_concernedPositions.
  ///
  /// In fr, this message translates to:
  /// **'Postes concernés'**
  String get field_concernedPositions;

  /// No description provided for @field_concernedTasks.
  ///
  /// In fr, this message translates to:
  /// **'Tâches concernées'**
  String get field_concernedTasks;

  /// No description provided for @field_includedSituations.
  ///
  /// In fr, this message translates to:
  /// **'Situations incluses : routine, urgence, coactivité, sous-traitance, travail isolé'**
  String get field_includedSituations;

  /// No description provided for @field_exposureDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée d’exposition quotidienne ou hebdomadaire'**
  String get field_exposureDuration;

  /// No description provided for @field_workMode.
  ///
  /// In fr, this message translates to:
  /// **'Travail sur site, télétravail ou mixte'**
  String get field_workMode;

  /// No description provided for @field_fieldVisitDone.
  ///
  /// In fr, this message translates to:
  /// **'Visite terrain réalisée : oui/non/à vérifier'**
  String get field_fieldVisitDone;

  /// No description provided for @field_jobObservationDone.
  ///
  /// In fr, this message translates to:
  /// **'Observation de poste réalisée : oui/non/à vérifier'**
  String get field_jobObservationDone;

  /// No description provided for @field_workersConsulted.
  ///
  /// In fr, this message translates to:
  /// **'Travailleurs consultés : oui/non/à vérifier'**
  String get field_workersConsulted;

  /// No description provided for @field_managementConsulted.
  ///
  /// In fr, this message translates to:
  /// **'Ligne hiérarchique consultée : oui/non/à vérifier'**
  String get field_managementConsulted;

  /// No description provided for @field_cpptConsulted.
  ///
  /// In fr, this message translates to:
  /// **'CPPT consulté : oui/non/non applicable/à vérifier'**
  String get field_cpptConsulted;

  /// No description provided for @field_incidentRegisterAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Registre accidents/incidents disponible : oui/non/à vérifier'**
  String get field_incidentRegisterAvailable;

  /// No description provided for @field_photosAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Photos disponibles : oui/non/à vérifier'**
  String get field_photosAvailable;

  /// No description provided for @field_controlReportsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Rapports de contrôle disponibles : oui/non/à vérifier'**
  String get field_controlReportsAvailable;

  /// No description provided for @field_technicalSheetsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Fiches techniques disponibles : oui/non/à vérifier'**
  String get field_technicalSheetsAvailable;

  /// No description provided for @field_safetyDataSheetsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Fiches de données de sécurité disponibles : oui/non/à vérifier'**
  String get field_safetyDataSheetsAvailable;

  /// No description provided for @field_sector.
  ///
  /// In fr, this message translates to:
  /// **'Secteur d’activité'**
  String get field_sector;

  /// No description provided for @field_workerCount.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de travailleurs'**
  String get field_workerCount;

  /// No description provided for @field_activity.
  ///
  /// In fr, this message translates to:
  /// **'Activité ou poste analysé'**
  String get field_activity;

  /// No description provided for @field_equipment.
  ///
  /// In fr, this message translates to:
  /// **'Machines ou équipements utilisés'**
  String get field_equipment;

  /// No description provided for @field_dangerousProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits dangereux utilisés'**
  String get field_dangerousProducts;

  /// No description provided for @field_exposedWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Travailleurs exposés'**
  String get field_exposedWorkers;

  /// No description provided for @field_knownIncidents.
  ///
  /// In fr, this message translates to:
  /// **'Accidents ou incidents connus'**
  String get field_knownIncidents;

  /// No description provided for @field_constraints.
  ///
  /// In fr, this message translates to:
  /// **'Contraintes particulières'**
  String get field_constraints;

  /// No description provided for @field_additionalInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations complémentaires'**
  String get field_additionalInformation;

  /// No description provided for @field_writtenInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Instructions écrites existantes'**
  String get field_writtenInstructions;

  /// No description provided for @field_completedTrainings.
  ///
  /// In fr, this message translates to:
  /// **'Formations déjà réalisées'**
  String get field_completedTrainings;

  /// No description provided for @field_availablePpe.
  ///
  /// In fr, this message translates to:
  /// **'EPI disponibles'**
  String get field_availablePpe;

  /// No description provided for @field_periodicControls.
  ///
  /// In fr, this message translates to:
  /// **'Contrôles périodiques réalisés'**
  String get field_periodicControls;

  /// No description provided for @field_availableEvidence.
  ///
  /// In fr, this message translates to:
  /// **'Preuves disponibles'**
  String get field_availableEvidence;

  /// No description provided for @field_oralMeasures.
  ///
  /// In fr, this message translates to:
  /// **'Mesures seulement orales ou non documentées'**
  String get field_oralMeasures;

  /// No description provided for @field_measuresToVerify.
  ///
  /// In fr, this message translates to:
  /// **'Mesures à vérifier sur terrain'**
  String get field_measuresToVerify;

  /// No description provided for @field_workAtHeight.
  ///
  /// In fr, this message translates to:
  /// **'Travail en hauteur : oui/non/à vérifier'**
  String get field_workAtHeight;

  /// No description provided for @field_dangerousMachines.
  ///
  /// In fr, this message translates to:
  /// **'Machines ou outillage dangereux : oui/non/à vérifier'**
  String get field_dangerousMachines;

  /// No description provided for @field_chemicalProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits chimiques : oui/non/à vérifier'**
  String get field_chemicalProducts;

  /// No description provided for @field_manualHandling.
  ///
  /// In fr, this message translates to:
  /// **'Manutention manuelle : oui/non/à vérifier'**
  String get field_manualHandling;

  /// No description provided for @field_vehiclePedestrianTraffic.
  ///
  /// In fr, this message translates to:
  /// **'Circulation véhicules/piétons : oui/non/à vérifier'**
  String get field_vehiclePedestrianTraffic;

  /// No description provided for @field_noise.
  ///
  /// In fr, this message translates to:
  /// **'Bruit : oui/non/à vérifier'**
  String get field_noise;

  /// No description provided for @field_fireRisk.
  ///
  /// In fr, this message translates to:
  /// **'Incendie : oui/non/à vérifier'**
  String get field_fireRisk;

  /// No description provided for @field_loneWork.
  ///
  /// In fr, this message translates to:
  /// **'Travail isolé : oui/non/à vérifier'**
  String get field_loneWork;

  /// No description provided for @field_coactivity.
  ///
  /// In fr, this message translates to:
  /// **'Coactivité avec public/sous-traitants : oui/non/à vérifier'**
  String get field_coactivity;

  /// No description provided for @field_weatherConstraints.
  ///
  /// In fr, this message translates to:
  /// **'Contraintes météo : oui/non/à vérifier'**
  String get field_weatherConstraints;

  /// No description provided for @field_newWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux travailleurs'**
  String get field_newWorkers;

  /// No description provided for @field_temporaryWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Intérimaires'**
  String get field_temporaryWorkers;

  /// No description provided for @field_youngWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Jeunes travailleurs'**
  String get field_youngWorkers;

  /// No description provided for @field_pregnantOrBreastfeedingWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Travailleuses enceintes ou allaitantes'**
  String get field_pregnantOrBreastfeedingWorkers;

  /// No description provided for @field_medicalRestrictionsWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Travailleurs avec restrictions médicales'**
  String get field_medicalRestrictionsWorkers;

  /// No description provided for @field_isolatedWorkers.
  ///
  /// In fr, this message translates to:
  /// **'Travailleurs isolés'**
  String get field_isolatedWorkers;

  /// No description provided for @field_subcontractors.
  ///
  /// In fr, this message translates to:
  /// **'Sous-traitants'**
  String get field_subcontractors;

  /// No description provided for @field_cpptPresence.
  ///
  /// In fr, this message translates to:
  /// **'Présence d’un CPPT'**
  String get field_cpptPresence;

  /// No description provided for @field_preventionService.
  ///
  /// In fr, this message translates to:
  /// **'Service interne ou externe'**
  String get field_preventionService;

  /// No description provided for @field_feedAnnualActionPlan.
  ///
  /// In fr, this message translates to:
  /// **'Le document doit-il alimenter le Plan Annuel d’Action ?'**
  String get field_feedAnnualActionPlan;

  /// No description provided for @field_feedGlobalPreventionPlan.
  ///
  /// In fr, this message translates to:
  /// **'Le document doit-il alimenter le Plan Global de Prévention ?'**
  String get field_feedGlobalPreventionPlan;

  /// No description provided for @field_presentToCppt.
  ///
  /// In fr, this message translates to:
  /// **'Le document doit-il être présenté au CPPT ?'**
  String get field_presentToCppt;

  /// No description provided for @field_externalServiceValidation.
  ///
  /// In fr, this message translates to:
  /// **'Une validation du service externe est-elle prévue ?'**
  String get field_externalServiceValidation;

  /// No description provided for @field_occupationalDoctorAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Un avis du médecin du travail est-il nécessaire ?'**
  String get field_occupationalDoctorAdvice;

  /// No description provided for @helpDescription.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez les informations utiles pour ce champ afin de cadrer correctement l’analyse.'**
  String get helpDescription;

  /// No description provided for @helpExample.
  ///
  /// In fr, this message translates to:
  /// **'Exemple à adapter selon la situation réelle de l’entreprise ou du service concerné.'**
  String get helpExample;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
