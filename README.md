# Career Portfolio Toolkit

[![Validate toolkit](https://github.com/AzizjonKasimov/career-portfolio-toolkit/actions/workflows/validate.yml/badge.svg)](https://github.com/AzizjonKasimov/career-portfolio-toolkit/actions/workflows/validate.yml)

A privacy-first, file-based system for keeping career facts, project stories, and job-search
records organized. The repository is intentionally made from templates and synthetic examples;
it does not contain anyone's real application history, contact details, resumes, or employer
confidential information.

The toolkit works well for people who want one durable source of truth that can be read by humans,
scripts, or AI assistants without locking their information into a particular application.

## What You Get

- Markdown templates for profiles, experience, projects, and case studies.
- A resume data template, print-ready HTML layout, PowerShell builder, and finished PDF example.
- A cover-letter template and fictional worked example.
- A CSV-based job-application ledger and append-only event log.
- PowerShell helpers for duplicate checks and tracker validation.
- Synthetic examples that demonstrate the format without exposing personal information.
- Privacy guidance for deciding what belongs in a public or private repository.
- GitHub Actions validation on every push and pull request.

## Quick Start

```powershell
git clone https://github.com/AzizjonKasimov/career-portfolio-toolkit.git
Set-Location .\career-portfolio-toolkit

Copy-Item .\profile\profile.template.md .\profile\my-profile.md
Copy-Item .\experience\experience.template.md .\experience\my-first-role.md
Copy-Item .\projects\project.template.md .\projects\my-project.md

pwsh -File .\scripts\validate-content.ps1
pwsh -File .\scripts\validate-applications.ps1

# Build the fictional example as HTML and PDF (Microsoft Edge is used for PDF printing).
pwsh -File .\scripts\build-resume.ps1 `
  -DataPath .\resumes\examples\example-resume.json `
  -HtmlPath .\resumes\examples\example-resume.html `
  -PdfPath .\resumes\examples\example-resume.pdf
```

Delete the synthetic rows from `job-search/applications.csv` and
`job-search/application-events.csv` before recording your own search.

## Recommended Repository Model

Use two repositories when your workflow includes sensitive material:

1. **Private source of truth:** real contact details, resumes, application records, recruiter
   conversations, private evidence, and detailed employer notes.
2. **Public portfolio:** approved summaries, public projects, sanitized case studies, and reusable
   templates or tooling.

Do not assume that deleting a file later removes it from Git history. Keep private material out of
the public repository from its first commit.

## Structure

| Path | Purpose |
|------|---------|
| `profile/` | Professional-summary template and public-contact guidance |
| `experience/` | One Markdown file per role |
| `projects/` | One Markdown file per personal or public project |
| `case-studies/` | Sanitized problem/approach/outcome narratives |
| `resumes/` | Resume source data, printable template, builder guide, and finished examples |
| `job-search/` | Application ledger, event log, and optional detail template |
| `examples/` | Fully synthetic examples for each content type |
| `scripts/` | Read-only PowerShell checks |
| `PRIVACY.md` | Publication checklist and public/private boundary |

## Content Conventions

- Keep one item per Markdown file.
- Start content files with YAML front matter for filtering and automation.
- Record facts and sources; label estimates and unknowns explicitly.
- Use repository-relative paths so the system remains portable.
- Store reusable facts separately from role-specific outputs.
- Treat job-search records as private by default.

## Resume Workflow

The resume kit keeps reusable career facts separate from the document you tailor for a specific
role. Start with the profile, experience, and project templates, then copy the strongest relevant
facts into `resumes/templates/resume-data.template.json`. Build a shareable version with:

```powershell
New-Item -ItemType Directory -Force .\resumes\private | Out-Null
Copy-Item .\resumes\templates\resume-data.template.json .\resumes\private\my-resume.json

pwsh -File .\scripts\build-resume.ps1 `
  -DataPath .\resumes\private\my-resume.json `
  -HtmlPath .\out\my-resume.html `
  -PdfPath .\out\my-resume.pdf
```

The repository includes a completely fictional
[source file](resumes/examples/example-resume.json),
[HTML resume](resumes/examples/example-resume.html), and
[PDF resume](resumes/examples/example-resume.pdf), plus a cover-letter template. See
[resumes/README.md](resumes/README.md) for the full workflow and customization guidance.

## Job-Search Workflow

Search for an existing application before adding a new one:

```powershell
pwsh -File .\scripts\check-application.ps1 -Company "Example Labs"
pwsh -File .\scripts\check-application.ps1 -Platform "ExampleBoard" -PostingId "EX-1001"
```

Validate the ledger and event log:

```powershell
pwsh -File .\scripts\validate-applications.ps1
```

See [job-search/README.md](job-search/README.md) for the schema and status workflow.

## Before Publishing Your Own Version

Read [PRIVACY.md](PRIVACY.md), replace synthetic examples carefully, and run:

```powershell
pwsh -File .\scripts\validate-content.ps1
pwsh -File .\scripts\validate-applications.ps1
pwsh -File .\scripts\build-resume.ps1 `
  -DataPath .\resumes\examples\example-resume.json `
  -HtmlPath .\out\example-resume.html
git status --short
```

The checks reduce common mistakes but cannot prove that publication is legally or professionally
safe. Obtain permission before describing employer, customer, or client systems that are not
already public.

## License

This project is available under the [MIT License](LICENSE). You may use, copy, modify, and share
the templates, examples, documentation, and scripts under those terms.
