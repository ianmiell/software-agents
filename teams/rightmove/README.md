# rightmove agent team

Maintains the `rightmove-*` repos (scraper, admin, backend, react-frontend,
maps, property-notes). Runs from `~/git/rightmove-data-scraper`; that repo's
`AGENTS.md` holds the push rules and the operational notes the agents rely on.

## Roles

| Agent | Model | Role |
|---|---|---|
| **triage** | haiku | Labels un-triaged issues `agent-task` (engineer) or `needs-human-review`, then `triaged` |
| **engineer** | sonnet | Picks up `agent-task` issues and implements fixes; pushes directly to main for safe changes |
| **code-reviewer** | sonnet | Adversarially reviews commits from the last 5h; opens `code-concern` issues |
| **log-reviewer** | haiku | Scans the scraper's `logs/`; opens `log-anomaly` issues for genuine errors |
| **manager** | haiku | Oversight: escalates stale issues, stalled PRs, and systemic problems |

## Running

```bash
# Persistent tmux session (recommended)
tmux new -s agents-rightmove '~/git/software-agents/bin/run-team rightmove'
tmux attach -t agents-rightmove

# One agent, once
~/git/software-agents/bin/run-agent rightmove log-reviewer
```

Each agent sleeps 10 minutes after an idle cycle and 5 minutes after doing
work; the manager always sleeps 10 minutes. Settings are in `team.sh`.

Logs: `~/git/rightmove-data-scraper/logs/agents/agent-<agent>.log`.

## Giving the engineer a task

```bash
gh issue create -R ianmiell/rightmove-data-scraper \
  --title "short description" \
  --body "full details of what to do" \
  --label agent-task
```

The engineer picks it up on its next cycle. Label with `agent-task-high` for
priority. Comments never trigger an agent; to hand a `needs-human-review`
issue to the engineer, swap the label to `agent-task`.

## What goes to prod without human review

The engineer pushes directly to `main` unless the change involves:
- SQL `DROP`, `TRUNCATE`, or unscoped `DELETE`
- Destructive schema migrations
- Backup/restore script changes
- Changes that could take cron jobs offline for >10 minutes

For those, the engineer opens a PR with `needs-human-review` instead.

## GitHub labels

| Label | Raised by | Meaning |
|---|---|---|
| `agent-task` | human, triage | Task for the engineer |
| `agent-task-high` | human | High-priority engineer task |
| `triaged` | triage | Already triaged; triage skips it |
| `log-anomaly` | log-reviewer | Error pattern in logs |
| `code-concern` | code-reviewer | Bug or risk in a commit |
| `critical` | code-reviewer | Requires immediate attention |
| `needs-human-review` | triage, engineer | Needs a human decision or approval |
| `awaiting-verification` | engineer | Fix pushed; waiting for a clean post-fix run |
| `manager-concern` | manager | Systemic team/backlog issue |

One-time label setup for a repo:

```bash
for label in "agent-task:0075ca:Task for the engineer agent" \
             "agent-task-high:e11d48:High-priority engineer task" \
             "log-anomaly:d93f0b:Raised by log-reviewer" \
             "code-concern:f9d0c4:Raised by code-reviewer" \
             "critical:b60205:Requires immediate attention" \
             "manager-concern:e4e669:Raised by manager" \
             "needs-human-review:0e8a16:Needs human approval before merge"; do
  name="${label%%:*}"; rest="${label#*:}"; color="${rest%%:*}"; desc="${rest#*:}"
  gh label create "$name" --color "$color" --description "$desc" \
    -R ianmiell/rightmove-data-scraper 2>&1 || true
done
```
