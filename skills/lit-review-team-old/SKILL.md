---
name: lit-review-team-old
description: "[DEPRECATED - use lit-review-team] Old sequential version. Conduct a CS literature review using Claude Code Agent Teams."
argument-hint: [plan-path] [num-agents]
disable-model-invocation: true
---

# Literature Review Team

You are coordinating a CS literature review using Claude Code Agent Teams. Read the review plan, determine the right team structure, spawn teammates, and orchestrate the review process.

## Arguments

- **Plan path**: `$ARGUMENTS[0]` - Path to a markdown file describing the review scope
- **Team size**: `$ARGUMENTS[1]` - Number of agents (optional, default 3)

## Step 1: Read the Review Plan

Read the plan document at `$ARGUMENTS[0]`. Understand:
- What is the research question or topic?
- What papers need to be reviewed? (arxiv URLs, PDF paths, titles, or topic areas to search)
- What is the reader's background level? (determines scaffolding depth)
- What output format is needed? (related work section, standalone survey, annotated bibliography)
- Are there specific concepts or terminology areas the user finds unfamiliar?
- What is the target venue or context? (e.g., "related work for my NeurIPS submission on X")

## Step 2: Determine Team Structure

If team size is specified (`$ARGUMENTS[1]`), use that number of agents.

Default is 3 agents. Guidelines:

- **2 agents**: Small review (≤10 papers) — one reader/scaffolder + one synthesizer
- **3 agents** (default): Standard review — reader + scaffolder + synthesizer
- **4 agents**: Large survey (30+ papers) or multiple sub-topics — split reading across two reader agents by sub-topic

### Agent Roles

**Reader** — The paper analyst
- Reads each paper (PDFs, arxiv pages, or searches for papers by topic)
- Extracts structured summaries: problem, method, key results, limitations, connections
- Identifies which papers cite or build on each other
- Tags terminology that may need explanation
- Produces a consistent per-paper summary in a standard format

**Scaffolder** — The terminology explainer
- Receives the reader's paper summaries and tagged terminology
- Explains each unfamiliar concept in plain language with examples
- Builds a glossary organized by concept area
- Adds context: why this concept matters, how it connects to other concepts
- Identifies prerequisite knowledge chains (concept A requires understanding concept B)
- Produces a "Concept Guide" document the user can reference alongside the review

**Synthesizer** — The review writer
- Receives paper summaries + concept guide
- Organizes papers into a taxonomy (by approach, by problem, by chronology — whichever fits)
- Identifies themes, trends, gaps, and contradictions across papers
- Writes the actual literature review as flowing prose (not bullet points)
- Ensures every claim cites the source paper
- Highlights the research gap that motivates the user's work (if specified in the plan)

## Step 3: Set Up Agent Team

Enable tmux split panes:

```
teammateMode: "tmux"
```

Enter **Delegate Mode** (Shift+Tab). You coordinate — you do not read papers or write the review yourself.

## Step 4: Spec-First Spawning

### Artifact Chain

```
Reader    → publishes paper summaries + tagged terms    → Scaffolder, Synthesizer
Scaffolder → publishes concept guide + glossary          → Synthesizer
Synthesizer → produces final literature review           → Lead
```

The reader MUST publish before the scaffolder and synthesizer begin. The scaffolder MUST publish before the synthesizer writes the review.

### Spawn Order

1. **Spawn the Reader first**
2. Reader's FIRST task: read all papers, produce structured summaries in the agreed format, tag unfamiliar terms
3. Reader sends summaries to lead via SendMessage
4. **Lead verifies**: Are summaries complete? Is the format consistent? Are terms tagged?
5. **Lead forwards verified summaries to Scaffolder**
6. Scaffolder produces concept guide and glossary
7. Scaffolder sends to lead via SendMessage
8. **Lead verifies**: Are all tagged terms explained? Are explanations clear and accurate?
9. **Lead forwards both summaries + concept guide to Synthesizer**
10. Synthesizer writes the literature review

### Paper Summary Format (Reader Must Follow)

The lead must instruct the Reader to produce summaries in this exact format for each paper:

