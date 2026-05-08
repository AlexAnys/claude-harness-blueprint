---
name: harness-design
description: Design and set up a multi-agent harness for any project type — software development (Planner → Builder → QA), knowledge compilation (Coordinator → Compiler → QA), or operations (Coordinator → Executor → Monitor). Use this skill whenever the user wants to build with multiple AI agents, set up automated workflows, create an agent pipeline, apply Anthropic's harness methodology, or structure any complex task that benefits from separating planning, execution, and verification. Covers software projects, knowledge bases/wikis, research systems, operational pipelines, and hybrids. Also use when the user mentions "harness", "multi-agent", "planner/builder/qa", "coordinator/compiler", "generator/evaluator", or wants to coordinate multiple Claude Code instances.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, WebSearch, WebFetch
---

# Harness Design — A Meta-Skill for Multi-Agent Scaffolding

Design a harness for: $ARGUMENTS

## Step 0: Detect mode — new build or upgrade?

Before anything else, check if the target project already has a harness:

```
Does $ARGUMENTS project have .claude/agents/ with agent definition files?
  ├─ NO  → New build mode (continue to "The core three roles" below)
  └─ YES → Upgrade mode (follow the upgrade procedure below)
```

### Upgrade mode

When a project already has a harness, don't rebuild — upgrade the existing agent definitions to match the latest principles and tool integrations.

**Procedure:**

1. **Read the existing agents** — read every `.claude/agents/*.md` and `.claude/settings.json`
2. **Classify the project domain** — read `CLAUDE.md` to determine: software, knowledge, or operations
3. **Read the latest references** — read the relevant reference files from this skill's `references/` directory
4. **Compare and generate a diff report** — for each agent and `settings.json`, list what's outdated or missing vs the current principles. Common upgrade items:
   - **`settings.json` baseline** — must have `"agent": "coordinator"` and a Stop hook QA gate. Flag either missing.
   - Agent Teams mechanism (SendMessage in tool list, idle discipline)
   - > **可选增强（需安装 gstack）**：gstack skill references (only for **software** projects): `/qa-only` for QA, `/investigate` for Builder, `/cso` for security
   - Stop hook improvements (project-specific QA dimensions)
   - Tool allocation fixes (QA should not have Edit, etc.)
5. **Present the diff to the user** — show exactly what would change in each file, and why
6. **Apply only confirmed changes** — user approves per-file, then write

> **可选增强（需安装 gstack）**：Project type awareness for gstack skills:
> - **Software projects** (web apps, CLI tools, APIs): gstack's `/qa-only`, `/investigate`, `/cso`, `/careful`, `/freeze` are relevant
> - **Knowledge / research projects**: gstack skills are generally NOT relevant — skip gstack-related upgrades
> - **Operations projects**: only `/careful` and `/investigate` may be relevant; skip browser-based skills
>
> Do NOT suggest gstack skills for projects where they don't apply.

---

Based on Anthropic's [harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps). The core idea: separate the agent doing the work from the agent judging it — like a GAN, but for software and operations.

## The meta-principle you must never forget

**Every layer of scaffolding you add beyond the core three roles is a statement that "the model can't do this alone."** Don't fall in love with your own scaffolding — keep it as light as the task allows.

---

## The core three roles — the universal invariant

Every harness, regardless of project type, has exactly three **functions** that must be separated:

1. **Coordinator/Planner** — understands the user's intent (proactively clarifying what's unclear), defines what "done" looks like, and dispatches work. This is one agent that wears both hats: the human-facing coordinator AND the planner who writes the spec. It does NOT specify implementation details — only deliverables and acceptance criteria.

2. **Generator/Builder** (one or many) — does the actual work. Reads the spec, produces output, writes an honest report of what it did and what it deferred. The Coordinator can dispatch to **multiple Generators in parallel** when work units are independent.

3. **Evaluator/QA** (one or many) — independently judges the Generator's output. Reads the spec and the build report, then **uses the product** (not just reads the code). For multiple Generators, there can be **multiple Evaluators**, each reviewing a different Generator's work.

