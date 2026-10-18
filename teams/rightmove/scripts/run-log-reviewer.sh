#!/bin/bash
# Invoked by cron every 6 hours. Runs the log-reviewer agent.
set -e

REPO_DIR="/home/imiell/git/rightmove-data-scraper"
LOG_OUT="$REPO_DIR/logs/agent-log-reviewer.log"

echo "$(date -u): log-reviewer starting" >> "$LOG_OUT"

claude \
  --dangerously-skip-permissions \
  --model claude-haiku-5-5 \
  --agent log-reviewer \
  -p "Run your log review process for the last 6 hours. Check /home/imiell/git/rightmove-data-scraper/logs/ for anomalies and raise GitHub issues as instructed." \
  >> "$LOG_OUT" 2>&1

echo "$(date -u): log-reviewer done" >> "$LOG_OUT"
