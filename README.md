# PreventIA Belgique

Application Flutter de génération locale de projets de documents de prévention
pour la Belgique.

## Génération IA via backend sécurisé

L’application ne contient aucune clé API, aucun secret et aucune clé OpenAI.
Elle ne doit pas appeler directement une API IA depuis le mobile.

La génération IA optionnelle passe par le backend HTTPS de production Render
configuré par défaut dans l’écran `Paramètres IA`.

Le backend configuré doit être un serveur sécurisé validé par l’entreprise. Les
données encodées peuvent contenir des informations sensibles. Il faut anonymiser
les noms de personnes, adresses privées et informations médicales lorsque c’est
possible, et l’entreprise doit valider son propre cadre de traitement des
données.

### Exemple de payload envoyé au backend

```json
{
  "source": "preventia_belgique_app",
  "task": "generate_prevention_document",
  "locale": "fr-BE",
  "dataSensitivityNotice": "Les données peuvent contenir des informations sensibles. Le backend doit appliquer le cadre de traitement validé par l’entreprise.",
  "formData": {
    "documentType": "Analyse de risques générale",
    "sector": "Construction",
    "workerCount": "25",
    "workplace": "Chantier",
    "activity": "Travail en hauteur",
    "equipment": "Échafaudages",
    "dangerousProducts": "",
    "exposedWorkers": "Ouvriers",
    "knownIncidents": "",
    "existingMeasures": "Formation et EPI",
    "cpptPresence": "Oui",
    "preventionService": "Service externe",
    "constraints": "",
    "additionalInformation": ""
  },
  "expectedSections": [
    "Contexte",
    "Hypothèses utilisées",
    "Tableau d’analyse des risques",
    "Priorités d’action",
    "Projet de plan d’action",
    "Documents à créer ou mettre à jour",
    "Points à valider"
  ]
}
```

### Exemple de réponse attendue

```json
{
  "document": "PROJET DE DOCUMENT - ANALYSE DE RISQUES GÉNÉRALE\n\n1. Contexte\n...\n\n7. Points à valider\n..."
}
```

## Export PDF desktop

Sur macOS et Windows, l’export PDF doit ouvrir une fenêtre système
`Enregistrer sous...` afin que l’utilisateur choisisse le dossier et le nom du
fichier. Le PDF est généré localement et aucune donnée n’est envoyée vers un
service externe.

À tester sur PC Windows avec :

```sh
flutter run -d windows
flutter build windows
```
