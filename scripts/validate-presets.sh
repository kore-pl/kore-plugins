#!/usr/bin/env bash
# 校验 8 类场景预设：schema / id 唯一 / 插件引用可解析 / sha256 格式 /
# 常驻数 ≤3 / 合计 RSS ≤48 MiB 红线（24 与 19.2 MiB 仅 WARN）/ basic 不得开箱可用。
# 零第三方依赖：Python3 标准库。KORE_PRESETS_MEASURED_JSON 可注入实测 RSS 覆盖体积代理。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$ROOT/index/plugins.json"
PRESETS="${KORE_PRESETS_DIR:-$ROOT/presets}"

fail() { echo "[FAIL] $*" >&2; exit 1; }

[ -f "$INDEX" ] || fail "缺少 $INDEX"
[ -d "$PRESETS" ] || fail "缺少预设目录 $PRESETS"
command -v python3 >/dev/null 2>&1 || fail "缺少 python3"

python3 - "$INDEX" "$PRESETS" "${KORE_PRESETS_MEASURED_JSON:-}" <<'PY'
import json, os, re, sys

index_path, presets_dir, measured_path = sys.argv[1:]
errors = []
warns = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warns.append(msg)


# ---- 索引侧 ----
try:
    index = json.load(open(index_path, encoding="utf-8"))
except Exception as exc:
    sys.exit(f"[FAIL] 索引 JSON 解析失败: {exc}")

plugins = {p["id"]: p for p in index.get("plugins", [])}
by_id = {}
for p in index.get("plugins", []):
    if p["id"] in by_id:
        err(f"索引 id 重复: {p['id']}")
    by_id[p["id"]] = p

for pid, p in by_id.items():
    if not re.fullmatch(r"[0-9a-f]{64}", p.get("sha256", "")):
        err(f"索引 {pid}.sha256 非 64 位小写 hex")

# 实测 RSS（KiB）覆盖体积代理：{plugin_id: KiB}，仅用于合计口径。
measured = {}
if measured_path:
    try:
        measured = json.load(open(measured_path, encoding="utf-8"))
    except Exception as exc:
        sys.exit(f"[FAIL] 实测 RSS 文件解析失败: {exc}")

RESIDENT_KINDS = {"resident", "lazy-active"}
ACTIVE_LAZY = {"lazy-active", "lazy"}
RED_LINE_KIB = 48 * 1024          # 49152 KiB，硬红线 FAIL
TARGET_KIB = 24 * 1024            # 24576 KiB，目标 WARN
EARLY_TARGET_KIB = int(24 * 1024 * 0.8)  # 19660 KiB（19.2 MiB）目标 WARN

EXPECTED = {"minimal", "web-lite", "web-pro", "db-only", "gateway",
            "security", "dev", "full"}

seen_ids = set()
for name in sorted(os.listdir(presets_dir)):
    if not name.endswith(".json"):
        continue
    path = os.path.join(presets_dir, name)
    try:
        d = json.load(open(path, encoding="utf-8"))
    except Exception as exc:
        err(f"{name}: JSON 解析失败: {exc}")
        continue

    if d.get("schema_version") != 1:
        err(f"{name}: schema_version 必须为 1")
    pid = d.get("id", "")
    if not re.fullmatch(r"[a-z][a-z0-9-]*", pid):
        err(f"{name}: id 非法: {pid}")
    if pid in seen_ids:
        err(f"{name}: id 重复: {pid}")
    seen_ids.add(pid)
    if not isinstance(d.get("name"), str) or not d["name"]:
        err(f"{name}: name 缺失")
    if not isinstance(d.get("description"), str) or not d["description"]:
        err(f"{name}: description 缺失")
    if not isinstance(d.get("plugins"), list):
        err(f"{name}: plugins 必须是数组")
        continue

    resident = 0
    total_kib = 0
    basic_enabled = []
    for i, ref in enumerate(d["plugins"]):
        if not isinstance(ref, dict):
            err(f"{name}.plugins[{i}] 必须是对象")
            continue
        rid = ref.get("id", "")
        if rid not in plugins:
            err(f"{name}.plugins[{i}] 引用未知插件 id: {rid}")
            continue
        p = plugins[rid]
        want_ver = str(ref.get("version", ""))
        if want_ver != str(p["version"]):
            err(f"{name}.plugins[{i}] 版本 {want_ver} 与索引 {rid}={p['version']} 不一致")
        desired = ref.get("desired")
        if desired not in ("enabled", "disabled"):
            err(f"{name}.plugins[{i}] desired 非法: {desired}")
            continue
        lifecycle = p["lifecycle"]
        if desired == "enabled":
            if lifecycle in RESIDENT_KINDS:
                resident += 1
            if p["depth_level"] == "basic":
                basic_enabled.append(rid)
            # 体积代理：实测覆盖优先，否则用索引 size_bytes（字节→KiB）。
            kib = measured.get(rid, p["size_bytes"] / 1024.0)
            total_kib += kib
        elif lifecycle in ACTIVE_LAZY and p["depth_level"] == "basic":
            # disabled 态不占槽，也不需要开箱校验，仅记录。
            pass

    if resident > 3:
        err(f"{name}: 同时常驻 {resident} > 3")
    if basic_enabled and d.get("out_of_box") is True:
        err(f"{name}: 含 basic 插件 {basic_enabled} 却标记 out_of_box=true（G-20）")

    total_mib = total_kib / 1024.0
    if total_kib > RED_LINE_KIB:
        err(f"{name}: 合计 RSS {total_mib:.2f} MiB > 48 MiB 红线")
    elif total_kib > TARGET_KIB:
        warn(f"{name}: 合计 RSS {total_mib:.2f} MiB 超目标 24 MiB（红线内，记趋势）")
    elif total_kib > EARLY_TARGET_KIB:
        warn(f"{name}: 合计 RSS {total_mib:.2f} MiB 超目标 19.2 MiB（红线内，记趋势）")
    print(f"[OK] {name}: 常驻 {resident}/3, 合计 {total_mib:.2f} MiB (体积代理; 红线 48 / 目标 24)")

missing = EXPECTED - seen_ids
if missing:
    err(f"缺少预设: {sorted(missing)}")
extra = seen_ids - EXPECTED
if extra:
    err(f"多余预设: {sorted(extra)}")

for w in warns:
    print(f"[WARN] {w}")
if errors:
    for e in errors:
        print(f"[FAIL] {e}", file=sys.stderr)
    sys.exit(1)
print(f"[OK] 校验通过：{len(seen_ids)} 个预设 / {len(plugins)} 个索引插件 / 0 FAIL / {len(warns)} WARN")
PY
