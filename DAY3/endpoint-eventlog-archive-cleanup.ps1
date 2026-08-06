<#
.SYNOPSIS
Safe Windows Event Log archive and cleanup utility (PowerShell 5.1).

.DESCRIPTION
- Dry run mode prints counts of records that would be deleted.
- Targets only logs whose records are older than a configurable cutoff.
- Uses per-operation try/catch handling.
- Logs all actions to a timestamped log file.
- Reports a summary at the end.
- Supports rollback using archived EVTX files and manifests.
- Idempotent behavior: if today's archive file exists for a log, archive is skipped.

.NOTES
Windows does not support selective deletion of only old records within a live channel.
To stay safe, this script clears a channel only when all records in that channel are older than the cutoff date.
Rollback restores archived EVTX files to a restore folder for review and retention.
#>

[CmdletBinding(DefaultParameterSetName = 'Cleanup')]
param(
    # SECTION 1: Cleanup parameters
    # These parameters control normal archive-and-clean execution.
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 3,

    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$LogNames = @('Application', 'System', 'Security'),

    # SECTION 2: Rollback parameter
    # Provide the run ID to restore archived files from that cleanup run.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RollbackRunId
)

# SECTION 3: Runtime paths and timestamps
# This section defines state locations for logs, archives, manifests, and restores.
$script:StateRoot = Join-Path $PSScriptRoot 'eventlog-cleanup-state'
$script:LogRoot = Join-Path $script:StateRoot 'logs'
$script:ArchiveRoot = Join-Path $script:StateRoot 'archives'
$script:ManifestRoot = Join-Path $script:StateRoot 'manifests'
$script:RestoreRoot = Join-Path $script:StateRoot 'restored'

$script:Now = Get-Date
$script:TodayTag = $script:Now.ToString('yyyyMMdd')
$script:RunId = if ($PSCmdlet.ParameterSetName -eq 'Cleanup') { $script:Now.ToString('yyyyMMdd-HHmmss') } else { $RollbackRunId }
$script:LogFile = Join-Path $script:LogRoot ((if ($PSCmdlet.ParameterSetName -eq 'Cleanup') { 'eventlog-cleanup' } else { 'eventlog-rollback' }) + "-$script:RunId.log")

# SECTION 4: Create state directories
# This section ensures all required folders exist before any operation starts.
foreach ($path in @($script:StateRoot, $script:LogRoot, $script:ArchiveRoot, $script:ManifestRoot, $script:RestoreRoot)) {
    try {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
    }
    catch {
        throw "Failed to initialize folder '$path': $($_.Exception.Message)"
    }
}

# SECTION 5: Logging helper
# This section writes timestamped messages to console and the log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message

    try {
        Write-Host $line
    }
    catch {
    }

    try {
        Add-Content -Path $script:LogFile -Value $line -ErrorAction Stop
    }
    catch {
        throw "Failed to write to log file '$script:LogFile': $($_.Exception.Message)"
    }
}

# SECTION 6: Safe per-log analysis helper
# This section reads metadata needed to decide whether a channel can be safely cleared.
function Get-LogAnalysis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [Parameter(Mandatory = $true)]
        [datetime]$CutoffDate
    )

    $analysis = [ordered]@{
        LogName            = $LogName
        Exists             = $false
        TotalCount         = 0
        OlderCount         = 0
        NewestRecordTime   = $null
        CanClearSafely     = $false
        Error              = $null
    }

    try {
        $null = Get-WinEvent -ListLog $LogName -ErrorAction Stop
        $analysis.Exists = $true
    }
    catch {
        $analysis.Error = "Log not accessible: $($_.Exception.Message)"
        return [pscustomobject]$analysis
    }

    try {
        $total = (Get-WinEvent -FilterHashtable @{ LogName = $LogName } -ErrorAction Stop | Measure-Object).Count
        $analysis.TotalCount = [int]$total
    }
    catch {
        $analysis.Error = "Unable to count records: $($_.Exception.Message)"
        return [pscustomobject]$analysis
    }

    if ($analysis.TotalCount -eq 0) {
        $analysis.CanClearSafely = $false
        return [pscustomobject]$analysis
    }

    try {
        $newest = Get-WinEvent -FilterHashtable @{ LogName = $LogName } -MaxEvents 1 -ErrorAction Stop
        $analysis.NewestRecordTime = $newest.TimeCreated
    }
    catch {
        $analysis.Error = "Unable to read newest record: $($_.Exception.Message)"
        return [pscustomobject]$analysis
    }

    try {
        $olderCount = (Get-WinEvent -FilterHashtable @{ LogName = $LogName; EndTime = $CutoffDate } -ErrorAction Stop | Measure-Object).Count
        $analysis.OlderCount = [int]$olderCount
    }
    catch {
        $analysis.Error = "Unable to count old records: $($_.Exception.Message)"
        return [pscustomobject]$analysis
    }

    if ($analysis.NewestRecordTime -le $CutoffDate -and $analysis.TotalCount -gt 0) {
        $analysis.CanClearSafely = $true
    }

    return [pscustomobject]$analysis
}