```
You ↔ Coordinator/Planner (1)  →  Generator (N, parallel)  ←  Evaluator (M, independent)
       aligns intent                does the work               judges the work
       writes spec                  writes build report          writes QA report
       creates team & monitors      reads spec                   reads spec + report
```

These three are **always separate**. A Generator judging its own output is systematically lenient (self-persuasion bias). A Coordinator specifying implementation details cascades errors. An Evaluator that can edit code will silently fix instead of report. The separation is the invariant.

The role **names** change by domain — Planner/Builder/QA in software, Editor/Writer/Reviewer in writing, Architect/Builder/Validator in data — but the **separation** does not.

### Agent Teams, not subagents — this is critical

The three roles collaborate as **peers in an Agent Team**, not as a coordinator dispatching subagents. The difference matters:

| | Subagent (wrong) | Agent Team member (right) |
|---|---|---|
| Lifetime | Short — does one task, dies | Persistent — stays alive across the loop |
| Permissions | Restricted, can't ask user | Full capabilities, full tool access |
| Communication | Only through parent | Direct peer-to-peer via SendMessage |
| Context | Cold-starts each round | Retains context across iterations |

**How it works in practice:**

1. **Coordinator creates a team** (TeamCreate) and spawns Generator + Evaluator as teammates
2. **Coordinator writes the plan** to `.harness/spec.md` and creates tasks (TaskCreate)
3. **Generator picks up tasks**, implements, writes build reports to `.harness/reports/`, messages Evaluator directly via SendMessage: "Module A done, report at build-a.md"
4. **Evaluator reads the report, runs the product**, writes QA report, messages Generator directly: "2 issues found, see qa.md"
5. **Generator reads QA report, fixes, messages Evaluator**: "Fixed, re-check"
6. **This Builder↔QA loop runs directly** — Coordinator is NOT in the middle. It monitors via TaskList and re-engages only on repeated failure or requirement gaps.
7. On PASS, Evaluator updates the task as completed, Coordinator picks next unit.

The Coordinator is your only conversation partner. Generator and Evaluator are persistent teammates with full capabilities, iterating directly with each other through **SendMessage + files**. Files (`.harness/`) are the audit trail; SendMessage is the real-time coordination.

### What "minimum viable" means

The three roles above are the floor, not something to be validated each time. "Minimum viable" means: **don't add components beyond these three without a specific reason.** Examples of extra components that need justification:
- A dedicated planner separate from the coordinator (only if planning overwhelms the coordinator)
- An experience layer (only for long-running operations harnesses)
- Multiple specialized evaluators (only if quality dimensions are too diverse for one)
- A blackboard beyond the basics (only if session state is being lost)

If someone tells you to "start simple and add complexity only when needed" — the three roles ARE the simple start. Everything else is optional.

---

## Classify the task (briefly)

Two axes shape the harness shape. Do this quickly, don't over-formalize.

**Duration / stakes**
- *One-shot* (<30 min, reversible): no harness, just do it
- *Session* (1–4 hr, one feature): light structure — written plan + human verification
- *Project* (4+ hr or multi-feature): full role separation + persistent blackboard
- *Operations* (ongoing, auto-running): add an experience/learning layer

**Domain**
- *Software* — cycle is Plan → Build → Verify; failure is in code correctness and runtime behavior
- *Knowledge / research* — cycle is Ingest → Compile → Lint; the compiled output *is* the blackboard
- *Operations* — cycle is Detect → Execute → Monitor; the harness runs continuously and accumulates experience
- *Hybrid* — compose from principles, don't force-fit

Duration tells you how much weight the harness should carry. Domain tells you what the roles are called and what "verification" means concretely. Both inform every downstream decision.

---

## Additional invariants

The three-role separation above is the primary invariant. These are supplementary rules that hold across every project:

1. **Evaluation is specific and scorable.** "Is this good?" is worthless. Break quality into named dimensions (e.g. for a UI: "loads without error," "matches spec visually," "handles empty state"), give each a pass threshold, and calibrate the evaluator with few-shot examples spanning clear-fail to clear-pass. Averaging dimensions hides failures; any dimension failing means the whole thing fails.

