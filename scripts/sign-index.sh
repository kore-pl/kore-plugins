#!/usr/bin/env bash
# 用 KORE_INDEX_KEY（ed25519 私钥 32 字节 seed 的 hex，64 字符）签 plugins.json → .sig。
# CI 集成：在 release 流水线中注入 KORE_INDEX_KEY secret，先 sign 再发布 index/。
# 私钥只存在于 CI secret / 运维本地，绝不入库。
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
