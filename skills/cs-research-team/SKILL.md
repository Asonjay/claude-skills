---
name: cs-research-team
description: Coordinate a CS PhD research project using Claude Code Agent Teams with tmux split panes. Takes a research plan document path and optional team size. Use when you want multiple agents collaborating on literature review, experiment development, analysis, and paper writing.
argument-hint: [plan-path] [num-agents]
disable-model-invocation: true
---

# CS Research Team

You are coordinating a CS PhD research project using Claude Code Agent Teams. Read the research plan, determine the right team structure, spawn teammates, and orchestrate the research workflow.

## Arguments

- **Plan path**: `$ARGUMENTS[0]` - Path to a markdown file describing the research project
- **Team size**: `$ARGUMENTS[1]` - Number of agents (optional)

## Step 1: Read the Research Plan

Read the plan document at `$ARGUMENTS[0]`. Understand:
- What is the research question or hypothesis?
- What are the key contributions?
- What methods/algorithms are involved?
- What experiments need to be run?
- What baselines and evaluation metrics are required?
- What is the target venue and formatting requirements?

## Step 2: Determine Team Structure

If team size is specified (`$ARGUMENTS[1]`), use that number of agents.

If NOT specified, analyze the plan and determine the optimal team size based on:
- **Scope of literature review** (how many related areas to cover?)
- **Implementation complexity** (new algorithms, baselines, data pipelines?)
- **Experiment workload** (how many experiments, ablations, baselines?)
- **Analysis and writing needs** (figures, tables, proofs, paper sections?)

**Guidelines:**
- 2 agents: Focused projects — one coder/experimenter + one writer/analyst
- 3 agents: Standard research — literature + implementation + analysis/writing
- 4 agents: Full pipeline — literature, implementation, experiments/analysis, writing
- 5+ agents: Large projects with multiple independent algorithmic components or multi-paper efforts

For each agent, define:
1. **Name**: Short, descriptive (e.g., "literature", "implementation", "experiments", "writer")
2. **Ownership**: What files/directories they own exclusively
3. **Does NOT touch**: What's off-limits (prevents conflicts)
4. **Key responsibilities**: What they're producing

## Step 3: Set Up Agent Team

Enable tmux split panes so each agent is visible:

```
teammateMode: "tmux"
```

Before spawning, enter **Delegate Mode** (Shift+Tab) to restrict yourself to coordination only. You should NOT implement code or write paper sections yourself.

## Step 4: Specification-First Spawning

**CRITICAL LESSON:** Research agents building in parallel WILL diverge on data formats, evaluation protocols, notation conventions, and experiment configurations unless they agree on specifications FIRST. The lead must enforce a **spec-first, build-second** protocol.

### Identify the Artifact Chain

Before spawning anyone, map out the dependency chain of research artifacts:

```
Literature Review  → publishes related work summary + gap analysis       → Implementation
Implementation     → publishes code interface + data format spec         → Experiments
Experiments        → publishes results tables + figures                  → Writer
Literature Review  → publishes notation/terminology conventions          → Writer
```

Agents UPSTREAM in this chain must publish their specification BEFORE downstream agents start building. This means spawning is **staggered, not fully parallel**.

### Spawn Order

1. **Spawn upstream agents first** (e.g., literature reviewer, then implementation)
2. Each upstream agent's FIRST task is: define and send their specification via SendMessage
3. **Lead receives and verifies the specification** — check for ambiguities, missing details
4. **Lead forwards the verified spec to downstream agents** — do NOT rely on agents messaging each other
5. **Only then spawn or unblock downstream agents** with the specification included in their prompt

### Lead as Active Specification Relay

**Do NOT just tell agents "share your findings with the other agent."** This fails because:
- The upstream agent may finish and share too late
- The downstream agent may already be building with wrong assumptions
- Messages between agents may be missed or unclear

Instead, the lead must:
1. Receive the specification from the producing agent
2. **Verify it** — check for: consistent notation, complete metric definitions, exact data format schemas, clear experimental protocols
3. **Forward it to consuming agents** with explicit instructions: "Build to this specification exactly. Do not deviate."

