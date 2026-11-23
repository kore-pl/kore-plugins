# kore-plugins

kore 的**纯静态插件索引仓**：只发布 `index/`（`plugins.json` / `plugins.json.sig` / `versions.lock.json`）、`presets/*.json` 与静态市场页 `market/`，并带一套校验脚本；不审核、不代管包、无账号、无服务端。

> 状态: M2 · 归属: M2-B / M5-B · 更新: 2026-11-23

## 发现渠道，不是信任源

索引**只回答"有哪些插件、在哪个版本、包多大、摘要是什么"**，它不证明包可信。安装时由 kore **自算包 sha256** 并与索引声明比对，不符即拒、不落盘。索引被篡改也过不了安装这一关——信任根在 kore 二进制内置的公钥与本地计算结果，不在这个仓。

## 无审核 / 无账号 / 离线可用

- **无审核**：任何人可提 PR 增改条目，合并即发布；使用者自行决定是否安装。
- **无账号**：不收集身份、不要求登录、不隐藏上报（G-10）。
- **离线可用**：`kore` 读本地索引缓存（`paths.index_dir`，默认 `/var/lib/kore/index`），零后台出站；商店只做索引读取 / 验签 / 安装触发，`POST /store/install` 支持本地包（`package_path`）或按索引下载（`download=true`，URL 与 `sha256` 只取自已验签索引、请求体不能注入地址，防 SSRF）。

## 静态市场页（`market/`）

`market/index.html` 是一个**断网可开、零框架、纯静态**的插件市场页（M5-B）：双击文件即可在 `file://` 下打开，不发起任何网络请求、不依赖服务端。

- **数据来源**：`market/plugins.js` 由 `bash scripts/build-market.sh` 从 `index/plugins.json` 构建期内嵌生成（`window.KORE_PLUGINS = [...]`）。页面引用本地脚本，**不用 fetch**——`file://` 下 fetch 会被浏览器拦截，内嵌数据天然规避该问题。索引变更后重跑构建即可刷新页面。
- **只内嵌显示字段**：`id / name / version / depth_level / description / scenario_tags` 六项；`download_url` 等外链不进生成物，页面无 CDN、无 http(s) 外链。
- **摘要来源**：索引 schema 无 `description` 字段，构建脚本在缺失时以「名称（场景：tags）」生成中性摘要，不编造插件能力；若后续条目自带 `description` 则优先采用。
- **页面功能**：原生 JS 搜索框（按 id / 名称 / 场景标签过滤），`production` / `basic` 深度等级标识，页面内断网与无账号无审核提示。
- **首屏预算**：独立页面，不进 kore 首屏预算；零框架、零 npm/node 运行时依赖，生成脚本仅用 python3 标准库。

```bash
bash scripts/build-market.sh   # 生成 market/plugins.js（断网可开，构建期数据内嵌）
```

## 索引格式

`index/plugins.json` 顶层 `schema_version=1`，`plugins[]` 每条必填 12 个字段：
`id / name / version / depth_level / lifecycle / size_bytes / sha256 / download_url / requires_kore / depends_on / conflicts / scenario_tags`。

**条目数与各插件版本以 `index/plugins.json` 为准**（版本账本见 `index/versions.lock.json`），本文不重复枚举，避免写死易过期数字；`depth_level` / `lifecycle` 来自各插件仓的 `info.json`，产品插件评级口径以 kore 的 `docs/PLUGIN-MATURITY.md` 为准（echo 为验证件）。

**非 schema 字段 `capabilities`**：按当前索引快照，3 条历史条目（`terminal 0.2.0`、`process 0.2.1`、`discover 0.3.0`）多带 `capabilities` 数组。它**不是** kore `market.Plugin` 的 12 字段 schema 之一，解析端 lenient 忽略（不参与校验、不参与安装判定）。**不得为此改 `index/plugins.json`**——索引内容与 `plugins.json.sig` 绑定，改内容必须重新签名（私钥不在本机），留待下次重签时统一清理。

