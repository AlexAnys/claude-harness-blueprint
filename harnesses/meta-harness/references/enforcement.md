# Reference: Enforcement (worked examples)

> **Read this as an example, not a template.** The JSON and shell below work; adapt the specifics (QA checklist, SessionStart banner content) to the project's actual rules.

---

## The four layers

```
Layer 0 : CLAUDE.md rules          (soft — guides, can be ignored under pressure)
Layer 1 : Structural default       (coordinator as default agent — baseline)
Layer 2 : Stop hook QA gate        (baseline — auto-verifies every response)
Layer 3 : settings.json tool scopes (hard limits — add when a specific operation must be prevented)
```

**L0 + L1 + L2 are the baseline for every harness.** L3 is added when a role must be prevented from touching specific tools (e.g. Evaluator must not have Edit). Experience layer is added only for operations harnesses.

A SessionStart banner hook is a nice-to-have for at-a-glance visibility but is not baseline — the `@coordinator` prefix in the Claude Code prompt is already enough to confirm the harness is loaded.

---

## Layer 1: Coordinator as default entry point (baseline)

Every harness project must set the coordinator as the default agent. The developer can't forget to use the harness because there's nothing else to use.

```json
{
  "agent": "coordinator"
}
```

Without this, opening Claude Code in the project lands on a generic session that knows project rules (via CLAUDE.md) but does not enter the plan → spec → delegate workflow, does not read `.harness/` state, and does not create agent teams unless explicitly asked. The user has to remember to `@coordinator` every time — and the main reason to build a harness is to stop relying on memory.

Agent definition lives in `.claude/agents/coordinator.md` — see `references/agent_definitions.md` for the frontmatter pattern.

---

## Layer 2: Stop hook QA gate (baseline)

Fires after every Claude response. Must be an *agent-type* hook (not command-type) so it can read the diff, read the plan, and reason about "does this match intent?" — not just "does this parse?"

### Optional companion: SessionStart banner hook

Fires when Claude Code opens. Prints a short status capsule: current spec tail, recent commits, last QA rounds, handoff note if any. Not baseline — the `@coordinator` prompt prefix already confirms the harness is loaded — but nice to have for at-a-glance progress when resuming work.

### Example: `.claude/settings.json`

```json
{
  "agent": "coordinator",
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "agent",
        "prompt": "You are a QA gate. Check git diff for uncommitted changes. Verify: (1) no obvious bugs, (2) tests exist for new logic where appropriate, (3) no security issues, (4) code follows conventions from CLAUDE.md, (5) changes match the plan in .harness/spec.md if one exists. Respond {\"ok\": true} or {\"ok\": false, \"reason\": \"specific issues\"}. $ARGUMENTS",
        "timeout": 120
      }]
    }],
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "printf '## Harness Active\\n'; printf 'Roles: coordinator(plan) -> builder(impl) -> qa(verify)\\n'; printf 'Auto-QA: Stop hook runs independent gate on every response\\n'; printf -- '---\\n'; printf 'Recent commits:\\n'; git -C \"$CLAUDE_PROJECT_DIR\" log --oneline -5 2>/dev/null || true; printf -- '---\\n'; if [ -f \"$CLAUDE_PROJECT_DIR/.harness/progress.tsv\" ]; then printf 'Last QA rounds:\\n'; tail -5 \"$CLAUDE_PROJECT_DIR/.harness/progress.tsv\" 2>/dev/null; printf -- '---\\n'; fi; printf 'Current spec:\\n'; tail -20 \"$CLAUDE_PROJECT_DIR/.harness/spec.md\" 2>/dev/null || printf '(no active spec)\\n'; if [ -f \"$CLAUDE_PROJECT_DIR/.harness/HANDOFF.md\" ]; then printf -- '---\\n'; printf 'HANDOFF:\\n'; cat \"$CLAUDE_PROJECT_DIR/.harness/HANDOFF.md\" 2>/dev/null; fi",
        "timeout": 10
      }]
    }]
  }
}
```

The QA gate and banner content should both be customized to the project — inject the domain-specific failure modes extracted during domain research into the QA prompt, and point the banner at whatever progress/handoff files the project actually uses.

---

## Layer 0: CLAUDE.md rules — orient every agent

CLAUDE.md is read by every Claude Code session. It should contain:

1. **What the project is** in one paragraph (not a wiki).
2. **Harness roles and communication paths** — who writes to what, who reads what. One small diagram or table.
3. **Reference code locations** — where to look for established patterns.
4. **Architecture constraints** — things the project has committed to (e.g. "modules don't import each other", "all external calls go through services/").
5. **How progress is measured** — the frontier metric and where it lives.
6. **Development conventions** — naming, formatting, test layout.

Agent-specific instructions do *not* belong here — they go in `.claude/agents/{role}.md`. Keep CLAUDE.md short; if it's longer than two screens, something belongs in a reference file instead.

---

## Layer 3: settings.json tool scopes — hard limits on specific operations

Use explicit `allowedTools` per agent in their definition files. Do **not** use `bypassPermissions` — it silently ignores the allow-list. Use `acceptEdits` plus explicit tool scopes.

This prevents, for example, a Verifier from accidentally editing code it was supposed to check, or an Executor from shelling out to destructive commands.

When gstack is installed, its safety skills provide additional protection at this layer: `/careful` warns before destructive commands (rm -rf, DROP TABLE, force-push), `/freeze` locks edits to a specific directory, `/guard` combines both. These can be activated per-session when working in high-risk areas.
