---
name: indeed-india-search
version: 1.0.0
description: >
  Use this skill to search job listings on Indeed India (in.indeed.com) for jobs
  anywhere in India — any city (Chennai, Bengaluru, Mumbai, Delhi NCR, Hyderabad,
  Pune, Kolkata) and any sector or role (accounting, software, data, sales,
  operations, healthcare, etc.). Also fetches the full description of a specific
  Indeed posting. Trigger phrases: find a job in India, Indeed jobs, Indeed India,
  search Indeed, job vacancies in <Indian city>, naukri/jobs in India, "are there
  any X jobs in <Indian city>", look up this Indeed job posting, in.indeed.com.
context: fork
allowed-tools: Bash(bun run skills/indeed-india-search/cli/src/cli.ts *)
---

# Indeed India Search Skill

Search live job listings from **Indeed India** (`https://in.indeed.com`). No
authentication, no API key, and **zero runtime dependencies** — it runs with just
`bun`. Search reads the results-page JSON blob; detail reads the posting's JSON-LD.

## ⚠️ Personal use only

Indeed's `robots.txt` **disallows** `/viewjob` (the job-detail path this skill
fetches), along with `/rc/`, `/pagead/`, and localized listing paths, and Indeed's
Terms of Service restrict automated access. This skill is provided for **personal
use only**: **keep request volume low, do not use it commercially or for bulk data
collection, and run it on your own responsibility.** If you need Indeed data at
scale, use Indeed's official Publisher/Employer APIs instead.

## When to use this skill

- Search for job openings anywhere in India by keyword and/or city
- Filter by recency (posted within 1 / 3 / 7 / 14 days)
- Get the full description of a specific Indeed India posting

## Commands

### Search job listings

```bash
bun run skills/indeed-india-search/cli/src/cli.ts search --query "<keywords>" [flags]
```

Key flags:
- `--query` / `-q <text>` — keyword search (title, skill, role). Recommended.
- `--location` / `-l <text>` — city or state, e.g. `"Chennai"`, `"Bengaluru, Karnataka"`, `"Mumbai, Maharashtra"`. Omit to search all of India.
- `--jobage <days>` — posted within N days: `1`, `3`, `7`, `14`. Omit for all postings.
- `--page <n>` — page number (1-indexed; offset advances by 10).
- `--limit <n>` / `-n <n>` — cap total results emitted (client-side).
- `--format json|table|plain` — default `json`.

At least one of `--query` or `--location` must be supplied.

### Fetch full job detail

```bash
bun run skills/indeed-india-search/cli/src/cli.ts detail <jobkey|url> [--format json|plain]
```

`jobkey` is the `id` from `search` results (e.g. `1758596463bc5d18`). You may also
pass a full `in.indeed.com/viewjob?jk=...` URL. Returns the full description,
company, location, employment type, salary (when listed), and apply link.

## Usage examples

```bash
# Accountant roles in Chennai
bun run skills/indeed-india-search/cli/src/cli.ts search -q "accountant" -l "Chennai" --format table

# Data analyst roles in Bengaluru, last 7 days
bun run skills/indeed-india-search/cli/src/cli.ts search -q "data analyst" -l "Bengaluru, Karnataka" --jobage 7 --format table

# Software engineer roles in Hyderabad
bun run skills/indeed-india-search/cli/src/cli.ts search -q "software engineer" -l "Hyderabad, Telangana" --format table

# Any role in Pune, remote-friendly search
bun run skills/indeed-india-search/cli/src/cli.ts search -q "customer support" -l "Pune, Maharashtra" --limit 10

# Full details for a specific job
bun run skills/indeed-india-search/cli/src/cli.ts detail 1758596463bc5d18 --format plain
```

## Output formats

| Format | Best for |
|--------|----------|
| `json` | Default — programmatic use, passing IDs to `detail` |
| `table` | Quick human-readable scanning |
| `plain` | Reading a single job's full detail (`detail` command) |

JSON search output is `{ "meta": { "count", "page" }, "results": [...] }`; each
result has `id`, `title`, `company`, `location`, `date`, `url` (missing values are
`null`). All errors are written to **stderr** as `{ "error": "...", "code": "..." }`
and the process exits with code `1`.

## Notes

- Job keys are hex strings (e.g. `1758596463bc5d18`) — pass them as-is to `detail`.
- Search results come from the embedded `mosaic-provider-jobcards` JSON; a results page carries ~15 organic postings and `--page` advances the offset by 10.
- Detail data comes from the posting's JSON-LD `JobPosting` block (title, company, location, posting date, employment type, salary, description).
- `date` in search results is the ISO posting date (from `pubDate`) when Indeed provides it, otherwise Indeed's relative label (e.g. "1 day ago").
- Fetching uses the system `curl` binary (present by default on Windows/macOS/Linux): Indeed's edge 403s Bun's TLS fingerprint, but accepts curl's. No npm runtime dependencies.
- Indeed may rate-limit; the CLI retries 429/403/5xx with exponential backoff. Keep volume low (see the personal-use note above).
- If results come back empty, Indeed may have changed the embedded blob key or JSON-LD — see `url-reference.md` for the parsing anchors to update.
