# Dotfiles

Personal terminal and Claude Code configuration.

## Structure

```
terminal/
  .tmux.conf             # tmux config (mouse, scrollback, sync-panes)
  starship.toml          # Starship prompt theme

claude/
  settings.json          # Claude Code settings (plugins, hooks, env vars)
  hooks/
    notify.sh            # Desktop + sound notifications on Stop/Permission/Notification
  skills/
    cs-research-team/    # Coordinate CS PhD research with agent teams
    lit-review-team/     # Run literature reviews with agent teams
    lit-review-team-old/ # Previous lit-review skill version
```

## Install

```bash
git clone https://github.com/Asonjay/claude-skills.git dotfiles
cd dotfiles
./install.sh
```

The interactive installer lets you pick what to set up:

1. **Terminal** — symlinks tmux and starship configs, optionally adds starship init to `.bashrc`
2. **Claude Code** — copies settings/hooks, symlinks skills, adds the `anthropics/claude-code` marketplace, checks for notification dependencies (`paplay`, `notify-send`)
3. **Everything**

Existing files are backed up before being replaced.

## Claude Code Plugins

These are auto-installed by Claude Code when enabled in `settings.json`:

| Plugin | Marketplace | What it provides |
|--------|------------|------------------|
| `superpowers` | `claude-plugins-official` | Development workflows: brainstorming, TDD, debugging, code review, git worktrees, parallel agents |
| `document-skills` | `anthropic-agent-skills` | PDF, DOCX, PPTX, XLSX manipulation, web artifacts, MCP builder |
| `fine-tuning` | `ai-research-skills` | Axolotl, LLaMA-Factory, PEFT, Unsloth guidance |
| `post-training` | `ai-research-skills` | GRPO, RLHF, DPO, SimPO, TRL, veRL guidance |
| `inference-serving` | `ai-research-skills` | vLLM, SGLang, TensorRT-LLM, llama.cpp guidance |
| `frontend-design` | `anthropics-claude-code` | Production-grade frontend UI with bold design choices, typography, animations |

Plugin format: `<plugin-name>@<marketplace-name>`. Claude Code resolves marketplace names to GitHub repos and downloads them to `~/.claude/plugins/cache/`.

The `frontend-design` plugin requires the `anthropics/claude-code` marketplace (the installer adds it automatically, or run `claude plugin marketplace add anthropics/claude-code`).

## Custom Skills

### CS Research Team
Spawns literature, implementation, experiments, and writing agents:
```bash
/cs-research-team ./plans/my-research.md
/cs-research-team ./plans/my-research.md 4   # specify team size
```

### Literature Review Team
Spawns reader, scaffolder, and synthesizer agents:
```bash
/lit-review-team ./plans/review-plan.md
/lit-review-team ./plans/review-plan.md 3   # specify team size
```

## Agent Teams

Agent teams are experimental. The `settings.json` already includes:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Or export in your shell:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```
