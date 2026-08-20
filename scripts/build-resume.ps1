[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$DataPath,

    [string]$TemplatePath = (Join-Path (Split-Path -Parent $PSScriptRoot) "resumes/templates/resume.template.html"),

    [Parameter(Mandatory)]
    [string]$HtmlPath,

    [string]$PdfPath
)

$ErrorActionPreference = "Stop"

function Get-ExistingPath {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Description)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description was not found: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-OutputPath {
    param([Parameter(Mandatory)][string]$Path)

    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }

    return [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Encode-Html {
    param([AllowNull()][object]$Value)
    return [Net.WebUtility]::HtmlEncode([string]$Value)
}

function Require-Property {
    param(
        [Parameter(Mandatory)][object]$Object,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Context
    )

    if ($Object.PSObject.Properties.Name -notcontains $Name) {
        throw "$Context is missing required property '$Name'."
    }

    $value = $Object.$Name
    if ($null -eq $value -or ([string]$value).Trim().Length -eq 0) {
        throw "$Context has an empty required property '$Name'."
    }

    return $value
}

function Render-Bullets {
    param([AllowNull()][object[]]$Items)

    $safeItems = @($Items | Where-Object { $null -ne $_ -and ([string]$_).Trim().Length -gt 0 })
    if ($safeItems.Count -eq 0) {
        return ""
    }

    $listItems = $safeItems | ForEach-Object { "<li>$(Encode-Html $_)</li>" }
    return "<ul>$($listItems -join '')</ul>"
}

$dataAbsolute = Get-ExistingPath -Path $DataPath -Description "Resume data file"
$templateAbsolute = Get-ExistingPath -Path $TemplatePath -Description "Resume template"
$htmlAbsolute = Get-OutputPath -Path $HtmlPath

try {
    $data = Get-Content -LiteralPath $dataAbsolute -Raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Resume data is not valid JSON: $($_.Exception.Message)"
}

$name = Require-Property -Object $data -Name "name" -Context "Resume"
$headline = Require-Property -Object $data -Name "headline" -Context "Resume"
$location = Require-Property -Object $data -Name "location" -Context "Resume"
$summary = Require-Property -Object $data -Name "summary" -Context "Resume"
$note = Require-Property -Object $data -Name "note" -Context "Resume"

$contactParts = [System.Collections.Generic.List[string]]::new()
$contactParts.Add("<span>$(Encode-Html $location)</span>")
foreach ($item in @($data.contact)) {
    $label = Require-Property -Object $item -Name "label" -Context "Contact item"
    $value = Require-Property -Object $item -Name "value" -Context "Contact item"
    $url = Require-Property -Object $item -Name "url" -Context "Contact item"

    $uri = $null
    if (-not [Uri]::TryCreate([string]$url, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -notin @("http", "https")) {
        throw "Contact item '$label' must use an absolute http or https URL."
    }

    $contactParts.Add(('<span><a href="{0}">{1}</a></span>' -f
            (Encode-Html $uri.AbsoluteUri), (Encode-Html $value)))
}

$skillRows = foreach ($group in @($data.skills)) {
    $label = Require-Property -Object $group -Name "label" -Context "Skill group"
    $items = @($group.items | Where-Object { $null -ne $_ -and ([string]$_).Trim().Length -gt 0 })
    if ($items.Count -eq 0) {
        throw "Skill group '$label' must contain at least one item."
    }

    $encodedItems = $items | ForEach-Object { Encode-Html $_ }
    '<div class="skill-row"><span class="skill-label">{0}</span><span>{1}</span></div>' -f
        (Encode-Html $label), ($encodedItems -join ' · ')
}

$experienceEntries = foreach ($entry in @($data.experience)) {
    $company = Require-Property -Object $entry -Name "company" -Context "Experience entry"
    $role = Require-Property -Object $entry -Name "role" -Context "Experience entry"
    $entryLocation = Require-Property -Object $entry -Name "location" -Context "Experience entry"
    $start = Require-Property -Object $entry -Name "start" -Context "Experience entry"
    $end = Require-Property -Object $entry -Name "end" -Context "Experience entry"
    $bullets = Render-Bullets -Items @($entry.bullets)

    @"
<article class="entry">
  <div class="entry-heading">
    <div><span class="entry-title">$(Encode-Html $role)</span> <span class="entry-subtitle">- $(Encode-Html $company)</span></div>
    <div class="entry-meta">$(Encode-Html $start)-$(Encode-Html $end) · $(Encode-Html $entryLocation)</div>
  </div>
  $bullets
</article>
"@
}

$projectEntries = foreach ($entry in @($data.projects)) {
    $projectName = Require-Property -Object $entry -Name "name" -Context "Project entry"
    $description = Require-Property -Object $entry -Name "description" -Context "Project entry"
    $projectUrl = Require-Property -Object $entry -Name "url" -Context "Project entry"

    $uri = $null
    if (-not [Uri]::TryCreate([string]$projectUrl, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -notin @("http", "https")) {
        throw "Project '$projectName' must use an absolute http or https URL."
    }

    $highlights = Render-Bullets -Items @($entry.highlights)
    @"
<article class="entry">
  <div class="entry-heading">
    <div class="entry-title"><a href="$(Encode-Html $uri.AbsoluteUri)">$(Encode-Html $projectName)</a></div>
    <div class="entry-meta">$(Encode-Html $uri.Host)</div>
  </div>
  <p class="project-description">$(Encode-Html $description)</p>
  $highlights
</article>
"@
}

$educationEntries = foreach ($entry in @($data.education)) {
    $institution = Require-Property -Object $entry -Name "institution" -Context "Education entry"
    $credential = Require-Property -Object $entry -Name "credential" -Context "Education entry"
    $educationLocation = Require-Property -Object $entry -Name "location" -Context "Education entry"
    $start = Require-Property -Object $entry -Name "start" -Context "Education entry"
    $end = Require-Property -Object $entry -Name "end" -Context "Education entry"

    @"
<article class="entry">
  <div class="entry-heading">
    <div><span class="entry-title">$(Encode-Html $credential)</span> <span class="entry-subtitle">- $(Encode-Html $institution)</span></div>
    <div class="entry-meta">$(Encode-Html $start)-$(Encode-Html $end) · $(Encode-Html $educationLocation)</div>
  </div>
</article>
"@
}

if (@($skillRows).Count -eq 0 -or @($experienceEntries).Count -eq 0 -or
    @($projectEntries).Count -eq 0 -or @($educationEntries).Count -eq 0) {
    throw "Resume data must include at least one skill group, experience entry, project, and education entry."
}

$replacements = [ordered]@{
    "{{DOCUMENT_TITLE}}" = "$(Encode-Html $name) - Resume"
    "{{NAME}}" = Encode-Html $name
    "{{HEADLINE}}" = Encode-Html $headline
    "{{CONTACT}}" = $contactParts -join ""
    "{{SUMMARY}}" = Encode-Html $summary
    "{{SKILLS}}" = @($skillRows) -join "`n"
    "{{EXPERIENCE}}" = @($experienceEntries) -join "`n"
    "{{PROJECTS}}" = @($projectEntries) -join "`n"
    "{{EDUCATION}}" = @($educationEntries) -join "`n"
    "{{NOTE}}" = Encode-Html $note
}

$html = [IO.File]::ReadAllText($templateAbsolute)
foreach ($item in $replacements.GetEnumerator()) {
    $html = $html.Replace($item.Key, [string]$item.Value)
}

if ($html -match "\{\{[A-Z_]+\}\}") {
    throw "The resume template contains an unresolved placeholder: $($Matches[0])"
}

$htmlDirectory = Split-Path -Parent $htmlAbsolute
[IO.Directory]::CreateDirectory($htmlDirectory) | Out-Null
[IO.File]::WriteAllText($htmlAbsolute, $html, [Text.UTF8Encoding]::new($false))
Write-Host "Wrote HTML resume: $htmlAbsolute"

if ($PdfPath) {
    $pdfAbsolute = Get-OutputPath -Path $PdfPath
    $pdfDirectory = Split-Path -Parent $pdfAbsolute
    [IO.Directory]::CreateDirectory($pdfDirectory) | Out-Null
    if (Test-Path -LiteralPath $pdfAbsolute -PathType Leaf) {
        [IO.File]::Delete($pdfAbsolute)
    }

    $edgeCandidates = @(
        @(
            (Get-Command "msedge.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
            "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
            "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
        ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -Unique
    )

    if ($edgeCandidates.Count -eq 0) {
        throw "Microsoft Edge was not found. Install Edge or omit -PdfPath to build HTML only."
    }

    $edge = $edgeCandidates[0]
    $htmlUri = ([Uri]$htmlAbsolute).AbsoluteUri
    $LASTEXITCODE = 0
    & $edge --headless --disable-gpu --no-pdf-header-footer "--print-to-pdf=$pdfAbsolute" $htmlUri
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Microsoft Edge failed to print the resume (exit code $LASTEXITCODE)."
    }

    # Edge can hand work to an existing browser process and return before the file is flushed.
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        if ((Test-Path -LiteralPath $pdfAbsolute -PathType Leaf) -and
            (Get-Item -LiteralPath $pdfAbsolute).Length -gt 0) {
            break
        }
        Start-Sleep -Milliseconds 100
    }

    if (-not (Test-Path -LiteralPath $pdfAbsolute -PathType Leaf) -or
        (Get-Item -LiteralPath $pdfAbsolute).Length -eq 0) {
        throw "Microsoft Edge did not create a non-empty PDF at: $pdfAbsolute"
    }

    Write-Host "Wrote PDF resume: $pdfAbsolute"
}