2. **Verifiers use the product, not just the code.** For anything with runtime behavior — UI, CLI, API, pipeline — the verifier actually runs the thing. A QA that only reads diffs cannot catch CSS layout bugs, data-format mismatches, or interaction regressions. For UI, this means browser automation (e.g. Playwright). For CLI/API, it means actually invoking and inspecting responses.

3. **Agents communicate directly — SendMessage for coordination, files for audit.** Once the plan exists, the coordinator steps back. Generator and Evaluator talk to each other via SendMessage ("done, check my work" / "2 issues, see qa.md") and write reports to `.harness/` as the audit trail. A coordinator relaying messages becomes both a bottleneck and a game-of-telephone.

4. **Session state is persisted.** At natural checkpoints, agents write to an agreed-upon file (a handoff note, a progress log, a status page) capturing: what's done, what's next, key decisions and their reasons. A fresh session reads this and continues without the user having to re-explain context. This is how a harness survives context limits, crashes, and handoffs.

5. **Sources are read-only.** For projects with input data — raw documents, datasets, external API responses — the input layer is immutable. Agents own the output layer only. Mixing the two erodes the source of truth and makes debugging impossible.

---

## Anti-patterns (must avoid)

1. **Pre-specifying sprint/phase decomposition.** Chopping work into fixed sprints was a workaround for short-context models that couldn't hold a whole project in mind. With 1M context, a well-framed plan + dynamic checkpoints outperforms rigid sprints. Only decompose when the work *actually* exceeds what one coherent session can hold.

2. **Detailed plans masquerading as thoroughness.** The urge to pin down every implementation decision upfront feels rigorous. It is the opposite. Every premature technical choice becomes a constraint the builder must either obey (possibly wrongly) or violate (wasting the plan).

3. **Fixed-round iteration.** "Run 3 rounds of review" is a ritual, not a quality strategy. Later rounds aren't always better than middle ones. Use a dynamic exit — e.g., two consecutive clean passes, or no new issues found — not a counter.

4. **Adding components beyond the three core roles without a reason.** The three roles (Coordinator/Planner, Generator, Evaluator) are always present. Beyond that — extra planners, multiple specialized evaluators, experience layers — each must earn its keep for this specific project.

5. **Assuming a local-only world.** Tool calls should fit an abstract shape (name, input, string output) so they could later move to a remote environment. Don't implement the abstraction before you need it — just don't hardcode assumptions that would block it.

6. **Urgency as a bypass excuse.** "This is a critical bug, skip the flow." This is exactly when flows matter most — pressure multiplies point-fix errors. Walk the harness for the urgent bug (even a one-line plan counts). Point-fixing under pressure has, in practice, caused the same bug to recur three or four times in a row.

---

## The core loop

```
Coordinator: plan → create team → create tasks → assign to Generator
Generator ↔ Evaluator loop (direct, via SendMessage + files):
  Generate → Verify ─── PASS → task completed → Coordinator assigns next
                    └─ FAIL → same failure as last round?
                                ├─ NO  → Generator fixes → re-verify
                                └─ YES → escalate to Coordinator → re-plan
```

The Generator↔Evaluator loop runs **directly between peers** via SendMessage. Coordinator is not in this loop — it monitors via TaskList and re-engages only when escalated or when all tasks complete.

**Dynamic exit — both directions.** Don't run fixed rounds.
- Positive exit: *two consecutive passes with no new issues* → ship it and move on. Additional rounds from this state typically add churn, not quality.
- Negative exit: *three repetitions of the same failure* → the plan or the approach is wrong. Escalate to Coordinator. Do not grind.

**Keep / discard at each checkpoint.** On PASS, commit (git, or the domain equivalent — a compiled page, a recorded result). On a fundamentally broken attempt, reset to the last good state and try a different approach. Record both in the progress log so patterns become visible over time: which kinds of units pass on the first try, which plateau, which repeatedly fail.

---

## The blackboard (principle only)

Agents collaborate through a shared file tree. The exact layout is the project's decision, not this skill's prescription. What must exist in *some* form:

