#!/usr/bin/env python3
"""Merge raw portal scrape outputs into job_scraper/seen_jobs.json.

Each <portal>.json in --raw-dir is a CLI envelope {"meta": ..., "results": [...]}
with per-result id/title/company/location/date/url. Entries are added
additively (never restructured), honouring /scrape + /rank contracts:

- key: posting URL, else "company::title" lowercased.
- new entries: status "new", fit null (agent does the Step 3 quick-fit next),
  first_seen today, portal = filename stem.
- already-seen keys: untouched.
- company+title already in job_search_tracker.csv: status "skipped".

Usage: py tools/scrape_merge.py --raw-dir job_scraper/raw/<stamp>
"""

import argparse
import csv
import datetime
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def norm(s):
    return " ".join((s or "").strip().lower().split())


def load_tracker_keys(tracker_path):
    keys = set()
    if not tracker_path.is_file():
        return keys
    with tracker_path.open(encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh):
            keys.add((norm(row.get("company")), norm(row.get("role"))))
    return keys


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Merge raw scrape JSON into seen_jobs.json."
    )
    ap.add_argument("--raw-dir", required=True, type=Path)
    ap.add_argument(
        "--seen", type=Path, default=ROOT / "job_scraper" / "seen_jobs.json"
    )
    ap.add_argument("--tracker", type=Path, default=ROOT / "job_search_tracker.csv")
    args = ap.parse_args(argv)

    raw_files = sorted(args.raw_dir.glob("*.json"))
    if not raw_files:
        print(f"scrape_merge: no .json files in {args.raw_dir}", file=sys.stderr)
        return 1

    seen = {"seen": {}}
    if args.seen.is_file():
        try:
            seen = json.loads(args.seen.read_text(encoding="utf-8"))
            seen.setdefault("seen", {})
        except json.JSONDecodeError as exc:
            print(f"scrape_merge: {args.seen} is corrupt: {exc}", file=sys.stderr)
            return 1

    tracker_keys = load_tracker_keys(args.tracker)
    today = datetime.date.today().isoformat()
    added, skipped_tracker, already = 0, 0, 0

    for raw in raw_files:
        portal = raw.stem
        try:
            envelope = json.loads(raw.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            print(
                f"scrape_merge: WARN {raw.name} is not JSON (see {portal}.stderr.txt) - skipped"
            )
            continue
        results = envelope.get("results", []) if isinstance(envelope, dict) else []
        for r in results:
            if not isinstance(r, dict):
                continue
            url = (r.get("url") or "").strip()
            key = url if url else f"{norm(r.get('company'))}::{norm(r.get('title'))}"
            if not key.strip(":"):
                continue
            if key in seen["seen"]:
                already += 1
                continue
            entry = {
                "title": r.get("title"),
                "company": r.get("company"),
                "url": url or None,
                "first_seen": today,
                "fit": None,  # agent quick-fit (/scrape Step 3) fills this in
                "status": "new",
                "portal": portal,
            }
            if (norm(r.get("company")), norm(r.get("title"))) in tracker_keys:
                entry["status"] = "skipped"
                skipped_tracker += 1
            else:
                added += 1
            seen["seen"][key] = entry

    args.seen.parent.mkdir(parents=True, exist_ok=True)
    args.seen.write_text(
        json.dumps(seen, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    total = len(seen["seen"])
    print(
        f"scrape_merge: +{added} new, {skipped_tracker} skipped (in tracker), "
        f"{already} already seen; {total} total in {args.seen.name}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
