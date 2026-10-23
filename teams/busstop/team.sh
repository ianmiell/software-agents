# Team config for the busstop agent team. Sourced by bin/run-agent and bin/run-team.

# Agents run from here, so they get this repo's git context and AGENTS.md.
# It is also the live checkout gunicorn and nginx serve from; a human restarts
# the service (scripts/busstop.sh restart) to deploy Python/template changes.
WORK_DIR=/home/imiell/git/transport_tracker
LOG_DIR=/home/imiell/git/software-agents/logs/busstop

# run-team: seconds to sleep after an idle cycle, and after a cycle that did work.
IDLE_SLEEP=1800
WORK_SLEEP=300
# Output matching this (case-insensitive) means the agent had nothing to do.
IDLE_PATTERNS="no agent-task issues open|no anomalies found|no findings|nothing to do|no issues to triage"

# Agents run-team starts, in order.
AGENTS=(log-reviewer triage engineer code-reviewer)
# These always sleep IDLE_SLEEP, even after doing work.
FIXED_SLEEP_AGENTS=()

declare -A PROMPT=(
  [log-reviewer]="Run your log review of the busstop_server journal for the last hour and the health check. Raise or update GitHub issues on ianmiell/transport_tracker as instructed."
  [triage]="Triage all open GitHub issues on ianmiell/transport_tracker. Comment on each un-triaged issue with who should handle it and label accordingly. Follow all rules in your agent definition."
  [engineer]="Check for open agent-task GitHub issues on ianmiell/transport_tracker and work on the highest priority one. Follow all rules in your agent definition."
  [code-reviewer]="Review new commits on origin/main of ianmiell/transport_tracker and any open needs-review PRs. Raise GitHub issues for any findings as instructed. Your reviewed-commits file is $LOG_DIR/code-reviewer-reviewed.txt"
)
