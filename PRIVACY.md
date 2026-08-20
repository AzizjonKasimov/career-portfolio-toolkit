# Privacy and Publication Guide

Git remembers content. A normal deletion removes a file from the latest snapshot, not from older
commits. The safest public repository is one that has never contained private material.

## Keep Private by Default

- Personal phone numbers, home addresses, private email addresses, and identity documents.
- Real job applications, outcomes, recruiter correspondence, and follow-up drafts.
- Resumes or cover letters containing contact information.
- Account screenshots, confirmation receipts, browser state, cookies, or session data.
- Salary history, immigration details, health information, or family information.
- Client datasets, internal dashboards, database schemas, credentials, and infrastructure names.
- Employer metrics, architecture, pricing logic, or operational details without approval.

## Usually Safe After Review

- A short public biography and a deliberately chosen public contact channel.
- Personal projects whose source and data you own.
- Sanitized case studies that use approved facts and generalized architecture.
- Empty templates, validation scripts, and synthetic examples.
- Links to material that is already intentionally public.

## Publication Checklist

- [ ] Search the current tree and every Git commit for secrets and personal data.
- [ ] Confirm examples use fictional names and `example.com` URLs.
- [ ] Inspect PDFs, Office files, images, and metadata—not only source text.
- [ ] Remove absolute local paths and usernames.
- [ ] Confirm you own the content or have permission to publish it.
- [ ] Add a license that matches how others may reuse the work.
- [ ] Review GitHub Actions logs and artifacts before changing visibility.
- [ ] Clone the repository without authentication and inspect that clean clone.

## If Sensitive Data Was Committed

Rotate exposed credentials first. Then use a dedicated history-rewrite workflow and coordinate
with every collaborator who has a clone. For personal or employer information, creating a new
repository with fresh history is often simpler and safer than attempting to clean an old one.