# SECTION 7: Cleanup workflow
# This section archives eligible channels and then clears them (unless dry run).
function Invoke-Cleanup {
    $summary = [ordered]@{
        Mode                         = if ($DryRun) { 'DryRun' } else { 'Cleanup' }
        RunId                        = $script:RunId
        CutoffDate                   = (Get-Date).AddDays(-$OlderThanDays)
        LogsRequested                = $LogNames.Count
        LogsAnalyzed                 = 0
        LogsEligibleForClear         = 0
        LogsSkippedNotAllOld         = 0
        LogsSkippedArchiveExists     = 0
        LogsCleared                  = 0
        TotalRecordsWouldDelete      = 0
        TotalRecordsCleared          = 0
        OperationErrors              = 0
    }

    $manifestEntries = New-Object System.Collections.Generic.List[object]

    Write-Log "Cleanup started. DryRun=$DryRun OlderThanDays=$OlderThanDays"

    foreach ($logName in $LogNames) {
        Write-Log "Analyzing log: $logName"

        $analysis = $null
        try {
            $analysis = Get-LogAnalysis -LogName $logName -CutoffDate $summary.CutoffDate
            $summary.LogsAnalyzed++
        }
        catch {
            $summary.OperationErrors++
            Write-Log "Unexpected analysis failure for '$logName': $($_.Exception.Message)" 'ERROR'
            continue
        }

        if ($analysis.Error) {
            $summary.OperationErrors++
            Write-Log "Skipping '$logName': $($analysis.Error)" 'WARN'
            continue
        }

        if (-not $analysis.CanClearSafely) {
            $summary.LogsSkippedNotAllOld++
            Write-Log "Skipping '$logName': not all records are older than cutoff. Newest=$($analysis.NewestRecordTime) Cutoff=$($summary.CutoffDate)"
            continue
        }

        $summary.LogsEligibleForClear++
        $summary.TotalRecordsWouldDelete += $analysis.TotalCount

        if ($DryRun) {
            Write-Host ("DRYRUN {0}: would delete {1} records" -f $logName, $analysis.TotalCount)
            Write-Log "DRYRUN '$logName': would delete $($analysis.TotalCount) records"
            continue
        }

        $safeLogName = ($logName -replace '[^a-zA-Z0-9._-]', '_')
        $archivePath = Join-Path $script:ArchiveRoot ("$safeLogName-$($script:TodayTag).evtx")
        $archivedToday = Test-Path -LiteralPath $archivePath

        if ($archivedToday) {
            $summary.LogsSkippedArchiveExists++
            Write-Log "Archive for today already exists, skipping archive: $archivePath" 'WARN'
        }
        else {
            try {
                & wevtutil.exe epl $logName $archivePath
                if ($LASTEXITCODE -ne 0) {
                    throw "wevtutil epl failed with exit code $LASTEXITCODE"
                }
                Write-Log "Archived '$logName' to $archivePath"
            }
            catch {
                $summary.OperationErrors++
                Write-Log "Archive failed for '$logName': $($_.Exception.Message)" 'ERROR'
                continue
            }
        }

        try {
            # Idempotent clear guard: if no records remain, skip clear cleanly.
            $postArchiveCount = (Get-WinEvent -FilterHashtable @{ LogName = $logName } -ErrorAction Stop | Measure-Object).Count
            if ($postArchiveCount -eq 0) {
                Write-Log "No records to clear after archive check for '$logName'."
                continue
            }
        }
        catch {
            $summary.OperationErrors++
            Write-Log "Unable to verify post-archive count for '$logName': $($_.Exception.Message)" 'ERROR'
            continue
        }

        try {
            & wevtutil.exe cl $logName
            if ($LASTEXITCODE -ne 0) {
                throw "wevtutil cl failed with exit code $LASTEXITCODE"
            }

            $summary.LogsCleared++
            $summary.TotalRecordsCleared += $analysis.TotalCount
            Write-Log "Cleared '$logName' records=$($analysis.TotalCount)"

            $manifestEntries.Add([pscustomobject]@{
                LogName         = $logName
                ArchivePath     = $archivePath
                ArchiveDateTag  = $script:TodayTag
                RecordsCleared  = $analysis.TotalCount
                ClearedAt       = (Get-Date)
            }) | Out-Null
        }
        catch {
            $summary.OperationErrors++
            Write-Log "Clear failed for '$logName': $($_.Exception.Message)" 'ERROR'
            continue
        }
    }

    if (-not $DryRun) {
        try {
            $manifest = [pscustomobject]@{
                RunId         = $script:RunId
                GeneratedAt   = Get-Date
                OlderThanDays = $OlderThanDays
                LogNames      = $LogNames
                Entries       = $manifestEntries
            }

            $manifestPath = Join-Path $script:ManifestRoot ("manifest-$($script:RunId).json")
            $manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8
            Write-Log "Manifest written: $manifestPath"
        }
        catch {
            $summary.OperationErrors++
            Write-Log "Failed to write manifest: $($_.Exception.Message)" 'ERROR'
        }
    }

    Write-Log "Cleanup completed."
    return [pscustomobject]$summary
}

