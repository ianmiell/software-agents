#!/bin/bash
# Invoked by cron every 6 hours. Runs the log-reviewer agent.
set -e

REPO_DIR="/home/imiell/git/rightmove-data-scraper"
LOG_OUT="$REPO_DIR/logs/agents/agent-log-reviewer.log"
mkdir -p "$REPO_DIR/logs/agents"

echo "$(date -u): log-reviewer starting" | tee -a "$LOG_OUT"

claude \
  --dangerously-skip-permissions \
  --model claude-haiku-5-5 \
  --agent log-reviewer \
  -p "Run your log review process for the last 6 hours. Check /home/imiell/git/rightmove-data-scraper/logs/ for anomalies and raise GitHub issues as instructed." \
  2>&1 | tee -a "$LOG_OUT"

echo "$(date -u): log-reviewer done" | tee -a "$LOG_OUT"
