#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${CONTAINER:-daily-stock-analysis-webui}"
MODE="${MODE:-full}"
FORCE_RUN="${FORCE_RUN:-false}"
LOG_FILE="${LOG_FILE:-/app/logs/scheduled_analysis.log}"
LOCK_FILE="${LOCK_FILE:-/tmp/daily-stock-analysis-scheduled.lock}"

case "$MODE" in
  full)
    MODE_ARGS=""
    ;;
  market-only)
    MODE_ARGS="--market-review"
    ;;
  stocks-only)
    MODE_ARGS="--no-market-review"
    ;;
  *)
    echo "Unsupported MODE=$MODE; expected full, market-only, or stocks-only" >&2
    exit 2
    ;;
esac

case "${FORCE_RUN,,}" in
  true|1|yes|on)
    FORCE_ARGS="--force-run"
    ;;
  false|0|no|off|"")
    FORCE_ARGS=""
    ;;
  *)
    echo "Unsupported FORCE_RUN=$FORCE_RUN; expected true/false" >&2
    exit 2
    ;;
esac

INNER_SCRIPT=$(cat <<'EOS'
set -euo pipefail
flock -n "$LOCK_FILE" bash -s <<'RUN'
set +e
cd /app
printf '\n===== scheduled analysis start %s | mode=%s | force=%s =====\n' "$(TZ=Asia/Shanghai date '+%F %T')" "$MODE" "$FORCE_RUN" >> "$LOG_FILE"
python main.py --no-notify $MODE_ARGS $FORCE_ARGS >> "$LOG_FILE" 2>&1
rc=$?
printf '===== scheduled analysis end %s | exit=%s =====\n' "$(TZ=Asia/Shanghai date '+%F %T')" "$rc" >> "$LOG_FILE"
exit "$rc"
RUN
EOS
)

docker exec \
  -e MODE="$MODE" \
  -e FORCE_RUN="$FORCE_RUN" \
  -e LOG_FILE="$LOG_FILE" \
  -e LOCK_FILE="$LOCK_FILE" \
  -e MODE_ARGS="$MODE_ARGS" \
  -e FORCE_ARGS="$FORCE_ARGS" \
  "$CONTAINER" bash -lc "$INNER_SCRIPT"
