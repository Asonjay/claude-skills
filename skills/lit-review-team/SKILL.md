---
name: lit-review-team
description: Conduct a CS literature review using a Schema-First Map-Reduce pipeline. Scaffolder generates an extraction schema, parallel Readers extract structured data from papers simultaneously, then Synthesizer reduces into a thematic review.
argument-hint: [plan-path] [num-readers]
disable-model-invocation: true
---

# Literature Review Team (Schema-First Map-Reduce)

You are coordinating a CS literature review using Claude Code Agent Teams with a **parallel pipeline**. The key insight: standardize the extraction format BEFORE reading, then fan out readers in parallel.

## Architecture Overview

```
Phase 0 (Schema)      Scaffolder analyzes research question
                      -> extraction schema + reading instructions
                      (sequential, fast)
                                |
Phase 1 (Map)          +--------+--------+--------+
                       |        |        |        |
                    Reader_1 Reader_2 Reader_3 ... Reader_N
                    (paper A) (paper B) (paper C)
                       |        |        |        |
                       +--------+--------+--------+
                       All fill same schema, tag terms
                       (PARALLEL - biggest time savings)
                                |
Phase 2 (Terminology)  Scaffolder receives all tagged terms
                       -> concept guide + glossary
                       (sequential, fast since terms pre-tagged)
                                |
Phase 3 (Reduce)       Synthesizer receives:
                       - structured extractions[]
                       - concept guide
                       -> thematic literature review
```

## Arguments

- **Plan path**: `$ARGUMENTS[0]` - Path to a markdown file describing the review scope. **If not provided, the skill enters interactive mode and asks the user questions to build the plan.**
- **Num readers**: `$ARGUMENTS[1]` - Max number of parallel reader agents (optional, auto-determined from paper count)

## Step 0: Get or Build the Review Plan

Check if `$ARGUMENTS[0]` is provided and non-empty.

### Path A: Plan file provided -> Skip to Step 1

If `$ARGUMENTS[0]` is a valid file path, read it and proceed to Step 1.

### Path B: No plan file -> Interactive Plan Builder

If `$ARGUMENTS[0]` is empty, missing, or not provided, interactively build the plan by asking the user a series of questions using the **AskUserQuestion** tool.

**Ask these questions in sequence (1-4 questions per AskUserQuestion call):**

#### Round 1: Core questions

Ask these 3 questions together:

1. **"What is your research question or topic?"**
   - header: "Topic"
   - options:
     - "I'll type my research question" (description: "Free-form research question or topic area")
     - "Compare methods/approaches" (description: "e.g., Compare offline RL vs imitation learning for grasping")
     - "Survey a field" (description: "e.g., Survey recent advances in diffusion models for robotics")
     - "Background for my paper" (description: "e.g., Related work section for my submission on X")

2. **"What papers should be reviewed?"**
   - header: "Papers"
   - options:
     - "I'll paste URLs/titles" (description: "Provide arxiv URLs, PDF paths, DOIs, or paper titles")
     - "Search for papers on a topic" (description: "I'll describe the topic and you find relevant papers")
     - "I have a mix of URLs and topics" (description: "Some specific papers + some topic areas to search")

3. **"What is your background level in this area?"**
   - header: "Background"
   - options:
     - "New to this area" (description: "Need thorough explanations of core concepts and terminology")
     - "Some familiarity" (description: "Know the basics but unfamiliar with advanced techniques")
     - "Domain expert" (description: "Familiar with the field, need minimal scaffolding")

#### Round 2: Details

Based on Round 1 answers, ask for specifics:

1. **Paper list**: If user chose to provide papers, ask them to list them. If they chose topic search, ask for the topic description. Use AskUserQuestion with a free-text option so the user can paste their list.

2. **"What output format do you need?"**
   - header: "Format"
   - options:
     - "Related work section" (description: "2-3 pages for a conference paper, LaTeX-ready prose")
     - "Standalone survey" (description: "Comprehensive standalone literature review document")
     - "Annotated bibliography" (description: "Structured summaries with brief analysis per paper")
     - "Quick summary" (description: "Brief overview of key findings and trends")

3. **"Any specific concepts or areas you find unfamiliar?"** (free-text)

4. **"Where should I save the output?"** (free-text, suggest default: `./lit-review-output/`)

#### Round 3: Optional context

Ask these only if relevant (skip if user seems to just want a general survey):

1. **"Are you writing this for a specific venue or context?"** (free-text, e.g., "ICRA 2026 submission on residual RL")
2. **"What is your own research about?"** (free-text, helps identify the research gap -- skip if not applicable)

