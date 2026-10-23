# software-agents

Teams of autonomous Claude Code agents that maintain other projects. Each team
lives in `teams/<team>/` and runs against its own target repo(s).

## Layout

```
bin/
  run-agent <team> <agent>   run one agent once
  run-team <team>            run all of a team's agents in loops (use tmux)
teams/<team>/
  .claude-plugin/plugin.json the team is loaded as a Claude Code plugin
  agents/<agent>.md          agent definitions (frontmatter sets model and tools)
  team.sh                    working dir, log dir, sleeps, prompt per agent
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
| `rightmove` | `rightmove-*` repos, run from `~/git/rightmove-data-scraper` | [teams/rightmove/README.md](teams/rightmove/README.md) |
| `busstop` | `transport_tracker`, run from its own clone `~/git/transport_tracker-agents` | [teams/busstop/README.md](teams/busstop/README.md) |
| `curzon` | `curzon-listings`, run from its own clone `~/git/curzon-listings-agents` | [teams/curzon/README.md](teams/curzon/README.md) |

## Adding a team

1. `mkdir -p teams/<team>/.claude-plugin teams/<team>/agents`
2. Add `plugin.json` with `"name": "<team>"` (the name must match the folder;
   `run-agent` calls agents as `<team>:<agent>`).
3. Write `agents/<agent>.md` with `name`, `description`, `model`, `tools`
   frontmatter.
4. Copy `teams/rightmove/team.sh` and set `WORK_DIR`, `LOG_DIR`, `AGENTS`,
   `PROMPT`, sleeps and `IDLE_PATTERNS`.
5. Try one agent with `bin/run-agent <team> <agent>`, then
   `tmux new -s agents-<team> '~/git/software-agents/bin/run-team <team>'`.

Project knowledge the agents learn at runtime (log quirks, API workarounds)
belongs in the target repo's `AGENTS.md`, which they load because they run
there; keep team mechanics here.