### Identify Cross-Cutting Concerns

Some research artifacts span multiple agents and WILL fall through the cracks unless explicitly assigned. Before spawning, identify these from the plan and assign ownership:

Common cross-cutting concerns in CS research:
- **Notation conventions**: Variable names, mathematical symbols, acronyms — must be consistent across code, figures, and paper
- **Data format**: How datasets are loaded, stored, split — both implementation and experiment agents must agree
- **Evaluation protocol**: Train/val/test splits, number of seeds, confidence intervals, statistical tests — must be identical across all baselines and methods
- **Reproducibility**: Random seeds, hyperparameter logging, environment specs — one agent must own this
- **Figure style**: Color palette, font sizes, axis labels, legend placement — must be consistent across all plots
- **Citation format**: BibTeX style, citation keys, how related work is referenced — must match target venue

Assign each concern to ONE agent with instructions to coordinate with the other.

### Spawn Prompt Structure

```
You are the [ROLE] agent for this research project.

## Your Ownership
- You own: [directories/files]
- Do NOT touch: [other agents' files]

## What You're Producing
[Relevant section from research plan]

## Mandatory Communication (REQUIRED)

### Before You Build
- Your FIRST deliverable is your [specification / interface / protocol]
- Send it to the lead via SendMessage BEFORE writing code or paper text
- Include: exact data format schemas, evaluation metric definitions, notation conventions
- Wait for the lead to confirm before proceeding

### The Specification You Must Conform To
[Include the upstream agent's verified specification here]

### Cross-Cutting Concerns You Own
[Explicitly list research artifacts this agent is responsible for standardizing]

## Coordination
- Share with [other agent] when: [trigger]
- Ask [other agent] about: [dependency]
- Challenge [other agent]'s work on: [methodology point]
```

## Step 5: Facilitate Collaboration

Research teams are NOT just parallel workers. They must communicate. The lead enforces this with the spec-first protocol.

### Phase 1: Specifications (Sequential, Lead-Orchestrated)

Spawn agents in dependency order. Each agent's first task is publishing their specification:

1. **Literature agent** → publishes related work taxonomy, gap analysis, notation conventions → lead verifies → forwards to implementation and writer
2. **Implementation agent** → receives literature context → publishes code API, data format spec, model interface → lead verifies → forwards to experiments
3. **Experiments agent** → receives code interface + data format → publishes experiment protocol (metrics, baselines, splits, seeds) → lead verifies → forwards to writer
4. **Writer agent** → receives all specs → builds paper conforming to established notation, cites correctly, references exact table/figure numbers

**Lead verification checklist for research specifications:**
- Are notation conventions explicit and consistent? (e.g., bold for vectors, calligraphic for sets)
- Are data format schemas exact? (e.g., CSV columns, tensor shapes, file naming conventions)
- Are evaluation metrics precisely defined? (e.g., "top-1 accuracy on test set, averaged over 5 seeds with std")
- Are baselines clearly specified? (exact implementations, hyperparameters, whether re-run or from paper)
- Are there any train/test leakage risks to address?
- Are statistical significance tests specified? (e.g., paired t-test, Wilcoxon, bootstrap CI)

### Phase 2: Implementation (Parallel where safe)

Once specifications are verified, agents build in parallel. They MUST:
- Send a message to the lead when they discover something that affects the specification
- Ask before deviating from the agreed protocol
- Flag cross-cutting concerns that weren't anticipated

### Phase 3: Pre-Completion Specification Verification

Before any agent reports "done", the lead runs a **spec diff**:
- "Implementation: what exact data format does your model output?"
- "Experiments: what exact data format are you loading results from?"
- "Writer: what exact table columns are you referencing?"
- Lead compares and flags mismatches BEFORE integration

### Phase 4: Cross-Review

Each agent reviews another's work for correctness:
- Writer reviews Implementation for algorithmic correctness against paper description
- Implementation reviews Experiments for correct usage of the code API
- Experiments reviews Writer for accurate reporting of results
- Literature reviews Writer for proper citations and positioning

