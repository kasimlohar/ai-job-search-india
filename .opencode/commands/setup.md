---
description: Onboard or refresh the candidate profile from documents/ or interactive interview
agent: build
---

# /setup — thin pointer; canonical spec is `.claude/commands/setup.md`

Follow `.claude/commands/setup.md` exactly. Input: $ARGUMENTS (empty = path selection; `--section <name>` = update-only flow).

Three paths (documents folder / single CV / interview mode) converge on Step 3. Idempotent: never silently overwrite; surface conflicts explicitly.
