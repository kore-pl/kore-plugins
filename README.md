# kore-plugins

kore 的**纯静态插件索引仓**：只发布 `index/plugins.json` 与校验脚本，不审核、不代管包、无账号、无服务端。

> 状态: M2 · 归属: M2-B / M5-B · 更新: 2026-11-22

## 发现渠道，不是信任源

索引**只回答"有哪些插件、在哪个版本、包多大、摘要是什么"**，它不证明包可信。安装时由 kore **自算包 sha256** 并与索引声明比对，不符即拒、不落盘。索引被篡改也过不了安装这一关——信任根在 kore 二进制内置的公钥与本地计算结果，不在这个仓。

## 无审核 / 无账号 / 离线可用

- **无审核**：任何人可提 PR 增改条目，合并即发布；使用者自行决定是否安装。
- **无账号**：不收集身份、不要求登录、不隐藏上报（G-10）。
- **离线可用**：`kore` 读本地索引缓存（`paths.index_dir`，默认 `/var/lib/kore/index`），零后台出站；商店只做索引读取 / 验签 / 安装触发，下载留 M2-B 第二批，`POST /store/install` 目前接收本地 tar.gz 路径。

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

`index/plugins.json` 顶层 `schema_version=1`，`plugins[]` 每条含：
`id / name / version / depth_level / lifecycle / size_bytes / sha256 / download_url / requires_kore / depends_on / conflicts / scenario_tags`。

首两条：`echo 0.1.1`（basic，sha256 `eaa34f…4219c`）、`site 0.1.0`（production，sha256 `59b107…520f`），摘要均为对应 `dist/*.tar.gz` 的实测值。

## 场景预设（`presets/`）

8 类预设均为 `schema_version=1` 的 JSON，含 `id / name / description / out_of_box / plugins[]`，每项插件引用 `{id, version, desired}`（`desired` ∈ `enabled|disabled`）。**只引用索引中真实存在的插件 id**——当前仅 `echo 0.1.1`（basic）、`site 0.1.0`（production）；未入索引的 `db` / `security` 类当前以空数组占位，待插件入索引后补充，绝不编造 id。

| 预设 | 用途 |
| --- | --- |
| `minimal` | 不启用任何插件，作为资源基线与故障隔离的干净起点。 |
| `dev` | 仅启用 echo，供协议联调与本地开发冒烟（含 basic，非开箱可用）。 |
| `web-lite` | 仅启用 site，提供最小站点与域名管理能力。 |
| `web-pro` | site 承载站点/反代，echo 默认关闭按需排障（含 basic）。 |
| `db-only` | 预留纯数据库场景；当前索引无 db 插件（db-mysql 在批2），保留占位，待批2 db 插件入索引后补充，不编造 id。 |
| `gateway` | 启用 site 的反向代理能力承担网关角色，不引入额外常驻中间件。 |
| `security` | 预留安全加固场景；security 插件未入索引，当前空置。 |
| `full` | 启用全部已入索引插件（echo + site）用于完整回归（含 basic）。 |

`out_of_box` 标记"开箱可用"：按 G-20，`depth_level=basic` 的插件（echo）所在预设必须为 `false`，校验脚本对此 FAIL 级拦截。

## 校验

```bash
bash scripts/validate-index.sh     # 索引：schema / id 唯一 / sha256 格式 / 验签 / 预设引用
bash scripts/validate-presets.sh   # 预设：id 引用 / 常驻≤3 / 合计 RSS / sha256 / basic 不开箱
make presets-check                  # 等价入口（G-18）
make check                          # 聚合：索引校验 + 预设校验
```

预设合计 RSS：48 MiB 为硬红线（超则 FAIL），24 MiB 与 19.2 MiB 仅记 WARN 不判失败（G-03 / G-18，裁决按 resident 实测中位数求和；本仓用索引 `size_bytes` 作体积代理，可用 `KORE_PRESETS_MEASURED_JSON` 注入实测值覆盖）。反向验证：临时副本注入未知插件 id 或第 4 个常驻插件，脚本必须以 `[FAIL]` 退出（非 0）；把 `plugins.json` 里任一 `sha256` 改一个字符，`make check` 必须以 `[FAIL]` 退出。

## 签名链与轮换（引用提案 0002 §2 M2-B / R2）

索引级 ed25519 签名**前移到 M2**（信任空窗 = 0）：签名对象 = `plugins.json` 文件本体，公钥内置 kore 二进制，未签名索引默认拒绝。

- **内置演示公钥（hex）**：`8f9e4c8585cad9745be7fdcb9c5ecd9137fccd3d45a9c29ded8ccbadb95ec684`。本仓用临时演示密钥签发，私钥不入库；生产须由发布方持有正式密钥并同步更新内核常量。
- **签名**：CI 在 release 流水线注入 `KORE_INDEX_KEY`（私钥 seed hex，仅存 CI secret），执行 `bash scripts/sign-index.sh` 产出 `index/plugins.json.sig`（64 字节 raw 签名），随后发布 `index/`。
- **轮换兼容窗口**（提案 §2 M2-B）：新公钥上线后必须保留**旧公钥验签能力一个发布周期**，确保轮换前已签发的索引在窗口内仍可验；窗口内新旧公钥并存，窗口结束才移除旧公钥并记 ADR。单版本公钥、无兼容窗口 = 断供死法（pre-mortem S-01）。
- **禁止信任空窗**：`store.allow_unsigned=true` 只能显式配置并写 WARN 审计，**不得进默认配置**；默认配置出现该开关即为 FAIL。

## CI 集成说明

```yaml
# GitHub Actions（示意，secret 名 KORE_INDEX_KEY）
- name: Sign index
  env:
    KORE_INDEX_KEY: ${{ secrets.KORE_INDEX_KEY }}
  run: bash scripts/sign-index.sh
- name: Validate index
  run: bash scripts/validate-index.sh
```

私钥只存在于 CI secret，不进仓、不进日志、不进容器镜像。
