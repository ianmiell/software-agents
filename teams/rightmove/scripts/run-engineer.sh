#!/bin/bash
# Invoked by cron every 4 hours. Runs the engineer agent.
set -e

REPO_DIR="/home/imiell/git/rightmove-data-scraper"
LOG_OUT="$REPO_DIR/logs/agent-engineer.log"

echo "$(date -u): engineer starting" >> "$LOG_OUT"

# Run from the scraper repo so git context is available
cd "$REPO_DIR"

claude \
  --dangerously-skip-permissions \
  --model claude-sonnet-5-5 \
  --agent engineer \
  -p "Check for open agent-task GitHub issues across all rightmove-* repos and work on the highest priority one. Follow all rules in your agent definition." \
  >> "$LOG_OUT" 2>&1

echo "$(date -u): engineer done" >> "$LOG_OUT"
