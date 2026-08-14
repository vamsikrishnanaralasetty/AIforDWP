# Floor 6 Evidence Collection Script Review

## Version Header
- Title: Floor 6 Evidence Collection Script Review
- Version: 1.0
- Date: 14/08/2026
- Author: Vamsi
- Status: Draft

## Scope
This document reviews an AI-generated evidence-collection script for a Floor 6 Windows 11 device and provides a hand-corrected engineer version. The script gathers evidence only and does not perform remediation.

Assumed leading hypothesis for this exercise:

> A recently deployed document management application is causing excessive resource utilization and login performance degradation.

---

## SECTION 1 - Investigation Goal

The goal is to collect enough endpoint evidence from a Floor 6 Windows 11 device to determine whether the recently deployed document management application is a credible contributor to slow or failed login experiences.

### What evidence needs to be collected
- Installed application presence, version, publisher, and install date/time
- Running processes related to the application
- Point-in-time CPU, memory, disk, and disk queue metrics
- Recent Application and System event log entries relevant to crashes, hangs, service failures, and resource pressure
- Recent application crash evidence from Windows Error Reporting if available
- Device hardware information such as model, CPU, disk, and RAM
- Available and total memory
- Startup application entries and recently installed software context

### Why this evidence is required
- Application install details establish whether the suspected software is present and when it was introduced.
- Process and performance metrics show whether the application is active and consuming significant resources.
- Event logs and crash data indicate whether the software or related services are failing, hanging, or causing side effects.
- Hardware and memory context help determine whether resource pressure is application-driven or amplified by device constraints.
- Startup data helps determine whether the application launches automatically and could affect login time.

### What questions the script is trying to answer
- Is the document management application installed on the device being investigated?
- Which version is installed, and when was it installed?
- Is the application or one of its components running during the investigation?
- Is the device under unusual CPU, memory, or disk pressure?
- Are there recent application or system events consistent with login degradation, hangs, or crashes?
- Does startup behavior suggest the application contributes to sign-in or desktop-load delay?
- Is the device under-resourced in a way that would worsen any application overhead?

### Why evidence collection is preferred before remediation
Evidence collection comes first because remediation changes the system state and can destroy the data needed to assess whether the application is actually contributing to the incident. In an enterprise investigation, the fastest useful path is to preserve observable facts, build an auditable record, and then decide whether the leading hypothesis is supported, weakened, or displaced by other evidence.

---

## SECTION 2 - Initial AI Generated Script

### AI Generated Version

```powershell
param(
    [string]$AppName = "Document Management",
    [string]$OutputFolder = "C:\Temp\Floor6Evidence",
    [switch]$DryRun
)

# Create output folder
if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonPath = Join-Path $OutputFolder "Evidence_$timestamp.json"
$txtPath = Join-Path $OutputFolder "Evidence_$timestamp.txt"

# Main result object
$result = [ordered]@{}
$result.Timestamp = Get-Date
$result.ComputerName = $env:COMPUTERNAME
$result.AppName = $AppName
$result.DryRun = [bool]$DryRun

# Installed applications
$result.InstalledApps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { $_.DisplayName -like "*$AppName*" } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

# Running processes
$result.Processes = Get-Process | Where-Object { $_.ProcessName -like "*$AppName*" } |
    Select-Object ProcessName, Id, CPU, WorkingSet, StartTime

# CPU and memory
$result.CpuSample = Get-Counter "\Processor(_Total)\% Processor Time"
$result.MemorySample = Get-Counter "\Memory\Available MBytes"

# Disk metrics
$result.DiskSample = Get-Counter "\PhysicalDisk(_Total)\% Disk Time"
$result.DiskQueue = Get-Counter "\PhysicalDisk(_Total)\Avg. Disk Queue Length"

# Event logs
$result.ApplicationEvents = Get-EventLog -LogName Application -Newest 50 |
    Where-Object { $_.Message -like "*$AppName*" -or $_.EntryType -eq "Error" } |
    Select-Object TimeGenerated, Source, EntryType, EventID, Message

$result.SystemEvents = Get-EventLog -LogName System -Newest 50 |
    Where-Object { $_.EntryType -eq "Error" -or $_.EntryType -eq "Warning" } |
    Select-Object TimeGenerated, Source, EntryType, EventID, Message

# Crash records
$result.Crashes = Get-WinEvent -LogName Application | Where-Object {
    $_.ProviderName -like "*Application Error*" -or $_.Message -like "*$AppName*"
} | Select-Object -First 20 TimeCreated, Id, ProviderName, Message

# Hardware
$result.ComputerSystem = Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory
$result.Processor = Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
$result.LogicalDisk = Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, Size, FreeSpace

# Startup items
$result.StartupApps = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User

if ($DryRun) {
    $result.Note = "Dry run only. No files should be written."
    $result | ConvertTo-Json -Depth 5
    return
}

# Save output
$result | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8
$result | Out-File -FilePath $txtPath

Write-Host "Evidence saved to $jsonPath and $txtPath"
```

