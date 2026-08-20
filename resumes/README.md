# Resume Kit

This folder turns selected career facts into a clean HTML resume and an optional PDF. The included
person, organizations, URLs, and results are fictional, so you can inspect and share the example
without exposing anyone's private information.

## Included Files

| Path | Purpose |
|------|---------|
| `templates/resume-data.template.json` | Blank structured source for one tailored resume |
| `templates/resume.template.html` | Print-ready A4 layout and styles |
| `templates/cover-letter.template.md` | Prompts and structure for a tailored cover letter |
| `examples/example-resume.json` | Completed fictional source data |
| `examples/example-resume.html` | Generated fictional resume for browser preview |
| `examples/example-resume.pdf` | Generated fictional resume ready to share |
| `examples/example-cover-letter.md` | Completed fictional cover letter |
| `../scripts/build-resume.ps1` | JSON-to-HTML/PDF builder |

## Build Your Resume

Keep factual evidence in `profile/`, `experience/`, `projects/`, and `case-studies/`. For each job,
copy only the most relevant facts into a private resume JSON file. Do not invent outcomes or expose
employer-confidential details.

```powershell
New-Item -ItemType Directory -Force .\resumes\private | Out-Null
Copy-Item .\resumes\templates\resume-data.template.json .\resumes\private\my-resume.json

pwsh -File .\scripts\build-resume.ps1 `
  -DataPath .\resumes\private\my-resume.json `
  -HtmlPath .\out\my-resume.html `
  -PdfPath .\out\my-resume.pdf
```

The PDF option uses Microsoft Edge's headless print mode. Omit `-PdfPath` if you only need HTML.
Open the HTML in a browser to review it before sharing the PDF.

## What to Tailor

1. Match the headline and summary to the role without overstating your background.
2. Put the most relevant skills first; remove skills you cannot discuss confidently.
3. Choose two to four bullets per recent role. Lead with the action, then the measurable outcome
   and enough context to make the result credible.
4. Include projects that demonstrate requirements the work history does not cover.
5. Check dates, links, spelling, page breaks, and PDF text selection before sending.

`resumes/private/` is ignored by Git. This is the safest place in this public repository for a
local working copy, but remember that any file can still be published accidentally if ignore rules
are overridden. Keep phone numbers, personal email addresses, home addresses, and job-specific
documents out of commits unless you deliberately want them public.

## Build the Fictional Example

```powershell
pwsh -File .\scripts\build-resume.ps1 `
  -DataPath .\resumes\examples\example-resume.json `
  -HtmlPath .\resumes\examples\example-resume.html `
  -PdfPath .\resumes\examples\example-resume.pdf
```

The generated files are committed so visitors can see the result without installing anything.
