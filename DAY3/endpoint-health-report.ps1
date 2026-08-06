<#
.SYNOPSIS
Read-only endpoint health report for DWP engineers (PowerShell 5.1).

.DESCRIPTION
Collects and displays:
1) System uptime
2) Free disk space
3) Pending reboot state (registry checks)
4) Top 5 processes by memory (Working Set)
5) Top 5 processes by CPU
6) Last 5 system log errors

This script is strictly read-only. It does not modify system state.
#>

# SECTION 0: Safety banner
# This section states the script's intent and confirms that all operations are read-only.
Write-Host "=== Endpoint Health Report (Read-Only) ===" -ForegroundColor Cyan
Write-Host ("Generated: {0}" -f (Get-Date))
Write-Host "No changes are made to system state by this script."
Write-Host ""

# SECTION 1: System uptime
# This section calculates uptime using Win32_OperatingSystem.LastBootUpTime.
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot

    Write-Host "--- 1) System Uptime ---" -ForegroundColor Yellow
    Write-Host ("Last boot time : {0}" -f $lastBoot)
    Write-Host ("Uptime         : {0} days {1} hours {2} minutes" -f [int]$uptime.TotalDays, $uptime.Hours, $uptime.Minutes)
    Write-Host ""
}
catch {
    Write-Warning "Unable to retrieve system uptime: $($_.Exception.Message)"
    Write-Host ""
}

# SECTION 2: Free disk space
# This section lists local fixed disks and reports free and total space in GB.
try {
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object DeviceID,
                      @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
                      @{Name='TotalGB';Expression={[math]::Round($_.Size / 1GB, 2)}},
                      @{Name='FreePercent';Expression={
                          if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { 0 }
                      }}

    Write-Host "--- 2) Free Disk Space ---" -ForegroundColor Yellow
    if ($disks) {
        $disks | Format-Table -AutoSize
    }
    else {
        Write-Host "No fixed disks found."
    }
    Write-Host ""
}
catch {
    Write-Warning "Unable to retrieve disk space data: $($_.Exception.Message)"
    Write-Host ""
}

# SECTION 3: Pending reboot check (registry)
# This section checks common read-only registry indicators that suggest a reboot is pending.
# VERIFY BEFORE RUNNING: Confirm these registry paths are valid in your environment and policy baseline.
try {
    # VERIFY BEFORE RUNNING: Path used to detect CBS reboot pending state (may not exist on all editions).
    $cbsRebootPendingPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'

    # VERIFY BEFORE RUNNING: Path used to detect Windows Update reboot required state.
    $wuRebootRequiredPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'

    # VERIFY BEFORE RUNNING: Registry value used to detect pending file rename operations.
    $sessionManagerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $sessionManagerValue = 'PendingFileRenameOperations'

    # VERIFY BEFORE RUNNING: Some environments use this non-zero value as an additional pending reboot hint.
    $updateExeVolatilePath = 'HKLM:\SOFTWARE\Microsoft\Updates'
    $updateExeVolatileValue = 'UpdateExeVolatile'

    $pendingRebootSignals = [ordered]@{
        CBSRebootPending              = Test-Path -Path $cbsRebootPendingPath
        WindowsUpdateRebootRequired   = Test-Path -Path $wuRebootRequiredPath
        PendingFileRenameOperations   = $false
        UpdateExeVolatileNonZero      = $false
    }

    $pendingRename = Get-ItemProperty -Path $sessionManagerPath -Name $sessionManagerValue -ErrorAction SilentlyContinue
    if ($null -ne $pendingRename.$sessionManagerValue) {
        $pendingRebootSignals.PendingFileRenameOperations = $true
    }

    $updateExeVolatile = Get-ItemProperty -Path $updateExeVolatilePath -Name $updateExeVolatileValue -ErrorAction SilentlyContinue
    if ($null -ne $updateExeVolatile.$updateExeVolatileValue -and $updateExeVolatile.$updateExeVolatileValue -ne 0) {
        $pendingRebootSignals.UpdateExeVolatileNonZero = $true
    }

    $isRebootPending = $pendingRebootSignals.Values -contains $true

    Write-Host "--- 3) Pending Reboot State ---" -ForegroundColor Yellow
    Write-Host ("Reboot pending: {0}" -f $(if ($isRebootPending) { 'YES' } else { 'NO' }))
    $pendingRebootSignals.GetEnumerator() | ForEach-Object {
        Write-Host ("- {0}: {1}" -f $_.Key, $_.Value)
    }
    Write-Host ""
}
catch {
    Write-Warning "Unable to determine pending reboot status: $($_.Exception.Message)"
    Write-Host ""
}