```markdown
## [Paper Title] ([Authors, Year])
**Source**: [arxiv URL / PDF path / venue]

### Problem
What problem does this paper address? (2-3 sentences)

### Method
What is their approach? (3-5 sentences, enough to understand the key idea)

### Key Results
- [Result 1 with numbers if available]
- [Result 2]

### Limitations
- [Limitation 1]

### Connections
- Builds on: [prior work this paper extends]
- Compared against: [baselines used]
- Cited by / extended by: [later papers in the review set, if known]

### Tagged Terms
- `[term 1]`: used in context of [how it appears in this paper]
- `[term 2]`: used in context of [...]
```

### Concept Guide Format (Scaffolder Must Follow)

```markdown
# Concept Guide

## Core Concepts

### [Concept Name]
**What it is**: [plain-language explanation, 2-3 sentences]
**Why it matters**: [why this concept is important in this research area]
**Example**: [concrete example to build intuition]
**Prerequisite concepts**: [other concepts needed to understand this one]
**Papers that use this**: [which papers from the review use this term]

## Concept Map
[How concepts relate to each other — which are prerequisites for which, which are alternatives to each other, which are specializations of a broader concept]

## Notation Guide
[If papers use mathematical notation, list symbols and their meanings]
| Symbol | Meaning | Used in |
|--------|---------|---------|
| π      | policy  | [papers] |
| ...    | ...     | ...     |
```

### Spawn Prompt Structure

```
You are the [ROLE] agent for this literature review.

## Your Ownership
- You own: [output files]
- Do NOT touch: [other agents' files]

## What You're Producing
[Role-specific deliverable description]

## Papers to Process
[Paper list from the plan — for Reader only]

## The Specification You Must Conform To
[Upstream agent's output — for Scaffolder and Synthesizer]

## Output Format
[Exact format template from above]

## Before Reporting Done
[Validation checklist]
```

## Step 5: Facilitate Collaboration

### Phase 1: Reading (Reader works, others wait)

The Reader processes all papers. For each paper, they:
1. Read the full paper (fetch arxiv page, read PDF, or search for it)
2. Extract the structured summary in the agreed format
3. Tag unfamiliar or domain-specific terms
4. Note connections between papers

**Lead checks**: When Reader sends summaries, verify:
- Every paper from the plan has a summary
- Summaries follow the exact format
- Terms are tagged consistently
- Connections between papers are noted

### Phase 2: Scaffolding (Scaffolder works, Synthesizer waits)

The Scaffolder receives all paper summaries and:
1. Collects all tagged terms across all papers
2. Researches and explains each term at the appropriate level
3. Identifies prerequisite chains (concept A requires B)
4. Builds the concept map showing relationships
5. Creates notation guide if papers use math

**Lead checks**: When Scaffolder sends the concept guide, verify:
- Every tagged term has an explanation
- Explanations are at the right level for the user's background
- Prerequisite chains are identified
- The concept map is coherent

### Phase 3: Synthesis (Synthesizer writes the review)

