#!/bin/bash
# Invoked by cron every 4 hours (offset 1h after engineer). Runs the code-reviewer agent.
set -e

REPO_DIR="/home/imiell/git/rightmove-data-scraper"
LOG_OUT="$REPO_DIR/logs/agents/agent-code-reviewer.log"
mkdir -p "$REPO_DIR/logs/agents"

echo "$(date -u): code-reviewer starting" | tee -a "$LOG_OUT"

cd "$REPO_DIR"

claude \
  --dangerously-skip-permissions \
  --model claude-sonnet-5-5 \
  --agent code-reviewer \
  -p "Review commits from the last 5 hours across all rightmove-* repos and any open needs-review PRs. Raise GitHub issues for any findings as instructed." \
  2>&1 | tee -a "$LOG_OUT"

echo "$(date -u): code-reviewer done" | tee -a "$LOG_OUT"
