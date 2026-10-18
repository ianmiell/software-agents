#!/bin/bash
# Invoked by the team runner every hour. Runs the triage agent.
set -e

REPO_DIR="/home/imiell/git/rightmove-data-scraper"
LOG_OUT="$REPO_DIR/logs/agents/agent-triage.log"
mkdir -p "$REPO_DIR/logs/agents"

echo "$(date -u): triage starting" | tee -a "$LOG_OUT"

cd "$REPO_DIR"

claude \
  --dangerously-skip-permissions \
  --model claude-haiku-5-5 \
  --agent triage \
  -p "Triage all open GitHub issues across rightmove-* repos. Comment on each un-triaged issue with who should handle it and label accordingly. Follow all rules in your agent definition." \
  2>&1 | tee -a "$LOG_OUT"

echo "$(date -u): triage done" | tee -a "$LOG_OUT"
