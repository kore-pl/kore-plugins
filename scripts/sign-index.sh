#!/usr/bin/env bash
# 用 KORE_INDEX_KEY（ed25519 私钥 32 字节 seed 的 hex，64 字符）签 plugins.json → .sig。
# 执行者 = 发布方（维护者），在自己的发布机上跑：签名是发布动作，不是 CI 动作。
# KORE_INDEX_KEY 的值（私钥 seed）只存在于发布机 / 发布时的临时密钥：绝不入库，
#   绝不进 GitHub / Gitee CI secret，也不进日志（CI 只验签、不签名）。
# CI 口径见 .github/workflows/ci.yml：push main / tag 全量验签；PR 用 KORE_INDEX_SKIP_SIG=1 跳过验签。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$ROOT/index/plugins.json"
SIG="$ROOT/index/plugins.json.sig"

: "${KORE_INDEX_KEY:?必须设置 KORE_INDEX_KEY（ed25519 私钥 seed hex）}"
[ -f "$INDEX" ] || { echo "[FAIL] 缺少 $INDEX" >&2; exit 1; }

KEY_HEX="$(printf '%s' "$KORE_INDEX_KEY" | tr -d '[:space:]')"
if ! printf '%s' "$KEY_HEX" | grep -Eq '^[0-9a-fA-F]{64}$'; then
  echo "[FAIL] KORE_INDEX_KEY 必须是 64 位 hex（32 字节 seed）" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# PKCS#8 DER 前缀 + 32B seed = 完整 ed25519 私钥，重建 PEM。
printf '%s' "302e020100300506032b657004220420${KEY_HEX,,}" | xxd -r -p > "$TMP/priv.der"
openssl pkey -inform DER -in "$TMP/priv.der" -out "$TMP/priv.pem"

openssl pkeyutl -sign -inkey "$TMP/priv.pem" -rawin -in "$INDEX" -out "$SIG"
echo "[OK] 已签名 $INDEX → $SIG"
