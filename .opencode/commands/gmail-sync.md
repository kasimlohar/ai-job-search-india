---
description: Classify Gmail status signals into tracker updates (writes only after approval)
agent: build
---

# /gmail-sync — thin pointer; canonical spec is `.claude/commands/gmail-sync.md`

Follow `.claude/commands/gmail-sync.md` exactly, in order. Input: $ARGUMENTS (empty = default lookback; `<company>`; `since <YYYY-MM-DD>`).

Requires a Gmail MCP server (see `opencode.json`; until configured, use `/outcome` manually — this command exits cleanly when tools are absent). Nothing is written before the user approves the Step 6 batch. Never propose `hired`/`offer_declined` from email.