#### After collecting answers: Generate and save the plan

Assemble the answers into a plan markdown file and **write it to `./lit-review-plan.md`** (or the user's specified output directory + `/plan.md`). Show the user the generated plan and ask for confirmation before proceeding.

The generated plan format:

```markdown
# Literature Review Plan

## Research Question
[From Round 1, Q1]

## Papers
- [paper 1]
- [paper 2]
- ...

## Background Level
[From Round 1, Q3]

## Output Format
[From Round 2, Q2]

## Unfamiliar Areas
[From Round 2, Q3 -- or "None specified"]

## Research Context
[From Round 3, Q2 -- or omit if not provided]

## Target Venue
[From Round 3, Q1 -- or omit if not provided]

## Output Directory
[From Round 2, Q4 -- default: ./lit-review-output/]
```

**After saving, tell the user**: "Plan saved to `./lit-review-plan.md`. You can reuse this file next time with `/lit-review-team ./lit-review-plan.md`."

Then proceed to Step 1 using the generated plan.

---

## Step 1: Read the Review Plan

Read the plan document (either from `$ARGUMENTS[0]` or the one just generated). Extract:
- What is the research question or topic?
- What papers need to be reviewed? (arxiv URLs, PDF paths, titles, or topic areas to search)
- What is the reader's background level? (determines scaffolding depth)
- What output format is needed? (related work section, standalone survey, annotated bibliography)
- Are there specific concepts or terminology areas the user finds unfamiliar?
- What is the target venue or context? (e.g., "related work for my NeurIPS submission on X")

**Count the papers.** This determines the parallelism strategy.

## Step 2: Determine Team Structure

### Routing Logic

```
num_papers = count papers in plan

if num_readers specified via $ARGUMENTS[1]:
    num_readers = $ARGUMENTS[1]
elif num_papers <= 1:
    num_readers = 1
elif num_papers <= 5:
    num_readers = num_papers          # one reader per paper
elif num_papers <= 15:
    num_readers = ceil(num_papers/2)  # two papers per reader
else:
    num_readers = ceil(num_papers/3)  # three papers per reader
```

### Total Agents = num_readers + 2

- **1 Scaffolder** (runs in Phase 0 and Phase 2)
- **N Readers** (run in parallel in Phase 1)
- **1 Synthesizer** (runs in Phase 3)

### Paper Assignment

Distribute papers across readers as evenly as possible. When grouping multiple papers per reader, group by sub-topic if possible (e.g., all RL papers to one reader, all imitation learning papers to another).

## Step 3: Set Up Agent Team

Create the team:

```
TeamCreate with team_name: "lit-review"
```

Enable tmux split panes:

```
teammateMode: "tmux"
```

Enter **Delegate Mode** (Shift+Tab). You coordinate -- you do not read papers or write the review yourself.

## Step 4: Phase 0 -- Schema Generation (Scaffolder)

**Spawn the Scaffolder FIRST, before any readers.**

The Scaffolder's Phase 0 task is to analyze the research question and produce an **extraction schema** -- a structured template that all parallel readers will fill out. This ensures every reader produces output in the exact same format, tailored to the specific research question.

### Scaffolder Phase 0 Prompt

```
You are the Scaffolder agent for this literature review.

## Phase 0 Task: Generate Extraction Schema

Analyze this research question and produce a JSON extraction schema that readers will fill out for each paper.

Research question: [FROM PLAN]
User background: [FROM PLAN]
Target output: [FROM PLAN]

## What You Must Produce

A markdown file at [output-dir]/extraction_schema.md containing:

### 1. Extraction Schema

A structured template with fields tailored to the research question. ALWAYS include these base fields:

- paper_id (string: "paper_01", "paper_02", etc.)
- title (string)
- authors (string)
- year (number)
- source (string: URL, PDF path, or venue)
- problem (string: 2-3 sentences)
- method (string: 3-5 sentences)
- key_results (list of strings with numbers where available)
- limitations (list of strings)
- connections.builds_on (list of paper_ids or paper names)
- connections.compared_against (list of baselines)
- tagged_terms (list of {term, context} objects)

PLUS domain-specific fields based on the research question. Examples:
- For an RL survey: algorithm_family, state_representation, action_space, reward_design, environment
- For an NLP survey: model_architecture, pretraining_data, task_type, language_support
- For a CV survey: backbone, input_modality, dataset, inference_speed

### 2. Reading Instructions

Brief guidance for readers on what to focus on given the research question. What aspects matter most? What can be skimmed?

### 3. Paper ID Assignment

List each paper with its assigned paper_id for cross-referencing:
- paper_01: [Paper Title or URL]
- paper_02: [Paper Title or URL]
- ...

## Before Reporting Done
- Schema covers the research question's key dimensions
- Base fields are all present
- Domain-specific fields are relevant (not generic filler)
- Paper IDs are assigned to every paper in the plan
- Reading instructions are actionable

Send the schema to the lead via SendMessage when done.
```

**Lead receives schema, verifies:**
- Does the schema capture the key dimensions of the research question?
- Are all papers assigned IDs?
- Are domain-specific fields relevant?

## Step 5: Phase 1 -- Parallel Reading (Map)

**This is the critical parallelization step.** Spawn ALL reader agents simultaneously using multiple Task tool calls in a SINGLE message.

### How to Spawn Readers in Parallel

You MUST spawn all readers in the same message to achieve parallelism. Example for 4 papers with 4 readers:

```
In a SINGLE response, make 4 Task tool calls:
  Task(name="reader-1", prompt="...", team_name="lit-review")
  Task(name="reader-2", prompt="...", team_name="lit-review")
  Task(name="reader-3", prompt="...", team_name="lit-review")
  Task(name="reader-4", prompt="...", team_name="lit-review")
```

**CRITICAL: All Task calls MUST be in the same message. If you spawn them in separate messages, they run sequentially and you lose all parallelism.**

### Reader Prompt Template

Each reader gets this prompt, customized with their assigned papers and the schema:

```
You are Reader agent [N] for this literature review.

## Your Assignment
Read the following paper(s) and extract structured data using the schema below.

### Paper(s) to Read
[List of papers assigned to this reader with their paper_ids]

### Extraction Schema
[PASTE THE FULL SCHEMA FROM SCAFFOLDER]

### Reading Instructions
[PASTE THE READING INSTRUCTIONS FROM SCAFFOLDER]

## How to Read Papers

**arxiv URLs** (https://arxiv.org/abs/XXXX.XXXXX):
- Use WebFetch to read the arxiv abstract page
- For full paper, fetch HTML version at https://arxiv.org/html/XXXX.XXXXX if available
- Fall back to abstract + related work if full text too long

**Local PDF files** (./papers/some-paper.pdf):
- Use Read tool to read PDF files directly
- For large PDFs (>10 pages), read in page ranges

**Paper titles or topics** (no URL given):
- Use WebSearch to find the paper on arxiv or Semantic Scholar
- Then proceed as with arxiv URLs

**DOI links** (https://doi.org/...):
- Use WebFetch to resolve the DOI

## Output

Write your extraction(s) to: [output-dir]/reader_[N]_extractions.md

Use this format for each paper:

---
## paper_id: [ID]

**title**: [Title]
**authors**: [Authors]
**year**: [Year]
**source**: [URL/path]

### Problem
[2-3 sentences]

### Method
[3-5 sentences]

### Key Results
- [result with numbers]

### Limitations
- [limitation]

### Domain-Specific Fields
[Fill out each domain-specific field from the schema]

### Connections
- builds_on: [prior work]
- compared_against: [baselines]

### Tagged Terms
- `[term]`: [context of how it appears in this paper]
---

## Before Reporting Done
- Every assigned paper has a complete extraction
- All schema fields are filled (use "N/A" only if truly not applicable)
- Tagged terms include any concept that might need explanation
- Connections to other papers in the review set are noted where known
- No paper is summarized from title/abstract alone when full text is available

Send your completed extractions to the lead via SendMessage when done.
```

### Lead Collects All Reader Results

As each reader finishes (they may finish at different times), collect their extractions. **Wait for ALL readers to complete before proceeding to Phase 2.**

**Lead checks for each reader:**
- Every assigned paper has an extraction
- All schema fields are filled
- Terms are tagged
- If a reader missed a paper or produced shallow output, send them back with specific feedback

## Step 6: Phase 2 -- Terminology (Scaffolder)

Once all readers are done, send ALL extractions to the Scaffolder for Phase 2.

### Scaffolder Phase 2 Prompt

```
You are the Scaffolder agent, now in Phase 2: Terminology.

## Your Input
Below are the structured extractions from all readers. Your job is to build a concept guide from all tagged terms.

[PASTE ALL READER EXTRACTIONS]

## What You Must Produce

Write to: [output-dir]/concept_guide.md

### Concept Guide Format

# Concept Guide

## Core Concepts

### [Concept Name]
**What it is**: [plain-language explanation, 2-3 sentences]
**Why it matters**: [why this concept is important in this research area]
**Example**: [concrete example to build intuition]
**Prerequisite concepts**: [other concepts needed to understand this one]
**Papers that use this**: [list paper_ids]

[Repeat for each tagged term across ALL readers]

## Concept Map
[How concepts relate -- prerequisites, alternatives, specializations]

## Notation Guide
[If papers use math notation]
| Symbol | Meaning | Used in |
|--------|---------|---------|
| ...    | ...     | paper_ids |

## Before Reporting Done
- EVERY tagged term from ALL readers is explained
- Explanations use plain language appropriate to: [USER BACKGROUND FROM PLAN]
- Each explanation includes a concrete example
- Prerequisite chains are identified
- Notation guide covers all mathematical symbols
- Concept map shows relationships between concepts
- Terms are deduplicated (same concept tagged differently by different readers = one entry)

Send the concept guide to the lead via SendMessage when done.
```

**Lead checks:**
- Collect all unique tagged terms from all readers
- Verify every term appears in the concept guide
- Verify explanations match the user's background level
- Check for deduplication (different readers may tag the same concept differently)

## Step 7: Phase 3 -- Synthesis (Reduce)

Send ALL reader extractions + concept guide to the Synthesizer.

### Synthesizer Prompt

```
You are the Synthesizer agent for this literature review.

## Your Input

### Research Question
[FROM PLAN]

### Structured Paper Extractions
[PASTE ALL READER EXTRACTIONS -- these are structured, schema-conformant data]

### Concept Guide
[PASTE CONCEPT GUIDE FROM SCAFFOLDER]

### Research Context
[User's own work context, if specified in plan -- for identifying the research gap]

## What You Must Produce

Write to: [output-dir]/literature_review.md

A thematic literature review in flowing prose. NOT an annotated bibliography.

### Requirements
1. **Organize by theme/approach/taxonomy** -- NOT paper-by-paper
2. **Group papers** that share methods, tackle similar problems, or reach comparable conclusions
3. **Identify trends**: how has the field evolved? what directions are gaining traction?
4. **Identify gaps**: what hasn't been tried? where do existing methods fall short?
5. **Identify contradictions**: do papers disagree on findings? why?
6. **Cite every claim**: use (Author, Year) format or [paper_id] -- every factual statement needs a citation
7. **Use terminology consistently** with the concept guide
8. **Highlight the research gap** that motivates the user's work (if research context provided)
9. **Write flowing prose** -- no bullet-point sections in the final review

### Structure Guide
- Introduction: frame the research area and question
- Body: 2-4 thematic sections grouping related work
- Analysis: trends, gaps, contradictions across the body
- Conclusion: state of the field + where opportunities lie

## Before Reporting Done
- All papers from the plan are cited at least once
- Organization is thematic (NOT paper-by-paper)
- Every factual claim cites a specific paper
- Research gap is clearly stated (if applicable)
- Prose flows naturally
- Terminology is consistent with the concept guide

Send the completed review to the lead via SendMessage when done.
```

**Lead checks:**
- All papers are cited (cross-check paper_ids against plan)
- Organization is thematic
- Claims are cited
- Prose quality is acceptable

## Step 8: Assembly

The lead assembles the final output:

1. **Literature review** (from Synthesizer) -- the primary deliverable
2. **Concept guide** as appendix (from Scaffolder Phase 2)
3. **Paper extractions** as reference appendix (from all Readers)

Write the assembled document to `[output-dir]/full_review.md` or the path specified in the plan.

Report completion with file paths for all deliverables.

## Reading Papers -- Source Type Reference

Include these instructions when spawning Reader agents:

**arxiv URLs** (`https://arxiv.org/abs/XXXX.XXXXX`):
- Use WebFetch to read the arxiv abstract page
- For full paper content, fetch HTML version at `https://arxiv.org/html/XXXX.XXXXX` if available
- Fall back to abstract + related work if full text too long

**Local PDF files** (`./papers/some-paper.pdf`):
- Use Read tool to read PDF files directly
- For large PDFs, read specific page ranges

**Paper titles or topics** (no URL given):
- Use WebSearch to find the paper on arxiv or Semantic Scholar
- Then proceed as with arxiv URLs

**DOI links** (`https://doi.org/...`):
- Use WebFetch to resolve the DOI

## Anti-Patterns

**Anti-pattern: Sequential readers** (loses all parallelism)
```
Spawn Reader_1, wait, spawn Reader_2, wait, ...
All readers run one after another
No time savings over single reader  !!WRONG!!
```

**Anti-pattern: Readers without schema** (inconsistent output)
```
Skip Phase 0, spawn readers immediately
Each reader invents their own summary format
Synthesizer can't compare structured data  !!WRONG!!
```

**Anti-pattern: Skipping scaffolding** (jargon-filled review)
```
Readers -> Synthesizer directly
Review uses unexplained terminology
User can't follow the review  !!WRONG!!
```

**Anti-pattern: Paper-by-paper review** (no synthesis)
```
Synthesizer writes one section per paper
Result is annotated bibliography
No themes, trends, or gaps  !!WRONG!!
```

**Good pattern: Schema-First Map-Reduce**
```
Scaffolder defines schema -> Lead spawns ALL readers in ONE message ->
Readers work in PARALLEL -> Scaffolder explains terms ->
Synthesizer reduces structured data into thematic review  CORRECT
```

## Common Pitfalls

1. **Spawning readers in separate messages**: They run sequentially. ALL reader Task calls must be in ONE message.
2. **Missing papers**: A reader skips an assigned paper -> Lead cross-checks every paper_id.
3. **Shallow extractions**: "This paper does X" without method details -> Send reader back with specific feedback.
4. **Schema drift**: Reader ignores domain-specific fields -> Lead checks schema compliance before Phase 2.
5. **Term duplication**: Different readers tag the same concept with different names -> Scaffolder must deduplicate.
6. **Wrong background level**: PhD-level explanations for a learner -> Check plan's stated background level.
7. **Uncited claims**: "Recent work shows..." -> Every claim must cite a specific paper_id.

## Definition of Done

The review is complete when:
1. Every paper from the plan has a structured extraction conforming to the schema
2. Every tagged term has a clear explanation in the concept guide
3. The literature review is organized thematically with proper citations
4. The research gap is articulated (if applicable)
5. All deliverables are written to the output directory
6. **Lead has verified consistency across all deliverables**

## Validation

### Schema Validation (Phase 0)
- [ ] Schema includes all base fields
- [ ] Domain-specific fields match the research question
- [ ] All papers have assigned paper_ids
- [ ] Reading instructions are actionable

### Reader Validation (Phase 1, per reader)
- [ ] Every assigned paper has an extraction
- [ ] All schema fields are filled
- [ ] Tagged terms include domain-specific concepts
- [ ] Connections to other papers noted where known
- [ ] No paper summarized from title/abstract alone when full text available

### Scaffolder Validation (Phase 2)
- [ ] Every tagged term from ALL readers is explained
- [ ] Duplicate terms across readers are merged
- [ ] Explanations use plain language at user's level
- [ ] Each explanation includes a concrete example
- [ ] Prerequisite chains identified
- [ ] Notation guide covers all symbols

### Synthesizer Validation (Phase 3)
- [ ] All papers cited in the review
- [ ] Organization is thematic (NOT paper-by-paper)
- [ ] Every factual claim cites a specific paper
- [ ] Research gap clearly stated (if applicable)
- [ ] Prose flows naturally
- [ ] Terminology consistent with concept guide

### Lead Validation (End-to-End)
- [ ] Paper count: extractions match plan paper count
- [ ] Term coverage: every tagged term in concept guide
- [ ] Citation coverage: every paper appears in review
- [ ] Schema compliance: all extractions follow the schema
- [ ] Consistency: terminology in review matches concept guide
- [ ] Readability: user with stated background can follow the review

---

## Execute

### If `$ARGUMENTS[0]` is provided and non-empty:

1. Read and understand the review plan at `$ARGUMENTS[0]`
2. Count papers, identify source types, determine num_readers
3. Assign papers to readers (distribute evenly, group by sub-topic if possible)
4. Create team and enter Delegate Mode
5. **Phase 0**: Spawn Scaffolder -> receive extraction schema -> verify
6. **Phase 1**: Spawn ALL readers in a SINGLE message (parallel) -> collect all extractions -> verify each
7. **Phase 2**: Send all extractions to Scaffolder for terminology -> receive concept guide -> verify
8. **Phase 3**: Send all extractions + concept guide to Synthesizer -> receive review -> verify
9. Assemble final output: review + concept guide + extractions
10. Shut down teammates, report completion with file paths

### If `$ARGUMENTS[0]` is empty or not provided:

1. **Interactive Plan Builder**: Ask the user questions using AskUserQuestion (see Step 0, Path B)
2. Generate the plan markdown and save to `./lit-review-plan.md`
3. Show the user the generated plan and confirm before proceeding
4. Then follow steps 1-10 above using the generated plan
