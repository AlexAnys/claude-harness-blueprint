# Scorecard Template

The single shared rubric. QA uses this during initial install; Curator uses it during re-verify; Comparator stacks them side by side. The dimensions must stay fixed — if they drift, comparison dies.

## The 8 dimensions (1-5, any <3 = fail)

| # | Dimension | 1 (bad) | 3 (threshold) | 5 (excellent) |
|---|---|---|---|---|
| 1 | **Works** | Doesn't build | Builds with known workaround | Clean first-try install |
| 2 | **Accessible** | Needs docs open constantly | Obvious after one pass through README | Learn by doing, no docs needed |
| 3 | **Minimal config** | 10+ config knobs touched | 3-5 touched, each justified | ≤2 touched beyond defaults |
| 4 | **Documented** | setup-log missing steps | setup-log reproducible by a careful person | setup-log reproducible blind |
| 5 | **Cost** | >$50/mo or >5GB disk | <$10/mo and <1GB | $0 and <200MB |
| 6 | **Isolation** | Pollutes system (global npm, /etc/, unconditional ~/.zshrc edit) | Respects `projects/<name>/` + documents global state dirs | Fully self-contained under `projects/<name>/` |
| 7 | **Reversibility** | No uninstall path | Uninstall documented, ~10min | Single command, ≤1min |
| 8 | **Upstream health** | Last commit >12 mo, many open critical bugs | Active within 6 mo | Weekly commits, low bug debt |

## Scoring notes

- **Evidence or the score doesn't count.** Every cell needs a command output, log snippet, or file citation. "Feels good" is not evidence.
- **Decimal scores are fine** (e.g. 3.5 when between 3 and 4).
- **Never average away a fail.** If any dimension is <3, the total doesn't matter — it FAILS.
- **Re-score on re-verify.** Curator produces a new scorecard; Comparator stacks the latest.

## Per-project `qa-report.md` template

```markdown
# <Project> — QA Report

_Date: YYYY-MM-DD • QA'd by: @qa / @curator_

## Scorecard

| Dimension | Score | Evidence |
|---|---|---|
| Works | X/5 | `npm build` clean — see setup-log.md Step 5 |
| Accessible | X/5 | ... |
| Minimal config | X/5 | ... |
| Documented | X/5 | ... |
| Cost | X/5 | ... |
| Isolation | X/5 | ... |
| Reversibility | X/5 | ... |
| Upstream health | X/5 | ... |
| **Total** | X/40 | (any dim <3 auto-fails) |

## Verdict: PASS / FAIL

## Issues found
1. ...
2. ...

## UX feedback asked
1. Q: <question> → A: <user's answer>
2. ...

## Recommendations
- For @executor (if FAIL): ...
- For @curator (re-verify cadence): monthly / weekly / deprecated
- For @coordinator (promote lifecycle): installed / adopted / deprecated
```

## When to update this template

Only when a failure mode keeps slipping through the existing 8 dimensions. Add a dimension = retroactive re-scoring of all past scorecards to stay comparable. High bar — don't add lightly.
