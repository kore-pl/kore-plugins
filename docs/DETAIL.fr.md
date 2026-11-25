> 状态: brouillon (草稿) · 归属: wave1 · 更新: 2026-11-25 · 里程碑: M5

# kore-plugins

Ce dépôt ne publie que `index/plugins.json` (et sa signature ed25519 `plugins.json.sig`), `index/versions.lock.json`, `presets/*.json` et la page de marché statique `market/`, avec des scripts de validation. L’index répond seulement « quels plugins, quelle version, quelle taille, quel résumé » ; il ne prouve pas qu’un paquet est fiable : kore recalcule le sha256 localement et compare. La racine de confiance est la clé publique compilée dans kore et le calcul local. Pas de revue, pas de compte, fonctionne hors ligne (G-10).

Langue : [简体中文](DETAIL.md) · [English](DETAIL.en.md) · [Español](DETAIL.es.md) · [Français](DETAIL.fr.md) · [Deutsch](DETAIL.de.md) · [Русский](DETAIL.ru.md) · [Português](DETAIL.pt.md)

## Ce que fait le projet

- **Canal de découverte, pas source de confiance** : le `sha256` / `download_url` de l’index ne sont vérifiés qu’avant installation ; la racine de confiance est la clé publique compilée dans kore et le recalcul local.
- **Chaîne de signature** : `plugins.json.sig` est une signature ed25519 brute de 64 octets, resignée par le mainteneur sur la source autoritative ; la CI vérifie en couches — PR : schéma seulement, push main/tag : vérification complète ; signature absente ou invalide = FAIL. La clé privée n’entre jamais dans le dépôt ni dans les secrets CI.
- **Registre des versions** : `versions.lock.json` est append-only ; un sha par `id@version` ; modifier un paquet impose un bump de version.
- **Huit préréglages** : `minimal` / `dev` / `web-lite` / `web-pro` / `db-only` / `gateway` / `security` / `full` ; `out_of_box=true` ne doit pas activer les plugins basic (G-20).
- **Marché statique** : `market/index.html` s’ouvre hors ligne, sans framework, CDN ni lien http(s) ; `market/plugins.js` est intégré à la construction par `build-market.sh`.
- **Portes de validation** : `make check` = `validate-index.sh` + `validate-presets.sh` (vérification complète par défaut) ; `KORE_INDEX_SKIP_SIG=1` uniquement pour le schéma en PR.

## Démarrage rapide

```bash
KORE_INDEX_SKIP_SIG=1 make check   # PR : schéma / registre / références de préréglages seulement
bash scripts/validate-index.sh     # validation complète (y compris signature ed25519)
bash scripts/validate-presets.sh   # validation des préréglages
bash scripts/build-market.sh       # reconstruire market/plugins.js
```

Après modification de `plugins.json`, le mainteneur doit resigner sur la source autoritative avec la clé privée de la machine de publication (`KORE_INDEX_KEY=<seed> bash scripts/sign-index.sh`) et pousser contenu et `.sig` dans le même commit ; la clé privée n’entre jamais dans le dépôt ni dans la CI.

## Sécurité et limites

Signalez toute falsification de l’index, problème de signature ou de chaîne d’approvisionnement via [SECURITY.md](../SECURITY.md) (accusé sous 72 h / divulgation coordonnée à 90 jours) ; n’ouvrez pas d’issue publique. **La clé privée est détenue par le mainteneur, jamais dans le dépôt ni dans les secrets CI ; la CI vérifie seulement, elle ne signe pas.** Un changement de clé publique doit être publié avec le noyau kore et conserver un cycle de compatibilité de rotation.

## Plan de la documentation

- [SECURITY.md](../SECURITY.md) — procédure de divulgation ; chaîne de signature et rotation dans le README.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — entrées d’index, registre des versions, préréglages et conventions de commit.
- [CHANGELOG.md](../CHANGELOG.md) — historique de l’index et des versions de plugins.
- [index/plugins.json](../index/plugins.json) — entrées actuelles (source de vérité).
- [index/versions.lock.json](../index/versions.lock.json) — registre des versions (append-only).
- [Documentation du protocole kore](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-PROTOCOL.md) — source de vérité du protocole.

## Autres documents

La description complète est dans [README.md](../README.md).
La procédure de divulgation est dans [SECURITY.md](../SECURITY.md) et la conception de la sécurité dans [SECURITY.md](../SECURITY.md).
L’historique des versions est dans [CHANGELOG.md](../CHANGELOG.md).
Comment contribuer : [CONTRIBUTING.md](../CONTRIBUTING.md).

## Questions fréquentes

**Q : Faut-il un compte ?**
Non. Il n’y a ni compte, ni vérification en ligne, ni télémétrie cachée ; la configuration est en texte brut, lisible et modifiable.

**Q : Où se trouvent les plugins ?**
Chaque plugin vit dans son propre dépôt `kore-plugin-<id>`. Ce dépôt ne contient que le noyau et le SDK public.

**Q : Quel document lire en premier ?**
Commencez par `QUICKSTART.md` (de la compilation au premier login), puis utilisez l’index « que veux-je faire ? » dans `docs/README.md`.
