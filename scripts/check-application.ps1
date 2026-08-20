[CmdletBinding()]
param(
    [string]$Company,
    [string]$Role,
    [string]$Platform,
    [string]$PostingId,
    [string]$Url,
    [string]$CsvPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "job-search\applications.csv")
)

if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "Application tracker not found: $CsvPath"
}

if (-not ($Company -or $Role -or $Platform -or $PostingId -or $Url)) {
    Write-Host "Provide at least one value: -Company, -Role, -Platform, -PostingId, or -Url."
    exit 2
}

function Test-ContainsText {
    param(
        [AllowNull()][string]$Value,
        [AllowNull()][string]$Needle
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or [string]::IsNullOrWhiteSpace($Needle)) {
        return $false
    }

    return $Value.IndexOf($Needle, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

$rows = @(Import-Csv -LiteralPath $CsvPath)
$matches = @($rows | Where-Object {
    if ($PostingId) {
        return $_.platform_posting_id -eq $PostingId -and
            (-not $Platform -or (Test-ContainsText $_.platform $Platform))
    }

    if ($Url) {
        return (Test-ContainsText $_.posting_url $Url) -and
            (-not $Platform -or (Test-ContainsText $_.platform $Platform))
    }

    if ($Platform -and -not (Test-ContainsText $_.platform $Platform)) {
        return $false
    }

    if ($Company -and -not (Test-ContainsText $_.company $Company)) {
        return $false
    }

    if ($Role -and -not (Test-ContainsText $_.role_title $Role)) {
        return $false
    }

    return $true
})

if ($matches.Count -eq 0) {
    Write-Host "No matching applications found."
    exit 0
}

$matches |
    Sort-Object date_applied, date_found, company |
    Select-Object status, date_applied, platform, platform_posting_id, company, role_title,
        fit_level, next_follow_up, posting_url |
    Format-Table -AutoSize
