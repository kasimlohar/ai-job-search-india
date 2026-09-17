---
description: Scaffold a job-portal search skill for a new market/board
agent: build
---

# /add-portal — thin pointer; canonical spec is `.claude/commands/add-portal.md`

Follow `.claude/commands/add-portal.md` exactly, in order. Input: $ARGUMENTS (`--list`; portal URL; empty = interview).

New skills must document the repo-root CLI path (`bun run .agents/skills/<name>/cli/src/cli.ts`), carry a personal-use warning when warranted, and pass `py tools/lint_skills.py` before registration.
