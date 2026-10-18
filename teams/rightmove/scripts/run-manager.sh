#!/bin/bash
# Invoked by cron daily. Runs the manager agent.
set -e

REPO_DIR="/home/imiell/git/rightmove-data-scraper"
LOG_OUT="$REPO_DIR/logs/agent-manager.log"

echo "$(date -u): manager starting" >> "$LOG_OUT"

claude \
  --dangerously-skip-permissions \
  --model claude-haiku-5-5 \
  --agent manager \
  -p "Run your daily team oversight checks across all rightmove-* repos as instructed." \
  >> "$LOG_OUT" 2>&1

echo "$(date -u): manager done" >> "$LOG_OUT"
