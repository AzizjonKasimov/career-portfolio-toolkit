# Contributing

Contributions that improve templates, portability, privacy checks, or documentation are welcome.

## Ground Rules

1. Use synthetic data in examples.
2. Do not submit real resumes, application records, recruiter messages, or employer-confidential
   material.
3. Keep scripts compatible with PowerShell 7 on Windows.
4. Update `README.md` when adding or moving a major workflow or folder.
5. Run both validation scripts before opening a pull request.

```powershell
pwsh -File .\scripts\validate-content.ps1
pwsh -File .\scripts\validate-applications.ps1
```

By contributing, you agree that your contribution is provided under the MIT License.