**`size_bytes` 口径**：该值是各插件仓 `info.json` 里的**自指估算值**（`info.json` 在 tarball 内，改这个数字会改包体本身），与 release 资产实测 size 的偏差可达 ±32 字节且非单调——精确相等通常存在但不保证（`container 0.5.1` 用精确搜索取到不动点 `1527626`；`ssh-guard 0.3.0` 实测 2840608 / 声明 2840609 属正常）。**索引入库与下载校验以 release 资产实测 size 为准，声明值仅作预检参考**；详见 `scripts/validate-index.sh` 顶部注释。

## 场景预设（`presets/`）

8 类预设均为 `schema_version=1` 的 JSON，含 `id / name / description / out_of_box / plugins[]`，每项插件引用 `{id, version, desired}`（`desired` ∈ `enabled|disabled`）。**只引用索引中真实存在的插件 id，且 `version` 必须与 `index/plugins.json` 一致**（`validate-presets.sh` 强校验，不一致即 FAIL）；各预设的具体组成以 `presets/*.json` 为准，下表只说明用途与口径。

| 预设 | 用途与组成（以 `presets/*.json` 为准） |
| --- | --- |
| `minimal` | 不启用任何插件，仅主壳运行；资源基线与故障隔离的干净起点。开箱可用。 |
| `dev` | echo 验证件 + `runtime-node` / `runtime-python` 联调；全部 basic，非开箱可用。 |
| `web-lite` | `site` + `ssl` + `runtime-php`，最小动态 Web；生产级，开箱可用。 |
| `web-pro` | `site` + `ssl` + `monitor` + `logs` + `runtime-php` + `db-mysql` 的 PHP + MySQL 生产栈；生产级，开箱可用。 |
| `db-only` | `db-mysql` + `file` + `backup` + `redis`；`db-postgres` 与 `db-mysql` 在索引中声明互斥，仅引用并默认 `disabled`。生产级，开箱可用。 |
| `gateway` | `site` + `ssl` + `dns` + `firewall` 承担网关/反向代理；含 basic（`dns`），非开箱可用。 |
| `security` | `ssh-guard` + `integrity` + `ssl` + `firewall` + `waf` 安全加固；含 basic，非开箱可用。 |
| `full` | 覆盖索引中绝大多数插件（`terminal` / `process` / `discover` 暂未纳入）：`site` / `monitor` / `echo` 默认启用，其余引用但默认 `disabled`；含 basic，非开箱可用。 |

`out_of_box` 标记"开箱可用"：按 G-20，预设标 `out_of_box=true` 时**不得启用** `depth_level=basic` 的插件（`validate-presets.sh` FAIL 级拦截）；basic 插件可以被引用，但必须默认 `disabled`。

## 校验

```bash
bash scripts/validate-index.sh     # 索引：schema / id 唯一 / sha256 格式 / 版本账本 / 验签 / 预设引用
KORE_INDEX_SKIP_SIG=1 bash scripts/validate-index.sh   # 仅 PR CI：跳过 ed25519 验签，其余照常
bash scripts/validate-presets.sh   # 预设：id 引用 / 常驻≤3 / 合计 RSS / sha256 / basic 不开箱
make presets-check                  # 等价入口（G-18）
make check                          # 聚合：索引校验 + 预设校验（默认全量验签）
KORE_INDEX_SKIP_SIG=1 make check    # 聚合但跳过验签（只给 PR schema 校验用）
```

`KORE_INDEX_SKIP_SIG=1` 是**唯一**的签名开关，只跳过 ed25519 验签；schema / 字段 / 账本 / 预设引用照常全量校验，`index/plugins.json.sig` 缺失仍 FAIL。**默认行为不变、fail-closed**：不设或 `=0` 全量验签，非法取值直接 FAIL，启动会打印一行当前模式。