# SECTION 4: Top 5 processes by memory (Working Set)
# This section lists the five processes using the most physical memory right now,
# including their executable names with full paths where access is available.
try {
    $processPathLookup = @{}
    Get-CimInstance -ClassName Win32_Process -ErrorAction SilentlyContinue | ForEach-Object {
        $processPathLookup[$_.ProcessId] = $_.ExecutablePath
    }

    $topMemoryProcesses = Get-Process |
        Sort-Object -Property WS -Descending |
        Select-Object -First 5 Name, Id,
                      @{Name='WorkingSetMB';Expression={[math]::Round($_.WS / 1MB, 2)}},
                      CPU,
                      @{Name='ExecutablePath';Expression={
                          if ($processPathLookup.ContainsKey($_.Id) -and $processPathLookup[$_.Id]) {
                              $processPathLookup[$_.Id]
                          }
                          else {
                              'Unavailable (permission-limited or process exited)'
                          }
                      }}

    Write-Host "--- 4) Top 5 Processes by Memory (Working Set) ---" -ForegroundColor Yellow
    $topMemoryProcesses | Format-Table -AutoSize
    Write-Host ""
}
catch {
    Write-Warning "Unable to retrieve top memory processes: $($_.Exception.Message)"
    Write-Host ""
}

# SECTION 5: Top 5 processes by CPU
# This section lists the five processes with the highest cumulative CPU time,
# including their executable names with full paths where access is available.
try {
    $processPathLookup = @{}
    Get-CimInstance -ClassName Win32_Process -ErrorAction SilentlyContinue | ForEach-Object {
        $processPathLookup[$_.ProcessId] = $_.ExecutablePath
    }

    $topCpuProcesses = Get-Process |
        Where-Object { $null -ne $_.CPU } |
        Sort-Object -Property CPU -Descending |
        Select-Object -First 5 Name, Id,
                      @{Name='CPUSeconds';Expression={[math]::Round($_.CPU, 2)}},
                      @{Name='WorkingSetMB';Expression={[math]::Round($_.WS / 1MB, 2)}},
                      @{Name='ExecutablePath';Expression={
                          if ($processPathLookup.ContainsKey($_.Id) -and $processPathLookup[$_.Id]) {
                              $processPathLookup[$_.Id]
                          }
                          else {
                              'Unavailable (permission-limited or process exited)'
                          }
                      }}

    Write-Host "--- 5) Top 5 Processes by CPU ---" -ForegroundColor Yellow
    $topCpuProcesses | Format-Table -AutoSize
    Write-Host ""
}
catch {
    Write-Warning "Unable to retrieve top CPU processes: $($_.Exception.Message)"
    Write-Host ""
}

# SECTION 6: Last 5 system log errors
# This section reads the most recent five Error events from the System log.
# VERIFY BEFORE RUNNING: Confirm 'System' log naming/access policy in your environment.
try {
    # VERIFY BEFORE RUNNING: This query can require elevated rights in hardened environments.
    $lastSystemErrors = Get-EventLog -LogName System -EntryType Error -Newest 5 -ErrorAction Stop |
        Select-Object TimeGenerated, Source, EventID, Message

    Write-Host "--- 6) Last 5 System Log Errors ---" -ForegroundColor Yellow
    if ($lastSystemErrors) {
        $lastSystemErrors | Format-Table -Wrap -AutoSize
    }
    else {
        Write-Host "No recent system errors found."
    }
    Write-Host ""
}
catch {
    Write-Warning "Unable to retrieve system log errors: $($_.Exception.Message)"
    Write-Host ""
}

# SECTION 7: Completion
# This section marks report completion and reiterates read-only behavior.
Write-Host "Health report complete. Read-only checks finished." -ForegroundColor Green
