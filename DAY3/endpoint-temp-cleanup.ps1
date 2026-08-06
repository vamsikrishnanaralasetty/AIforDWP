<#
.SYNOPSIS
Safe temp file cleanup for Windows endpoints (PowerShell 5.1).

.DESCRIPTION
- Supports dry run mode
- Targets files older than a configurable number of days
- Skips locked files
- Uses try/catch per file
- Logs every action to a timestamped log file
- Prints a summary at the end
- Supports rollback using a per-run manifest
- Designed to be idempotent
#>

[CmdletBinding(DefaultParameterSetName = 'Cleanup')]
param (
    # SECTION 1: Cleanup mode options
    # These parameters control normal cleanup behavior.
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$TargetPaths = @($env:TEMP, (Join-Path $env:WINDIR 'Temp')),

    # SECTION 2: Rollback mode option
    # Provide a run ID to restore files moved during that cleanup run.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RollbackRunId
)

# SECTION 3: Initialize runtime paths and timestamps
# This section sets up state folders for logs, manifests, and quarantine.
$script:StateRoot = Join-Path $PSScriptRoot 'temp-cleanup-state'
$script:LogRoot = Join-Path $script:StateRoot 'logs'
$script:ManifestRoot = Join-Path $script:StateRoot 'manifests'
$script:QuarantineRoot = Join-Path $script:StateRoot 'quarantine'
$script:Now = Get-Date
$script:RunId = if ($PSCmdlet.ParameterSetName -eq 'Cleanup') { $script:Now.ToString('yyyyMMdd-HHmmss') } else { $RollbackRunId }
$script:LogFile = Join-Path $script:LogRoot ((if ($PSCmdlet.ParameterSetName -eq 'Cleanup') { 'cleanup' } else { 'rollback' }) + "-$script:RunId.log")

# SECTION 4: Ensure folders exist
# This section creates script state directories if missing.
foreach ($path in @($script:StateRoot, $script:LogRoot, $script:ManifestRoot, $script:QuarantineRoot)) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# SECTION 5: Logging helper
# This section writes timestamped log entries to console and file.
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Host $line
    Add-Content -Path $script:LogFile -Value $line
}

# SECTION 6: Locked file check helper
# This section tests whether a file is locked by trying exclusive ReadWrite access.
function Test-FileLocked {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        return $false
    }
    catch [System.IO.IOException] {
        return $true
    }
    catch {
        return $false
    }
}

# SECTION 7: Cleanup workflow
# This section finds eligible temp files and moves them to quarantine (or prints in dry run).
function Invoke-Cleanup {
    $summary = [ordered]@{
        Mode             = if ($DryRun) { 'DryRun' } else { 'Cleanup' }
        RunId            = $script:RunId
        CutoffDate       = (Get-Date).AddDays(-$OlderThanDays)
        FilesScanned     = 0
        FilesEligible    = 0
        FilesMoved       = 0
        FilesWouldDelete = 0
        FilesLocked      = 0
        FilesErrors      = 0
        PathsMissing     = 0
    }

    $manifestEntries = New-Object System.Collections.Generic.List[object]
    $runQuarantineDir = Join-Path $script:QuarantineRoot $script:RunId
    if (-not $DryRun -and -not (Test-Path -LiteralPath $runQuarantineDir)) {
        New-Item -Path $runQuarantineDir -ItemType Directory -Force | Out-Null
    }

    Write-Log "Cleanup started. DryRun=$DryRun OlderThanDays=$OlderThanDays"

    foreach ($target in $TargetPaths) {
        if ([string]::IsNullOrWhiteSpace($target)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $target)) {
            $summary.PathsMissing++
            Write-Log "Target path missing, skipped: $target" 'WARN'
            continue
        }

        Write-Log "Scanning target path: $target"

        Get-ChildItem -LiteralPath $target -File -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $file = $_
            $summary.FilesScanned++

            if ($file.LastWriteTime -ge $summary.CutoffDate) {
                return
            }

            $summary.FilesEligible++

            if (Test-FileLocked -Path $file.FullName) {
                $summary.FilesLocked++
                Write-Log "Locked file skipped: $($file.FullName)" 'WARN'
                return
            }

            try {
                if ($DryRun) {
                    $summary.FilesWouldDelete++
                    Write-Output $file.FullName
                    Write-Log "DRYRUN would delete: $($file.FullName)"
                }
                else {
                    $encodedName = ($file.FullName -replace '[:\\/\s]', '_')
                    $destination = Join-Path $runQuarantineDir $encodedName

                    Move-Item -LiteralPath $file.FullName -Destination $destination -Force -ErrorAction Stop

                    $manifestEntries.Add([pscustomobject]@{
                        OriginalPath   = $file.FullName
                        QuarantinePath = $destination
                        LastWriteTime  = $file.LastWriteTime
                        Length         = $file.Length
                        MovedAt        = (Get-Date)
                    }) | Out-Null

                    $summary.FilesMoved++
                    Write-Log "Moved to quarantine: $($file.FullName) -> $destination"
                }
            }
            catch {
                $summary.FilesErrors++
                Write-Log "Error processing file '$($file.FullName)': $($_.Exception.Message)" 'ERROR'
            }
        }
    }

    if (-not $DryRun) {
        $manifest = [pscustomobject]@{
            RunId          = $script:RunId
            GeneratedAt    = Get-Date
            OlderThanDays  = $OlderThanDays
            TargetPaths    = $TargetPaths
            Entries        = $manifestEntries
        }

        $manifestPath = Join-Path $script:ManifestRoot ("manifest-$($script:RunId).json")
        $manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8
        Write-Log "Manifest written: $manifestPath"
    }

    Write-Log "Cleanup completed."
    return [pscustomobject]$summary
}

