#!/bin/bash
# Invoked by cron daily. Runs the manager agent.
set -e

REPO_DIR="/home/imiell/git/rightmove-data-scraper"
LOG_OUT="$REPO_DIR/logs/agent-manager.log"

echo "$(date -u): manager starting" | tee -a "$LOG_OUT"

claude \
  --dangerously-skip-permissions \
  --model claude-haiku-5-5 \
  --agent manager \
  -p "Run your daily team oversight checks across all rightmove-* repos as instructed." \
  2>&1 | tee -a "$LOG_OUT"

echo "$(date -u): manager done" | tee -a "$LOG_OUT"
