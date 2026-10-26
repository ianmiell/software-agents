# Team config for the ianmiell agent team. Sourced by bin/run-agent and bin/run-team.

TEAM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Which repos are watched, and whether they are worked on main or through PRs.
REPOS="$TEAM_DIR/repos"

# Agents run from here, outside any target repo. The engineer and code-reviewer
# keep their own clones of the target repos under it.
WORK_DIR=/home/imiell/git/software-agents/work/ianmiell
LOG_DIR=/home/imiell/git/software-agents/logs/ianmiell
mkdir -p "$WORK_DIR"

# Triage only looks at issues opened on or after this date, so the years-old
# issues on old repos are not handed to the engineer. Move it back to triage them.
TRIAGE_SINCE=2026-10-01

# run-team: seconds to sleep after an idle cycle, and after a cycle that did work.
IDLE_SLEEP=1800
WORK_SLEEP=300
# Output matching this (case-insensitive) means the agent had nothing to do.
IDLE_PATTERNS="no agent-task issues open|no findings|nothing to do|no issues to triage"

# Agents run-team starts, in order.
AGENTS=(triage engineer code-reviewer)
# These always sleep IDLE_SLEEP, even after doing work.
FIXED_SLEEP_AGENTS=()

declare -A PROMPT=(
  [triage]="Triage open GitHub issues created on or after $TRIAGE_SINCE across the watched ianmiell repos. The repos helper is $REPOS. Comment on each un-triaged issue with who should handle it and label accordingly. Follow all rules in your agent definition."
  [engineer]="Check for open agent-task GitHub issues across the watched ianmiell repos and work on the highest priority one. The repos helper is $REPOS and your clones live in $WORK_DIR. Follow all rules in your agent definition."
  [code-reviewer]="Review new commits on the default branches of the watched ianmiell repos and their open PRs. The repos helper is $REPOS and clones live in $WORK_DIR. Raise GitHub issues for any findings as instructed. Your reviewed file is $LOG_DIR/code-reviewer-reviewed.txt"
)
