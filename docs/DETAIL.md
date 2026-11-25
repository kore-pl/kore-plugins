> 状态: draft · 归属: wave1 · 更新: 2026-11-25 · 里程碑: M5

# kore-plugins

本仓只发布 `index/plugins.json`（及其 ed25519 签名 `plugins.json.sig`）、`index/versions.lock.json`、`presets/*.json` 与静态市场页 `market/`，附一套校验脚本。索引只回答「有哪些插件、在哪个版本、包多大、摘要是什么」，不证明包可信：安装时由 kore 自算包 sha256 与索引声明比对，信任根在 kore 二进制内置公钥与本地计算。无审核、无账号、离线可用（G-10）。

语言：[简体中文](DETAIL.md) · [English](DETAIL.en.md) · [Español](DETAIL.es.md) · [Français](DETAIL.fr.md) · [Deutsch](DETAIL.de.md) · [Русский](DETAIL.ru.md) · [Português](DETAIL.pt.md)

## 它做什么

- **发现渠道，不是信任源**：索引声明的 `sha256` / `download_url` 只用于安装前校验，信任根在 kore 二进制内置公钥与本地复算结果。
- **签名链**：`plugins.json.sig` 是 64 字节 raw ed25519 签名，由发布方在权威源重签；CI 分层验签——PR 只验 schema，push main/tag 全量验签，缺签或错签即 FAIL。私钥不入库、不进 CI secret。
- **版本账本**：`versions.lock.json` 只追加，同一 `id@version` 只允许一个 sha；改包必须 bump 版本。
- **8 类场景预设**：`minimal` / `dev` / `web-lite` / `web-pro` / `db-only` / `gateway` / `security` / `full`；标 `out_of_box=true` 不得启用 basic 插件（G-20）。
- **静态市场页**：`market/index.html` 断网可开、零框架、无 CDN / 无 http(s) 外链；`market/plugins.js` 由 `build-market.sh` 构建期内嵌生成。
- **校验门禁**：`make check` = `validate-index.sh` + `validate-presets.sh`（默认全量验签）；`KORE_INDEX_SKIP_SIG=1` 仅 PR schema 校验用。

## 快速开始

```bash
KORE_INDEX_SKIP_SIG=1 make check   # PR：只验 schema / 账本 / 预设引用
bash scripts/validate-index.sh     # 索引全量校验（含 ed25519 验签）
bash scripts/validate-presets.sh   # 预设校验
bash scripts/build-market.sh       # 重建 market/plugins.js
```

维护者改 `plugins.json` 后必须在权威源用发布机私钥同批重签（`KORE_INDEX_KEY=<seed> bash scripts/sign-index.sh`），内容与 `.sig` 同一提交推送；私钥不入库、不进 CI。

## 安全与边界

索引篡改、签名链或供应链问题走 [SECURITY.md](../SECURITY.md)（72 小时确认 / 90 天协调披露），不要开公开 issue。**私钥由发布方持有，不入库、不进 CI secret；CI 只验签不签名**；公钥变更必须与 kore 内核同批发布并保留一个发布周期的轮换兼容窗口。

## 文档导航

- [SECURITY.md](../SECURITY.md) — 漏洞披露流程；签名链与轮换口径见 README。
- [CONTRIBUTING.md](../CONTRIBUTING.md) — 索引条目、版本账本、预设与提交规范。
- [CHANGELOG.md](../CHANGELOG.md) — 索引与各插件版本变更记录。
- [index/plugins.json](../index/plugins.json) — 当前索引条目（唯一真源）。
- [index/versions.lock.json](../index/versions.lock.json) — 版本账本（只追加）。
- [kore 协议文档](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-PROTOCOL.md) — 插件协议唯一真源。

## 更多文档

完整说明见 [README.md](../README.md)。
安全披露流程见 [SECURITY.md](../SECURITY.md)，安全设计见 [docs/SECURITY.md](SECURITY.md)。
版本变更记录见 [CHANGELOG.md](../CHANGELOG.md)。
贡献方式见 [CONTRIBUTING.md](../CONTRIBUTING.md)。

## 常见问题

**问：需要注册账号才能用吗？**
不需要。没有账号、没有联网校验、没有隐藏上报；配置是明文的，看得懂也改得动。

**问：插件装在哪个仓库？**
插件住在各自的 `kore-plugin-<id>` 仓，本仓库只放内核与公开 SDK。

**问：我该先读哪份文档？**
先看 `QUICKSTART.md`（构建到登录），再按 `docs/README.md` 的「我想做什么」索引找专题文档。
