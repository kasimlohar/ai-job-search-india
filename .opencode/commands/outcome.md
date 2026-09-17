---
description: Record an application result and archive materials to the tracker
agent: build
---

# /outcome — thin pointer; canonical spec is `.claude/commands/outcome.md`

Follow `.claude/commands/outcome.md` exactly, in order. Input: $ARGUMENTS (empty = list open; `<company> [<role>]`; `followup [N|<company>]`).

Writes data only (`job_search_tracker.csv` + `documents/applications/<company>_<role>/`); calibration belongs to `/setup`. Follow-ups are draft-only, max two per application, no new claims beyond submitted materials.
