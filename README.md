# software-agents

Teams of autonomous Claude Code agents that maintain other projects. Each team
lives in `teams/<team>/` and runs against its own target repo(s).

## Layout

```
bin/
  run-agent <team> <agent>   run one agent once
  run-team <team>            run all of a team's agents in loops (use tmux)
  notify <team> "<subject>"  email the team's NOTIFY_TO (body on stdin; SMTP config in ~/.config/software-agents/notify.env)
  rotate-logs <team>         rotate team logs daily, gzip after 3 days, delete after 31 (run-team runs it)
  watch-issues <team>        wake the team's agents when a GitHub issue changes (run-team runs it)
systemd/
  software-agents@.service   systemd user unit running run-team <team> (instance = team)
teams/<team>/
  .claude-plugin/plugin.json the team is loaded as a Claude Code plugin
  agents/<agent>.md          agent definitions (frontmatter sets model and tools)
  team.sh                    working dir, log dir, sleeps, issue poll, prompt per agent
  README.md                  roles, labels, how to give the team work
```

`run-agent` sources the team's `team.sh`, `cd`s into `WORK_DIR` (so the agent
sees that repo's git context and `AGENTS.md`), and runs:

```bash
claude --dangerously-skip-permissions --plugin-dir teams/<team> \
  --model <from frontmatter> --agent <team>:<agent> -p "<PROMPT[agent]>"
```

Output is appended to `$LOG_DIR/agent-<agent>.log`.

## Teams

| Team | Target | Docs |
|---|---|---|
| `ianmiell` | every `ianmiell` GitHub repo, forks included, except archived repos and its ignore list | [teams/ianmiell/README.md](teams/ianmiell/README.md) |

## Running as a service

`systemd/software-agents@.service` runs `bin/run-team <team>` as a systemd
user service, `software-agents@<team>`: no sudo, started at boot (lingering is
on for this user), restarted a minute after a crash.

Install once (a symlink, so `git pull` updates the unit; run
`systemctl --user daemon-reload` after a pull that changes it):

```bash
ln -sf ~/git/software-agents/systemd/software-agents@.service ~/.config/systemd/user/
systemctl --user daemon-reload
```

Then, per team:

```bash
systemctl --user enable --now software-agents@ianmiell   # start now and at boot
systemctl --user status software-agents@ianmiell
journalctl --user -u software-agents@ianmiell -f         # run-team's output
systemctl --user restart software-agents@ianmiell        # after changing team.sh
systemctl --user disable --now software-agents@ianmiell  # stop, and don't start at boot
```

Each agent still logs to `$LOG_DIR/agent-<agent>.log`. Stopping or restarting
kills any agent mid-cycle. Don't also run the team in tmux: two copies would
work the same issues. Changes to agent definitions, the repo lists and prompts
in `team.sh` are picked up at each agent's next cycle without a restart; sleeps
and the agent list need one.

The unit sets `PATH` for `claude`, `gh`, `python3` and `node` (nvm's
v22.17.1). If one moves, put a full `PATH=...` line in
`~/.config/software-agents/env` and restart.

## Adding a team

1. `mkdir -p teams/<team>/.claude-plugin teams/<team>/agents`
2. Add `plugin.json` with `"name": "<team>"` (the name must match the folder;
   `run-agent` calls agents as `<team>:<agent>`).
3. Write `agents/<agent>.md` with `name`, `description`, `model`, `tools`
   frontmatter.
4. Copy `teams/ianmiell/team.sh` and set `WORK_DIR`, `LOG_DIR`, `AGENTS`,
   `PROMPT`, `MIN_SLEEP`/`MAX_SLEEP` and `IDLE_PATTERNS`.
5. Try one agent with `bin/run-agent <team> <agent>`, then run the team as a
   service (`systemctl --user enable --now software-agents@<team>`) or with
   `tmux new -s agents-<team> '~/git/software-agents/bin/run-team <team>'`.

Project knowledge the agents learn at runtime (log quirks, API workarounds)
belongs in the target repo's `AGENTS.md`, which they read before working on
that repo; keep team mechanics here.
