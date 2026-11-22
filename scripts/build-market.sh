#!/usr/bin/env bash
# 构建静态市场页数据：把 index/plugins.json 收敛为 market/plugins.js（window.KORE_PLUGINS）。
# 零框架 / 零 npm / 零网络：仅用 python3 标准库，页面引用本地脚本，file:// 断网可开。
# 只白名单六个显示字段，download_url 等外链不进生成物（grep 无 http 外链）。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$ROOT/index/plugins.json"
OUT_DIR="$ROOT/market"
OUT="$OUT_DIR/plugins.js"

fail() { echo "[FAIL] $*" >&2; exit 1; }
ok() { echo "[OK] $*"; }

[ -f "$INDEX" ] || fail "缺少 $INDEX"
command -v python3 >/dev/null 2>&1 || fail "缺少 python3（本脚本仅依赖 python3 标准库）"

mkdir -p "$OUT_DIR"

# 生成 + 校验：内嵌数据可解析、数组非空、字段齐全、description 非空、无外链。
python3 - "$INDEX" "$OUT" <<'PY'
import json
import re
import sys

src, out = sys.argv[1], sys.argv[2]
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

ok "静态市场数据构建完成"
