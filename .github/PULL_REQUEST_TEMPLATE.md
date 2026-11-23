## 变更说明

<!-- 改了哪个索引条目 / 预设，为什么。签名由维护者合入时统一重签，不用写在这里。 -->

## 影响面

- [ ] `index/plugins.json`（条目新增 / 版本更新 / sha256 变更）
- [ ] `index/versions.lock.json`（追加版本账本）
- [ ] `presets/*.json`（固定版本 / 开箱标记）
- [ ] `market/plugins.js`（市场页数据重建）
- [ ] 校验脚本（`scripts/`）
- [ ] 文档

## 验证

```text
命令: KORE_INDEX_SKIP_SIG=1 make check
退出码: 0
输出: （粘贴关键输出）
```

- [ ] 已贴 `KORE_INDEX_SKIP_SIG=1 make check` 命令原文 + 退出码（PR 侧只验 schema / 版本账本 / 预设引用，不验签）
- [ ] 已核对 schema / 版本账本 / 预设引用
- [ ] 反向验证：故意改坏 sha256 / 注入未知 id / 第 4 个常驻插件时 `make check` 以非 0 退出
- [ ] 包 `sha256` / `size_bytes` 来自插件仓 `dist/*.sha256` 与包体实际字节数，非手抄
- [ ] `download_url` 指向对应 tag 的 release 资产且文件名与 dist 产物一致

## 版本与账本

- [ ] `index/versions.lock.json` 已追加 `{version, sha256}`，未删改历史
- [ ] 同一 `id@version` 只对应一个 sha；改包已 bump 版本
- [ ] `presets/*.json` 中该插件的固定版本已同步

## 签名

- 签名由维护者合入时统一重签；**贡献者不提供 `.sig`、不修改 `.sig`**（私钥在发布方发布机，本仓与 CI 都不持有）。
- [ ] 已确认本次 PR 未改 `index/plugins.json.sig`
- [ ] 公钥轮换时保留旧公钥验签窗口，并记 ADR（由维护者在发布分支执行）

## 关联 issue

<!-- Closes #编号 -->

## 安全影响

<!-- 是否新增外链、外部请求、放宽校验；没有就写"无"。 -->