# SECTION 8: Rollback workflow
# This section restores archived EVTX files from a selected run into a restore folder.
function Invoke-Rollback {
    $summary = [ordered]@{
        Mode                  = 'Rollback'
        RunId                 = $RollbackRunId
        EntriesInManifest     = 0
        ArchivesFound         = 0
        ArchivesRestored      = 0
        ArchivesAlreadyCopied = 0
        OperationErrors       = 0
    }

    $manifestPath = Join-Path $script:ManifestRoot ("manifest-$RollbackRunId.json")

    try {
        if (-not (Test-Path -LiteralPath $manifestPath)) {
            throw "Manifest not found: $manifestPath"
        }
    }
    catch {
        throw "Rollback cannot start: $($_.Exception.Message)"
    }

    Write-Log "Rollback started for RunId=$RollbackRunId"

    $manifest = $null
    try {
        $manifest = Get-Content -Path $manifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Failed to read rollback manifest '$manifestPath': $($_.Exception.Message)"
    }

    foreach ($entry in $manifest.Entries) {
        $summary.EntriesInManifest++

        $archivePath = $entry.ArchivePath
        $logName = $entry.LogName
        $safeLogName = ($logName -replace '[^a-zA-Z0-9._-]', '_')
        $restoreDir = Join-Path $script:RestoreRoot $RollbackRunId
        $restorePath = Join-Path $restoreDir ("$safeLogName-restored.evtx")

        try {
            if (-not (Test-Path -LiteralPath $archivePath)) {
                Write-Log "Archive missing for '$logName': $archivePath" 'WARN'
                continue
            }
            $summary.ArchivesFound++
        }
        catch {
            $summary.OperationErrors++
            Write-Log "Error checking archive for '$logName': $($_.Exception.Message)" 'ERROR'
            continue
        }

        try {
            if (-not (Test-Path -LiteralPath $restoreDir)) {
                New-Item -Path $restoreDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            $summary.OperationErrors++
            Write-Log "Failed creating restore folder '$restoreDir': $($_.Exception.Message)" 'ERROR'
            continue
        }

        try {
            if (Test-Path -LiteralPath $restorePath) {
                $summary.ArchivesAlreadyCopied++
                Write-Log "Restore file already exists, skipping copy: $restorePath" 'WARN'
                continue
            }

            Copy-Item -LiteralPath $archivePath -Destination $restorePath -ErrorAction Stop
            $summary.ArchivesRestored++
            Write-Log "Restored archive copy for '$logName' to $restorePath"
        }
        catch {
            $summary.OperationErrors++
            Write-Log "Failed restoring '$logName': $($_.Exception.Message)" 'ERROR'
            continue
        }
    }

    Write-Log "Rollback completed."
    return [pscustomobject]$summary
}

# SECTION 9: Main execution and final summary
# This section runs the selected mode and prints a concise summary.
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
    try {
        Write-Log "Fatal error: $($_.Exception.Message)" 'ERROR'
    }
    catch {
    }
    throw
}
