#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIREBASE_JSON="$ROOT_DIR/firebase.json"

if ! command -v firebase >/dev/null 2>&1; then
  echo "[ERROR] firebase CLI is not installed or not in PATH."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[ERROR] python3 is required for port preflight checks."
  exit 1
fi

if [[ ! -f "$FIREBASE_JSON" ]]; then
  echo "[ERROR] Missing firebase.json at: $FIREBASE_JSON"
  exit 1
fi

# Read emulator ports from firebase.json so startup guard always matches repo config.
readarray -t PORT_ENTRIES < <(python3 - "$FIREBASE_JSON" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

emulators = data.get("emulators", {})
for name in ("auth", "functions", "firestore", "database", "storage", "eventarc"):
    block = emulators.get(name, {})
    port = block.get("port")
    if isinstance(port, int):
        print(f"{name}:{port}")
PY
)

if [[ ${#PORT_ENTRIES[@]} -eq 0 ]]; then
  echo "[WARN] No emulator ports found in firebase.json. Starting anyway..."
  exec firebase emulators:start "$@"
fi

is_port_busy() {
  local port="$1"
  lsof -t -iTCP:"$port" -sTCP:LISTEN -n -P >/dev/null 2>&1
}

pid_cmdline() {
  local pid="$1"
  ps -p "$pid" -o args= 2>/dev/null || true
}

for entry in "${PORT_ENTRIES[@]}"; do
  service="${entry%%:*}"
  port="${entry##*:}"

  if ! is_port_busy "$port"; then
    continue
  fi

  readarray -t pids < <(lsof -t -iTCP:"$port" -sTCP:LISTEN -n -P | sort -u)
  for pid in "${pids[@]}"; do
    cmdline="$(pid_cmdline "$pid")"

    if [[ "$cmdline" == *".cache/firebase/emulators"* ]] || [[ "$cmdline" == *"firebase emulators:start"* ]]; then
      echo "[INFO] Releasing stale Firebase emulator process on $service:$port (pid=$pid)"
      kill "$pid" 2>/dev/null || true
      sleep 0.4
      if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
      fi
      continue
    fi

    echo "[ERROR] Port $port ($service emulator) is used by a non-Firebase process (pid=$pid)."
    echo "        Command: $cmdline"
    echo "        Stop that process or change the emulator port in firebase.json."
    exit 1
  done
done

echo "[INFO] Port preflight passed. Starting Firebase emulators..."
exec firebase emulators:start "$@"

