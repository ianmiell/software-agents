# Team config for the ianmiell agent team. Sourced by bin/run-agent and bin/run-team.

TEAM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Which repos are watched, and whether they are worked on main or through PRs.
REPOS="$TEAM_DIR/repos"
# The only address the agents email. bin/notify reads it from here and sends
# nowhere else; run-agent also emails it when an agent starts failing.
NOTIFY_TO=ian.miell@gmail.com
NOTIFY="$(cd "$TEAM_DIR/../.." && pwd)/bin/notify ianmiell"
# The GitHub login whose issues the agents act on: opened by it, or commented
# on, labeled or edited by it.
OWNER_LOGIN=ianmiell

# Agents run from here, outside any target repo. The engineer and code-reviewer
# keep their own clones of the target repos under it.
WORK_DIR=/home/imiell/git/software-agents/work/ianmiell
LOG_DIR=/home/imiell/git/software-agents/logs/ianmiell
mkdir -p "$WORK_DIR"

# Triage only looks at issues updated on or after this date, so the years-old
# issues on old repos are not handed to the engineer. Move it back to triage them.
TRIAGE_SINCE=2026-10-01

# run-team backoff, in seconds: an agent sleeps MIN_SLEEP after a cycle that
# did work, and doubles its sleep after each idle or failed cycle, up to MAX_SLEEP.
# MAX_SLEEP can be long because bin/watch-issues wakes every agent within
# ISSUE_POLL seconds of an issue changing; it only bounds how long a commit
# pushed by hand waits for the code-reviewer.
MIN_SLEEP=30
MAX_SLEEP=3600
# Per-agent MAX_SLEEP overrides. Triage is cheap and picks up new issues, so it
# checks at least every 5 minutes.
declare -A AGENT_MAX_SLEEP=([triage]=300)
# Output matching this (case-insensitive) means the agent had nothing to do.
IDLE_PATTERNS="no agent-task issues open|no findings|nothing to do|no issues to triage"

# Agents run-team starts, in order.
AGENTS=(triage engineer code-reviewer)
# These always sleep their MAX_SLEEP, even after doing work.
FIXED_SLEEP_AGENTS=()

declare -A PROMPT=(
  [triage]="Triage open GitHub issues updated on or after $TRIAGE_SINCE across the watched ianmiell repos, acting only on issues $OWNER_LOGIN opened or updated. The repos helper is $REPOS. The notify command is $NOTIFY. Comment on each un-triaged issue with who should handle it and label accordingly. Follow all rules in your agent definition."
  [engineer]="Check for open agent-task GitHub issues across the watched ianmiell repos, acting only on issues $OWNER_LOGIN opened or updated, and work on the highest priority one. The repos helper is $REPOS and your clones live in $WORK_DIR. The notify command is $NOTIFY. Follow all rules in your agent definition."
  [code-reviewer]="Review new commits on the default branches of the watched ianmiell repos and open PRs opened by $OWNER_LOGIN. The repos helper is $REPOS and clones live in $WORK_DIR. The notify command is $NOTIFY. Raise GitHub issues for any findings as instructed. Your reviewed file is $LOG_DIR/code-reviewer-reviewed.txt"
)
