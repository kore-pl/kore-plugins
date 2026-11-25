# Offenlegung von Sicherheitslücken

Diese Datei beschreibt den Offenlegungsprozess, nicht das Sicherheitsdesign. Das Kernel-Design steht in docs/SECURITY.md, das Kore-Bedrohungsmodell im kore-Repository.

## Geltungsbereich

Covered: `index/plugins.json` and its signature `index/plugins.json.sig`, `index/versions.lock.json`, `presets/*.json`, the `market/` static page and `scripts/` validation scripts.

## Unterstützte Versionen

| Version | Status | Hinweise |
| --- | --- | --- |
| 当前 `main` | Ja — wird angenommen und behoben | Vorschau-/Entwicklungssnapshot; bitte aktualisieren. |
| 历史 commit / 快照 | Nein — nicht unterstützt | Vorschau-/Entwicklungssnapshot; bitte aktualisieren. |

In der 0.x-Phase gilt ein minimaler Support: nur der neueste Patch einer Minor-Linie wird behoben; ältere Patches werden nicht zurückportiert.

## Angriffsfläche in diesem Repository

Ferngesteuerte Aktionen und Host-Schreibzugriffe sind auf deklarierte Capabilities beschränkt; eine Umgehung ist eine Schwachstelle. Plugin-Sockets werden von der Shell mit eingeschränkten Rechten angelegt; Umgehung der Socket-Rechte oder das Lesen fremder Plugin-Daten ist eine Schwachstelle.

## Meldung

Bevorzugt: GitHub Security Advisory in diesem Repository („Schwachstelle melden“, privat, kein öffentliches Issue). Ersatz-E-Mail: pengtang1024@users.noreply.github.com mit Betreff `[kore security] <repo>`. Keine öffentlichen Issues öffnen und keine ausnutzbaren Details in Diskussionen oder PRs posten.

Bitte angeben: betroffene Version oder Commit, Reproduktionsschritte oder PoC, Auswirkungsabschätzung, bereits öffentlich bekannt, und Bevorzugung bei der Namensnennung.

## Fristen und Offenlegung

Bestätigung innerhalb von 72 Stunden mit Ersteinschätzung; komplexe Fälle erhalten einen Investigationsplan. Koordinierte Offenlegung mit standardmäßig 90 Tagen; vorher kontaktieren, wenn eine frühere Offenlegung nötig ist (z. B. aktive Ausnutzung). Sicherheitskorrekturen ohne Ausnutzungsdetails in CHANGELOG.md festhalten und bei Bedarf eine Sicherheitswarnung veröffentlichen.

## Danksagung

Mit deiner Zustimmung danken wir dem Melder in den Release Notes; auf Wunsch anonym.
