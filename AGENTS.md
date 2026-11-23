# AGENTS — 本仓给 AI / agent 贡献者的约定

- 只改本仓（`kore-plugins`，kore 的纯静态索引仓）；插件实现与内核不在本仓改。
- 协议与门禁以 `kore` 仓为准：[docs/PLUGIN-PROTOCOL.md](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-PROTOCOL.md)、[docs/PLUGIN-SDK.md](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-SDK.md)、[AGENTS.md](https://github.com/kore-pl/kore/blob/main/AGENTS.md)。
- 校验命令：`KORE_INDEX_SKIP_SIG=1 make check`（PR 侧只验 schema / 版本账本 / 预设引用）；改索引后由维护者重签（`bash scripts/sign-index.sh`，私钥在发布方发布机，不入库、不进 CI secret），贡献者不提供 `.sig`；市场页数据 `bash scripts/build-market.sh`。
- 索引条目值必须来自插件仓产物：`version` / `sha256` / `size_bytes` / `download_url` 逐字一致，不手写猜测。
- `versions.lock.json` 只追加，不删历史；同一 `id@version` 只允许一个 sha，改包必须 bump。
- 预设引用的 id / 版本必须能在索引解析；`basic` 插件不得标"开箱可用"。
- 精确 `git add <file>`，禁止 `git add .`；提交用 `git commit -s` 签 DCO；格式 `type(scope): 中文描述`。
- 安全与凭据：漏洞走 [SECURITY.md](SECURITY.md)，不开公开 issue；不写明文私钥 / token，私钥由发布方持有、不进仓。
