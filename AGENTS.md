# AGENTS — 本仓给 AI / agent 贡献者的约定

- 只改本仓（`kore-plugins`，kore 的纯静态索引仓）；插件实现与内核不在本仓改。
- 协议与门禁以 `kore` 仓为准：[docs/PLUGIN-PROTOCOL.md](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-PROTOCOL.md)、[docs/PLUGIN-SDK.md](https://github.com/kore-pl/kore/blob/main/docs/PLUGIN-SDK.md)、[AGENTS.md](https://github.com/kore-pl/kore/blob/main/AGENTS.md)。
- 校验命令：`make check`（`scripts/validate-presets.sh` + `scripts/validate-index.sh`）；改索引后重跑 `bash scripts/sign-index.sh` 与 `bash scripts/build-market.sh`。
- 索引条目值必须来自插件仓产物：`version` / `sha256` / `size_bytes` / `download_url` 逐字一致，不手写猜测。
- `versions.lock.json` 只追加，不删历史；同一 `id@version` 只允许一个 sha，改包必须 bump。
- 预设引用的 id / 版本必须能在索引解析；`basic` 插件不得标"开箱可用"。
- 精确 `git add <file>`，禁止 `git add .`；提交用 `git commit -s` 签 DCO；格式 `type(scope): 中文描述`。
- 安全与凭据：漏洞走 [SECURITY.md](SECURITY.md)，不开公开 issue；不写明文私钥 / token，私钥由发布方持有、不进仓。
