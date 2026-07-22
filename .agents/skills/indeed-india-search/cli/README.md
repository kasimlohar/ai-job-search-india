# indeed-india-cli

CLI for searching jobs on **Indeed India** (`https://in.indeed.com`), across any
sector.

**Data source**: Indeed India public pages — the search results JSON blob
(`mosaic-provider-jobcards`) and the detail page's JSON-LD `JobPosting`.
**Authentication**: None required.
**Dependencies**: No npm runtime deps (`bun install` only pulls dev type defs). Fetching shells out to the system **`curl`** binary — Indeed's edge blocks Bun's TLS fingerprint with a 403, but curl's is accepted. `curl` ships by default on Windows 10+, macOS, and virtually every Linux.

> ⚠️ **Personal use only.** Indeed's `robots.txt` disallows `/viewjob` (the detail
> path) and Indeed's Terms of Service restrict automated access. Keep volume low,
> don't use it commercially or for bulk data collection, and run it on your own
> responsibility.

## Installation

```bash
cd .agents/skills/indeed-india-search/cli
bun install   # optional — only installs TypeScript dev types
```

The CLI runs without any install because it has zero runtime dependencies.

## Commands

| Command | Description |
|---------|-------------|
| `search` | Search for job listings (`--query` and/or `--location`) |
| `detail` | Fetch full detail for a single job listing |

`search` accepts `--format json|table|plain` (default `json`); `detail` accepts `--format json|plain`.
All errors are written to **stderr** as `{ "error": "...", "code": "..." }` with exit code `1`.

## Quick examples

```bash
# Accountant roles in Chennai
bun run src/cli.ts search -q "accountant" -l "Chennai" --format table

# Data analyst roles in Bengaluru, last 7 days
bun run src/cli.ts search -q "data analyst" -l "Bengaluru, Karnataka" --jobage 7 --format table

# Sales roles in Mumbai, capped at 10
bun run src/cli.ts search -q "sales executive" -l "Mumbai, Maharashtra" --limit 10

# Full detail for one job
bun run src/cli.ts detail 1758596463bc5d18 --format plain
```

See `../SKILL.md` for the full flag reference and the Terms-of-Service note.

## Search flags

| Flag | Alias | Description |
|------|-------|-------------|
| `--query` | `-q` | Keywords (title / skill / role). Recommended. |
| `--location` | `-l` | City / state, e.g. `"Chennai"`, `"Bengaluru, Karnataka"`. Omit for all-India. |
| `--jobage` | | Posted within N days: `1`, `3`, `7`, `14`. |
| `--page` | | 1-indexed page (offset steps of 10). |
| `--limit` | `-n` | Cap results emitted. |
| `--format` | | `json` \| `table` \| `plain`. |

At least one of `--query` or `--location` is required.
