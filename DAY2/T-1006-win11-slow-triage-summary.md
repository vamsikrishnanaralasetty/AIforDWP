# Triage Summary — T-1006

## Summary
User reports everything is slow since upgrading to Windows 11 two days ago.

## Impact
- Who: Single user (name, team, and role not provided: to-verify)
- How many: 1 confirmed; whether others upgraded at the same time are affected is unknown (to-verify)
- Business urgency: Not stated; ongoing slowness affects productivity (to-verify)

## Known Facts
- User upgraded to Windows 11 two days ago
- User reports general slowness across their device
- Issue began following the Windows 11 upgrade
- Ticket reference: T-1006

## Missing Information to Gather
- User name, team, and contact details (to-verify)
- Device make, model, asset number, and Windows 11 build version installed (to-verify)
- Device specs: RAM, storage type (SSD or HDD), and available disk space (to-verify)
- Whether the slowness is constant or occurs at specific times (startup, app launch, etc.) (to-verify)
- Which applications or tasks are most affected (to-verify)
- Whether drivers and firmware were updated as part of or following the upgrade (to-verify)
- Whether Windows 11 compatibility checks were run before the upgrade (to-verify)
- Whether background processes such as indexing, OneDrive sync, or update installation are still running post-upgrade (to-verify)
- Whether the device has been restarted since the upgrade completed (to-verify)
- Whether other users who upgraded at the same time are reporting similar issues (to-verify)

## Likely Category
Endpoint Performance — Post-Windows 11 Upgrade Degradation (to-verify; likely causes include background indexing/update finalisation, incompatible drivers, or insufficient hardware spec for Windows 11)

## First Diagnostic Step
Open Task Manager and check CPU, memory, and disk utilisation to identify the bottleneck and which process is consuming the most resource, noting whether any Windows update, indexing, or driver-related processes are still running post-upgrade.
