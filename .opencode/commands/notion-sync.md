---
description: Push ranked jobs and applications to a Notion database (one-way, read-only view)
agent: build
---

# /notion-sync — thin pointer; canonical spec is `.claude/commands/notion-sync.md`

Follow `.claude/commands/notion-sync.md` exactly, in order. Input: $ARGUMENTS (empty = score >= 60 + all tracked; `--min-score <N>`; `--all`; `--rebuild`).

Requires the Notion MCP server (see `opencode.json` `mcp.notion`; enable per-run). Repo files stay the system of record; page bodies are write-once; CV/cover content never syncs (filenames only).
