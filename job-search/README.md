# Job-Search Tracker

This folder demonstrates a local, file-based workflow for preventing duplicate applications and
preserving a reliable application timeline.

Real job-search records are sensitive. Use this folder in a private fork, or replace the synthetic
rows with empty files before keeping your fork public.

## Files

| File | Purpose |
|------|---------|
| `applications.csv` | Latest state of each opportunity or application |
| `application-events.csv` | Append-only history of meaningful events |
| `application-detail.template.md` | Optional notes when a CSV row is not enough |

## Workflow

1. Search the tracker by posting ID, URL, company, and role before applying.
2. Add a row when an opportunity becomes worth tracking.
3. Use `materials_prepared` until submission is confirmed.
4. Set `applied` only after submission or email delivery is confirmed.
5. Append an event whenever the status or next action changes.
6. Record only information needed to manage the search.
7. Never store passwords, one-time codes, cookies, tokens, or identity documents.

## Status Values

`found`, `materials_prepared`, `applied`, `follow_up`, `interview`, `offer`, `rejected`,
`withdrawn`, `expired`, `closed`, `duplicate`, `on_hold`, or `skipped`.

## Fit Levels

`strong`, `good`, `adjacent`, `stretch`, or `unknown`.

## Duplicate Key

Prefer a stable platform posting ID:

```text
exampleboard:EX-1001
```

When no posting ID exists, use a normalized company and role:

```text
company-role:northstar-systems:data-engineer
```

## Commands

```powershell
pwsh -File .\scripts\check-application.ps1 -Company "Example Labs"
pwsh -File .\scripts\validate-applications.ps1
```