This version is intentionally presented as a plausible AI-generated script without correction in this section.

---

## SECTION 3 - Engineer Review

The AI-generated version is directionally useful, but it is not ready for reliable enterprise investigation use without review.

### Risks
- It assumes the application can be found by matching the friendly app name directly against process names.
- It uses registry uninstall data from only one standard uninstall path and may miss 32-bit installs or user-scope installs.
- It may fail or hang on large event log queries because filtering is performed late and broadly.
- It does not preserve enough execution context about what succeeded, failed, or was skipped.

Why that matters:
- Investigators may incorrectly conclude the app is absent or not running.
- Missing app records can create false negatives.
- Slow or failing log queries reduce usefulness during an active incident.
- Lack of collection status makes the output harder for another engineer to trust.

### Weaknesses
- Dry-run behavior is incomplete: collection still occurs and only file writing is skipped.
- There is no device/user/context metadata beyond computer name.
- Performance data is a single point-in-time sample with no retry or sampling window.
- Event log collection is not constrained to a recent time window.
- Startup data is collected but not normalized or tied to the target application.

Why that matters:
- Dry-run should show intended actions clearly.
- Incident evidence needs execution context and consistent structure.
- A single sample may miss intermittent spikes.
- Broad logs increase noise and runtime.
- Output should help an engineer answer the specific hypothesis, not just dump data.

### Missing validation
- No validation of output path writability.
- No validation that required cmdlets/counters are available.
- No validation that application name input is usable.
- No validation of administrative privilege requirements or degraded-mode behavior if admin access is unavailable.

Why that matters:
- Enterprise devices differ in controls and available providers.
- Scripts need predictable behavior when running under limited rights.
- Failed collections should be explicit, not silent.

### Missing error handling
- No try/catch blocks around registry, CIM, event log, or performance counter access.
- Access to process StartTime can throw for protected processes.
- Event log queries can fail on restricted systems.
- JSON serialization depth may truncate nested data without warning.

Why that matters:
- A single failing query can stop the script or silently degrade the results.
- In incident handling, partial success is still useful if clearly logged.

### Areas where output could be improved
- Output should include a collection manifest showing each step, status, error, and record count.
- Output should store both human-readable summary and structured JSON.
- Output should normalize byte values into GB/MB where appropriate.
- Output should include explicit timestamps and investigation parameters.

Why that matters:
- Another engineer should be able to continue analysis without rerunning the script.
- Structured output is needed for comparison across multiple devices.

### Areas where the script may fail in enterprise environments
- Some performance counters may be unavailable or disabled.
- Event logs can be restricted or large enough to cause delay.
- Startup entries may include null or inaccessible fields.
- Registry-based install detection may be incomplete on Intune-managed or MSIX-based deployments.
- The application may run under helper or service process names that do not match the friendly app name.

Why that matters:
- Enterprise scripts must tolerate inconsistent endpoint conditions and still produce defensible evidence.

---

## SECTION 4 - Hand Corrected Version

### Hand Corrected Version

