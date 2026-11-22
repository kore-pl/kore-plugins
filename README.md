# kore-plugins

kore 的**纯静态插件索引仓**：只发布 `index/plugins.json` 与校验脚本，不审核、不代管包、无账号、无服务端。

> 状态: M2 · 归属: M2-B · 更新: 2026-11-22

## 发现渠道，不是信任源

索引**只回答"有哪些插件、在哪个版本、包多大、摘要是什么"**，它不证明包可信。安装时由 kore **自算包 sha256** 并与索引声明比对，不符即拒、不落盘。索引被篡改也过不了安装这一关——信任根在 kore 二进制内置的公钥与本地计算结果，不在这个仓。

## 无审核 / 无账号 / 离线可用

- **无审核**：任何人可提 PR 增改条目，合并即发布；使用者自行决定是否安装。
- **无账号**：不收集身份、不要求登录、不隐藏上报（G-10）。
- **离线可用**：`kore` 读本地索引缓存（`paths.index_dir`，默认 `/var/lib/kore/index`），零后台出站；商店只做索引读取 / 验签 / 安装触发，下载留 M2-B 第二批，`POST /store/install` 目前接收本地 tar.gz 路径。

## 索引格式

`index/plugins.json` 顶层 `schema_version=1`，`plugins[]` 每条含：
`id / name / version / depth_level / lifecycle / size_bytes / sha256 / download_url / requires_kore / depends_on / conflicts / scenario_tags`。

首两条：`echo 0.1.1`（basic，sha256 `eaa34f…4219c`）、`site 0.1.0`（production，sha256 `59b107…520f`），摘要均为对应 `dist/*.tar.gz` 的实测值。

## 校验

```bash
bash scripts/validate-index.sh     # schema / id 唯一 / sha256 格式 / 验签 / 预设引用
make check                          # 等价入口
```

反向验证：把 `plugins.json` 里任一 `sha256` 改一个字符，脚本必须以 `[FAIL]` 退出（非 0）。

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
