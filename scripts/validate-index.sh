#!/usr/bin/env bash
# 校验静态索引仓：schema / id 唯一 / sha256 格式 / ed25519 签名 / 预设引用。
# 零第三方依赖：Python3 标准库 + openssl（系统自带）。私钥不参与校验。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$ROOT/index/plugins.json"
SIG="$ROOT/index/plugins.json.sig"
# 内置演示公钥（hex，32 字节）。生产应由内核二进制内置同一把公钥。
PUB_HEX="8f9e4c8585cad9745be7fdcb9c5ecd9137fccd3d45a9c29ded8ccbadb95ec684"
PUB_DER="$ROOT/.validate-pub.der"
trap 'rm -f "$PUB_DER"' EXIT

fail() { echo "[FAIL] $*" >&2; exit 1; }
ok() { echo "[OK] $*"; }

[ -f "$INDEX" ] || fail "缺少 $INDEX"
[ -f "$SIG" ] || fail "缺少 $SIG"
command -v python3 >/dev/null 2>&1 || fail "缺少 python3"
command -v openssl >/dev/null 2>&1 || fail "缺少 openssl"

# 1) schema + id 唯一 + sha256 64 位 hex + 必填字段 + 预设引用可解析。
python3 - "$INDEX" "$ROOT/presets" <<'PY'
import json, os, re, sys
p, presets = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(p, encoding="utf-8"))
except Exception as e:
    sys.exit(f"[FAIL] JSON 解析失败: {e}")
if data.get("schema_version") != 1:
    sys.exit("[FAIL] schema_version 必须为 1")
plugins = data.get("plugins")
if not isinstance(plugins, list) or not plugins:
    sys.exit("[FAIL] plugins 必须是非空数组")
required = ("id", "name", "version", "depth_level", "lifecycle", "size_bytes",
            "sha256", "download_url", "requires_kore", "depends_on",
            "conflicts", "scenario_tags")
ids = set()
for i, item in enumerate(plugins):
    for k in required:
        if k not in item:
            sys.exit(f"[FAIL] plugins[{i}] 缺字段 {k}")
    pid = item["id"]
    if not re.fullmatch(r"[a-z][a-z0-9-]*", pid):
        sys.exit(f"[FAIL] plugins[{i}].id 非法: {pid}")
    if pid in ids:
        sys.exit(f"[FAIL] id 重复: {pid}")
    ids.add(pid)
    if not re.fullmatch(r"[0-9a-f]{64}", item["sha256"]):
        sys.exit(f"[FAIL] {pid}.sha256 非 64 位小写 hex: {item['sha256']}")
    if not isinstance(item["size_bytes"], int) or item["size_bytes"] < 0:
        sys.exit(f"[FAIL] {pid}.size_bytes 非法")
    if item["depth_level"] not in ("production", "basic"):
        sys.exit(f"[FAIL] {pid}.depth_level 非法")
    if item["lifecycle"] not in ("resident", "lazy", "oneshot"):
        sys.exit(f"[FAIL] {pid}.lifecycle 非法")
print("[OK] schema / 必填字段 / id 唯一 / sha256 格式通过（%d 条）" % len(plugins))
# 预设引用可解析：presets/ 为空时视为占位通过；存在 JSON 时逐条解析。
checked = 0
if os.path.isdir(presets):
    for name in sorted(os.listdir(presets)):
        if not name.endswith(".json"):
            continue
        d = json.load(open(os.path.join(presets, name), encoding="utf-8"))
        for ref in d.get("plugins", []):
            rid = ref["id"] if isinstance(ref, dict) else ref
            if rid not in ids:
                sys.exit(f"[FAIL] preset {name} 引用未知插件 id: {rid}")
            checked += 1
print(f"[OK] 预设引用可解析（占位/已校验 {checked} 条引用）")
PY

# 2) ed25519 验签：用内置公钥 hex 重建 DER 公钥，验 .sig 对索引本体有效。
python3 - "$PUB_HEX" "$PUB_DER" <<'PY'
import sys
h, out = sys.argv[1], sys.argv[2]
h = h.strip().lower()
if len(h) != 64 or any(c not in "0123456789abcdef" for c in h):
    sys.exit("[FAIL] 内置公钥 hex 非法")
# SubjectPublicKeyInfo: 30 2a 30 05 06 03 2b 65 70 03 21 00 <32B>
der = bytes.fromhex("302a300506032b6570032100" + h)
open(out, "wb").write(der)
PY
if openssl pkeyutl -verify -pubin -inkey "$PUB_DER" -rawin \
    -in "$INDEX" -sigfile "$SIG" >/dev/null 2>&1; then
  ok "ed25519 签名验证通过（内置公钥）"
else
  fail "ed25519 签名验证失败（索引被篡改或签名不匹配）"
fi

ok "索引校验全部通过"
