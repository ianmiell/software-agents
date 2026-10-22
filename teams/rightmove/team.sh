# Team config for the rightmove agent team. Sourced by bin/run-agent and bin/run-team.

# Agents run from here, so they get this repo's git context and AGENTS.md.
WORK_DIR=/home/imiell/git/rightmove-data-scraper
LOG_DIR=$WORK_DIR/logs/agents

# run-team: seconds to sleep after an idle cycle, and after a cycle that did work.
IDLE_SLEEP=600
WORK_SLEEP=300
# Output matching this (case-insensitive) means the agent had nothing to do.
IDLE_PATTERNS="no agent-task issues open|no anomalies found|no findings|no open issues|no concerns found|nothing to do|no issues to triage"

# Agents run-team starts, in order.
AGENTS=(log-reviewer triage engineer code-reviewer manager)
# These always sleep IDLE_SLEEP, even after doing work.
FIXED_SLEEP_AGENTS=(manager)

declare -A PROMPT=(
  [log-reviewer]="Run your log review process for the last 6 hours. Check /home/imiell/git/rightmove-data-scraper/logs/ for anomalies and raise GitHub issues as instructed."
  [triage]="Triage all open GitHub issues across rightmove-* repos. Comment on each un-triaged issue with who should handle it and label accordingly. Follow all rules in your agent definition."
  [engineer]="Check for open agent-task GitHub issues across all rightmove-* repos and work on the highest priority one. Follow all rules in your agent definition."
  [code-reviewer]="Review commits from the last 5 hours across all rightmove-* repos and any open needs-review PRs. Raise GitHub issues for any findings as instructed."
  [manager]="Run your daily team oversight checks across all rightmove-* repos as instructed."
)
