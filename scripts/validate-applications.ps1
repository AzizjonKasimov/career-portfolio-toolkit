[CmdletBinding()]
param(
    [string]$CsvPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "job-search\applications.csv"),
    [string]$EventsPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "job-search\application-events.csv")
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$errors = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "Application tracker not found: $CsvPath"
}

$expectedColumns = @(
    "application_id", "company", "role_title", "platform", "platform_posting_id",
    "posting_url", "date_found", "date_applied", "status", "fit_level", "materials_path",
    "next_action", "next_follow_up", "outcome_date", "notes", "duplicate_check_key"
)

$requiredFields = @(
    "application_id", "company", "role_title", "platform", "date_found", "status",
    "duplicate_check_key"
)

$validStatuses = @(
    "found", "materials_prepared", "applied", "follow_up", "interview", "offer",
    "rejected", "withdrawn", "expired", "closed", "duplicate", "on_hold", "skipped"
)

$validFitLevels = @("strong", "good", "adjacent", "stretch", "unknown")
$validEventTypes = @(
    "found", "materials_prepared", "applied", "follow_up", "interview", "outcome", "note"
)
$dateFields = @("date_found", "date_applied", "next_follow_up", "outcome_date")

function Test-IsoDate {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    $parsed = [datetime]::MinValue
    return [datetime]::TryParseExact(
        $Value,
        "yyyy-MM-dd",
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None,
        [ref]$parsed
    )
}

$rows = @(Import-Csv -LiteralPath $CsvPath)
if ($rows.Count -eq 0) {
    $errors.Add("applications.csv must contain at least one row or a retained synthetic example row.")
} else {
    $actualColumns = @($rows[0].PSObject.Properties.Name)
    foreach ($column in $expectedColumns) {
        if ($actualColumns -notcontains $column) {
            $errors.Add("applications.csv is missing expected column '$column'.")
        }
    }
}

for ($index = 0; $index -lt $rows.Count; $index++) {
    $row = $rows[$index]
    $lineNumber = $index + 2

    foreach ($field in $requiredFields) {
        if ([string]::IsNullOrWhiteSpace($row.$field)) {
            $errors.Add("applications.csv line ${lineNumber}: missing '$field'.")
        }
    }

    if ($row.status -and $validStatuses -notcontains $row.status) {
        $errors.Add("applications.csv line ${lineNumber}: invalid status '$($row.status)'.")
    }

    if ($row.fit_level -and $validFitLevels -notcontains $row.fit_level) {
        $errors.Add("applications.csv line ${lineNumber}: invalid fit_level '$($row.fit_level)'.")
    }

    foreach ($field in $dateFields) {
        if (-not (Test-IsoDate $row.$field)) {
            $errors.Add("applications.csv line ${lineNumber}: '$field' must use YYYY-MM-DD.")
        }
    }

    if ($row.status -eq "applied" -and [string]::IsNullOrWhiteSpace($row.date_applied)) {
        $errors.Add("applications.csv line ${lineNumber}: applied status requires date_applied.")
    }

    if (-not [string]::IsNullOrWhiteSpace($row.materials_path)) {
        $materialPath = Join-Path $repoRoot $row.materials_path
        if (-not (Test-Path -LiteralPath $materialPath)) {
            $errors.Add("applications.csv line ${lineNumber}: materials_path does not exist.")
        }
    }
}

$rows |
    Group-Object duplicate_check_key |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_.Name) -and $_.Count -gt 1 } |
    ForEach-Object { $errors.Add("Duplicate application key '$($_.Name)'.") }

$eventCount = 0
if (Test-Path -LiteralPath $EventsPath) {
    $events = @(Import-Csv -LiteralPath $EventsPath)
    $eventCount = $events.Count
    $applicationIds = @{}
    foreach ($row in $rows) {
        $applicationIds[$row.application_id] = $true
    }

    for ($index = 0; $index -lt $events.Count; $index++) {
        $event = $events[$index]
        $lineNumber = $index + 2
        foreach ($field in @("event_id", "application_id", "event_date", "event_type", "summary")) {
            if ([string]::IsNullOrWhiteSpace($event.$field)) {
                $errors.Add("application-events.csv line ${lineNumber}: missing '$field'.")
            }
        }

        if ($event.application_id -and -not $applicationIds.ContainsKey($event.application_id)) {
            $errors.Add("application-events.csv line ${lineNumber}: unknown application_id.")
        }

        if ($event.event_type -and $validEventTypes -notcontains $event.event_type) {
            $errors.Add("application-events.csv line ${lineNumber}: invalid event_type.")
        }

        if ($event.status_after -and $validStatuses -notcontains $event.status_after) {
            $errors.Add("application-events.csv line ${lineNumber}: invalid status_after.")
        }

        if (-not (Test-IsoDate $event.event_date)) {
            $errors.Add("application-events.csv line ${lineNumber}: event_date must use YYYY-MM-DD.")
        }
    }

    $events |
        Group-Object event_id |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_.Name) -and $_.Count -gt 1 } |
        ForEach-Object { $errors.Add("Duplicate event_id '$($_.Name)'.") }
}

if ($errors.Count -gt 0) {
    foreach ($message in $errors) {
        Write-Error $message
    }
    exit 1
}

Write-Host "Application data is valid. Rows: $($rows.Count). Events: $eventCount."