- **The plan / spec** — the ground truth for what's being built. Written before execution, readable by every agent.
- **A progress record** — answers "is this iteration better than the last one?" and "what has been tried?" This can be a TSV, an append-only log, an index page — whatever fits the domain. The requirement is that it's objective and comparable across rounds.
- **A session-handoff artifact** — lets a new session pick up where the previous one left off, without having to re-load the whole history into context.
- **Reports** — execution and verification results, written to files so they're auditable and so agents can read each other's work without the coordinator relaying.

The coordinator does not relay messages between agents. It steps in only when agents hit repeated failure, when a requirement gap is discovered, or when work completes.

For concrete directory layouts — software, knowledge, operations — see `references/software_harness.md`, `references/knowledge_harness.md`, and `references/operations_harness.md`. Those are worked examples, not templates. The skill adapts them to each project's actual shape.

---

## Enforcement layers (principle only)

Harness discipline decays the moment it depends on human memory. Make it infrastructure, not advice.

**Baseline for every harness (all three required):**

1. **CLAUDE.md rules** — read by every session; holds project architecture, conventions, and known pitfalls.
2. **Structural default** — `settings.json` sets `"agent": "coordinator"`. Opening Claude Code in the project lands on the coordinator, not a generic session. There is nothing to "remember."
3. **Stop hook QA gate** — agent-type hook that runs after every Claude response. Reads the diff, checks it against the plan and project conventions, blocks on issues. Fires regardless of change size or developer discipline.

**Added when needed:**

4. **Tool scope limits** (per-agent `tools` lists in agent definitions, `acceptEdits` permission mode) — add when a specific role must be blocked from specific tools (e.g. Evaluator must not have Edit).
5. **SessionStart banner hook** — prints harness status (spec tail, progress, handoff) on session open. Nice-to-have for at-a-glance visibility, not infra-critical.
6. **Experience layer** — add only for operations harnesses (see `references/operations_harness.md`).

For hook JSON and settings.json template, see `references/enforcement.md`.

---

## Ceremony scales with risk — let the agent judge

There is no fixed table saying "under N lines, skip planning." Ceremony should scale with the *risk* of the change: a typo needs no plan; a schema migration needs one; a refactor across modules needs a plan and an impact analysis. The Agent should classify the risk of each change in one sentence and pick the appropriate ceremony level — not follow a line-count rule. The goal is "enough structure to catch mistakes, not so much that developers route around it."

The Stop hook QA gate applies to *everything*, regardless of risk level. It's cheap and it catches the things that bypass human judgment.

---

## Agent definitions (principle only)

Every named agent needs a definition file (`.claude/agents/{role}.md`) describing: its role in one sentence, when to delegate to it, the minimum tool set it needs, and the domain knowledge it must carry (extracted from the domain-research step).

**Tool allocation — minimum necessary, but complete for the role:**
- Coordinator/Planner: Agent, TeamCreate, SendMessage, TaskCreate/Update/List, Read, Write, Glob, Grep (orchestrates, does not build)
- Generator/Builder: Read, Write, Edit, Bash, Glob, Grep, SendMessage (full build toolkit + can message Evaluator)
- Evaluator/QA: Read, Write, Bash, Glob, Grep, SendMessage + observation tools like Playwright (can message Generator, cannot Edit source)

Key: **Evaluator should NOT have Edit** — a verifier that can edit code will silently fix instead of report. **Generator should have SendMessage** — so it can communicate directly with Evaluator without Coordinator relaying.

**Idle discipline**: teammates should be told to wait quietly after completing their tasks and notifying the next agent once. Without this, they wake on system events, re-check TaskList, send duplicate "I'm done" messages, and waste tokens in a loop.

> **可选增强（需安装 gstack）**：harness agents can invoke gstack skills within their sessions. Evaluator/QA should use `/qa-only` (persistent Chromium browser, report-only) for web project verification and `/cso` for security audits. Generator/Builder can use `/investigate` for structured debugging. These are invoked as skills within the agent's session, not as separate agents. Do NOT route through gstack's planning pipeline (`/autoplan`, `/plan-*-review`) — the Coordinator handles planning directly.

