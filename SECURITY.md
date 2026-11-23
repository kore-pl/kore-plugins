# 安全漏洞披露

本文件是**本索引仓（`kore-plugins`，即 kore 的插件索引仓）的漏洞披露流程**，不是安全设计文档。

## 范围

覆盖：`index/plugins.json` 与其签名 `index/plugins.json.sig`、`index/versions.lock.json`、`presets/*.json`、`market/` 静态页与 `scripts/` 校验脚本。

不覆盖：内核与协议问题——请按 [kore SECURITY.md](https://github.com/kore-pl/kore/blob/main/SECURITY.md) 报告；单个插件实现的问题请报到对应 `kore-plugin-<id>` 仓；上游依赖的已知漏洞请同时反馈上游。

## 支持版本

| 版本 | 支持状态 | 说明 |
| --- | --- | --- |
| 当前 `main` | ✅ 接收并修复 | 索引滚动发布，只保证最新提交获得修复 |
| 历史 commit / 快照 | ❌ 不支持 | 发现旧快照有问题请先确认 `main` 是否仍存在 |

## 本仓攻击面

- **索引篡改**：改 `sha256` / `download_url` / `version` 指向恶意包。防线是安装时由 `kore` 本地复算 sha256 并比对；索引本身不证明包可信。
- **签名链**：`plugins.json.sig` 是 ed25519 签名（64 字节 raw），公钥内置 `kore` 二进制。私钥泄露、签名重放、替换公钥都属高危；**私钥由发布方持有**（发布机 / 发布时的临时密钥），**不入库、不进 GitHub CI secret**。**CI 只验签、不签名**——`push main` / tag 全量验签，PR 只验 schema（`KORE_INDEX_SKIP_SIG=1`，因为贡献者无私钥）。若未来改为 CI 签发，落点应是 **Gitea Actions** 的 tag / 手动 job + protected environment + 人工审批，而不是 GitHub 镜像。
- **供应链**：`download_url` 指向的 release 资产、插件仓的构建环境与发布权限。索引与插件仓任一被接管都会影响安装链路。
- **校验脚本**：`scripts/validate-index.sh` / `scripts/validate-presets.sh` 是合并前门禁，放宽校验或吞掉 FAIL 等于移除防线。
- **静态市场页**：`market/index.html` 必须断网可开、无 CDN、无 http(s) 外链；引入任何外部请求都属回归。

## 报告

1. **优先 GitHub Security Advisory**：本仓 Security 页 → "Report a vulnerability"（私密渠道，不产生公开 issue）。
2. **备用邮箱**：`pengtang1024@users.noreply.github.com`，主题 `[kore security] kore-plugins`。
3. **不要开公开 issue、不要在讨论区或 PR 里贴可利用细节。**
4. 报告请包含：受影响的文件 / commit、复现步骤、影响面（能否导致安装恶意包）、是否已公开、署名偏好。

## 时限与披露

- **72 小时内**确认收到并给初判；复杂问题同步排查计划。
- 修复后协调披露，默认 **90 天**窗口；若已被实际利用需要提前披露，请先沟通。
- 修复发布后在 `CHANGELOG.md` 记安全修复（不写利用细节），并按需轮换签名密钥与公钥。

## 致谢

在获得同意后于发布说明中致谢；不希望具名的按匿名处理。
