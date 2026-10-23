# busstop agent team

Maintains [`ianmiell/transport_tracker`](https://github.com/ianmiell/transport_tracker),
the busstop countdown-sign app served at https://ianmiell.com/busstop/. The
repo's `AGENTS.md` holds how the app works; the agents read it because they run
in a clone of the repo.

## Roles

| Agent | Model | Role |
|---|---|---|
| **log-reviewer** | haiku | Reads the `busstop_server` journal and `scripts/busstop.sh health`; opens `log-anomaly` issues |
| **triage** | haiku | Labels un-triaged issues `agent-task` (engineer) or `needs-human-review`, then `triaged` |
| **engineer** | sonnet | Works `agent-task` issues; pushes safe fixes to main, opens PRs for the rest |
| **code-reviewer** | sonnet | Adversarially reviews new commits on main (anyone's) and open PRs; opens `code-concern` issues |

There is no manager: it is one small repo.

## How it differs from rightmove

- **The agents work in their own clone**, `~/git/transport_tracker-agents`,
  not the live checkout `~/git/transport_tracker` that gunicorn and nginx serve
  from (nginx serves `static/` straight from disk, so a half-edited JS file in
  the live checkout would go out immediately).
- **Agents cannot deploy.** Restarting `busstop_server` needs `sudo`. A pushed
  fix goes live only when you run, in the live checkout:
  ```bash
  scripts/busstop.sh update     # git pull --ff-only, deps, restart, health check
  ```
  The engineer leaves runtime fixes `awaiting-verification` and only closes
  them after an hour of clean journal following a restart that included the
  fix. After 24 hours undeployed it asks you, with `needs-human-review`.
- Because the engineer pushes to main, pull before committing in the live
  checkout, or `update` will refuse to fast-forward.

## Setup (once)

```bash
git clone git@github.com:ianmiell/transport_tracker.git ~/git/transport_tracker-agents
cd ~/git/transport_tracker-agents/flask_app && python3 -m venv venv && venv/bin/pip install -r requirements.txt
```
Labels are created on the repo (see below).

## Running

```bash
tmux new -s agents-busstop '~/git/software-agents/bin/run-team busstop'
tmux attach -t agents-busstop

# One agent, once
~/git/software-agents/bin/run-agent busstop log-reviewer
```

Each agent sleeps 30 minutes after an idle cycle and 5 minutes after doing
work. Settings are in `team.sh`.

Logs: `~/git/software-agents/logs/busstop/agent-<agent>.log`. The
code-reviewer keeps the hashes it has reviewed in
`logs/busstop/code-reviewer-reviewed.txt`; delete it to re-review the last 7 days.

## Giving the engineer a task

```bash
gh issue create -R ianmiell/transport_tracker \
  --title "short description" --body "full details" --label agent-task
```

Label `agent-task-high` for priority. Comments never trigger an agent; to hand
a `needs-human-review` issue to the engineer, swap the label to `agent-task`.

## What goes to main without human review

Fixes and small additive features in `flask_app/`, and docs. Everything in
`kiosk_files/`, `scripts/busstop.sh`, the run scripts, `Dockerfile`,
`app.yaml` and `requirements.txt`, plus removals, `/admin`/auth changes and
changes to which stops are shown, go through a PR labeled `needs-human-review`.

## GitHub labels

| Label | Raised by | Meaning |
|---|---|---|
| `agent-task` | human, triage | Task for the engineer |
| `agent-task-high` | human | High-priority engineer task |
| `triaged` | triage | Already triaged; triage skips it |
| `log-anomaly` | log-reviewer | Error pattern in the journal or health check |
| `code-concern` | code-reviewer | Bug or risk in a commit |
| `critical` | code-reviewer | Requires immediate attention |
| `needs-human-review` | triage, engineer | Needs a human decision, approval or deploy |
| `awaiting-verification` | engineer | Fix pushed; waiting for a deploy and a clean hour of journal |

```bash
for label in "agent-task:0075ca:Task for the engineer agent" \
             "agent-task-high:e11d48:High-priority engineer task" \
             "triaged:c5def5:Triaged by the triage agent" \
             "log-anomaly:d93f0b:Raised by log-reviewer" \
             "code-concern:f9d0c4:Raised by code-reviewer" \
             "critical:b60205:Requires immediate attention" \
             "needs-human-review:0e8a16:Needs a human decision, approval or deploy" \
             "awaiting-verification:fbca04:Fix pushed; waiting for a clean post-deploy run"; do
  name="${label%%:*}"; rest="${label#*:}"; color="${rest%%:*}"; desc="${rest#*:}"
  gh label create "$name" --color "$color" --description "$desc" \
    -R ianmiell/transport_tracker 2>&1 || true
done
```
