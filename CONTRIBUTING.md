# 贡献指南（CONTRIBUTING）

`kore-plugins` 是 **kore** 的插件索引仓：只发布 `index/plugins.json`、`index/plugins.json.sig`、`index/versions.lock.json`、`presets/*.json` 与静态市场页 `market/`，并带一套校验脚本。CI 只在 push main / tag / PR / 手动触发（2026-11-23 策略：CI 少执行）；索引校验以本地 `bash scripts/validate-index.sh` / `bash scripts/validate-presets.sh` / `make check` 为准。**CI 分层**：PR 只验 schema / 版本账本 / 预设引用（跳过验签），push main 与 tag 才全量验签——签名是发布方动作，贡献者不签名（见 §2.1）。

## 1. 边界

- **纯静态**：没有服务端、没有数据库、没有后台任务；`kore` 只读本地索引缓存，零后台出站（G-10）。
- **不审核**：任何人可提 PR 增改条目，合并即发布；使用者自行决定是否安装。
- **不代管包**：包体由各 `kore-plugin-<id>` 仓的 `make dist` 产出并挂在它们自己的 release 上；本仓只记录 `download_url` / `size_bytes` / `sha256`。
- **无账号、无上传接口**：不收集身份、不要求登录、不提供上传端点。
- **不是信任源**：索引只回答"有哪些插件、哪个版本、包多大、摘要是什么"。信任根是 `kore` 二进制内置的 ed25519 公钥与安装时的本地 sha256 复算；索引被篡改也过不了安装这一关。

## 2. 改 `index/plugins.json` 的流程

1. 先确认插件仓已发版：`make dist` 产出 `dist/<id>-<version>.tar.gz` 与 `.sha256`，tag 已推。
2. 在 `plugins[]` 里增改条目，`schema_version` 保持 `1`。每条必填 12 个字段：
   `id` / `name` / `version` / `depth_level` / `lifecycle` / `size_bytes` / `sha256` / `download_url` / `requires_kore` / `depends_on` / `conflicts` / `scenario_tags`。
3. **值必须与产物逐字一致**：`version` 等于 tag 的版本，`sha256` 是 `.sha256` 文件里的摘要，`size_bytes` 是包体实际字节数，`download_url` 指向该 tag 的 release 资产且文件名与 dist 产物一致。
4. `requires_kore` / `depth_level` / `lifecycle` 来自插件 `info.json`，不得手写猜测值。
5. 向 `index/versions.lock.json` 对应 id 的数组**追加** `{version, sha256}`；不删旧版本、不改历史条目。
6. 同步 `presets/*.json`：预设里固定的 `{id, version, desired}` 必须与索引版本一致；`depth_level=basic` 的插件所在预设 `out_of_box` 必须为 `false`（G-20）。
7. **不要签名**：提交内容时不需要、**也不能**提供 `index/plugins.json.sig`——私钥在发布方手里，贡献者无法产出有效签名（见 §2.1）。签名由维护者合入时统一重签。
8. 重建市场页数据：`bash scripts/build-market.sh`（生成 `market/plugins.js`，页面断网可开、无外链）。

**同一 `id@version` 只允许一个 sha**：任何改变 dist sha 的改动必须 bump 版本并追加基线；`validate-index.sh` 会拒绝同版本换 sha、版本回退与跳版。

### 2.1 签名归属与验证分层（方案 A）

