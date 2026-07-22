# Indeed India URL Reference

Public job pages on `https://in.indeed.com`. There is no clean public JSON API;
the data is embedded in the HTML responses and parsed from there.

> ⚠️ **Access restriction.** Indeed's `robots.txt` disallows `/viewjob`, `/rc/`,
> `/pagead/`, and many localized `/jobs/<CC>/` listing paths (including
> `/jobs/IN/`), and Indeed's Terms of Service restrict automated access. The
> primary search path used here, `/jobs?q=...&l=...`, is not itself listed under
> `Disallow`, but the detail path `/viewjob?jk=...` **is**. This skill is for
> **personal use only** — keep volume low. See SKILL.md.

## Search

```
GET https://in.indeed.com/jobs?q=<keywords>&l=<location>&fromage=<days>&start=<offset>
```

Query params:

| Param | Meaning | Example |
|-------|---------|---------|
| `q` | Free-text query (title / skill / role) | `accountant` |
| `l` | Location (city / state) | `Chennai` · `Bengaluru, Karnataka` |
| `fromage` | Posted-within window, in days | `1`, `3`, `7`, `14` |
| `start` | Pagination offset (steps of 10) | `0`, `10`, `20`, … |

**Response structure.** The results page embeds the job list as a JSON object
assigned to:

```
window.mosaic.providerData["mosaic-provider-jobcards"] = { ... };
```

The postings live at `metaData.mosaicProviderJobCardsModel.results[]`. Per-result
fields used by this skill:

| Field | Maps to |
|-------|---------|
| `jobkey` | `id` (also builds the detail URL) |
| `displayTitle` / `title` | `title` |
| `company` | `company` |
| `formattedLocation` | `location` |
| `pubDate` (epoch ms) / `formattedRelativeTime` | `date` |

The CLI extracts the balanced `{...}` object after the marker (a non-greedy
regex would stop at the first `}`), then reads `results[]`. A results page
carries ~15 organic cards; `start` advances by 10.

## Detail

```
GET https://in.indeed.com/viewjob?jk=<jobkey>
```

**Response structure.** The detail page contains a JSON-LD block:

```
<script type="application/ld+json"> { "@type": "JobPosting", ... } </script>
```

Fields used:

| JSON-LD path | Maps to |
|--------------|---------|
| `title` | `title` |
| `hiringOrganization.name` | `company` |
| `jobLocation.address` (`addressLocality`, `addressRegion`, `addressCountry`) | `location` |
| `datePosted` | `date` |
| `employmentType` | `employmentType` |
| `baseSalary` | `salary` |
| `description` (HTML) | `description` (tags stripped, entities decoded) |

Fallbacks when JSON-LD is missing/sparse: location from
`data-testid="inlineHeader-companyLocation"`, description from
`<div id="jobDescriptionText">`, title from
`data-testid="jobsearch-JobInfoHeader-title"`. Apply URL, when present, from the
`data-indeed-apply-joburl` attribute.

## Notes

- No authentication required for either endpoint (as of build).
- Browser `User-Agent` is required; requests without one may be blocked.
- **Transport quirk:** Indeed's edge 403s Bun's/Node's `fetch` (TLS fingerprint) but accepts the system `curl` binary, so `htmlFetch` shells out to `curl`. It also 403s some header combinations — notably `Accept` + `--compressed` together — so the CLI sends only `User-Agent` + `Accept-Language`.
- The CLI backs off on 429/403/5xx and returns `""` on 404.
- If Indeed migrates the results blob key or removes the JSON-LD block, update
  the markers in `cli/src/helpers.ts` (`mosaic-provider-jobcards"]=` and the
  `application/ld+json` / `JobPosting` selectors).