```powershell
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AppName = "Document Management",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFolder = "C:\Temp\Floor6Evidence",

    [Parameter()]
    [ValidateRange(1, 60)]
    [int]$SampleSeconds = 5,

    [Parameter()]
    [ValidateRange(1, 20)]
    [int]$SampleCount = 3,

    [switch]$DryRun
)

$script:CollectionLog = New-Object System.Collections.Generic.List[object]

function Add-CollectionLog {
    param(
        [string]$Step,
        [string]$Status,
        [string]$Detail
    )

    $script:CollectionLog.Add([pscustomobject]@{
        Timestamp = Get-Date
        Step      = $Step
        Status    = $Status
        Detail    = $Detail
    }) | Out-Null
}

function Invoke-Safely {
    param(
        [string]$Step,
        [scriptblock]$ScriptBlock,
        $DefaultValue = $null
    )

    try {
        $value = & $ScriptBlock
        Add-CollectionLog -Step $Step -Status "Success" -Detail "Collection completed."
        return $value
    }
    catch {
        Add-CollectionLog -Step $Step -Status "Failed" -Detail $_.Exception.Message
        return $DefaultValue
    }
}

function Convert-BytesToGB {
    param([Nullable[double]]$Bytes)

    if ($null -eq $Bytes) {
        return $null
    }

    return [math]::Round($Bytes / 1GB, 2)
}

function Get-UninstallEntries {
    param([string]$MatchName)

    $paths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $results = foreach ($path in $paths) {
        if (Test-Path $path) {
            Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -and $_.DisplayName -like "*$MatchName*" } |
                Select-Object @{Name='RegistryPath';Expression={$path}}, DisplayName, DisplayVersion, Publisher, InstallDate
        }
    }

    $results | Sort-Object DisplayName, DisplayVersion -Unique
}

function Get-RelatedProcesses {
    param([string]$MatchName)

    $allProcesses = Get-CimInstance Win32_Process -ErrorAction Stop
    $allProcesses |
        Where-Object {
            $_.Name -like "*$MatchName*" -or
            $_.ExecutablePath -like "*$MatchName*" -or
            $_.CommandLine -like "*$MatchName*"
        } |
        Select-Object ProcessId, Name, ExecutablePath, CommandLine, KernelModeTime, UserModeTime, WorkingSetSize
}

function Get-CounterSamples {
    param(
        [string[]]$CounterPaths,
        [int]$IntervalSeconds,
        [int]$MaxSamples
    )

    $counterResult = Get-Counter -Counter $CounterPaths -SampleInterval $IntervalSeconds -MaxSamples $MaxSamples -ErrorAction Stop
    $counterResult.CounterSamples |
        Select-Object Path, InstanceName, CookedValue, Timestamp
}

function Get-RecentEventData {
    param(
        [string]$LogName,
        [datetime]$StartTime,
        [string]$MatchName,
        [int]$MaxEvents = 100
    )

    Get-WinEvent -FilterHashtable @{ LogName = $LogName; StartTime = $StartTime } -ErrorAction Stop |
        Where-Object {
            $_.ProviderName -like "*$MatchName*" -or
            $_.Message -like "*$MatchName*" -or
            $_.LevelDisplayName -in @('Error', 'Warning')
        } |
        Select-Object -First $MaxEvents TimeCreated, Id, ProviderName, LevelDisplayName, Message
}

$runTimestamp = Get-Date
$windowStart = $runTimestamp.AddDays(-3)
$outputTimestamp = $runTimestamp.ToString("yyyyMMdd_HHmmss")
$jsonPath = Join-Path $OutputFolder "Evidence_$outputTimestamp.json"
$summaryPath = Join-Path $OutputFolder "Evidence_$outputTimestamp.summary.txt"

$plan = [pscustomobject]@{
    AppName      = $AppName
    OutputFolder = $OutputFolder
    SampleSeconds = $SampleSeconds
    SampleCount  = $SampleCount
    WindowStart  = $windowStart
    Mode         = if ($DryRun) { "DryRun" } else { "Collect" }
}

if ($DryRun) {
    $plan | ConvertTo-Json -Depth 4
    return
}

if (-not (Test-Path -LiteralPath $OutputFolder)) {
    try {
        New-Item -ItemType Directory -Path $OutputFolder -Force -ErrorAction Stop | Out-Null
        Add-CollectionLog -Step "CreateOutputFolder" -Status "Success" -Detail "Output folder created or already present."
    }
    catch {
        throw "Unable to create output folder '$OutputFolder'. $($_.Exception.Message)"
    }
}
else {
    Add-CollectionLog -Step "CreateOutputFolder" -Status "Success" -Detail "Output folder already exists."
}

$deviceInfo = Invoke-Safely -Step "DeviceInfo" -DefaultValue $null -ScriptBlock {
    $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $processor = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

    [pscustomobject]@{
        ComputerName         = $env:COMPUTERNAME
        LoggedOnUser         = $env:USERNAME
        Manufacturer         = $computerSystem.Manufacturer
        Model                = $computerSystem.Model
        TotalPhysicalMemoryGB = Convert-BytesToGB -Bytes $computerSystem.TotalPhysicalMemory
        AvailableMemoryMB    = [math]::Round($os.FreePhysicalMemory / 1024, 2)
        OSName               = $os.Caption
        OSVersion            = $os.Version
        LastBootUpTime       = $os.LastBootUpTime
        ProcessorName        = $processor.Name
        LogicalProcessors    = $processor.NumberOfLogicalProcessors
        BIOSSerial           = $bios.SerialNumber
    }
}

$installedApplications = Invoke-Safely -Step "InstalledApplications" -DefaultValue @() -ScriptBlock {
    Get-UninstallEntries -MatchName $AppName
}

$relatedProcesses = Invoke-Safely -Step "RelatedProcesses" -DefaultValue @() -ScriptBlock {
    Get-RelatedProcesses -MatchName $AppName
}

$performanceCounters = Invoke-Safely -Step "PerformanceCounters" -DefaultValue @() -ScriptBlock {
    Get-CounterSamples -CounterPaths @(
        "\Processor(_Total)\% Processor Time",
        "\Memory\Available MBytes",
        "\PhysicalDisk(_Total)\% Disk Time",
        "\PhysicalDisk(_Total)\Avg. Disk Queue Length"
    ) -IntervalSeconds $SampleSeconds -MaxSamples $SampleCount
}

$applicationEvents = Invoke-Safely -Step "ApplicationEvents" -DefaultValue @() -ScriptBlock {
    Get-RecentEventData -LogName "Application" -StartTime $windowStart -MatchName $AppName -MaxEvents 75
}

$systemEvents = Invoke-Safely -Step "SystemEvents" -DefaultValue @() -ScriptBlock {
    Get-RecentEventData -LogName "System" -StartTime $windowStart -MatchName $AppName -MaxEvents 75
}

$crashEvents = Invoke-Safely -Step "CrashEvents" -DefaultValue @() -ScriptBlock {
    Get-WinEvent -FilterHashtable @{ LogName = 'Application'; StartTime = $windowStart; ProviderName = 'Application Error' } -ErrorAction Stop |
        Where-Object { $_.Message -like "*$AppName*" } |
        Select-Object -First 25 TimeCreated, Id, ProviderName, LevelDisplayName, Message
}

$logicalDisks = Invoke-Safely -Step "LogicalDisks" -DefaultValue @() -ScriptBlock {
    Get-CimInstance Win32_LogicalDisk -ErrorAction Stop |
        Select-Object DeviceID,
            @{Name='SizeGB';Expression={ Convert-BytesToGB -Bytes $_.Size }},
            @{Name='FreeSpaceGB';Expression={ Convert-BytesToGB -Bytes $_.FreeSpace }},
            DriveType
}

$startupApplications = Invoke-Safely -Step "StartupApplications" -DefaultValue @() -ScriptBlock {
    Get-CimInstance Win32_StartupCommand -ErrorAction Stop |
        Select-Object Name, Command, Location, User |
        Sort-Object Name
}

$summary = [pscustomobject]@{
    Timestamp            = $runTimestamp
    ComputerName         = $env:COMPUTERNAME
    Hypothesis           = "Recently deployed document management application may be contributing to excessive resource utilization and login degradation."
    Parameters           = $plan
    DeviceInfo           = $deviceInfo
    InstalledApplications = $installedApplications
    RelatedProcesses     = $relatedProcesses
    PerformanceCounters  = $performanceCounters
    ApplicationEvents    = $applicationEvents
    SystemEvents         = $systemEvents
    CrashEvents          = $crashEvents
    LogicalDisks         = $logicalDisks
    StartupApplications  = $startupApplications
    CollectionLog        = $script:CollectionLog
}

try {
    $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
    Add-CollectionLog -Step "WriteJson" -Status "Success" -Detail "Structured JSON written."
}
catch {
    Add-CollectionLog -Step "WriteJson" -Status "Failed" -Detail $_.Exception.Message
    throw
}

try {
    @(
        "Floor 6 Evidence Collection Summary",
        "Timestamp: $runTimestamp",
        "ComputerName: $($env:COMPUTERNAME)",
        "AppName: $AppName",
        "InstalledApplicationMatches: $(@($installedApplications).Count)",
        "RelatedProcessMatches: $(@($relatedProcesses).Count)",
        "ApplicationEvents: $(@($applicationEvents).Count)",
        "SystemEvents: $(@($systemEvents).Count)",
        "CrashEvents: $(@($crashEvents).Count)",
        "CollectionLog:",
        ($script:CollectionLog | ForEach-Object { "[$($_.Status)] $($_.Step): $($_.Detail)" })
    ) | Set-Content -LiteralPath $summaryPath -Encoding UTF8
    Add-CollectionLog -Step "WriteSummary" -Status "Success" -Detail "Text summary written."
}
catch {
    Add-CollectionLog -Step "WriteSummary" -Status "Failed" -Detail $_.Exception.Message
    throw
}

Write-Output ([pscustomobject]@{
    Result       = "Success"
    JsonPath     = $jsonPath
    SummaryPath  = $summaryPath
    Records      = [pscustomobject]@{
        InstalledApplications = @($installedApplications).Count
        RelatedProcesses      = @($relatedProcesses).Count
        PerformanceSamples    = @($performanceCounters).Count
        ApplicationEvents     = @($applicationEvents).Count
        SystemEvents          = @($systemEvents).Count
        CrashEvents           = @($crashEvents).Count
        StartupApplications   = @($startupApplications).Count
    }
})
```