Agents should use a 1M-context model. Permission mode should be explicit; `bypassPermissions` silently ignores allowed-tool lists — prefer `acceptEdits` with explicit tool scopes.

For YAML frontmatter examples and tool-allocation patterns, see `references/agent_definitions.md`.

---

## Domain research happens before agent design

Before writing any agent file, do a short research pass:

- **Existing codebase**: read the reference code. Extract established patterns, naming conventions, known pitfalls.
- **Greenfield**: search for how this kind of project typically breaks — common bugs, edge cases, testing strategies.

The output of research is not a document — it's content embedded directly into the planner's and verifier's prompts. The planner learns what's ambitious-but-achievable in this domain. The verifier learns which failure modes to check for. Generic harnesses produce generic solutions; embedded domain knowledge is how this skill produces work that feels like it understands the problem.

---

## Acceptance test: `test.md`

Every harness produces a `test.md` as its final deliverable. This is the first thing run when Claude Code opens the project after setup. It contains:

- **What the user originally asked for**, in their words, so intent drift is visible.
- **Concrete goals** the harness is meant to achieve, derived from the aligned requirements.
- **A pass/fail checklist** covering: infrastructure exists, default agent loads, hooks fire, core workflow runs end-to-end, integrations reachable.

Each item must be *observable* (runs a command or checks output), *binary* (passes or doesn't), and *specific* (names exact files, agents, behaviors). "Content creation works" is not a test item. "Give Coordinator a raw idea → Creator writes a draft to `drafts/`→ draft passes the three-question check" is.

Without acceptance tests, harness problems hide until real work begins, at which point debugging mixes with actual tasks and the cost doubles. `test.md` catches problems while the context is fresh and the fix is cheap.

---

## Instantiation checklist

Before handing the harness to the user, confirm:

- [ ] **Three core roles designed** — Coordinator/Planner, Generator(s), Evaluator(s) — each with a definition file, all as Agent Team peers (not subagents)
- [ ] Duration + domain classified, *briefly*
- [ ] Progress signal defined (answers "is this round better than the last?")
- [ ] Units of work identified with a concrete definition of "done"
- [ ] Domain research done, embedded into planner/evaluator prompts
- [ ] Blackboard structure exists (plan, progress, handoff, reports)
- [ ] Agent definition files written, with minimum-necessary tool allocation
- [ ] CLAUDE.md written (project context, harness rules, progress metric)
- [ ] Evaluator calibrated with few-shot examples and domain failure modes
- [ ] **`settings.json` sets `"agent": "coordinator"` as default agent** (baseline, no exceptions)
- [ ] **`settings.json` has Stop hook QA gate** (baseline, agent-type)
- [ ] Dynamic exit conditions specified (positive and negative)
- [ ] Experience layer (operations harnesses only) — where patterns accumulate
- [ ] `test.md` written with observable, binary, specific acceptance items

---

## Pointers to reference material

These files hold concrete examples — layouts, hook JSON, YAML frontmatter, ceremony patterns. Treat them as *worked examples*, not templates. Adapt, don't copy-paste.

| If you need … | Read |
|---|---|
| Software project blackboard, Planner/Builder/QA agents, Playwright patterns | `references/software_harness.md` |
| Knowledge base / wiki / research harness (wiki-is-blackboard variant) | `references/knowledge_harness.md` |
| Operations harness (experience layer, continuous loops, ops-specific patterns) | `references/operations_harness.md` |
| Stop hook JSON, settings.json structure, CLAUDE.md orientation patterns | `references/enforcement.md` |
| Agent YAML frontmatter, tool allocation, permission modes, MCP setup | `references/agent_definitions.md` |

---

Now, for the task at hand — work on: $ARGUMENTS

First, run Step 0 to detect mode. If the project already has `.claude/agents/`, run upgrade mode. Otherwise, start with the three core roles (Coordinator/Planner, Generator, Evaluator), classify the project, do domain research, then build out only the additional components the project actually needs.
