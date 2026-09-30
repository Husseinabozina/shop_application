#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${FIREBASE_PROJECT_ID:-shopapp-29118}"
INSTANCE="${FIREBASE_DATABASE_INSTANCE:-shopapp-29118-default-rtdb}"

if ! command -v firebase >/dev/null 2>&1; then
  echo "Firebase CLI is not installed or not on PATH."
  exit 1
fi

if [ ! -f "firebase.json" ] || [ ! -f "database.rules.json" ]; then
  echo "Run this script from the shop_application repository root."
  exit 1
fi

echo "== Firebase clean reset =="
echo "Project:  $PROJECT_ID"
echo "Instance: $INSTANCE"

echo
echo "Checking Realtime Database availability..."
PROBE="$(
  firebase database:get /__clean_reset_probe__ \
    --project "$PROJECT_ID" \
    --instance "$INSTANCE" \
    2>/dev/null
)"
if [ "$PROBE" != "null" ]; then
  echo "Unexpected probe response: $PROBE"
  exit 1
fi

echo
echo "Removing legacy application data..."
for path in /products /userfavorite /addresses /order; do
  echo "  - $path"
  firebase database:remove "$path" \
    --project "$PROJECT_ID" \
    --instance "$INSTANCE" \
    --force
done

echo
echo "Verifying application paths are empty..."
for path in /products /userfavorite /addresses /order; do
  value="$(
    firebase database:get "$path" \
      --project "$PROJECT_ID" \
      --instance "$INSTANCE" \
      2>/dev/null
  )"
  if [ "$value" != "null" ]; then
    echo "Verification failed: $path is not empty."
    exit 1
  fi
done

echo
echo "Deploying Realtime Database security rules..."
firebase deploy \
  --only database \
  --project "$PROJECT_ID" \
  --non-interactive

echo
echo "Checking unauthenticated access is blocked..."
DB_URL="https://${INSTANCE}.firebaseio.com"

READ_RESPONSE="$(curl -sS "$DB_URL/products.json")"
if printf '%s' "$READ_RESPONSE" | grep -q '"Permission denied"'; then
  echo "  - public read blocked"
else
  echo "Warning: public read probe did not return Permission denied."
  echo "Response: $READ_RESPONSE"
  exit 1
fi

WRITE_RESPONSE="$(
  curl -sS \
    -X PUT \
    -H 'Content-Type: application/json' \
    --data '{"probe":true}' \
    "$DB_URL/__security_probe__.json"
)"
if printf '%s' "$WRITE_RESPONSE" | grep -q '"Permission denied"'; then
  echo "  - public write blocked"
else
  echo "Warning: public write probe did not return Permission denied."
  echo "Response: $WRITE_RESPONSE"
  exit 1
fi

echo
echo "Firebase clean reset complete."
echo "Legacy RTDB app data removed; security rules deployed; unauthenticated read/write blocked."
