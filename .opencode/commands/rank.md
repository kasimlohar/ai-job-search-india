---
description: Batch-score scraped jobs into a ranked shortlist (triage, not final evaluation)
agent: build
---

# /rank — thin pointer; canonical spec is `.claude/commands/rank.md`

Follow `.claude/commands/rank.md` exactly, in order. Input: $ARGUMENTS (empty = rank all `new`; focus area; `--all`; `--top <N>`).

Produces triage scores from posting text + profile only. `/apply` Step 1 re-evaluation stays authoritative. State in `job_scraper/seen_jobs.json` is additive-only.
