# curzon agent team

Maintains [`ianmiell/curzon-listings`](https://github.com/ianmiell/curzon-listings),
which scrapes London Curzon cinema showtimes from curzon.com with puppeteer,
loads them into SQLite and publishes a plain-text listings page to
`/var/www/ianmiell.com/curzon-listings`. The repo's `AGENTS.md` holds how the
pipeline works; the agents read it because they run in the repo.

## Roles

| Agent | Model | Role |
|---|---|---|
| **monitor** | haiku | Checks the capture, database and published file for staleness, missing venues and errors; opens `listings-anomaly` issues |
| **triage** | haiku | Labels un-triaged issues `agent-task` (engineer) or `needs-human-review`, then `triaged` |
| **engineer** | sonnet | Works `agent-task` issues; pushes safe fixes to main, opens PRs for the rest |
| **code-reviewer** | sonnet | Adversarially reviews new commits on main (anyone's) and open PRs; opens `code-concern` issues |

There is no manager: it is one small repo. There is no log-reviewer either:
the pipeline is a cron job, so the monitor checks its outputs (and the cron log,
if the crontab redirects to one).

## How it works

- **The agents run in the live checkout**, `~/git/curzon-listings`, which
  cron runs the scrape from. Cron rewrites `curzon_listings.txt` there, so that
  file being modified is normal.
- **The engineer never edits or runs the pipeline in the live checkout.** It
  works in a throwaway worktree in `/tmp` (the scripts write the database,
  tokens and listings relative to the current directory, and its check strips
  the `/var/www` copy), pushes to main, then `git pull --ff-only`s the live
  checkout. So a fix goes live at the next cron run.
- **The engineer leaves your work alone.** If the live checkout isn't on
  `main`, or has uncommitted changes other than `curzon_listings.txt`, it skips
  the cycle and doesn't pull. A fix still not pulled after 24 hours gets a
  `needs-human-review` reminder.
- **Agents cannot `make install`** (it needs `sudo`). Makefile and dependency
  changes go through a PR, and you run `make install` after merging.
- Runtime fixes stay `awaiting-verification` until a scheduled run has
  published clean listings with the fix pulled in.
- **`curzon_tokens*.json` hold bearer tokens.** All agents are told never to
  commit them or quote their values in issues.

## Setup (once)

The engineer needs `node` (with puppeteer's Chrome in `~/.cache/puppeteer`),
`jq`, `sqlite3` and `python3` on `PATH`, and uses the live checkout's
`node_modules`. Create the labels on the repo (see below).

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

Fixes to the capture JS, jq parsing, `import_showtimes.py` and the query SQL,
small additive features, and docs. The `Makefile`, the publish path, the
crontab, `package.json`/`package-lock.json`, your VENUE GUIDE and FILMS SEEN
notes, which venues are listed, and removals go through a PR labeled
`needs-human-review`.

## GitHub labels

| Label | Raised by | Meaning |
|---|---|---|
| `agent-task` | human, triage | Task for the engineer |
| `agent-task-high` | human | High-priority engineer task |
| `triaged` | triage | Already triaged; triage skips it |
| `listings-anomaly` | monitor | Stale, empty or incomplete listings, or a failed capture |
| `code-concern` | code-reviewer | Bug or risk in a commit |
| `critical` | code-reviewer | Requires immediate attention |
| `needs-human-review` | triage, engineer | Needs a human decision, approval or deploy |
| `awaiting-verification` | engineer | Fix pushed; waiting for a deploy and a clean scheduled run |

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
