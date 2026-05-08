#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ -f .env.local ]]; then
  # Optional local overrides for secrets that should not live in source control.
  # shellcheck disable=SC1091
  source .env.local
fi

export SUNO_CALLBACK_URL="${SUNO_CALLBACK_URL:-https://punctuate-demote-rocking.ngrok-free.dev/api/suno/callback}"
export SUNO_ACCOUNT_1_COOKIE="${SUNO_ACCOUNT_1_COOKIE:-authorization=2ecbb570-11ab-4741-8151-cc2e9f866adf; g_state={\"i_l\":0,\"i_ll\":1776412580330,\"i_e\":{\"enable_itp_optimization\":19},\"i_et\":1776397639153,\"i_b\":\"udGkYWpiTfRTG1psNBSi4XuFCGXy//gDUqfHvlNy54c\"}}"

# Reuse the Firebase project already configured by the Flutter app so only the
# backend auth password is usually missing locally.
export FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-${FIREBASE_TOOL_PROJECT_ID:-appmusi-4ff75}}"
export FIREBASE_WEB_API_KEY="${FIREBASE_WEB_API_KEY:-${FIREBASE_TOOL_API_KEY:-AIzaSyCaunJrZfmVkcX6XQidUh5fi6F7VntnZ8w}}"
export FIREBASE_BACKEND_EMAIL="${FIREBASE_BACKEND_EMAIL:-${FIREBASE_TOOL_EMAIL:-admin@gmail.com}}"
export FIREBASE_BACKEND_PASSWORD="${FIREBASE_BACKEND_PASSWORD:-${FIREBASE_TOOL_PASSWORD:-123456}}"
export MUSIC_STORE_PATH="${MUSIC_STORE_PATH:-${XDG_STATE_HOME:-$HOME/.local/state}/backend/backend_generation_store.json}"

if [[ -n "${FIREBASE_BACKEND_PASSWORD:-}" ]]; then
  echo "Firestore sync: enabled"
  echo "Firebase project: $FIREBASE_PROJECT_ID"
  echo "Firebase backend email: $FIREBASE_BACKEND_EMAIL"
else
  echo "Firestore sync: disabled (missing FIREBASE_BACKEND_PASSWORD)"
  echo "Backend will use local persisted store at: $MUSIC_STORE_PATH"
  echo "Tip: export FIREBASE_TOOL_PASSWORD or FIREBASE_BACKEND_PASSWORD before running this script to sync generated songs to Firestore."
fi

mix phx.server
