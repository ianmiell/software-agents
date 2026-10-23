# curzon agent team

Maintains [`ianmiell/curzon-listings`](https://github.com/ianmiell/curzon-listings),
a Flask web app that scrapes London Curzon cinema showtimes from curzon.com
(headless Chrome for an API token, then Curzon's OCAPI) and serves them at
https://ianmiell.com/curzon-listings/. It runs as the systemd unit
`curzon_listings` (gunicorn, 127.0.0.1:6752) from the live checkout. The repo's
`AGENTS.md` holds how the app works; the agents read it because they run in
the repo.

## Roles

| Agent | Model | Role |
|---|---|---|
| **monitor** | haiku | Checks the service, `/health`, per-cinema showtime counts, the journal and the public URL; opens `listings-anomaly` issues |
| **triage** | haiku | Labels un-triaged issues `agent-task` (engineer) or `needs-human-review`, then `triaged` |
| **engineer** | sonnet | Works `agent-task` issues; pushes safe fixes to main, opens PRs for the rest |
| **code-reviewer** | sonnet | Adversarially reviews new commits on main (anyone's) and open PRs; opens `code-concern` issues |

There is no manager: it is one small repo. The monitor also does the
log-reviewer's job (the `curzon_listings` journal).

## How it works

- **The agents run in the live checkout**, `~/git/curzon-listings`, which the
  service runs from. `venv/` and `cache/` there are the service's and untracked.
- **The engineer never edits or runs the app in the live checkout.** It works
  in a throwaway worktree in `/tmp`, checks with the live venv's Python by
  path (render every route through the Flask test client against a copy of the
  live cache, and a live scrape if it touched the scraper), pushes to main, then
  `git pull --ff-only`s the live checkout.
- **Deploying Python and template changes needs you.** Agents can't `sudo`, so
  a pulled fix to `*.py` or `templates/` only runs after you `make restart` in
  `~/git/curzon-listings`. `static/` and `curzon_config.ini` changes apply as
  soon as they are pulled.
- **The engineer leaves your work alone.** If the live checkout isn't on
  `main`, or has uncommitted tracked changes, it skips the cycle and doesn't
  pull. A fix still not running after 24 hours gets a `needs-human-review`
  reminder.
- Runtime fixes stay `awaiting-verification` until the fix has been running
  for two hours with the failure absent.
- **The OCAPI token is a secret.** All agents are told never to log, commit or
  quote it.

## Setup (once)

The service needs Google Chrome (`/usr/bin/google-chrome`) and the venv from
`make install`; the engineer reuses that venv and needs `gh` and `curl`.
Create the labels on the repo (see below).

## Running

```bash
tmux new -s agents-curzon '~/git/software-agents/bin/run-team curzon'
tmux attach -t agents-curzon

# One agent, once
~/git/software-agents/bin/run-agent curzon monitor
```

Each agent sleeps an hour after an idle cycle and 5 minutes after doing work;
the monitor always sleeps an hour. Settings are in `team.sh`.

Logs: `~/git/software-agents/logs/curzon/agent-<agent>.log`. The
code-reviewer keeps the hashes it has reviewed in
`logs/curzon/code-reviewer-reviewed.txt`; delete it to re-review the last 7 days.

## Giving the engineer a task

```bash
gh issue create -R ianmiell/curzon-listings \
  --title "short description" --body "full details" --label agent-task
```

Label `agent-task-high` for priority. Comments never trigger an agent; to hand
a `needs-human-review` issue to the engineer, swap the label to `agent-task`.

## What goes to main without human review

Fixes to `curzon.py`, `app.py`, `templates/` and `static/` that pass the
engineer's check, small additive features, and docs. `requirements.txt`, the
`Makefile`, `deploy/` (systemd unit, nginx snippet), `cat_listings.sh` (the
webhook), `curzon_config.ini` (your venue notes, films seen, sites, refresh
interval), removals, and anything that makes the scraper hit curzon.com more
often go through a PR labeled `needs-human-review`.

## GitHub labels

| Label | Raised by | Meaning |
|---|---|---|
| `agent-task` | human, triage | Task for the engineer |
| `agent-task-high` | human | High-priority engineer task |
| `triaged` | triage | Already triaged; triage skips it |
| `listings-anomaly` | monitor | Service down, public URL failing, stale or incomplete listings, or repeated scrape errors |
| `code-concern` | code-reviewer | Bug or risk in a commit |
| `critical` | code-reviewer | Requires immediate attention |
| `needs-human-review` | triage, engineer | Needs a human decision, approval or deploy |
| `awaiting-verification` | engineer | Fix pushed; waiting for a deploy (pull, and restart for Python/templates) and two clean hours |

```bash
for label in "agent-task:0075ca:Task for the engineer agent" \
             "agent-task-high:e11d48:High-priority engineer task" \
             "triaged:c5def5:Triaged by the triage agent" \
             "listings-anomaly:d93f0b:Raised by monitor" \
             "code-concern:f9d0c4:Raised by code-reviewer" \
             "critical:b60205:Requires immediate attention" \
             "needs-human-review:0e8a16:Needs a human decision, approval or deploy" \
             "awaiting-verification:fbca04:Fix pushed; waiting for a clean post-deploy run"; do
  name="${label%%:*}"; rest="${label#*:}"; color="${rest%%:*}"; desc="${rest#*:}"
  gh label create "$name" --color "$color" --description "$desc" \
    -R ianmiell/curzon-listings 2>&1 || true
done
```