- **签名 = 发布方动作**：`index/plugins.json.sig` 必须由**发布方私钥**签发，私钥只在维护者发布机（或发布时的临时密钥），不入库、不进 GitHub / Gitee CI secret、不进日志。贡献者改内容后**没有能力**产出有效签名，所以**不要把 `.sig` 放进 PR**：放进去的要么是旧签名 + 新内容（必然失配），要么是伪造。
- **PR CI 只验 schema**：`pull_request` 跑 `KORE_INDEX_SKIP_SIG=1 make check` —— schema / 必填字段 / 版本账本 / 预设引用全量校验，**跳过 ed25519 验签**。这不是放宽门禁，而是因为贡献者无私钥、在 PR 上验签必然红，会把正常贡献挡在门外。
- **维护者合入时统一重签**：维护者把 PR 内容取到本地发布分支 → `KORE_INDEX_KEY=<seed> bash scripts/sign-index.sh` → `bash scripts/validate-index.sh` 正向 exit 0、改一字节反例非 0 → 内容与 `.sig` **同一个提交**推送。`push main` 与 tag 的 CI 跑全量 `make check`（含验签），未签 / 错签 / 内容与 `.sig` 不一致即红。
- **本地自查用跳过模式**：贡献者本地跑 `KORE_INDEX_SKIP_SIG=1 make check` 验自己的内容改动即可；该开关只跳过验签，其它校验一条不少，缺 `plugins.json.sig` 仍 FAIL。**禁止**在合并前验收 / 发布前复核 / 任何判定「索引可发布」的场合使用。完整流程见 [README.md](README.md) 的「签名链与轮换」。

## 3. 校验

| 命令 | 作用 |
| --- | --- |
| `bash scripts/validate-index.sh` | schema / 必填字段 / id 唯一 / sha256 格式 / 版本账本 / ed25519 验签 / 预设引用（默认全量，fail-closed） |
| `KORE_INDEX_SKIP_SIG=1 bash scripts/validate-index.sh` | 同上但**跳过 ed25519 验签**；只给 PR 侧 schema 校验用 |
| `bash scripts/validate-presets.sh` | 预设 id 可解析、常驻 ≤3、合计 RSS 红线、sha256、basic 不开箱 |
| `make presets-check` | 等价于 `bash scripts/validate-presets.sh`（G-18 入口） |
| `make check` | `presets-check` + `bash scripts/validate-index.sh`，发布前必须全绿（含验签） |
| `KORE_INDEX_SKIP_SIG=1 make check` | 贡献者自查用：schema / 账本 / 预设全绿，跳过验签 |

反向验证是硬要求：临时副本里把任一 `sha256` 改一个字符、注入未知插件 id 或第 4 个常驻插件，`make check` 必须以 `[FAIL]` 非 0 退出；正例必须 exit 0。贡献者用 `KORE_INDEX_SKIP_SIG=1 make check` 做这一步即可；**「改一字节 → 验签失败」这条反例属于发布方**，由维护者在重签后验收（见 §2.1），贡献者无需也无法复现。

## 4. 提交与 PR

- 提交信息：`type(scope): 中文描述`，type ∈ `feat` / `fix` / `perf` / `refactor` / `docs` / `test` / `chore` / `build`。
- 用 `git commit -s` 签 DCO（inbound = outbound，按 MIT 授权，无 CLA）。
- **精确 `git add <file>`，禁止 `git add .`**；贡献者的内容组是 `plugins.json`、`versions.lock.json`、`presets/*.json`、`market/plugins.js`（成组一致）；**`plugins.json.sig` 不在贡献者的提交里**，由维护者重签后与内容同批提交。
- PR 必须贴 `KORE_INDEX_SKIP_SIG=1 make check` 的命令原文 + 退出码 + 关键输出（PR CI 走的就是这一档）；改过索引的再贴正例与反例结果。
- 一个 PR 只做一件事：条目更新、预设调整、签名轮换分开提；签名轮换 / 重签由维护者在发布分支完成，不在 PR 里做。

## 5. 发版

本仓不打包、不发插件产物；版本线服务于索引自身的变更（schema 升级、签名轮换等）。签名是**发布方动作**：私钥只在维护者发布机，内容合入时由维护者统一重签并与内容同批提交。签名轮换必须保留旧公钥验签能力一个发布周期，确保轮换前已签发的索引仍可验；窗口结束才移除旧公钥并记 ADR。`CHANGELOG.md` 按版本记录索引条目、预设同步与重签结果。

## 6. 安全与行为准则

- 索引被篡改、签名异常或供应链问题不要开公开 issue，按 [SECURITY.md](SECURITY.md) 私下披露。
- 参与即表示同意 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。
