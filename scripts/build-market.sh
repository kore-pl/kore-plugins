#!/usr/bin/env bash
# 构建静态市场页数据：把 index/plugins.json 收敛为 market/plugins.js（window.KORE_PLUGINS）。
# 零框架 / 零 npm / 零网络：仅用 python3 标准库，页面引用本地脚本，file:// 断网可开。
# 只白名单六个显示字段，download_url 等外链不进生成物（grep 无 http 外链）。
#
# 两种模式：
#   无参数     生成并写入 market/plugins.js（发版第 8 步 / 改完索引后必跑）
#   --check    只读比对：断言现有 market/plugins.js 与当前 index/plugins.json 生成的期望内容
#              **逐字节一致**，不一致 exit 1 并列出 market↔index 的版本差异。不写任何文件。
#              validate-index.sh 第 1c 步调用它，防止「改了索引没重建市场页」。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$ROOT/index/plugins.json"
OUT_DIR="$ROOT/market"
OUT="$OUT_DIR/plugins.js"

fail() { echo "[FAIL] $*" >&2; exit 1; }
ok() { echo "[OK] $*"; }

MODE="write"
case "${1:-}" in
  "") MODE="write" ;;
  --check) MODE="check" ;;
  *) fail "未知参数：$1（只接受 --check 或不带参数）" ;;
esac

[ -f "$INDEX" ] || fail "缺少 $INDEX"
command -v python3 >/dev/null 2>&1 || fail "缺少 python3（本脚本仅依赖 python3 标准库）"

# --check 是只读门禁：不得创建目录/改文件（否则门禁会自己"修好"再判过）。
if [ "$MODE" = "write" ]; then
  mkdir -p "$OUT_DIR"
fi

# 生成 + 校验：内嵌数据可解析、数组非空、字段齐全、description 非空、无外链。
# --check：只读比对（不写文件），断言现有生成物 == 当前索引的期望内容，逐字节一致。
python3 - "$INDEX" "$OUT" "$MODE" <<'PY'
import json
import re
import sys

src, out = sys.argv[1], sys.argv[2]
mode = sys.argv[3]
try:
    with open(src, encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    sys.exit(f"[FAIL] index/plugins.json 解析失败: {e}")

plugins = data.get("plugins")
if not isinstance(plugins, list) or not plugins:
    sys.exit("[FAIL] plugins 必须是非空数组")

FIELDS = ("id", "name", "version", "depth_level", "description", "scenario_tags")
rows = []
for i, p in enumerate(plugins):
    # description 不在索引 schema 中：缺失时由 name + 场景标签生成中性摘要，不编造能力。
    desc = p.get("description")
    if not isinstance(desc, str) or not desc.strip():
        tags = p.get("scenario_tags") or []
        tag_text = " / ".join(tags) if isinstance(tags, list) and tags else "通用"
        desc = f"{p.get('name', p.get('id', ''))}（场景：{tag_text}）。详情见对应插件仓库。"
    tags = p.get("scenario_tags")
    if not isinstance(tags, list):
        tags = []
    row = {
        "id": str(p.get("id", "")),
        "name": str(p.get("name", "")),
        "version": str(p.get("version", "")),
        "depth_level": str(p.get("depth_level", "")),
        "description": desc.strip(),
        "scenario_tags": [str(t) for t in tags],
    }
    for key in ("id", "name", "version", "depth_level"):
        if not row[key]:
            sys.exit(f"[FAIL] plugins[{i}].{key} 为空")
    if row["depth_level"] not in ("production", "basic"):
        sys.exit(f"[FAIL] plugins[{i}].depth_level 非法: {row['depth_level']}")
    rows.append(row)

ids = [r["id"] for r in rows]
if len(ids) != len(set(ids)):
    sys.exit("[FAIL] id 重复")

# 生成物：window.KORE_PLUGINS = [...]; 仅显示字段，不含外链。
payload = json.dumps(rows, ensure_ascii=False, separators=(",", ":"))
content = "// 由 scripts/build-market.sh 自动生成，请勿手改。\n" \
          "window.KORE_PLUGINS = " + payload + ";\n"

if mode == "check":
    # 只读门禁：不写文件。生成器是确定性的（同索引 → 同字节），故用 byte 级比对。
    try:
        with open(out, encoding="utf-8") as f:
            existing = f.read()
    except FileNotFoundError:
        sys.exit("[FAIL] 缺少 %s：改了 index 必须同轮重建市场页（bash scripts/build-market.sh）"
                 % out)
    if existing != content:
        # 定位差异：直接列出 market 与 index 的 id/version，症状即"商店页显示旧版本"。
        old_rows = []
        try:
            m_old = re.search(r"window\.KORE_PLUGINS\s*=\s*(\[.*\])\s*;", existing, re.S)
            if m_old:
                old_rows = json.loads(m_old.group(1))
        except Exception:
            old_rows = []
        old_map = {r.get("id"): r.get("version") for r in old_rows if isinstance(r, dict)}
        new_map = {r["id"]: r["version"] for r in rows}
        drift = ["  %s: market=%s index=%s"
                 % (pid, old_map.get(pid, "<缺>"), new_map.get(pid, "<缺>"))
                 for pid in sorted(set(old_map) | set(new_map))
                 if old_map.get(pid) != new_map.get(pid)]
        sys.exit("[FAIL] market/plugins.js 与 index/plugins.json 不一致"
                 "（改了索引却没同轮重建市场页）：\n"
                 + ("\n".join(drift[:10]) if drift else "  （内容差异，非版本差异）")
                 + "\n修复：bash scripts/build-market.sh，并与索引同一提交提交")
    print("[OK] market/plugins.js 与索引逐字节一致（%d 个插件）" % len(rows))
    sys.exit(0)

with open(out, "w", encoding="utf-8") as f:
    f.write(content)

# 回读生成文件：非空、可解析、条数一致。
with open(out, encoding="utf-8") as f:
    written = f.read()
if not written.strip():
    sys.exit("[FAIL] 生成文件为空")
m = re.search(r"window\.KORE_PLUGINS\s*=\s*(\[.*\])\s*;", written, re.S)
if not m:
    sys.exit("[FAIL] 生成文件缺少 window.KORE_PLUGINS 赋值")
try:
    parsed = json.loads(m.group(1))
except Exception as e:
    sys.exit(f"[FAIL] 内嵌 JSON 解析失败: {e}")
if len(parsed) != len(rows):
    sys.exit("[FAIL] 回读条数不一致")
if any(c not in r for r in parsed for c in FIELDS):
    sys.exit("[FAIL] 回读缺显示字段")
if re.search(r"https?://|cdn\.|<script", written, re.I):
    sys.exit("[FAIL] 生成物含外链或额外 script 标签")

print(f"[OK] 生成 {out}：{len(parsed)} 个插件（{len(written)} 字节），六字段齐全、无外链")
PY

# --check 模式的结果行已由 python 打印（含差异明细），这里不再重复。
[ "$MODE" = "check" ] || ok "静态市场数据构建完成"