预设合计 RSS：48 MiB 为硬红线（超则 FAIL），24 MiB 与 19.2 MiB 仅记 WARN 不判失败（G-03 / G-18，裁决按 resident 实测中位数求和；本仓用索引 `size_bytes` 作体积代理，可用 `KORE_PRESETS_MEASURED_JSON` 注入实测值覆盖）。反向验证：临时副本注入未知插件 id 或第 4 个常驻插件，脚本必须以 `[FAIL]` 退出（非 0）；把 `plugins.json` 里任一 `sha256` 改一个字符，`make check` 必须以 `[FAIL]` 退出。

## 签名链与轮换（引用提案 0002 §2 M2-B / R2）

索引级 ed25519 签名**前移到 M2**（信任空窗 = 0）：签名对象 = `plugins.json` 文件本体，公钥内置 kore 二进制，未签名索引默认拒绝。

### 角色：签名是发布方的动作，不是 CI 的动作

- **签名 = 发布方（维护者）在权威源执行的发布动作**：`index/plugins.json.sig` 由维护者在发布机上执行 `KORE_INDEX_KEY=<seed> bash scripts/sign-index.sh` 生成，并与内容**同批提交**。私钥只存在于发布机（或 [RUNBOOK §1](https://github.com/kore-pl/kore/blob/main/docs/RUNBOOK.md) 的临时密钥），**不入库、不进 GitHub / Gitee CI secret、不进日志**——本仓与两个镜像都不持有签发能力。
- **验证 = CI 分层（不持有签名能力）**：`pull_request` 只验 schema / 版本账本 / 预设引用，**不验签**（贡献者没有私钥，改内容就无法提供有效 `.sig`）；`push main` 与 tag 全量验签，未签 / 错签 / 内容与 `.sig` 不一致直接红。CI 权限保持 `contents: read`，不注入任何密钥。

### 内容变更的合并流程（维护者，4 步）

1. **取内容**：把 PR 的内容改动取到本地发布分支（`git rebase` / `git am` / 手工 apply 均可）。此时**还没有**新的 `.sig`。
2. **重签**：`KORE_INDEX_KEY=<seed> bash scripts/sign-index.sh` —— 用发布机上的私钥对改后的 `index/plugins.json` 重新签名，产出 `index/plugins.json.sig`（64 字节 raw 签名）。
3. **双向验收**：`bash scripts/validate-index.sh` 必须 exit 0（正向）；再把 `plugins.json` 改一个字节，同一命令必须非 0（篡改反例），随后恢复原文。
4. **同批提交推送**：内容与新的 `.sig` 放进**同一个提交**，先 `git push origin main`（Gitea 权威源），再推 `github` / `gitee` 镜像。只推内容不推 `.sig`，main 上的全量验签会直接红。

### 三条硬规则

- **内容改动必须同批重签**：`plugins.json` 任何字节变化都让旧 `.sig` 失效。不存在"先合并、下次补签"——`push main` 的全量验签会立刻红，而未签索引在 kore 侧一律 401。
- **公钥变更必须与 kore 内核同批发布**：公钥是内核里的编译期常量，旧 `kored` 验新签名 → 商店**全部 401**，恢复只能重新编译并重启内核。公钥副本必须逐字一致（见下）。
- **回滚时二进制与索引必须一起回滚**：只回滚索引 = 旧签名对新公钥失配；只回滚二进制 = 旧公钥不认新签名。两者必须在同一发布窗口内一起回到同一个已知良态（步骤见 RUNBOOK §1）。

### 内置公钥与轮换窗口

- **内置公钥（hex）**：`e3a00492b030fe00ccef267390d384c58fa9f651c073c448b8d0a729d58a0e9a`（第 36 把）。三处必须逐字一致：本仓 `scripts/validate-index.sh` 的 `PUB_HEX`、kore 内核 `internal/core/market/verify.go` 的 `IndexPublicKeyHex`、以及当前 `index/plugins.json.sig` 的签发密钥。
- **轮换兼容窗口**（提案 §2 M2-B）：新公钥上线后必须保留**旧公钥验签能力一个发布周期**，确保轮换前已签发的索引在窗口内仍可验；窗口内新旧公钥并存，窗口结束才移除旧公钥并记 ADR。单版本公钥、无兼容窗口 = 断供死法（pre-mortem S-01）。**当前实现是内核内单个公钥常量（尚无多公钥并存机制）**，因此在多公钥验签落地前，轮换只能「同批改常量 + 重签 + 重启」，否则那段窗口就是验签空窗。
- **禁止信任空窗**：`store.allow_unsigned=true` 只能显式配置并写 WARN 审计，**不得进默认配置**；默认配置出现该开关即为 FAIL。

### 非目标：改成 CI 签发

若未来改为 CI 签发，落点应是 **Gitea Actions** 的 tag / 手动 job + protected environment + 人工审批，**而不是 GitHub 镜像**——GitHub 只是镜像，私钥不进 GitHub。仓库拓扑与权威源口径见 [ADR-0024 §2](https://github.com/kore-pl/kore/blob/main/docs/DECISIONS/0024-repo-topology-and-gitea.md)。

### CI 分层验签（实际实现）

`.github/workflows/ci.yml` 按事件分流，同一 job 内两条互斥步骤：

```yaml
# PR：贡献者无私钥 → 跳过验签，只验 schema / 账本 / 预设（脚本打印「已跳过」）
- name: make check（PR：schema / 账本 / 预设，跳过验签）
  if: "github.event_name == 'pull_request'"
  env:
    KORE_INDEX_SKIP_SIG: "1"
  run: make check

# main / tag：发布侧全量校验，含 ed25519 验签，fail-closed
- name: make check（push main / tag：全量含 ed25519 验签）
  if: "github.event_name != 'pull_request'"
  run: make check
```

`KORE_INDEX_SKIP_SIG=1` 是**唯一**的签名开关，只跳过 ed25519 验签；schema / 字段 / 账本 / 预设引用照常校验，缺 `index/plugins.json.sig` 仍 FAIL。合并前本地验收、发布前复核、`push main` / tag 一律禁止使用（脚本启动会打印当前模式）。

<!-- oss:begin -->
## 开源与贡献

[![CI](https://github.com/kore-pl/kore-plugins/actions/workflows/ci.yml/badge.svg)](https://github.com/kore-pl/kore-plugins/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Go 1.26](https://img.shields.io/badge/Go-1.26-00ADD8?logo=go&logoColor=white)](go.mod)

本仓库是 **kore** 的插件索引仓（`kore-plugins`）：纯静态 `index/plugins.json` + 校验脚本，**不审核、不代管包、无账号、无上传接口**。包体由各插件仓 `make dist` 产出并挂在它们自己的 release 上，这里只记录 `download_url` / `size_bytes` / `sha256`。CI 只在 push main / tag / PR / 手动触发；校验以本地 `make check` 为准。

- **许可**：MIT（inbound = outbound，不要求 CLA）；提交用 `git commit -s` 签 DCO。
- **贡献**：[CONTRIBUTING.md](CONTRIBUTING.md)（索引条目、版本账本、预设、签名、校验）。
- **安全**：[SECURITY.md](SECURITY.md)——索引篡改 / 签名 / 供应链问题不要开公开 issue。
- **行为准则**：[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。
- **索引 schema**：`schema_version=1`；`plugins[]` 每条必填 `id` / `name` / `version` / `depth_level` / `lifecycle` / `size_bytes` / `sha256` / `download_url` / `requires_kore` / `depends_on` / `conflicts` / `scenario_tags`。同一 `id@version` 只允许一个 sha（`index/versions.lock.json` 对账）。
- **校验**：本地 `make check` → `scripts/validate-presets.sh` + `scripts/validate-index.sh`（含 ed25519 验签；CI 少触发，以本地为准）。
- **相关仓库**：[kore](https://github.com/kore-pl/kore) · [协议文档](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-PROTOCOL.md) · [SDK 指南](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-SDK.md)

<!-- oss:end -->
