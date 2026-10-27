# ianmiell agent team

Maintains every repo owned by [`ianmiell`](https://github.com/ianmiell) on
GitHub, forks included, except archived repos and the repos in `ignore-repos.txt`.
Project knowledge belongs in each target repo's `AGENTS.md`; the agents read it
before working there.

## Roles

| Agent | Model | Role |
|---|---|---|
| **triage** | haiku | Labels your new un-triaged issues `agent-task` (engineer) or `needs-human-review`, then `triaged` |
| **engineer** | sonnet | Works one `agent-task` issue per cycle: pushes to the default branch, or opens a PR in `pr` repos |
| **code-reviewer** | sonnet | Adversarially reviews new commits on default branches (anyone's) and your open PRs; opens `code-concern` issues |

There is no monitor or log-reviewer: those depend on how each project runs.

## Which repos, and how

`repos` decides, from two lists in this folder (one repo name per line, `#`
comments):

| File | Effect |
|---|---|
| `ignore-repos.txt` | The team leaves the repo alone: no triage, engineering or review |
| `pr-repos.txt` | The engineer opens a PR labeled `needs-human-review` instead of pushing to the default branch |

**The ignore list wins**: a repo in both is ignored. Every other repo is worked
directly on its default branch. Archived repos are always ignored; forks are
watched like any other repo.

```bash
teams/ianmiell/repos list               # watched repos and their mode
teams/ianmiell/repos mode curzon-listings
```

Edits to the lists take effect at each agent's next cycle; no restart needed.

## How it works

- **The agents run in `work/ianmiell/`**, outside any target repo. The
  engineer keeps a clone of each repo it works on there and resets it freely.
- **Your checkouts are left alone.** After pushing to a repo's default branch,
  the engineer `git pull --ff-only`s `~/git/<repo>` only if that checkout is on
  the default branch with no uncommitted changes. It never edits or runs
  anything there, and never deploys.
- **Even in `main` repos, destructive changes go through a PR**: deleting or
  overwriting data, or removing a feature, script or option.
- **The agents only act on your issues**: ones `ianmiell` opened, or has
  commented on, labeled or edited (`repos mine <repo> <N>`). Others' issues
  get no comment, label or code, and comments by others on your issues are
  treated as information, not instructions. The code-reviewer only reviews PRs
  you opened. To have a stranger's issue handled, comment on it or label it
  `agent-task`. Since the agents post as `ianmiell` too, their comments start
  `**Triage:**` or `**Engineer:**`.
- **Triage only looks at issues updated on or after `TRIAGE_SINCE`** in
  `team.sh`, so years-old issues on old repos aren't handed to the engineer.
  Label an older issue `agent-task` yourself to have it worked.
- **Labels are created per repo on first use** (`repos labels <repo>`).
- The agents find work through `gh search` across the owner, so polling doesn't
  grow with the number of repos. GitHub search can lag a minute or two behind.

## Email

The agents email `NOTIFY_TO` in `team.sh` (ian.miell@gmail.com) over SMTP
with `bin/notify ianmiell`, at most one email per agent per cycle, when
something significant happened:

| From | When |
|---|---|
| triage | An issue was routed to you (`needs-human-review`) |
| engineer | It pushed a commit, opened a PR, or asked a question on an issue |
| code-reviewer | It opened or reopened a `code-concern` issue, or commented findings on a PR |
| run-agent | An agent started exiting non-zero, and again when it recovers |

Subjects start `[ianmiell]` (`CRITICAL` first for critical findings). Idle
cycles send nothing. Every notification is also appended to
`logs/notifications.log`, sent or not, so nothing is lost while email isn't
set up.

`bin/notify` takes the recipient only from `team.sh`; nothing an agent passes
can change it. The agents are also told never to send email any other way.

Setup (once): make a Gmail [app password](https://myaccount.google.com/apppasswords)
for the account to send from, and put the SMTP settings in a file readable only
by you (the recipient is not set here):

```bash
mkdir -p ~/.config/software-agents
install -m 600 /dev/null ~/.config/software-agents/notify.env
cat > ~/.config/software-agents/notify.env <<'EOF'
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=ian.miell@gmail.com
SMTP_PASSWORD=<app password>
EOF
echo test | ~/git/software-agents/bin/notify ianmiell "[ianmiell] test"
```

## Running

As a systemd user service (install the unit once as in the
[top-level README](../../README.md#running-as-a-service)):

```bash
systemctl --user enable --now software-agents@ianmiell
journalctl --user -u software-agents@ianmiell -f
systemctl --user disable --now software-agents@ianmiell   # stop
```

Or in tmux, not both at once:

```bash
tmux new -s agents-ianmiell '~/git/software-agents/bin/run-team ianmiell'

# One agent, once
~/git/software-agents/bin/run-agent ianmiell triage
```

Each agent backs off on its own. After a cycle that did work it sleeps 30
seconds; after each idle or failed cycle it sleeps twice as long as last time
(30s, 1m, 2m, 4m ... up to an hour, or 5 minutes for triage). So a new issue
is triaged within 5 minutes and then worked on quickly. When an
agent finishes a cycle that did work, it also wakes all the other agents (via
`logs/ianmiell/.wake`), which end their sleep early and restart their backoff
at 30s. Settings
(`MIN_SLEEP`, `MAX_SLEEP`, `AGENT_MAX_SLEEP`) are in `team.sh`; restart the service after
changing them.

Logs: `~/git/software-agents/logs/ianmiell/agent-<agent>.log`. The
code-reviewer keeps the commits and PR heads it has reviewed in
`logs/ianmiell/code-reviewer-reviewed.txt`; delete it to re-review the last 7
days (20 commits and 5 PRs per cycle).

## Giving the engineer a task

```bash
gh issue create -R ianmiell/<repo> --title "short description" --body "full details" --label agent-task
```

Label `agent-task-high` for priority (run `teams/ianmiell/repos labels <repo>`
first if the repo has never had the team's labels). Comments never trigger an
agent; to hand a `needs-human-review` issue to the engineer, swap the label to
`agent-task`.

## GitHub labels

| Label | Raised by | Meaning |
|---|---|---|
| `agent-task` | human, triage | Task for the engineer |
| `agent-task-high` | human | High-priority engineer task |
| `triaged` | triage | Already triaged; triage skips it |
| `code-concern` | code-reviewer | Bug or risk in a commit |
| `critical` | code-reviewer | Requires immediate attention |
| `needs-human-review` | triage, engineer | Needs a human decision, approval or deploy |
