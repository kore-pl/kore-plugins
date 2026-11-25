# Divulgation des vulnérabilités de sécurité

Ce fichier décrit la procédure de divulgation, pas la conception de la sécurité. La conception du noyau est dans docs/SECURITY.md ; le modèle de menaces de kore est dans le dépôt kore.

## Périmètre

Covered: `index/plugins.json` and its signature `index/plugins.json.sig`, `index/versions.lock.json`, `presets/*.json`, the `market/` static page and `scripts/` validation scripts.

## Versions prises en charge

| Version | Statut | Notes |
| --- | --- | --- |
| 当前 `main` | Oui — accepte et corrige | Instantané de développement ; veuillez mettre à jour. |
| 历史 commit / 快照 | Non — non pris en charge | Instantané de développement ; veuillez mettre à jour. |

Pendant la phase 0.x, la prise en charge est minimale : seul le dernier correctif d’une ligne mineure est corrigé ; les anciens correctifs ne sont pas rétroportés.

## Surface d’attaque dans ce dépôt

Les actions distantes et les écritures hôte sont limitées aux capacités déclarées ; un contournement est une vulnérabilité. Les sockets des plugins sont créés par le shell avec des permissions restreintes ; contourner ces permissions ou lire les données d’un autre plugin est une vulnérabilité.

## Signalement

Préféré : GitHub Security Advisory sur ce dépôt (« Signaler une vulnérabilité », privé, sans issue publique). E-mail de secours : pengtang1024@users.noreply.github.com avec l’objet `[kore security] <repo>`. N’ouvrez pas d’issue publique et ne publiez pas de détails exploitables dans les discussions ou PR.

Incluez : version ou commit affecté, étapes de reproduction ou PoC, évaluation de l’impact, caractère public éventuel et votre préférence d’attribution.

## Délais et divulgation

Accusé de réception sous 72 heures avec une première évaluation ; les cas complexes reçoivent un plan d’investigation. Divulgation coordonnée avec une fenêtre par défaut de 90 jours ; contactez-nous d’abord si une divulgation anticipée est nécessaire (p. ex. exploitation active). Consignez les correctifs dans CHANGELOG.md sans détails d’exploitation et publiez un avis si nécessaire.

## Remerciements

Avec votre accord, nous remercions le rapporteur dans les notes de version ; anonyme sur demande.
