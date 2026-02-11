# Claude Code Skills & Config

Personal Claude Code skills and configuration for multi-agent research workflows.

## What's Inside

```
skills/
  cs-research-team/    # Coordinate CS PhD research with agent teams
  lit-review-team/     # Run literature reviews with agent teams
settings.json          # Claude Code settings (plugins, hooks, env vars)
.tmux.conf             # tmux config for agent team split panes
```

## Installation

### 1. Copy custom skills

```bash
cp -r skills/* ~/.claude/skills/
```

### 2. Copy settings

Merge into your existing settings or replace:

```bash
cp settings.json ~/.claude/settings.json
```

This enables these plugins (installed automatically by Claude Code from their marketplaces):

| Plugin | Marketplace | What it provides |
|--------|------------|------------------|
| `superpowers` | `claude-plugins-official` | Development workflows: brainstorming, TDD, debugging, code review, git worktrees, parallel agents |
| `document-skills` | `anthropic-agent-skills` | PDF, DOCX, PPTX, XLSX manipulation, web artifacts, MCP builder |
| `fine-tuning` | `ai-research-skills` | Axolotl, LLaMA-Factory, PEFT, Unsloth guidance |
| `post-training` | `ai-research-skills` | GRPO, RLHF, DPO, SimPO, TRL, veRL guidance |
| `inference-serving` | `ai-research-skills` | vLLM, SGLang, TensorRT-LLM, llama.cpp guidance |

You don't need to install these plugins manually -- Claude Code fetches them from GitHub when you enable them in `settings.json`.

### 3. Set up tmux

```bash
cp .tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

### 4. Enable Agent Teams

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

## Usage

### CS Research Team

Give it a research plan and it spawns literature, implementation, experiments, and writing agents:

```bash
/cs-research-team ./plans/my-research.md
/cs-research-team ./plans/my-research.md 4   # specify team size
```

### Literature Review Team

Give it a review plan with papers to read and it spawns reader, scaffolder, and synthesizer agents:

```bash
/lit-review-team ./plans/review-plan.md
/lit-review-team ./plans/review-plan.md 3   # specify team size
```

## How Plugins Work

There are two types of skills in Claude Code:

- **Custom skills** (in `~/.claude/skills/`) -- user-created markdown files like the ones in this repo
- **Marketplace plugins** (referenced in `settings.json` under `enabledPlugins`) -- installed from GitHub repos by Claude Code automatically

The `enabledPlugins` section of `settings.json` tells Claude Code which marketplace plugins to fetch:

```json
{
  "enabledPlugins": {
    "document-skills@anthropic-agent-skills": true,
    "superpowers@claude-plugins-official": true,
    "fine-tuning@ai-research-skills": true,
    "post-training@ai-research-skills": true,
    "inference-serving@ai-research-skills": true
  }
}
```

Plugin format: `<plugin-name>@<marketplace-name>`. Claude Code resolves marketplace names to GitHub repos and downloads them to `~/.claude/plugins/cache/`.
