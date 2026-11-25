# Changelog

## [未发布]

### 新增
- 补齐七语言（zh/en/es/fr/de/ru/pt）`DETAIL` 文档与 `locale/*.json`、README 语言切换行与 star 提示；无日语文件、无死链，JSON 校验通过。
- 新增六语言 `SECURITY` 译文、`.github/dependabot.yml`（gomod/npm/github-actions weekly）与 `.github/CODEOWNERS`。
- `CONTRIBUTING.md` 写明 Git Flow 分支模型（kebab-case 命名、release/hotfix 双向合流、`--no-ff`、SSH 签名 tag 约定）。

## 0.2.4 — 2026-11-23

- `app-deploy` 0.1.1 → 0.2.0 入索引：内置 4 模板真部署（nginx / wordpress / redis / postgres），方法 `app-deploy.templates` 返回模板清单；`sha256` / `size_bytes` / `download_url` 同步，`versions.lock.json` 追加 0.2.0（sha `56ee94417068…5ba34`）。
- 预设 `full` 的 app-deploy 固定版本同步到 0.2.0；`market/plugins.js` 重建。
- 第二十五次重签：新 ed25519 密钥对（公钥 `ac71264ca5cc…ab07a`），公钥同步 `kore/internal/core/market/verify.go` 与 `scripts/validate-index.sh`；正例 exit 0（24 条 + 版本单调 + id@version 唯一）、反例 exit 1、24 条 release 资产 sha 全等 `BAD_COUNT=0`。

## 0.2.3 — 2026-11-23

- `db-postgres` 0.1.1 → 0.2.0 入索引：5 方法真连接 + SQL 白名单（连接 / 库列表 / 只读查询 / 状态，去 noop）；`sha256` / `size_bytes` / `download_url` 同步，`versions.lock.json` 追加 0.2.0（sha `d315f699a946…af74b`）。
- 预设 `db-only` / `full` 的 db-postgres 固定版本同步到 0.2.0；`market/plugins.js` 重建。
- 第二十四次重签：新 ed25519 密钥对，公钥同步 `kore/internal/core/market/verify.go` 与 `scripts/validate-index.sh`；正例 exit 0（24 条 + 版本单调 + id@version 唯一）、反例 exit 1、24 条 release 资产 sha 全等 `BAD_COUNT=0`。

## 0.2.2 — 2026-11-23

- `firewall` 0.2.2 → 0.2.3 入索引：非 root 时 `status` / 提权动作统一返回 `E_NEED_ROOT`（403）而不是误报 401 登录失效；`sha256` / `size_bytes` / `download_url` 同步，`versions.lock.json` 追加 0.2.3（sha `353d56264532…651b`）。
- 预设 `security` / `full` / `gateway` 的 firewall 固定版本同步到 0.2.3；`market/plugins.js` 重建。
- 第二十三次重签：新 ed25519 密钥对，公钥同步 `kore/internal/core/market/verify.go` 与 `scripts/validate-index.sh`；正例 exit 0（24 条 + 版本单调 + id@version 唯一）、反例 exit 1、24 条 release 资产 sha 全等 `BAD_COUNT=0`。

## 0.2.1 — 2026-11-23

- `monitor` 0.2.0 → 0.2.1 入索引：`lifecycle` 由 `resident` 改为 `lazy`，修复 `MaxSlots=3` 下 3 个 resident 占满槽位、11 个 lazy 插件唤醒全部 429 的 P1 事故；`sha256` / `size_bytes` / `download_url` 同步，`versions.lock.json` 追加 0.2.1（sha `fb153e56482c…16b5`）。
- 预设 `web-pro` / `full` 的 monitor 固定版本同步到 0.2.1；`market/plugins.js` 重建。
- 第二十二次重签：新 ed25519 密钥对，公钥同步 `kore/internal/core/market/verify.go` 与 `scripts/validate-index.sh`；正例 exit 0（24 条）、反例 exit 1、24 条 release 资产 sha 全等 `BAD_COUNT=0`。

## 0.2.0 — 2026-11-23

- 23 个插件版本 bump（4 个 minor、19 个 patch；`discover` 无产物变化不 bump），索引同步 `version` / `sha256` / `size_bytes` / `download_url`。
- 新增 `index/versions.lock.json` 发版账本：`validate-index.sh` 增加「`id@version` 唯一 sha、版本单调递增、同版本换 sha 拒绝」校验。
- 8 个预设的固定版本同步到新版本；`market/plugins.js` 重建。
- 第十八次重签：新 ed25519 密钥对，公钥同步 `kore/internal/core/market/verify.go` 与 `scripts/validate-index.sh`；正例 exit 0、反例非 0、24 条包 sha 核对 0 差异。

## 0.1.0 — 2026-11-22

- 新增 `index/plugins.json`（schema_version=1）：echo 0.1.1 / site 0.1.0，摘要为实测 sha256。
- 新增索引级 ed25519 签名 `index/plugins.json.sig`（演示密钥，私钥不入库）。
- 新增 `scripts/validate-index.sh`：schema / id 唯一 / sha256 格式 / 验签 / 预设引用校验。
- 新增 `scripts/sign-index.sh`：CI 通过 `KORE_INDEX_KEY` 环境变量签发索引。
- 新增 README / Makefile / LICENSE（MIT）。
- 索引同步（未重签）：db-mysql 方法名域修正后 dist 变更，sha256/size_bytes 更新为 `94b40647…` / 1483657；同批 app-deploy、db-postgres、runtime-node、runtime-php、runtime-python 各自 dist 摘要更新。`index/plugins.json.sig` 仍为旧签名，待下一轮统一重签。
