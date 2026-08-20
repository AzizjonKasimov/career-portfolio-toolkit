[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
$errors = [System.Collections.Generic.List[string]]::new()
$repoPath = (Resolve-Path -LiteralPath $RepoRoot).Path

$markdownFiles = @(
    Get-ChildItem -LiteralPath $repoPath -Recurse -File -Filter "*.md" |
        Where-Object {
            $_.FullName -notmatch "[\\/]\.git[\\/]" -and
            ($_.FullName -match "[\\/]examples[\\/]" -or $_.Name -like "*.template.md")
        }
)

foreach ($file in $markdownFiles) {
    $lines = @(Get-Content -LiteralPath $file.FullName)
    $relative = [IO.Path]::GetRelativePath($repoPath, $file.FullName)

    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne "---") {
        $errors.Add("$relative must start with YAML front matter.")
        continue
    }

    $closingIndex = -1
    for ($index = 1; $index -lt [Math]::Min($lines.Count, 60); $index++) {
        if ($lines[$index].Trim() -eq "---") {
            $closingIndex = $index
            break
        }
    }

    if ($closingIndex -lt 2) {
        $errors.Add("$relative has no closing YAML front-matter delimiter in its first 60 lines.")
        continue
    }

    $frontMatter = $lines[1..($closingIndex - 1)] -join "`n"
    foreach ($field in @("type", "updated")) {
        if ($frontMatter -notmatch "(?m)^$([regex]::Escape($field))\s*:") {
            $errors.Add("$relative is missing front-matter field '$field'.")
        }
    }
}

$textExtensions = @(".md", ".csv", ".ps1", ".yml", ".yaml", ".json", ".txt")
$textFiles = @(
    Get-ChildItem -LiteralPath $repoPath -Recurse -File |
        Where-Object {
            $_.FullName -notmatch "[\\/]\.git[\\/]" -and
            $textExtensions -contains $_.Extension.ToLowerInvariant()
        }
)

$secretPatterns = [ordered]@{
    "private-key marker" = "-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"
    "AWS access key" = "AKIA[0-9A-Z]{16}"
    "GitHub token" = "(?:gh" + "[pousr]_[A-Za-z0-9]{20,}|github" + "_pat_[A-Za-z0-9_]{20,})"
    "OpenAI-style token" = "s" + "k-[A-Za-z0-9_-]{20,}"
    "database URL with credentials" = "(?:postgres(?:ql)?|mysql|mongodb(?:\+srv)?|redis)://[^\s]+"
}

foreach ($file in $textFiles) {
    $relative = [IO.Path]::GetRelativePath($repoPath, $file.FullName)
    if ($relative -eq "scripts\validate-content.ps1") {
        continue
    }

    $content = [IO.File]::ReadAllText($file.FullName)
    foreach ($entry in $secretPatterns.GetEnumerator()) {
        if ($content -match $entry.Value) {
            $errors.Add("$relative matches a possible $($entry.Key).")
        }
    }

    if ($content -match "(?i)[A-Z]:\\Users\\|/mnt/[a-z]/Users/") {
        $errors.Add("$relative contains an absolute user-directory path.")
    }
}

if ($errors.Count -gt 0) {
    foreach ($message in $errors) {
        Write-Error $message
    }
    exit 1
}

Write-Host "Content structure and privacy-marker checks passed. Markdown files checked: $($markdownFiles.Count)."