This corrected version preserves the AI version's purpose and structure, but improves reliability, validation, logging, and evidence quality.

---

## SECTION 5 - Correction Summary

| Change Made | Why the AI Version Was Insufficient | Why the Correction Was Necessary |
| --- | --- | --- |
| Added parameter validation | Inputs could be empty or unrealistic | Prevents bad execution state before collection starts |
| Changed dry-run behavior to output plan only | AI version still performed collection during dry-run | Dry-run should be safe and predictable in enterprise use |
| Added collection log | AI version did not show step-by-step success/failure | Investigators need to know what data was collected and what failed |
| Added safe wrapper with try/catch | AI version could fail mid-run without structured error capture | Partial evidence is still useful if failures are logged clearly |
| Expanded uninstall detection paths | AI version searched only one registry uninstall path | Enterprise devices may have 32-bit or user-scope installs |
| Improved process discovery | AI version matched friendly app name against process name only | Real app components may appear in path or command line instead |
| Added sampling window for performance counters | AI version used single samples | Short series sampling is more useful for transient performance issues |
| Limited event logs to recent time window | AI version used broad recent event lists with noisy filtering | Reduces noise and runtime while keeping incident-relevant evidence |
| Added hardware and OS context | AI version lacked enough system baseline context | Resource symptoms must be interpreted against device capability |
| Normalized output and summary files | AI version wrote raw output with limited troubleshooting value | Another engineer needs actionable structured evidence without rerun |
| Improved disk and memory readability | AI version returned raw byte-heavy data | Human review is faster with normalized units |
| Preserved evidence-only approach | AI version was evidence-focused but operationally weak | Correction keeps scope safe while making output trustworthy |