The Synthesizer receives both summaries and concept guide, then:
1. Groups papers into a taxonomy (by approach, problem, chronology)
2. Identifies themes, trends, and gaps
3. Writes flowing prose organized by theme
4. Cites every claim
5. Highlights the research gap (if user specified their own work's context)

**Lead checks**: When Synthesizer sends the draft, verify:
- All papers from the plan are cited
- Organization is by theme/taxonomy, not just paper-by-paper summaries
- Claims are supported by citations
- The research gap is clearly articulated
- Prose flows naturally (no bullet-point dumps in the final review)

### Phase 4: Assembly

The lead assembles the final output:
1. Literature review document (from Synthesizer)
2. Concept guide as appendix or companion document (from Scaffolder)
3. Full paper summaries as reference (from Reader)

## Reading Papers — How Each Source Type Works

Instruct the Reader agent on how to handle different paper sources:

**arxiv URLs** (`https://arxiv.org/abs/XXXX.XXXXX`):
- Use WebFetch to read the arxiv abstract page
- For full paper content, fetch the HTML version at `https://arxiv.org/html/XXXX.XXXXX` if available
- Fall back to the abstract + related work section if full text is too long

**Local PDF files** (`./papers/some-paper.pdf`):
- Use the Read tool to read PDF files directly (supports PDF reading)
- For large PDFs, read specific page ranges

**Paper titles or topics** (no URL given):
- Use WebSearch to find the paper on arxiv or Semantic Scholar
- Then proceed as with arxiv URLs

**DOI links** (`https://doi.org/...`):
- Use WebFetch to resolve the DOI and find the paper

## Collaboration Anti-Patterns

**Anti-pattern: Parallel reading + writing** (synthesizer guesses)
```
Reader and Synthesizer start simultaneously
Synthesizer writes review based on paper titles only
Reader finishes with different understanding of the papers ❌
```

**Anti-pattern: Skipping scaffolding** (user can't follow the review)
```
Reader → Synthesizer directly
Review is full of unexplained jargon
User has to look up every other term ❌
```

**Anti-pattern: Paper-by-paper review** (no synthesis)
```
Synthesizer writes one section per paper
Result is an annotated bibliography, not a literature review
No themes, trends, or gaps identified ❌
```

**Good pattern: Sequential with lead relay**
```
Reader produces summaries → Lead verifies → forwards to Scaffolder
Scaffolder produces concept guide → Lead verifies → forwards with summaries to Synthesizer
Synthesizer writes thematic review referencing concept guide ✅
```

## Common Pitfalls to Prevent

1. **Missing papers**: Reader skips a paper from the plan → Lead cross-checks every paper
2. **Shallow summaries**: "This paper does X" without explaining how → Require method details
3. **Jargon in scaffolding**: Scaffolder explains terms using equally obscure terms → Require plain language + examples
4. **Annotated bibliography instead of review**: One section per paper → Require thematic organization
5. **Uncited claims**: "Recent work has shown..." → Every claim must cite a specific paper
6. **Missing connections**: Papers treated in isolation → Reader must note which papers cite/extend each other
7. **Wrong background level**: PhD-level explanations for someone learning the area → Check user's stated background
8. **Stale format**: Summaries drift from the agreed format → Lead enforces format on first batch before continuing

## Definition of Done

The review is complete when:
1. Every paper from the plan has a structured summary
2. Every tagged term has a clear explanation in the concept guide
3. The literature review is organized thematically with proper citations
4. The research gap is articulated (if applicable)
5. The concept guide covers prerequisite chains
6. **Lead has verified all three deliverables are consistent**

## Validation

### Reader Validation
- [ ] Every paper from the plan has a summary
- [ ] Summaries follow the exact agreed format
- [ ] Tagged terms are consistent (same term tagged the same way across papers)
- [ ] Connections between papers are noted
- [ ] No paper is summarized from title/abstract alone when full text is available

### Scaffolder Validation
- [ ] Every tagged term from the Reader is explained
- [ ] Explanations use plain language appropriate to user's background
- [ ] Each explanation includes a concrete example
- [ ] Prerequisite chains are identified
- [ ] Notation guide covers all mathematical symbols used across papers
- [ ] Concept map shows relationships between concepts

### Synthesizer Validation
- [ ] All papers from the plan are cited in the review
- [ ] Organization is thematic (NOT paper-by-paper)
- [ ] Every factual claim cites a specific paper
- [ ] Research gap is clearly stated (if applicable)
- [ ] Prose flows naturally — no bullet-point sections in the final review
- [ ] Terminology usage is consistent with the concept guide

### Lead Validation (End-to-End)
- [ ] Paper count: number of summaries matches number of papers in the plan
- [ ] Term coverage: every tagged term appears in the concept guide
- [ ] Citation coverage: every paper appears in the literature review
- [ ] Consistency: terminology in review matches concept guide definitions
- [ ] Readability: a reader with the stated background can follow the review using the concept guide

---

## Execute

Now read the review plan at `$ARGUMENTS[0]` and begin:

1. Read and understand the review plan
2. Count papers, identify source types (arxiv, PDF, topic search)
3. Determine team size (use `$ARGUMENTS[1]` if provided, default to 3)
4. Define agent roles with ownership and output format
5. Enter Delegate Mode
6. **Spawn Reader** — first task is producing all paper summaries in the agreed format
7. **Receive and verify summaries** — check format, completeness, tagged terms
8. **Forward to Scaffolder** — include the full summaries and tagged term list
9. **Receive and verify concept guide** — check term coverage, explanation quality
10. **Forward summaries + concept guide to Synthesizer** — include both, plus the user's research context
11. **Receive and verify literature review** — check thematic organization, citations, prose quality
12. Assemble final output: review + concept guide + paper summaries
13. Report completion with file paths for all deliverables
