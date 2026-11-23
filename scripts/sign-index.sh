#!/usr/bin/env bash
# 用**长期 ed25519 私钥**签 index/plugins.json → .sig（ADR-0025 方案 A）。
#
# 设计（2026-11-23）：
#   - 公钥是编译期常量（kore/internal/core/market/verify.go IndexPublicKeyHex），**永不随重签变化**；
#   - 私钥托管在仓库外：$KORE_SIGNING_KEY 指定的文件，缺省 ~/.config/kore/signing/index-signing.seed；
#     目录 0700、文件 0600、32 字节 seed 的 hex（64 字符）；
#   - 缺失私钥时**报错退出（码 2）并指向 docs/SIGNING-KEY-SOP.md**——绝不静默生成新钥
#     （那正是 39 次重建/重启事故链的起点）；
#   - 首次播种显式 --generate（只创建一次，拒绝覆盖），打印对应公钥供 verify.go 固定。
#
# 执行者 = 发布方（维护者），在自己的发布机上跑：签名是发布动作，不是 CI 动作。
# 私钥的值绝不入库、绝不进 CI secret、绝不进日志。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$ROOT/index/plugins.json"
SIG="$ROOT/index/plugins.json.sig"
DEFAULT_KEY="${HOME}/.config/kore/signing/index-signing.seed"
KEY_PATH="${KORE_SIGNING_KEY:-$DEFAULT_KEY}"
SOP_URL="docs/SIGNING-KEY-SOP.md"

fail() { echo "[FAIL] $*" >&2; exit "${2:-1}"; }

# --generate：首次播种（仓库外默认位置；显式指定 KORE_SIGNING_KEY 时写到该路径）
if [ "${1:-}" = "--generate" ]; then
  mkdir -p "$(dirname "$KEY_PATH")"
  chmod 0700 "$(dirname "$KEY_PATH")"
  [ -e "$KEY_PATH" ] && fail "私钥已存在，拒绝覆盖：$KEY_PATH（轮换见 $SOP_URL §4）" 3
  umask 077
  openssl rand -hex 32 > "$KEY_PATH"
  chmod 0600 "$KEY_PATH"
  PUB_HEX="$(openssl pkey -inform DER -in <(printf '%s' "302e020100300506032b657004220420$(tr -d '[:space:]' < "$KEY_PATH")" | xxd -r -p) -pubout -outform DER 2>/dev/null | tail -c 32 | xxd -p -c 64)"
  echo "[OK] 已生成长期签名私钥：$KEY_PATH（0600）"
  echo "[OK] 对应公钥（写入 kore/internal/core/market/verify.go 的 IndexPublicKeyHex）：$PUB_HEX"
  echo "[INFO] 立即离线备份该文件；备份与恢复见 $SOP_URL §2"
  exit 0
fi

[ -f "$INDEX" ] || fail "缺少 $INDEX"

# 私钥来源：长期密钥文件（优先）→ 兼容 KORE_INDEX_KEY（旧的一次性 seed hex，不生成）
KEY_HEX=""
if [ -n "${KORE_INDEX_KEY:-}" ]; then
  KEY_HEX="$(printf '%s' "$KORE_INDEX_KEY" | tr -d '[:space:]')"
elif [ -f "$KEY_PATH" ]; then
  KEY_HEX="$(tr -d '[:space:]' < "$KEY_PATH")"
else
  echo "[FAIL] 找不到长期签名私钥：$KEY_PATH" >&2
  echo "       首次播种：KORE_SIGNING_KEY=<路径> bash scripts/sign-index.sh --generate" >&2
  echo "       或把 KORE_SIGNING_KEY 指向既有私钥；完整流程见 $SOP_URL" >&2
  echo "       已拒绝：本脚本不再静默生成新密钥（ADR-0025 方案 A）" >&2
  exit 2
fi

KEY_HEX="${KEY_HEX,,}"
printf '%s' "$KEY_HEX" | grep -Eq '^[0-9a-f]{64}$' || fail "私钥必须是 64 位 hex（32 字节 ed25519 seed）：$KEY_PATH"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# PKCS#8 DER 前缀 + 32B seed = 完整 ed25519 私钥，重建 PEM。
printf '%s' "302e020100300506032b657004220420${KEY_HEX}" | xxd -r -p > "$TMP/priv.der"
openssl pkey -inform DER -in "$TMP/priv.der" -out "$TMP/priv.pem"

openssl pkeyutl -sign -inkey "$TMP/priv.pem" -rawin -in "$INDEX" -out "$SIG"
echo "[OK] 已用长期密钥签名（公钥常量不变，无需 make build / 重启 kored）：$INDEX → $SIG"
