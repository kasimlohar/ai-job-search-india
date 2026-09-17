---
description: Find new job postings via portal CLIs, dedupe, quick fit assessment
agent: build
---

# /scrape — thin pointer; canonical spec is `.claude/skills/job-scraper/SKILL.md`

Follow `.claude/skills/job-scraper/SKILL.md` exactly. Input: $ARGUMENTS (optional focus area; `broad`; `health`).

Fast path: run `pwsh -File scripts/Invoke-Scrape.ps1 -Query "<keywords>" -Location "<city>"` first for the India white-collar batch (hirist, cutshort, instahyre, iimjobs, protocoljobs, indeed-india), then continue at Step 2 (fetch & parse) with the merged `job_scraper/seen_jobs.json`. Portal CLI paths are `bun run .agents/skills/<portal>/cli/src/cli.ts` from the repo root.
