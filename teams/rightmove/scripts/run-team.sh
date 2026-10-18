#!/bin/bash
# Runs the full agent team continuously.
# Each agent sleeps IDLE_SLEEP seconds when there's nothing to do,
# or WORK_SLEEP seconds after completing work, then loops.
#
# Usage:
#   ./src/agents/run-team.sh           # foreground (ctrl-c to stop)
#   nohup ./src/agents/run-team.sh &   # detached
#   tmux new -s agents './src/agents/run-team.sh'

REPO_DIR="/home/imiell/git/rightmove-data-scraper"
IDLE_SLEEP=3600   # 1 hour when nothing to do
WORK_SLEEP=300    # 5 minutes between tasks

# Patterns that indicate the agent had nothing to do this cycle
IDLE_PATTERNS="no agent-task issues open|no anomalies found|no findings|no open issues|no concerns found|nothing to do"

agent_loop() {
  local name="$1"
  local script="$REPO_DIR/src/agents/run-${name}.sh"
  local log="$REPO_DIR/logs/agent-${name}.log"

  while true; do
    output=$("$script" 2>&1)
    echo "$output"
    if echo "$output" | grep -qiE "$IDLE_PATTERNS"; then
      echo "$(date -u): [$name] idle — sleeping ${IDLE_SLEEP}s" | tee -a "$log"
      sleep "$IDLE_SLEEP"
    else
      echo "$(date -u): [$name] worked — sleeping ${WORK_SLEEP}s" | tee -a "$log"
      sleep "$WORK_SLEEP"
    fi
  done
}

# Manager runs less often even when active (daily oversight role)
manager_loop() {
  local log="$REPO_DIR/logs/agent-manager.log"
  while true; do
    "$REPO_DIR/src/agents/run-manager.sh" 2>&1
    echo "$(date -u): [manager] sleeping ${IDLE_SLEEP}s" | tee -a "$log"
    sleep "$IDLE_SLEEP"
  done
}

echo "$(date -u): Starting rightmove agent team"
echo "  Idle sleep:  ${IDLE_SLEEP}s (1h)"
echo "  Work sleep:  ${WORK_SLEEP}s (5min)"
echo "  Logs: $REPO_DIR/logs/agent-*.log"
echo "  Stop: ctrl-c (or kill $$)"
echo ""

agent_loop log-reviewer &
LOG_REVIEWER_PID=$!

agent_loop engineer &
ENGINEER_PID=$!

agent_loop code-reviewer &
CODE_REVIEWER_PID=$!

manager_loop &
MANAGER_PID=$!

echo "PIDs: log-reviewer=$LOG_REVIEWER_PID engineer=$ENGINEER_PID code-reviewer=$CODE_REVIEWER_PID manager=$MANAGER_PID"

# Trap ctrl-c and kill all children cleanly
trap "echo 'Stopping team...'; kill $LOG_REVIEWER_PID $ENGINEER_PID $CODE_REVIEWER_PID $MANAGER_PID 2>/dev/null; exit 0" INT TERM

wait
