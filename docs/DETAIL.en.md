> 状态: draft (草稿) · 归属: wave1 · 更新: 2026-11-25 · 里程碑: M5

# kore-plugins

This repository only publishes `index/plugins.json` (and its ed25519 signature `plugins.json.sig`), `index/versions.lock.json`, `presets/*.json` and the static marketplace page `market/`, with validation scripts. The index only answers “which plugins, which version, how large, what summary”; it does not prove a package is trustworthy: kore recomputes the package sha256 locally and compares it with the index. The trust root is the public key compiled into kore plus local computation. No review, no account, works offline (G-10).

Language: [简体中文](DETAIL.md) · [English](DETAIL.en.md) · [Español](DETAIL.es.md) · [Français](DETAIL.fr.md) · [Deutsch](DETAIL.de.md) · [Русский](DETAIL.ru.md) · [Português](DETAIL.pt.md)

## What it does

- **Discovery channel, not a trust source**: the index’s `sha256` / `download_url` are only checked before install; the trust root is the public key compiled into kore plus local recomputation.
- **Signature chain**: `plugins.json.sig` is a 64-byte raw ed25519 signature, re-signed by the maintainer on the authoritative source; CI verifies in layers — PRs check schema only, push main/tag verify fully; missing or bad signatures FAIL. The private key never enters the repository or CI secrets.
- **Version ledger**: `versions.lock.json` is append-only; one sha per `id@version`; changing a package requires a version bump.
- **Eight presets**: `minimal` / `dev` / `web-lite` / `web-pro` / `db-only` / `gateway` / `security` / `full`; `out_of_box=true` must not enable basic plugins (G-20).
- **Static marketplace**: `market/index.html` opens offline with no framework, CDN or http(s) links; `market/plugins.js` is embedded at build time by `build-market.sh`.
- **Validation gates**: `make check` = `validate-index.sh` + `validate-presets.sh` (full verification by default); `KORE_INDEX_SKIP_SIG=1` is only for PR schema checks.

## Quick start

```bash
KORE_INDEX_SKIP_SIG=1 make check   # PR: schema / ledger / preset references only
bash scripts/validate-index.sh     # full index validation (including ed25519 verification)
bash scripts/validate-presets.sh   # preset validation
bash scripts/build-market.sh       # rebuild market/plugins.js
```

After changing `plugins.json`, the maintainer must re-sign it on the authoritative source with the release-machine private key (`KORE_INDEX_KEY=<seed> bash scripts/sign-index.sh`) and push content and `.sig` in the same commit; the private key never enters the repository or CI.

## Security and boundaries

Report index tampering, signature-chain or supply-chain issues through [SECURITY.md](../SECURITY.md) (72-hour acknowledgement / 90-day coordinated disclosure); do not open public issues. **The private key is held by the maintainer, never stored in the repository or CI secrets; CI only verifies, never signs.** A public-key change must ship with the kore kernel and keep one release cycle of rotation compatibility.

## Documentation map

- [SECURITY.md](../SECURITY.md) — disclosure process; signature chain and rotation rules are in the README.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — index entries, version ledger, presets and commit conventions.
- [CHANGELOG.md](../CHANGELOG.md) — index and plugin version history.
- [index/plugins.json](../index/plugins.json) — current index entries (source of truth).
- [index/versions.lock.json](../index/versions.lock.json) — version ledger (append-only).
- [kore protocol docs](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-PROTOCOL.md) — source of truth for the plugin protocol.

## More documents

See [README.md](../README.md) for the full description.
See [SECURITY.md](../SECURITY.md) for disclosure and [docs/SECURITY.md](SECURITY.md) for the security design.
See [CHANGELOG.md](../CHANGELOG.md) for version history.
See [CONTRIBUTING.md](../CONTRIBUTING.md) for how to contribute.

## FAQ

**Q: Do I need an account?**
No. There is no account, no online verification and no hidden telemetry; configuration is plain text that you can read and change.

**Q: Where do plugins live?**
Each plugin lives in its own `kore-plugin-<id>` repository. This repository holds only the kernel and the public SDK.

**Q: Which document should I read first?**
Start with `QUICKSTART.md` (build to first login), then use the “what I want to do” index in `docs/README.md` to find topic documents.