# SECTION 8: Rollback workflow
# This section restores files from quarantine using the manifest of a specific run.
function Invoke-Rollback {
    $summary = [ordered]@{
        Mode                   = 'Rollback'
        RunId                  = $RollbackRunId
        FilesListedInManifest  = 0
        FilesRestored          = 0
        FilesAlreadyRestored   = 0
        FilesRestoreConflicts  = 0
        FilesErrors            = 0
    }

    $manifestPath = Join-Path $script:ManifestRoot ("manifest-$RollbackRunId.json")
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Manifest not found for RunId '$RollbackRunId': $manifestPath"
    }

    Write-Log "Rollback started for RunId=$RollbackRunId"

    $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json

    foreach ($entry in $manifest.Entries) {
        $summary.FilesListedInManifest++

        try {
            if (-not (Test-Path -LiteralPath $entry.QuarantinePath)) {
                $summary.FilesAlreadyRestored++
                Write-Log "Already restored or missing in quarantine: $($entry.QuarantinePath)" 'WARN'
                continue
            }

            if (Test-Path -LiteralPath $entry.OriginalPath) {
                $summary.FilesRestoreConflicts++
                Write-Log "Restore conflict, original path already exists: $($entry.OriginalPath)" 'WARN'
                continue
            }

            $parentDir = Split-Path -Path $entry.OriginalPath -Parent
            if (-not (Test-Path -LiteralPath $parentDir)) {
                New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $entry.QuarantinePath -Destination $entry.OriginalPath -Force -ErrorAction Stop
            $summary.FilesRestored++
            Write-Log "Restored: $($entry.OriginalPath)"
        }
        catch {
            $summary.FilesErrors++
            Write-Log "Error restoring '$($entry.OriginalPath)': $($_.Exception.Message)" 'ERROR'
        }
    }

    Write-Log "Rollback completed."
    return [pscustomobject]$summary
}

# SECTION 9: Main execution
# This section runs cleanup or rollback and prints a final summary.
try {
    $result = if ($PSCmdlet.ParameterSetName -eq 'Rollback') {
        Invoke-Rollback
    }
    else {
        Invoke-Cleanup
    }

    Write-Host ''
    Write-Host '=== Summary ===' -ForegroundColor Cyan
    $result.PSObject.Properties | ForEach-Object {
        Write-Host ('{0}: {1}' -f $_.Name, $_.Value)
    }
    Write-Host ("Log file: {0}" -f $script:LogFile)
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" 'ERROR'
    throw
}
