#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/home/m1536749012/documents/daily_stock_analysis"
RUN_SCRIPT="$REPO_DIR/scripts/local_daily_analysis_cron.sh"
LOG_HOST="$REPO_DIR/logs/scheduled_analysis.log"
WEB_URL="https://stock.12161216.xyz"
MODE="${MODE:-full}"
FORCE_RUN="${FORCE_RUN:-true}"

start_ts=$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S')
start_epoch=$(date +%s)

set +e
MODE="$MODE" FORCE_RUN="$FORCE_RUN" "$RUN_SCRIPT"
rc=$?
set -e

end_ts=$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S')
end_epoch=$(date +%s)
duration=$((end_epoch - start_epoch))
minutes=$((duration / 60))
seconds=$((duration % 60))

status_text="完成"
emoji="✅"
if [ "$rc" -ne 0 ]; then
  status_text="失败"
  emoji="⚠️"
fi

latest_tail=""
if [ -f "$LOG_HOST" ]; then
  latest_tail=$(tail -n 8 "$LOG_HOST" | sed 's/[[:cntrl:]]//g')
fi

run_state="可能未真正执行"
if printf '%s\n' "$latest_tail" | grep -q '配置为不立即运行分析'; then
  emoji="⚠️"
  status_text="跳过"
elif [ "$rc" -eq 0 ]; then
  run_state="已触发分析"
else
  run_state="执行失败"
fi

cat <<MSG
${emoji} 每日股票分析已${status_text}
时间：${start_ts} → ${end_ts}（${minutes}分${seconds}秒）
模式：${MODE}，强制运行：${FORCE_RUN}，状态：${run_state}
查看：${WEB_URL}

最近日志：
${latest_tail}
MSG

exit "$rc"
