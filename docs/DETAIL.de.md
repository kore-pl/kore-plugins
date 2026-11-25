> 状态: Entwurf (草稿) · 归属: wave1 · 更新: 2026-11-25 · 里程碑: M5

# kore-plugins

Dieses Repository veröffentlicht nur `index/plugins.json` (und dessen ed25519-Signatur `plugins.json.sig`), `index/versions.lock.json`, `presets/*.json` und die statische Marktseite `market/`, mit Validierungsskripten. Der Index beantwortet nur „welche Plugins, welche Version, welche Größe, welche Zusammenfassung“; er beweist nicht die Vertrauenswürdigkeit eines Pakets: kore berechnet den sha256 lokal neu und vergleicht. Die Vertrauenswurzel ist der in kore einkompilierte öffentliche Schlüssel plus lokale Berechnung. Keine Prüfung, keine Konten, offline nutzbar (G-10).

Sprache: [简体中文](DETAIL.md) · [English](DETAIL.en.md) · [Español](DETAIL.es.md) · [Français](DETAIL.fr.md) · [Deutsch](DETAIL.de.md) · [Русский](DETAIL.ru.md) · [Português](DETAIL.pt.md)

## Was es tut

- **Entdeckungskanal, keine Vertrauensquelle**: `sha256` / `download_url` des Index werden nur vor der Installation geprüft; die Vertrauenswurzel ist der in kore einkompilierte öffentliche Schlüssel plus lokale Neuberechnung.
- **Signaturkette**: `plugins.json.sig` ist eine 64-Byte-Roh-ed25519-Signatur, vom Maintainer auf der autoritativen Quelle neu signiert; CI prüft geschichtet — PR nur Schema, push main/tag vollständig; fehlende oder falsche Signatur = FAIL. Der private Schlüssel gelangt nie ins Repository oder in CI-Secrets.
- **Versionsbuch**: `versions.lock.json` ist append-only; ein sha pro `id@version`; ein Paket zu ändern erfordert einen Versionsbump.
- **Acht Presets**: `minimal` / `dev` / `web-lite` / `web-pro` / `db-only` / `gateway` / `security` / `full`; `out_of_box=true` darf keine basic-Plugins aktivieren (G-20).
- **Statischer Markt**: `market/index.html` öffnet offline, ohne Framework, CDN oder http(s)-Links; `market/plugins.js` wird zur Buildzeit von `build-market.sh` eingebettet.
- **Validierungs-Gates**: `make check` = `validate-index.sh` + `validate-presets.sh` (standardmäßig vollständig); `KORE_INDEX_SKIP_SIG=1` nur für PR-Schema-Prüfung.

## Schnellstart

```bash
KORE_INDEX_SKIP_SIG=1 make check   # PR: nur Schema / Buch / Preset-Referenzen
bash scripts/validate-index.sh     # vollständige Indexprüfung (inkl. ed25519)
bash scripts/validate-presets.sh   # Preset-Prüfung
bash scripts/build-market.sh       # market/plugins.js neu bauen
```

Nach einer Änderung an `plugins.json` muss der Maintainer auf der autoritativen Quelle mit dem privaten Schlüssel der Release-Maschine neu signieren (`KORE_INDEX_KEY=<seed> bash scripts/sign-index.sh`) und Inhalt und `.sig` im selben Commit pushen; der private Schlüssel gelangt nie ins Repository oder in CI.

## Sicherheit und Grenzen

Melde Index-Manipulation, Signaturketten- oder Lieferkettenprobleme über [SECURITY.md](../SECURITY.md) (72 Stunden Bestätigung / 90 Tage koordinierte Offenlegung); keine öffentlichen Issues. **Der private Schlüssel liegt beim Maintainer, nie im Repository oder in CI-Secrets; CI prüft nur, signiert nie.** Ein Wechsel des öffentlichen Schlüssels muss mit dem kore-Kernel ausgeliefert werden und einen Release-Zyklus Rotationskompatibilität bewahren.

## Dokumentationsübersicht

- [SECURITY.md](../SECURITY.md) — Offenlegungsprozess; Signaturkette und Rotation stehen in der README.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — Indexeinträge, Versionsbuch, Presets und Commit-Konventionen.
- [CHANGELOG.md](../CHANGELOG.md) — Historie von Index und Plugin-Versionen.
- [index/plugins.json](../index/plugins.json) — aktuelle Einträge (einzige Wahrheitsquelle).
- [index/versions.lock.json](../index/versions.lock.json) — Versionsbuch (nur Ergänzungen).
- [kore-Protokolldokumentation](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-PROTOCOL.md) — einzige Wahrheitsquelle des Protokolls.

## Weitere Dokumente

Die vollständige Beschreibung steht in [README.md](../README.md).
Der Offenlegungsprozess steht in [SECURITY.md](../SECURITY.md), das Sicherheitsdesign in [docs/SECURITY.md](SECURITY.md).
Die Versionshistorie steht in [CHANGELOG.md](../CHANGELOG.md).
Wie du beiträgst: [CONTRIBUTING.md](../CONTRIBUTING.md).

## Häufige Fragen

**F: Brauche ich ein Konto?**
Nein. Es gibt keine Konten, keine Online-Prüfung und keine versteckte Telemetrie; die Konfiguration ist Klartext, den du lesen und ändern kannst.

**F: Wo liegen die Plugins?**
Jedes Plugin liegt in einem eigenen Repository `kore-plugin-<id>`. Dieses Repository enthält nur den Kernel und das öffentliche SDK.

**F: Welches Dokument sollte ich zuerst lesen?**
Beginne mit `QUICKSTART.md` (vom Build bis zur ersten Anmeldung) und nutze dann den „Was möchte ich tun?“-Index in `docs/README.md`.
