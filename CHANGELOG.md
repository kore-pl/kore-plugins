# Changelog

## 0.1.0 — 2026-11-22

- 新增 `index/plugins.json`（schema_version=1）：echo 0.1.1 / site 0.1.0，摘要为实测 sha256。
- 新增索引级 ed25519 签名 `index/plugins.json.sig`（演示密钥，私钥不入库）。
- 新增 `scripts/validate-index.sh`：schema / id 唯一 / sha256 格式 / 验签 / 预设引用校验。
- 新增 `scripts/sign-index.sh`：CI 通过 `KORE_INDEX_KEY` 环境变量签发索引。
- 新增 README / Makefile / LICENSE（MIT）。
- 索引同步（未重签）：db-mysql 方法名域修正后 dist 变更，sha256/size_bytes 更新为 `94b40647…` / 1483657；同批 app-deploy、db-postgres、runtime-node、runtime-php、runtime-python 各自 dist 摘要更新。`index/plugins.json.sig` 仍为旧签名，待下一轮统一重签。
