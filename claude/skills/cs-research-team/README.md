# CS Research Team

A Claude Code skill for conducting CS PhD research projects using [Agent Teams](https://www.anthropic.com/news/claude-opus-4-6) — Anthropic's multi-agent collaboration feature where multiple Claude instances work in parallel, communicate with each other, and coordinate autonomously. Give it a research plan describing your project, and it spawns a team of specialized agents in tmux split panes to handle literature review, implementation, experiments, and paper writing.

Once set up, it's as simple as:

```bash
/cs-research-team [plan-path] [num-agents]
```

## Prerequisites

### 1. Install tmux

Agent teams use tmux for split-pane visualization so you can see all agents working simultaneously.

**macOS:**
```bash
brew install tmux
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update && sudo apt install tmux
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install tmux
```

**Windows (WSL required):**

Agent teams require WSL (Windows Subsystem for Linux). Native Windows is not supported.

```powershell
# 1. Install WSL from PowerShell (Admin)
wsl --install

# 2. Restart your computer

# 3. Open WSL and install tmux
sudo apt update && sudo apt install tmux
```

Verify installation:
```bash
tmux -V
```

### 2. Enable Agent Teams

Agent teams are experimental and disabled by default. Enable by adding to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Or export in your shell profile (`~/.bashrc` or `~/.zshrc`):
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Installation

Copy the skill to your personal skills directory:

```bash
cp -r cs-research-team ~/.claude/skills/
```

Or for project-level use:
```bash
cp -r cs-research-team .claude/skills/
```

## Create Your Research Plan

Write a markdown document describing your research project. This works for:

- **New research**: A novel method, algorithm, or system from scratch
- **Extending existing work**: Building on prior methods with new contributions
- **Empirical studies**: Large-scale benchmarking or comparison studies
- **Systems papers**: Building and evaluating research infrastructure

Your plan should be detailed enough that multiple agents could divide the work. Include:

- Research question and hypothesis
- Key contributions (what's novel)
- Proposed method/algorithm
- Related work areas to survey
- Datasets and evaluation metrics
- Experiment design (baselines, ablations, configurations)
- Target venue and formatting requirements
- Acceptance criteria (what results would validate the hypothesis)

See `example-plan/residual-rl-grasping-plan.md` for an example.

## Usage

```bash
/cs-research-team [plan-path] [num-agents]
```

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `plan-path` | Yes | Path to your research plan markdown file |
| `num-agents` | No | Number of agents to spawn. If omitted, determined automatically based on the plan's complexity |

**Examples:**

```bash
# Let the skill determine team size
/cs-research-team ./plans/my-research.md

# Specify 3 agents (literature + implementation + experiments/writing)
/cs-research-team ./plans/my-research.md 3

# Full 4-agent team for a complete paper
/cs-research-team ./plans/novel-algorithm.md 4

# Pair for quick empirical study
/cs-research-team ./plans/benchmark-study.md 2
```

The skill will:
1. Read your research plan
2. Analyze it to determine agent roles (literature, implementation, experiments, writing)
3. Spawn agents in tmux split panes
4. Coordinate specification sharing between agents
5. Ensure agents communicate and challenge each other's methodology

## Agent Roles

Typical agent roles for CS research projects:

| Role | Responsibilities |
|------|-----------------|
| **Literature** | Survey related work, identify baselines, establish notation conventions, gap analysis |
| **Implementation** | Build proposed method, baselines, data pipeline, ensure reproducibility |
| **Experiments** | Design experiment matrix, run evaluations, compute statistics, generate figures |
| **Writer** | Draft paper sections, compile LaTeX, ensure consistency across all artifacts |

## Research Teams vs Software Teams

| | Software Build Team | CS Research Team |
|---|---------------------|-----------------|
| **Contracts** | API endpoints, response shapes, URL conventions | Data formats, evaluation protocols, notation |
| **Artifacts** | Frontend, backend, database | Literature survey, code, experiments, paper |
| **Validation** | E2E browser testing, server startup | Reproducibility, statistical tests, LaTeX compilation |
| **Cross-cutting** | Trailing slashes, error shapes, SSE format | Notation, figure style, citation format, seeds |
| **Definition of done** | App runs, all features work | Results support hypothesis, paper compiles, numbers match |

## Key Differences from Software Development Teams

1. **Specification-first, not contract-first**: Research agents agree on data formats, metrics, and notation — not API endpoints
2. **Reproducibility is paramount**: Every experiment must log seeds, hyperparameters, and environment specs
3. **Numbers must match**: Tables in the paper must reference actual output files — no manual copying
4. **Cross-review is methodological**: Agents check each other's scientific rigor, not just code quality
5. **The final artifact is a paper**: Everything converges to a compilable, submission-ready document
