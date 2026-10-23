# Team config for the curzon agent team. Sourced by bin/run-agent and bin/run-team.

# Agents run from their own clone of curzon-listings, not the live checkout
# (~/git/curzon-listings, which cron runs the scrape from and which publishes
# to /var/www/ianmiell.com/curzon-listings). They push to origin; a human
# deploys with git pull (and make install where needed) in the live checkout.
WORK_DIR=/home/imiell/git/curzon-listings-agents
LIVE_DIR=/home/imiell/git/curzon-listings
LOG_DIR=/home/imiell/git/software-agents/logs/curzon

# run-team: seconds to sleep after an idle cycle, and after a cycle that did work.
# Listings change daily, so an hour between idle cycles is plenty.
IDLE_SLEEP=3600
WORK_SLEEP=300
# Output matching this (case-insensitive) means the agent had nothing to do.
IDLE_PATTERNS="no agent-task issues open|no anomalies found|no findings|nothing to do|no issues to triage"

# Agents run-team starts, in order.
AGENTS=(monitor triage engineer code-reviewer)
# These always sleep IDLE_SLEEP, even after doing work.
FIXED_SLEEP_AGENTS=(monitor)

declare -A PROMPT=(
  [monitor]="Check the curzon-listings pipeline in $LIVE_DIR and the published listings for freshness and completeness. Raise or update GitHub issues on ianmiell/curzon-listings as instructed."
  [triage]="Triage all open GitHub issues on ianmiell/curzon-listings. Comment on each un-triaged issue with who should handle it and label accordingly. Follow all rules in your agent definition."
  [engineer]="Check for open agent-task GitHub issues on ianmiell/curzon-listings and work on the highest priority one. Follow all rules in your agent definition."
  [code-reviewer]="Review new commits on origin/main of ianmiell/curzon-listings and any open needs-review PRs. Raise GitHub issues for any findings as instructed. Your reviewed-commits file is $LOG_DIR/code-reviewer-reviewed.txt"
)