## Collaboration Anti-Patterns

**Anti-pattern 1: Fully parallel spawn** (agents diverge)
```
Lead spawns literature + implementation + writer simultaneously
Writer uses different notation than implementation
Experiments use different metrics than what writer describes ❌
```

**Anti-pattern 2: Late specification sharing** (rework required)
```
Implementation finishes → shares data format with experiments
Experiments already wrote loading code with wrong tensor shapes → has to redo ❌
```

**Anti-pattern 3: "Tell them to talk"** (they won't reliably)
```
Lead tells implementation "share your API with experiments"
Implementation sends spec but experiments already hardcoded paths ❌
```

**Good pattern: Spec-first with lead relay**
```
Implementation publishes data format → Lead verifies → Lead forwards to experiments with "build to this exactly"
Experiments builds to verified spec → zero integration mismatches ✅
```

**Good pattern: Active research collaboration**
```
Agent A: "Here's my model output format — Agent B, does this work for your evaluation script?"
Agent B: "I need a confidence score column for the ROC analysis"
Agent A: "Good catch, adding `pred_confidence` to output CSV"
Agent C: "I see you're using accuracy — should we also report F1 for the imbalanced classes?"
```

## Task Management

Create a shared task list with dependencies:

```
[ ] Literature: Search and summarize related work
[ ] Literature: Identify baselines and evaluation protocols
[ ] Implementation: Set up project structure and data pipeline (blocked by Literature notation)
[ ] Implementation: Implement proposed method
[ ] Implementation: Implement baselines (blocked by Literature baseline identification)
[ ] Experiments: Design experiment matrix (blocked by Implementation API)
[ ] Experiments: Run main experiments (blocked by Implementation)
[ ] Experiments: Run ablation studies (blocked by main experiments)
[ ] Analysis: Generate figures and tables (blocked by Experiments)
[ ] Writer: Draft introduction and related work (blocked by Literature)
[ ] Writer: Draft method section (blocked by Implementation)
[ ] Writer: Draft experiments section (blocked by Analysis)
[ ] Writer: Compile full paper and verify LaTeX (blocked by all sections)
```

Track progress and unblock agents when dependencies complete.

## Common Pitfalls to Prevent

1. **File conflicts**: Two agents editing the same file → Assign clear ownership
2. **Lead over-implementing**: You start coding → Stay in Delegate Mode
3. **Isolated work**: Agents don't communicate → Require explicit handoffs via lead relay
4. **Vague boundaries**: "Help with experiments" → Specify exact scripts/responsibilities
5. **Missing dependencies**: Experiments agent waits on implementation forever → Track blockers actively
6. **Fully parallel spawn**: All agents start simultaneously → Notation/format divergence. Spawn upstream agents first, get specs, then spawn downstream
7. **Implicit protocols**: "Evaluate on the test set" → Ambiguous. Require exact splits, seeds, metrics, significance tests
8. **Orphaned cross-cutting concerns**: Figure style, notation, citation format → Nobody owns them. Explicitly assign to one agent
9. **Inconsistent results**: Table in paper doesn't match experiment output → Writer must reference exact output files, not manually copy numbers
10. **Unreproducible experiments**: No seed logging, no environment spec → One agent must own reproducibility

## Definition of Done

The research project is complete when:
1. All agents report their work is done
2. Each agent has validated their own domain
3. Specifications are consistent across all artifacts (code, figures, paper)
4. Cross-review feedback has been addressed
5. The plan's research objectives are met
6. **Lead agent has run end-to-end validation**

---

## Step 6: Validation

Validation happens at two levels: **agent-level** (each agent validates their domain) and **lead-level** (you validate the integrated research output).

### Agent Validation

Before any agent reports "done", they must validate their work. When analyzing the plan, identify what validation each agent should run:

**Literature agent** validates:
- All key related works in the area are covered
- Taxonomy of approaches is coherent and complete
- Gap analysis clearly motivates the proposed contribution
- BibTeX entries are complete and correctly formatted
- No missing citations for claims made

**Implementation agent** validates:
- Code runs without errors on a small test case
- Unit tests pass for core algorithmic components
- Data pipeline correctly loads and preprocesses data
- Model produces outputs in the agreed-upon format
- Dependencies are pinned and documented (requirements.txt / environment.yml)
- Random seeds are set and reproducibility is verified on a toy example

**Experiments agent** validates:
- All baselines run to completion
- Proposed method runs to completion
- Results are saved in the agreed-upon format
- Statistical significance tests are computed
- Ablation studies cover the key design choices
- Hyperparameter configurations are logged
- Training curves / convergence plots are generated

**Writer/Analysis agent** validates:
- LaTeX compiles without errors (`pdflatex` or `latexmk`)
- All figures are generated and referenced correctly
- All tables match the actual experiment outputs (no manual number copying)
- Citations resolve (no undefined references)
- Paper meets page limits for the target venue
- Abstract accurately summarizes contributions and results
- Notation is consistent throughout

When spawning agents, include their validation checklist:

```
## Before Reporting Done

Run these validations and fix any failures:
1. [specific validation command or check]
2. [specific validation command or check]
3. [manual verification if needed]

Do NOT report done until all validations pass.
```

### Lead Validation (End-to-End)

After ALL agents return control to you, run end-to-end validation yourself. This catches integration issues that individual agents can't see.

**Your validation checklist:**

1. **Does the code run end-to-end?**
   - Run the full pipeline from data loading to final results
   - No runtime errors

2. **Are results reproducible?**
   - Run with a fixed seed
   - Compare output to what's reported in the paper
   - Numbers must match exactly

3. **Are all artifacts consistent?**
   - Notation in paper matches variable names in code
   - Table numbers in paper match experiment output files
   - Figure captions accurately describe what's plotted
   - Related work citations are all present in bibliography

4. **Does the paper compile cleanly?**
   - LaTeX compiles with no warnings (undefined references, missing figures)
   - Fits within page limits
   - Formatting matches target venue style

5. **Is the contribution clearly supported?**
   - Claims in the abstract/introduction are backed by experiment results
   - Statistical significance is reported where needed
   - Limitations are acknowledged

If validation fails:
- Identify which agent's domain contains the issue
- Re-spawn that agent with the specific problem
- Re-run validation after fix

### Validation in the Plan

Good research plans include a **Validation** section with specific checks for each component. When reading the plan:

1. Look for a Validation section
2. If present, use those exact checks when instructing agents
3. If absent, derive validation steps from the Research Objectives

Example plan validation section:
```markdown
## Validation

### Literature Validation
[Checklist of areas that must be covered, key papers that must be cited]

### Implementation Validation
[Commands to run unit tests, toy examples, reproducibility checks]

### Experiment Validation
[Commands to verify results, statistical tests, expected baselines]

### Paper Validation
[LaTeX compilation, page limit check, figure/table cross-references]

### End-to-End Validation
[Full pipeline run from data to compiled paper]
```

---

## Execute

Now read the research plan at `$ARGUMENTS[0]` and begin:

1. Read and understand the research plan
2. Determine team size (use `$ARGUMENTS[1]` if provided, otherwise decide)
3. Define agent roles, ownership, **cross-cutting concern assignments**, and **validation requirements for each**
4. **Map the artifact chain** — which agent produces specifications that others consume?
5. Enter Delegate Mode
6. **Spawn upstream agents first** — their first task is publishing their specification
7. **Receive and verify each specification** — check for ambiguities, exact formats, consistent notation
8. **Forward verified specifications to downstream agents** — include in their spawn prompt
9. Spawn downstream agents with verified specs + their validation checklist
10. **Run spec diff before integration** — compare implementation output format vs experiment loading code vs paper table columns
11. When all agents return, run **end-to-end validation yourself** (run pipeline, compile paper, verify numbers match)
12. If validation fails, re-spawn the relevant agent with the specific issue
13. Confirm the research output meets the plan's objectives
