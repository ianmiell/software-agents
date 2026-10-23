# Team config for the curzon agent team. Sourced by bin/run-agent and bin/run-team.

# Agents run from here, so they get this repo's git context and AGENTS.md.
# It is also the live checkout the curzon_listings systemd unit (gunicorn,
# 127.0.0.1:6752) runs from; the engineer edits and tests in /tmp worktrees and
# only fast-forwards this checkout. A human runs `make restart` here to deploy
# Python/template changes.
WORK_DIR=/home/imiell/git/curzon-listings
LOG_DIR=/home/imiell/git/software-agents/logs/curzon

# run-team: seconds to sleep after an idle cycle, and after a cycle that did work.
# The app scrapes hourly, so an hour between idle cycles is plenty.
IDLE_SLEEP=3600
WORK_SLEEP=300
# Output matching this (case-insensitive) means the agent had nothing to do.
IDLE_PATTERNS="no agent-task issues open|no anomalies found|no findings|nothing to do|no issues to triage"

# Agents run-team starts, in order.
AGENTS=(monitor triage engineer code-reviewer)
# These always sleep IDLE_SLEEP, even after doing work.
FIXED_SLEEP_AGENTS=(monitor)

declare -A PROMPT=(
  [monitor]="Check the curzon_listings service, its /health and listings, its journal for the last two hours, and the public URL https://ianmiell.com/curzon-listings/. The live dir is $WORK_DIR. Raise or update GitHub issues on ianmiell/curzon-listings as instructed."
  [triage]="Triage all open GitHub issues on ianmiell/curzon-listings. Comment on each un-triaged issue with who should handle it and label accordingly. Follow all rules in your agent definition."
  [engineer]="Check for open agent-task GitHub issues on ianmiell/curzon-listings and work on the highest priority one. Follow all rules in your agent definition."
  [code-reviewer]="Review new commits on origin/main of ianmiell/curzon-listings and any open needs-review PRs. Raise GitHub issues for any findings as instructed. Your reviewed-commits file is $LOG_DIR/code-reviewer-reviewed.txt"
)
