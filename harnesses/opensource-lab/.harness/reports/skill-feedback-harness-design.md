# Feedback to `harness-design` skill — 6 documentation gaps

**From**: Open Source Lab (built from harness-design skill, hit silent failure on first real install attempt)

This is the post-mortem of a silent-failure mode that took an open-source-lab harness from "looks fully built" to "silently dead" on its first real install attempt. Six documentation gaps in `harness-design` contributed.

## The failure pattern (so the skill writer can recognize it)

1. Skill was used to build a 6-agent harness with persistent-team architecture (Coordinator + Builder + Verifier + 3 supporting roles).
2. All files were generated correctly. `test.md` passed. Stop hook fired without warnings. CLAUDE.md described the team architecture accurately.
3. User asked the coordinator to install a project. Coordinator did similarity-check + dispatched planner + showed plan to user with "approve?" checkpoint.
4. Coordinator's task ended at the checkpoint (blocking I/O = task termination in Claude Code's Agent tool model).
5. User approved. Top-level Claude `SendMessage`d the approval to coordinator. **Message went to dead inbox.** No error.
6. Top-level Claude (incorrectly) waited for coordinator to respond. Coordinator never woke up because it was dead.
7. After two more rounds of "I'll restart coordinator and it'll continue," the user finally asked "what's going on?" — at which point inspection revealed `~/.claude/teams/lab/` did not exist. The harness had never actually entered team mode.

Root cause: the generated `coordinator.md` placed `TeamCreate` at **Step 5 of the install flow, after the user-approval checkpoint at Step 4**. The skill examples imply this ordering is fine because "team is created when needed." It is not fine: by the time Step 5 would execute, the coordinator is already dead.

## Gap 1: TeamCreate timing is not specified (critical)

> SKILL.md says: *"Coordinator creates a team (TeamCreate) and spawns Generator + Evaluator as teammates"*

But the skill never says **when**. The natural reading is "create the team when you need to spawn teammates" — which is what the lab's coordinator did. That reading is fatally wrong because of how Claude Code's Agent tool works: any blocking checkpoint terminates a non-team agent.

**Suggested fix**: add an explicit "TeamCreate must be the first action of the coordinator's first turn, before any user-facing work or I/O. Placing it after a checkpoint causes silent failure: the coordinator dies at the checkpoint and never reaches the TeamCreate line." Make this part of the **anti-patterns** list, not a side note.

## Gap 2: top-level Claude Code's role is not addressed

> SKILL.md says: *"Coordinator is your only conversation partner"*

In Claude Code, the user's actual entry point is always the top-level Claude session. The coordinator is reachable only via `Agent` or `SendMessage`. The skill's framing implies the user types directly to the coordinator; in practice, top-level Claude is always a router.

**Suggested fix**: add a "Bootstrap protocol for any entry point" section. State that whoever first touches the harness — top-level Claude in a fresh session, a CLI invocation, an external tool calling in — must check for the team's existence and call `TeamCreate` if absent. This protocol belongs in CLAUDE.md verbatim, not just in the coordinator's prompt.

## Gap 3: no pattern for "agent stays alive across user-approval checkpoint"

User-approval checkpoints are extremely common (plan review, destructive-action confirmation, design selection). The skill's plan-build-verify cycle has at least one such checkpoint per cycle. But the skill doesn't acknowledge that a checkpoint is a special kind of I/O event that ends a non-team agent's task.

**Suggested fix**: a short section on "blocking I/O and agent persistence." Explain: any checkpoint where the agent waits on the user becomes a task boundary; only team members survive it.

## Gap 4: `"agent": "coordinator"` alone is insufficient

> `references/enforcement.md` Layer 1: *"Opening Claude Code in the project lands on the coordinator, not a generic session."*

True, but landing on the coordinator does not make it persistent. A default-agent coordinator is still a short-lived subagent unless it explicitly calls `TeamCreate`. Layer 1 as written suggests the default-agent setting is sufficient for the harness to "work."

**Suggested fix**: amend Layer 1 to "default-agent coordinator + a Step-0 bootstrap inside the coordinator's prompt that calls `TeamCreate` if no team exists." Cite this as inseparable, not two independent settings.

## Gap 5: `test.md` template lacks runtime team-persistence checks

The skill's `test.md` invariant ("each item is observable, binary, specific") is correct, but the example items focus on file presence and script execution. None of them exercise the runtime behavior that distinguishes a working harness from a silently-broken one.

**Suggested fix**: require at least these acceptance items in every harness's `test.md`:
- After the coordinator's first turn, `~/.claude/teams/{name}/config.json` exists.
- The team config has all roles listed in the skill (coordinator + builder + verifier at minimum).
- After a user-approval checkpoint, the same coordinator instance continues (verifiable by sending "what's the status?" — coordinator should remember context, not re-introduce itself).
- `SendMessage` from another agent to the coordinator is delivered, not bounced.

These can only pass if `TeamCreate` actually fired. They turn the silent failure into a loud one.

## Gap 6: team-spawned members lose `Agent` and `TeamCreate` tools — undocumented platform behavior (critical)

**Found during recovery**, after applying gaps 1-5 above. We were testing the new "Coordinator Step 0 spawns missing members" logic and the spawned coordinator immediately reported back: it had only `Read, Write, Glob, Grep, Bash, SendMessage` — **no `Agent`, no `TeamCreate`**, even though its `.md` frontmatter clearly declared them. This is apparently a deliberate Claude Code platform behavior (likely to prevent recursive team spawning) but it is **not documented anywhere in the harness-design skill or its references**.

This silently breaks the natural design "coordinator owns team membership" because coordinator literally cannot create teammates. The only entity that retains `Agent` and `TeamCreate` after spawning is the **team-lead** (top-level Claude Code).

**Suggested fix to skill**:
- Document the platform behavior explicitly: "When you call `Agent({team_name: ..., name: ..., subagent_type: ...})`, the spawned teammate's tool list is filtered — `Agent` and `TeamCreate` are removed regardless of frontmatter. Only the team-lead (top-level Claude Code) retains these tools."
- Reframe the coordinator's role: it dispatches via `SendMessage`, it does NOT spawn. Spawning belongs to the team-lead's bootstrap protocol.
- Update example coordinator definitions: replace `Agent` and `TeamCreate` from `tools:` since they will be stripped anyway. Or keep them and add a comment noting the platform strip.
- Update CLAUDE.md examples: the bootstrap protocol must be in the team-lead's mental model, not just the coordinator's. The coordinator's Step 0 should "verify and request team-lead to spawn missing members" — never "spawn them myself."

This is closely related to Gap 2 (top-level Claude is the actual entry point, not coordinator). Together they imply: **the team-lead has unique infrastructure responsibilities that no other agent can fulfill, and the skill must name and document those responsibilities first-class.**

---

## Summary

Each gap individually is small. Together they form a class of silent failure where the skill produces a harness that **looks** correct on every static check (files exist, configs parse, hooks fire) but **is** broken at runtime in a way that takes hours of debugging to localize. The fix in each case is small (one paragraph or a couple of lines per gap). The cost of not fixing is that every future user of the skill will hit the same silent failure on their first real workload.

If applied, all six fixes are likely under 200 lines of skill changes total.
