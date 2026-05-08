# Meta Harness -- Harness Design Skill

A meta-skill for Claude Code that automatically designs multi-agent harnesses for any project type.

## What it does

Given a project description, this skill designs a complete multi-agent harness following Anthropic's [harness design methodology](https://www.anthropic.com/engineering/harness-design-long-running-apps). It covers three project domains:

- **Software development** -- Planner -> Builder -> QA
- **Knowledge compilation** -- Coordinator -> Compiler -> QA
- **Operations** -- Coordinator -> Executor -> Monitor

The skill generates agent definition files, settings.json with enforcement hooks, blackboard structure, and acceptance tests -- everything needed to run a multi-agent workflow in Claude Code.

## Files

| File | Description |
|---|---|
| `SKILL.md` | Core meta-skill (the main instruction file) |
| `references/software_harness.md` | Worked example for software projects |
| `references/knowledge_harness.md` | Worked example for knowledge/research projects |
| `references/operations_harness.md` | Worked example for operations pipelines |
| `references/enforcement.md` | Stop hooks, settings.json, CLAUDE.md patterns |
| `references/agent_definitions.md` | Agent YAML frontmatter, tool allocation, permissions |

## Installation

Copy the entire directory to your Claude Code skills folder:

```bash
cp -r harnesses/meta-harness/ ~/.claude/skills/harness-design/
```

After installation, you can invoke it with `/harness-design` followed by a project description:

```
/harness-design build a documentation wiki from markdown sources
/harness-design set up CI/CD pipeline monitoring
/harness-design web app with React frontend and Python API
```

The skill will classify your project, do domain research, and generate the complete harness infrastructure.

## Core methodology

The skill enforces three invariants:

1. **Role separation** -- the agent doing the work is never the agent judging it
2. **Specific evaluation** -- quality is broken into named, scorable dimensions
3. **Infrastructure over advice** -- harness discipline is enforced by settings.json hooks, not human memory