---

## SECTION 6 - Reflection

My first assumption was that the recently deployed document management application was the most likely explanation for the login slowdown because the timing matched the Friday rollout and the symptom pattern could be consistent with resource-heavy startup behavior.

Before accepting that assumption, I would need evidence showing that the application is actually installed on affected devices, that it is active during the relevant phase, and that measurable CPU, memory, disk, crash, or startup evidence aligns with the user experience.

The script helps validate or challenge that assumption by gathering direct evidence about install state, active processes, performance metrics, startup configuration, and recent operating system and application events without changing the device state.

Engineer review of AI-generated code is important because a plausible script can still miss enterprise validation, fail silently, collect misleading data, or behave unsafely under real endpoint conditions; responsible engineering requires that generated code be reviewed, corrected, and made operationally defensible before use.

This reflection satisfies the capstone requirement by showing the initial assumption, the evidence threshold needed before accepting it, the role of structured evidence collection, and the importance of engineer oversight.

---

## SECTION 7 - Expected Output

Sample structured output from the corrected script:

```json
{
  "Timestamp": "2026-08-14T09:42:15.3349211+01:00",
  "ComputerName": "FLOOR6-LT-014",
  "Hypothesis": "Recently deployed document management application may be contributing to excessive resource utilization and login degradation.",
  "Parameters": {
    "AppName": "Document Management",
    "OutputFolder": "C:\\Temp\\Floor6Evidence",
    "SampleSeconds": 5,
    "SampleCount": 3,
    "WindowStart": "2026-08-11T09:42:15.3349211+01:00",
    "Mode": "Collect"
  },
  "DeviceInfo": {
    "ComputerName": "FLOOR6-LT-014",
    "LoggedOnUser": "jsmith",
    "Manufacturer": "Dell Inc.",
    "Model": "Latitude 7440",
    "TotalPhysicalMemoryGB": 16.0,
    "AvailableMemoryMB": 4210.43,
    "OSName": "Microsoft Windows 11 Enterprise",
    "OSVersion": "10.0.22631",
    "LastBootUpTime": "2026-08-14T08:11:54",
    "ProcessorName": "12th Gen Intel(R) Core(TM) i7-1265U",
    "LogicalProcessors": 12,
    "BIOSSerial": "ABC1234"
  },
  "InstalledApplications": [
    {
      "RegistryPath": "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*",
      "DisplayName": "Document Management Client",
      "DisplayVersion": "5.4.2",
      "Publisher": "Contoso Legal Systems",
      "InstallDate": "20260809"
    }
  ],
  "RelatedProcesses": [
    {
      "ProcessId": 4420,
      "Name": "DocMgmtAgent.exe",
      "ExecutablePath": "C:\\Program Files\\Contoso\\Document Management\\DocMgmtAgent.exe",
      "CommandLine": "\"C:\\Program Files\\Contoso\\Document Management\\DocMgmtAgent.exe\" --startup",
      "KernelModeTime": 3125000,
      "UserModeTime": 5468750,
      "WorkingSetSize": 248676352
    }
  ],
  "PerformanceCounters": [
    {
      "Path": "\\floor6-lt-014\\processor(_total)\\% processor time",
      "InstanceName": "_Total",
      "CookedValue": 78.24,
      "Timestamp": "2026-08-14T09:42:20"
    },
    {
      "Path": "\\floor6-lt-014\\physicaldisk(_total)\\avg. disk queue length",
      "InstanceName": "_Total",
      "CookedValue": 4.18,
      "Timestamp": "2026-08-14T09:42:20"
    }
  ],
  "ApplicationEvents": [
    {
      "TimeCreated": "2026-08-14T08:17:55",
      "Id": 1000,
      "ProviderName": "Application Error",
      "LevelDisplayName": "Error",
      "Message": "Faulting application name: DocMgmtAgent.exe"
    }
  ],
  "SystemEvents": [
    {
      "TimeCreated": "2026-08-14T08:14:09",
      "Id": 7000,
      "ProviderName": "Service Control Manager",
      "LevelDisplayName": "Error",
      "Message": "The Document Management Agent service failed to start in a timely fashion."
    }
  ],
  "CrashEvents": [
    {
      "TimeCreated": "2026-08-14T08:17:55",
      "Id": 1000,
      "ProviderName": "Application Error",
      "LevelDisplayName": "Error",
      "Message": "Faulting application name: DocMgmtAgent.exe"
    }
  ],
  "LogicalDisks": [
    {
      "DeviceID": "C:",
      "SizeGB": 476.11,
      "FreeSpaceGB": 41.82,
      "DriveType": 3
    }
  ],
  "StartupApplications": [
    {
      "Name": "Document Management Agent",
      "Command": "C:\\Program Files\\Contoso\\Document Management\\DocMgmtAgent.exe --startup",
      "Location": "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
      "User": "All Users"
    }
  ],
  "CollectionLog": [
    {
      "Timestamp": "2026-08-14T09:42:15",
      "Step": "InstalledApplications",
      "Status": "Success",
      "Detail": "Collection completed."
    },
    {
      "Timestamp": "2026-08-14T09:42:31",
      "Step": "WriteJson",
      "Status": "Success",
      "Detail": "Structured JSON written."
    }
  ]
}
```

Why this output is actionable:
- It identifies whether the suspected application is installed and which version is present.
- It shows whether related processes are active and whether resource pressure exists.
- It preserves recent relevant operating system and application evidence.
- It includes collection status so another engineer can trust what was and was not gathered.
- It is structured enough for comparison across multiple devices without rerunning collection.

---

End of Document
