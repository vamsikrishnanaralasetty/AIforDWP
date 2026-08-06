# Endpoint Temp Cleanup Script (PowerShell 5.1)

This document explains how to use the cleanup script:
- Script: `endpoint-temp-cleanup.ps1`
- Location: `DAY3`

## What the script does

- Cleans temp files from safe default locations:
  - `%TEMP%`
  - `%WINDIR%\Temp`
- Targets only files older than a configurable number of days.
- Skips locked files and logs them.
- Uses per-file `try/catch` so one bad file does not stop the run.
- Logs every action to a timestamped log file.
- Writes a summary at the end.
- Supports rollback using run manifests.
- Designed to be idempotent:
  - Cleanup: moved files are no longer eligible on repeated runs.
  - Rollback: already-restored files are skipped safely.

## Parameters

### Cleanup mode (default)

- `-DryRun`
  - Prints the list of files that would be deleted (moved to quarantine in real run).
  - Makes no file changes.

- `-OlderThanDays <int>`
  - Deletes only files with `LastWriteTime` older than now minus this value.
  - Default: `0`

- `-TargetPaths <string[]>`
  - Optional override for target folders.
  - Default: `%TEMP%`, `%WINDIR%\Temp`

### Rollback mode

- `-RollbackRunId <string>`
  - Restores files from a previous cleanup run ID.
  - Run ID format used by cleanup: `yyyyMMdd-HHmmss`

## Examples

### 1) Dry run using defaults

```powershell
.\endpoint-temp-cleanup.ps1 -DryRun
```

### 2) Cleanup files older than 7 days

```powershell
.\endpoint-temp-cleanup.ps1 -OlderThanDays 7
```

### 3) Dry run with custom targets

```powershell
.\endpoint-temp-cleanup.ps1 -DryRun -OlderThanDays 3 -TargetPaths "C:\Temp", "$env:TEMP"
```

### 4) Rollback a previous run

```powershell
.\endpoint-temp-cleanup.ps1 -RollbackRunId 20260805-153000
```

## Logs and state files

The script creates a state folder under `DAY3`:

- `temp-cleanup-state\logs`:
  - One timestamped log per execution.
- `temp-cleanup-state\manifests`:
  - One JSON manifest per cleanup run.
- `temp-cleanup-state\quarantine`:
  - Files moved during cleanup, grouped by run ID.

## Safety notes

- Use `-DryRun` first in production endpoints.
- Rollback depends on quarantine + manifest files remaining intact.
- Running with least privilege may reduce access to some files; those are logged and skipped.
