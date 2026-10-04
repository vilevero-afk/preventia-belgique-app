# PreventIA Architecture Notes

## Responsabilités actuelles

- Flutter génère actuellement le PGA/PAA/PGP localement pour le dossier société.
- Le backend génère les analyses de risques et certains rendus spécialisés.
- Le PIU est alimenté par le dossier société et/ou le backend selon le flux utilisé.
- La source de vérité locale du dossier société est `PreventiaCompanyProject`.

## Points de vigilance

- Ne pas supprimer les anciens services sans tests de non-régression couvrant les dossiers société, PIU, PGA/PAA/PGP et exports.
- `company_folder_detail_screen.dart` concentre encore validation, génération, export et navigation.
- Les libellés `documentType` sont contractuels côté Flutter et doivent rester couverts par des tests de caractérisation avant toute normalisation plus large.
- Les nettoyages de markdown/export doivent rester testés contre les bruits connus comme `Page 1 / 1` et les métadonnées techniques.
