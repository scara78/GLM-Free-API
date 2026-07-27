#!/bin/sh
set -eu

DB_PATH=/data/tokens.sqlite
TOKEN_COUNT=${CAPTCHA_TOKENS:-250}
BATCH_COUNT=${CAPTCHA_BATCHES:-1}

mkdir -p /data
cd /data

existing=0
if [ -f "$DB_PATH" ]; then
  existing=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tokens;" 2>/dev/null || printf '0')
fi

if [ "$existing" -eq 0 ]; then
  echo "[startup] Baza captcha este goală; colectez ${TOKEN_COUNT} tokenuri în container..."
  /usr/local/bin/token-collector \
    --tokens "$TOKEN_COUNT" \
    --batch "$BATCH_COUNT" \
    --parallel 1 \
    --no-tui
  echo "[startup] Tokenurile captcha au fost salvate în $DB_PATH"
else
  echo "[startup] Folosesc $existing tokenuri captcha existente din volumul persistent."
fi

exec /usr/local/bin/zai-bridge --db-path "$DB_PATH" "$@"