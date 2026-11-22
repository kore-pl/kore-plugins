#!/usr/bin/env bash
# 校验静态索引仓：schema / id 唯一 / sha256 格式 / ed25519 签名 / 预设引用。
# 零第三方依赖：Python3 标准库 + openssl（系统自带）。私钥不参与校验。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$ROOT/index/plugins.json"
SIG="$ROOT/index/plugins.json.sig"
# 内置演示公钥（hex，32 字节）。生产应由内核二进制内置同一把公钥。
PUB_HEX="7aa1c96734b46546905ed1558a8ac18a12267044208811c2ef71ac7bef285fea"
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

# 1b) 版本单调递增 + 同版本 sha 唯一：对照 index/versions.lock.json 基线。
#     基线不是信任源（信任根是 plugins.json 的 ed25519 签名），而是发版流程的"版本→sha 账本"：
#     同 id@version 换 sha、版本回退/跳版、两个版本同 sha，都会在这里被拒绝。
lock_path = os.path.join(os.path.dirname(p), "versions.lock.json")
if not os.path.isfile(lock_path):
    sys.exit("[FAIL] 缺少版本基线 %s（每次发版必须追加新版本与 sha）" % lock_path)
try:
    lock = json.load(open(lock_path, encoding="utf-8"))
except Exception as e:
    sys.exit("[FAIL] versions.lock.json 解析失败: %s" % e)
if lock.get("schema_version") != 1 or not isinstance(lock.get("plugins"), dict):
    sys.exit("[FAIL] versions.lock.json schema 非法")
def ver_tuple(v):
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", v or ""):
        return None
    return tuple(int(x) for x in v.split("."))
seen = set()
for item in plugins:
    key = item["id"] + "@" + item["version"]
    if key in seen:
        sys.exit("[FAIL] 同一 id@version 出现多次: %s" % key)
    seen.add(key)
    hist = lock["plugins"].get(item["id"])
    if not isinstance(hist, list) or not hist:
        sys.exit("[FAIL] 基线缺少 %s 的版本历史" % item["id"])
    versions, shas = [], set()
    for h in hist:
        hv, hs = str(h.get("version", "")), str(h.get("sha256", ""))
        if ver_tuple(hv) is None:
            sys.exit("[FAIL] 基线 %s 版本非法: %r" % (item["id"], hv))
        if not re.fullmatch(r"[0-9a-f]{64}", hs):
            sys.exit("[FAIL] 基线 %s@%s sha256 非法" % (item["id"], hv))
        if hv in versions:
            sys.exit("[FAIL] 基线 %s 版本重复: %s" % (item["id"], hv))
        if hs in shas:
            sys.exit("[FAIL] %s 两个版本共用同一 sha（说明改了包却没 bump）: %s" % (item["id"], hs))
        versions.append(hv); shas.add(hs)
    if [ver_tuple(v) for v in versions] != sorted(ver_tuple(v) for v in versions):
        sys.exit("[FAIL] 基线 %s 版本非严格递增: %s" % (item["id"], versions))
    last = hist[-1]
    if item["version"] != last["version"] or item["sha256"] != last["sha256"]:
        sys.exit("[FAIL] 索引 %s@%s sha=%s 与基线最新 %s@%s sha=%s 不一致："
                 "改包必须 bump 版本并追加基线，禁止同版本换 sha"
                 % (item["id"], item["version"], item["sha256"][:12],
                    item["id"], last["version"], last["sha256"][:12]))
print("[OK] 版本单调递增 / 同 id@version 唯一 sha 校验通过（基线 %d 条）" % len(lock["plugins"]))

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
