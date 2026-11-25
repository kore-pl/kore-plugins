# Security vulnerability disclosure

This file is the disclosure process, not the security design. For the kernel design see docs/SECURITY.md; for the kore threat model see the kore repository.

## Scope

Covered: `index/plugins.json` and its signature `index/plugins.json.sig`, `index/versions.lock.json`, `presets/*.json`, the `market/` static page and `scripts/` validation scripts.

## Supported versions

| Version | Status | Notes |
| --- | --- | --- |
| 当前 `main` | Yes — accepts and fixes | Preview/development snapshot; please upgrade. |
| 历史 commit / 快照 | No — not supported | Preview/development snapshot; please upgrade. |

During the 0.x phase we use a minimal support surface: only the latest patch of a minor line is fixed; older patch versions are not backported.

## Attack surface in this repository

Remote actions and host writes are limited to declared capabilities; a bypass is a vulnerability. Plugin sockets are created by the shell with restricted permissions; socket permission bypass or cross-plugin reads are vulnerabilities.

## Reporting

Preferred: GitHub Security Advisory on this repository ("Report a vulnerability", private, no public issue). Backup email: pengtang1024@users.noreply.github.com with subject `[kore security] <repo>`. Do not open public issues or post exploit details in discussions or PRs.

Please include: affected version or commit, reproduction steps or PoC, impact assessment, whether it is public already, and your attribution preference.

## Timeline and disclosure

Acknowledge within 72 hours with a first assessment; complex cases get an investigation plan. Coordinate disclosure with a default 90-day window; contact us first if early disclosure is needed (e.g. active exploitation). Record security fixes in CHANGELOG.md without exploit details and publish an advisory as needed.

## Acknowledgements

With your consent we thank the reporter in the release notes; anonymous on request.
